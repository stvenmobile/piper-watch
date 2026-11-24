// CrowPanel Advanced 7" ESP32-P4 (Elecrow DHE04107D V1.0) - display bring-up for Piper's face.
//
// What it does:
//   * powers the MIPI-DSI PHY (internal LDO3 at 2.5 V) and the touch pull-ups (LDO4 at 3.3 V),
//   * starts the EK79007 panel (1024x600, 2 lanes @ 1000 Mbps, 51 MHz pixel clock) with two frame buffers,
//   * shows a test pattern: colour bars, a 64 px grid and coloured corner squares
//       red = top-left, green = top-right, blue = bottom-left, white = bottom-right
//     (if they're elsewhere the picture is mirrored / upside down - tell Claude which),
//   * animates full screen on request and reports frames per second,
//   * reports GT911 touches and draws a dot where you touch.
//
// Serial (115200): ?        state           B<0..100>  backlight %      P  test pattern
//                  A        animation (fps printed every second)        T  touch dots on/off
//                  R        rotate the picture 180 degrees (toggle)
//
// Display settings come from Elecrow's V1.0 Arduino example (board_config.h, esp_lcd_ek79007.c).

#include <Arduino.h>
#include <Wire.h>
#include "esp_lcd_mipi_dsi.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_io.h"
#include "esp_ldo_regulator.h"
#include "esp_idf_version.h"
#include "sdkconfig.h"

// ---- board -------------------------------------------------------------------------------------
static const int W = 1024, H = 600;
static const int PIN_BL = 31, PIN_LCD_RST = 41;
static const int PIN_SDA = 45, PIN_SCL = 46, PIN_TP_RST = 40, PIN_TP_INT = 42;

// ---- display -----------------------------------------------------------------------------------
static esp_lcd_panel_handle_t panel = nullptr;
static uint16_t *fb[2] = {nullptr, nullptr};
static int back = 1;                                   // the buffer we draw into (the other is on screen)
static SemaphoreHandle_t fbFree = nullptr;             // given when the panel has switched buffers
static int brightness = 80;
static esp_lcd_panel_io_handle_t panelIo = nullptr;
static bool flipped = true;                          // rotate 180 deg (the panel scans bottom-up by default)

// EK79007 MADCTL (36h): bit 0 = scan left/right (SHLR), bit 1 = scan up/down (UPDN); Elecrow's default is 0x01.
// Flipping both turns the picture 180 degrees, in the panel itself (costs nothing per frame).
static void setFlip(bool f) {
  flipped = f;
  uint8_t madctl = f ? 0x02 : 0x01;
  esp_lcd_panel_io_tx_param(panelIo, 0x36, &madctl, 1);
}

static bool IRAM_ATTR onFrameDone(esp_lcd_panel_handle_t, esp_lcd_dpi_panel_event_data_t *, void *) {
  BaseType_t woken = pdFALSE;
  xSemaphoreGiveFromISR(fbFree, &woken);
  return woken == pdTRUE;
}

static void check(esp_err_t e, const char *what) {
  if (e == ESP_OK) return;
  Serial.printf("face: FAILED %s: %s\n", what, esp_err_to_name(e));
  while (true) delay(1000);                          // stop here so the message stays readable
}

static void setBacklight(int pct) {
  brightness = constrain(pct, 0, 100);
  ledcWrite(PIN_BL, (1023 * brightness) / 100);      // 10-bit PWM, active high
}

static void displayBegin() {
  // MIPI D-PHY power (LDO3, 2.5 V) and the touch / I2C pull-ups (LDO4, 3.3 V)
  static esp_ldo_channel_handle_t ldo3 = nullptr, ldo4 = nullptr;
  esp_ldo_channel_config_t c3 = {}; c3.chan_id = 3; c3.voltage_mv = 2500;
  esp_ldo_channel_config_t c4 = {}; c4.chan_id = 4; c4.voltage_mv = 3300;
  check(esp_ldo_acquire_channel(&c3, &ldo3), "LDO3 (DSI PHY power)");
  check(esp_ldo_acquire_channel(&c4, &ldo4), "LDO4 (touch power)");

  ledcAttach(PIN_BL, 30000, 10);
  setBacklight(0);                                   // dark until there is a picture

  pinMode(PIN_LCD_RST, OUTPUT);                      // hardware reset: low 10 ms, high, wait
  digitalWrite(PIN_LCD_RST, LOW);  delay(10);
  digitalWrite(PIN_LCD_RST, HIGH); delay(20);

  esp_lcd_dsi_bus_handle_t bus = nullptr;
  esp_lcd_dsi_bus_config_t bc = {};
  bc.bus_id = 0;
  bc.num_data_lanes = 2;
#if CONFIG_ESP32P4_SELECTS_REV_LESS_V3
  bc.phy_clk_src = MIPI_DSI_PHY_PLLREF_CLK_SRC_DEFAULT_LEGACY;   // chip rev < 3 (Elecrow V1.0)
#else
  bc.phy_clk_src = MIPI_DSI_PHY_PLLREF_CLK_SRC_DEFAULT;
#endif
  bc.lane_bit_rate_mbps = 1000;
  check(esp_lcd_new_dsi_bus(&bc, &bus), "DSI bus");

  esp_lcd_panel_io_handle_t io = nullptr;           // the command channel (DBI over DSI)
  esp_lcd_dbi_io_config_t ic = {};
  ic.virtual_channel = 0; ic.lcd_cmd_bits = 8; ic.lcd_param_bits = 8;
  check(esp_lcd_new_panel_io_dbi(bus, &ic, &io), "DBI panel IO");
  panelIo = io;

  // EK79007 init (Elecrow's sequence): 2-lane mode, vendor registers, sleep out
  struct Cmd { uint8_t cmd, val; bool hasVal; uint16_t waitMs; };
  static const Cmd init[] = {
    {0xB2, 0x10, true, 0},                           // pad control: 2 data lanes
    {0x80, 0x8B, true, 0}, {0x81, 0x78, true, 0}, {0x82, 0x84, true, 0}, {0x83, 0x88, true, 0},
    {0x84, 0xA8, true, 0}, {0x85, 0xE3, true, 0}, {0x86, 0x88, true, 0},
    {0x11, 0, false, 120},                           // sleep out
  };
  for (const Cmd &c : init) {
    check(esp_lcd_panel_io_tx_param(io, c.cmd, c.hasVal ? &c.val : nullptr, c.hasVal ? 1 : 0), "EK79007 init");
    if (c.waitMs) delay(c.waitMs);
  }

  esp_lcd_dpi_panel_config_t pc = {};
  pc.virtual_channel = 0;
  pc.dpi_clk_src = MIPI_DSI_DPI_CLK_SRC_DEFAULT;
  pc.dpi_clock_freq_mhz = 51;
  pc.pixel_format = LCD_COLOR_PIXEL_FORMAT_RGB565;
  pc.num_fbs = 2;
  pc.video_timing.h_size = W;
  pc.video_timing.v_size = H;
  pc.video_timing.hsync_pulse_width = 70;
  pc.video_timing.hsync_back_porch = 160;
  pc.video_timing.hsync_front_porch = 160;
  pc.video_timing.vsync_pulse_width = 10;
  pc.video_timing.vsync_back_porch = 23;
  pc.video_timing.vsync_front_porch = 21;
  check(esp_lcd_new_panel_dpi(bus, &pc, &panel), "DPI panel");
  check(esp_lcd_panel_init(panel), "panel init");
  check(esp_lcd_panel_io_tx_param(io, 0x29, nullptr, 0), "display on");
  setFlip(flipped);

  void *a = nullptr, *b = nullptr;
  check(esp_lcd_dpi_panel_get_frame_buffer(panel, 2, &a, &b), "frame buffers");
  fb[0] = (uint16_t *)a; fb[1] = (uint16_t *)b;

  fbFree = xSemaphoreCreateBinary();
  esp_lcd_dpi_panel_event_callbacks_t cbs = {};
  // on_refresh_done: the name every IDF 5.x has (newer ones call it on_frame_buf_complete, same slot)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  cbs.on_refresh_done = onFrameDone;
#pragma GCC diagnostic pop
  check(esp_lcd_dpi_panel_register_event_callbacks(panel, &cbs, nullptr), "frame callback");
}

// Show the back buffer: the panel switches to it at the next frame, then we draw into the other one.
static void present() {
  xSemaphoreTake(fbFree, 0);                         // drop a stale "done"
  esp_lcd_panel_draw_bitmap(panel, 0, 0, W, H, fb[back]);
  xSemaphoreTake(fbFree, pdMS_TO_TICKS(100));        // wait until it is on screen
  back ^= 1;
}

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

static void animFrame(uint16_t *d, uint32_t t) {     // full-screen redraw: sweeping bars + a bouncing box
  fill(d, 0, 0, W, H, rgb(0, 0, 0));
  int n = 32;
  for (int i = 0; i < n; i++) {
    float ph = t * 0.004f + i * 0.35f;
    int h = (int)((0.5f + 0.5f * sinf(ph)) * (H / 2 - 20)) + 4;
    int x = i * W / n + 4;
    fill(d, x, H / 2 - h, W / n - 8, 2 * h, rgb(40 + i * 6, 180, 255 - i * 6));
  }
  int bx = (int)((0.5f + 0.5f * sinf(t * 0.0021f)) * (W - 80)), by = (int)((0.5f + 0.5f * cosf(t * 0.0017f)) * (H - 80));
  fill(d, bx, by, 80, 80, rgb(255, 255, 255));
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

// ---- main --------------------------------------------------------------------------------------
enum Mode { PATTERN, ANIM };
static Mode mode = PATTERN;
static bool dots = true;
static float fps = 0;

static void report() {
  Serial.printf("face: CrowPanel P4 7in %dx%d, mode %s, fps %.1f, backlight %d%%, rotated %s, touch %s, "
                "PSRAM free %u KB\n", W, H, mode == ANIM ? "anim" : "pattern", fps, brightness, flipped ? "180" : "0",
                tpAddr ? "ok" : "none",
                (unsigned)(ESP.getFreePsram() / 1024));
}

static void showPattern() { testPattern(fb[back]); present(); testPattern(fb[back]); }  // both buffers

static void command(char *s) {
  switch (s[0]) {
    case '?': report(); break;
    case 'B': case 'b': setBacklight(atoi(s + 1)); report(); break;
    case 'P': case 'p': mode = PATTERN; showPattern(); report(); break;
    case 'A': case 'a': mode = ANIM; report(); break;
    case 'R': case 'r': setFlip(!flipped); report(); break;
    case 'T': case 't': dots = !dots; Serial.printf("face: touch dots %s\n", dots ? "on" : "off"); break;
    default: if (s[0]) Serial.printf("face: unknown command '%s'\n", s);
  }
}

void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.printf("\nface: CrowPanel P4 bring-up, IDF %s, PSRAM %u KB\n", esp_get_idf_version(),
                (unsigned)(ESP.getPsramSize() / 1024));
  displayBegin();
  Serial.println("face: display started");
  showPattern();
  setBacklight(80);
  touchBegin();
  report();
}

void loop() {
  static char line[32];
  static int len = 0;
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') { line[len] = 0; if (len) command(line); len = 0; }
    else if (len < (int)sizeof(line) - 1) line[len++] = c;
  }

  if (mode == ANIM) {
    static uint32_t frames = 0, t0 = millis();
    animFrame(fb[back], millis());
    present();
    frames++;
    if (millis() - t0 >= 1000) { fps = frames * 1000.0f / (millis() - t0); frames = 0; t0 = millis();
                                 Serial.printf("face: %.1f fps\n", fps); }
  }

  static uint32_t lastTouch = 0;
  if (millis() - lastTouch >= 20) {
    lastTouch = millis();
    int x, y;
    if (touchPoint(x, y)) {
      Serial.printf("face: touch %d,%d\n", x, y);
      if (dots && mode == PATTERN) {                 // draw on both buffers so it stays put
        fill(fb[back], x - 6, y - 6, 12, 12, rgb(255, 0, 255)); present();
        fill(fb[back], x - 6, y - 6, 12, 12, rgb(255, 0, 255));
      }
    }
  }
  if (mode == PATTERN) delay(5);
}
