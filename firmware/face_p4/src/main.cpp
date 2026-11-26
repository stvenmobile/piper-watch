// Piper's face on a CrowPanel Advanced ESP32-P4, running the face in face.cpp - RoboEyes-style eyes over the
// spectrum mouth. The panel is picked at build time (panel.h, one PlatformIO env each):
//   crowpanel_p4_5  5" DHE04005D 800x480, parallel RGB (the final head)
//   crowpanel_p4_7  7" DHE04107D 1024x600, MIPI-DSI EK79007 (the bench)
//
// Serial (115200), one command per line. The mouth OLED's protocol, so piper_assistant drives it unchanged:
//   M<mode>  I<status>  L<0..255>  G<x>,<y>  D1/D0  S<style>  C<0..255>  ?      (see face.h)
// and for the bench:
//   B<0..100>  backlight %, overriding C       P  test pattern on / off
//   R          rotate 180 degrees              F  frames per second
//
// Upright: the board's USB connectors on the LEFT (R for the other way round).
//
// Display settings come from Elecrow's V1.0 examples (see panel_7in_dsi.cpp / panel_5in_rgb.cpp).
// The face's eyes are a port of FluxGarage RoboEyes (GPL-3.0-or-later), so this firmware is GPL-3.0-or-later.
//
// Version: 1.1.0
// Created: 2026-11-23
// Last modified: 2026-11-26
// History:
//   1.0.0  2026-11-23  7" CrowPanel P4: display bring-up + the face.
//   1.1.0  2026-11-26  Display code moved to panel_7in_dsi.cpp / panel_5in_rgb.cpp behind panel.h; the 5"
//                      CrowPanel P4 added. Frames are drawn into drawBuf(); touch goes through touchToScreen().

#include <Arduino.h>
#include <Wire.h>
#include "esp_idf_version.h"
#include "panel.h"
#include "face.h"

// ---- drawing -----------------------------------------------------------------------------------
static inline uint16_t rgb(uint8_t r, uint8_t g, uint8_t b) { return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3); }

static void fill(uint16_t *d, int x, int y, int w, int h, uint16_t c) {
  if (x < 0) { w += x; x = 0; }
  if (y < 0) { h += y; y = 0; }
  if (x + w > W) w = W - x;
  if (y + h > H) h = H - y;
  for (int j = 0; j < h; j++) { uint16_t *p = d + (y + j) * W + x; for (int i = 0; i < w; i++) p[i] = c; }
}

static void testPattern(uint16_t *d) {
  static const uint16_t bars[8] = {rgb(255, 255, 255), rgb(255, 255, 0), rgb(0, 255, 255), rgb(0, 255, 0),
                                   rgb(255, 0, 255), rgb(255, 0, 0), rgb(0, 0, 255), rgb(0, 0, 0)};
  fill(d, 0, 0, W, H, rgb(16, 16, 16));
  for (int i = 0; i < 8; i++) fill(d, i * W / 8, 0, W / 8 + 1, H / 2, bars[i]);
  for (int x = 0; x < W; x++) {                      // grey ramp under the bars
    uint8_t v = x * 255 / (W - 1);
    fill(d, x, H / 2, 1, 60, rgb(v, v, v));
  }
  for (int x = 0; x < W; x += 64) fill(d, x, H / 2 + 60, 1, H / 2 - 60, rgb(90, 90, 90));
  for (int y = H / 2 + 60; y < H; y += 64) fill(d, 0, y, W, 1, rgb(90, 90, 90));
  const int s = 48;                                  // orientation markers
  fill(d, 0, 0, s, s, rgb(255, 0, 0));
  fill(d, W - s, 0, s, s, rgb(0, 255, 0));
  fill(d, 0, H - s, s, s, rgb(0, 0, 255));
  fill(d, W - s, H - s, s, s, rgb(255, 255, 255));
  fill(d, 0, 0, W, 2, rgb(255, 128, 0));             // 2 px orange frame: every edge pixel visible?
  fill(d, 0, H - 2, W, 2, rgb(255, 128, 0));
  fill(d, 0, 0, 2, H, rgb(255, 128, 0));
  fill(d, W - 2, 0, 2, H, rgb(255, 128, 0));
}

// ---- touch (GT911) -----------------------------------------------------------------------------
static uint8_t tpAddr = 0;

static bool tpRead(uint16_t reg, uint8_t *buf, int n) {
  Wire.beginTransmission(tpAddr); Wire.write(reg >> 8); Wire.write(reg & 0xFF);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom((int)tpAddr, n) != n) return false;
  for (int i = 0; i < n; i++) buf[i] = Wire.read();
  return true;
}

static void tpWrite(uint16_t reg, uint8_t v) {
  Wire.beginTransmission(tpAddr); Wire.write(reg >> 8); Wire.write(reg & 0xFF); Wire.write(v); Wire.endTransmission();
}

static void touchBegin() {
  pinMode(PIN_TP_INT, OUTPUT); digitalWrite(PIN_TP_INT, LOW);   // INT low during reset -> address 0x5D
  pinMode(PIN_TP_RST, OUTPUT); digitalWrite(PIN_TP_RST, LOW); delay(10);
  digitalWrite(PIN_TP_RST, HIGH); delay(60);
  pinMode(PIN_TP_INT, INPUT);
  Wire.begin(PIN_SDA, PIN_SCL, 400000);
  for (uint8_t a : {(uint8_t)0x5D, (uint8_t)0x14}) {
    Wire.beginTransmission(a);
    if (Wire.endTransmission() == 0) { tpAddr = a; break; }
  }
  if (!tpAddr) { Serial.println("face: no GT911 answered on I2C (0x5D / 0x14)"); return; }
  uint8_t id[4] = {0};
  tpRead(0x8140, id, 4);
  Serial.printf("face: touch GT911 at 0x%02X, id %c%c%c%c\n", tpAddr, id[0], id[1], id[2], id[3]);
}

static bool touchPoint(int &x, int &y) {
  if (!tpAddr) return false;
  uint8_t st;
  if (!tpRead(0x814E, &st, 1) || !(st & 0x80)) return false;
  bool got = false;
  if ((st & 0x0F) > 0) {
    uint8_t p[6];
    if (tpRead(0x8150, p, 6)) { x = p[0] | (p[1] << 8); y = p[2] | (p[3] << 8); got = true; }
  }
  tpWrite(0x814E, 0);                                // "read it"
  return got;
}

static void showPattern() { testPattern(drawBuf()); present(); testPattern(drawBuf()); }  // both buffers

// ---- main --------------------------------------------------------------------------------------------------
static bool pattern = false;                         // P: the bring-up test pattern instead of the face
static int backlightOverride = -1;                   // B: fixed %, else the face's (C / blank)
static float fps = 0;

static void say(const char *s) { Serial.println(s); }

static void command(char *s) {
  switch (s[0]) {
    case 'B': case 'b': backlightOverride = constrain(atoi(s + 1), 0, 100);
                        Serial.printf("face: backlight %d%%\n", backlightOverride); return;
    case 'P': case 'p': pattern = !pattern; if (pattern) showPattern();
                        Serial.printf("face: test pattern %s\n", pattern ? "on" : "off"); return;
    case 'R': case 'r': setFlip(!flipped()); if (pattern) showPattern();
                        Serial.printf("face: rotated %s\n", flipped() ? "180" : "0"); return;
    case 'F': case 'f': Serial.printf("face: %.1f fps, PSRAM free %u KB, touch %s\n", fps,
                                      (unsigned)(ESP.getFreePsram() / 1024), tpAddr ? "ok" : "none"); return;
    default: face::command(s, millis(), say);
  }
}

void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.printf("\nface: %s face, IDF %s, PSRAM %u KB\n", PANEL_NAME, esp_get_idf_version(),
                (unsigned)(ESP.getPsramSize() / 1024));
  displayBegin();
  face::begin(W, H, esp_random());
  face::draw(drawBuf(), millis());                   // first frame before the light comes on
  present();
  touchBegin();
  face::command("?", millis(), say);
}

void loop() {
  static char line[48];
  static int len = 0;
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') { line[len] = 0; if (len) command(line); len = 0; }
    else if (len < (int)sizeof(line) - 1) line[len++] = c;
  }

  if (!pattern) {
    static uint32_t frames = 0, t0 = millis();
    face::draw(drawBuf(), millis());
    present();
    if (++frames, millis() - t0 >= 1000) { fps = frames * 1000.0f / (millis() - t0); frames = 0; t0 = millis(); }
  } else {
    delay(10);
  }

  int bl = backlightOverride >= 0 ? backlightOverride : face::backlight();
  if (bl != backlight()) setBacklight(bl);

  static uint32_t lastTouch = 0;                     // touches are reported (piper_assistant ignores them for now)
  if (millis() - lastTouch >= 30) {
    lastTouch = millis();
    int x, y;
    if (touchPoint(x, y)) { touchToScreen(x, y); Serial.printf("face: touch %d,%d\n", x, y); }
  }
}
