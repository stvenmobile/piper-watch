// Piper's face - Guition ESP32-2432S024 (2.4" CYD) in the head: eyes on the screen, the LED-ring mouth.
//
// Link: newline-delimited JSON over USB (the board's CH340), 115200 baud - the same messages as the old
// head controller, so piper_assistant's head link drives it as it is:
//   Pi -> face
//     {"t":"HEARTBEAT","seq":812}                                  at least every second
//     {"t":"FACE","state":"speaking","mood":"warm","attention":-20}   (mood/attention optional;
//                                                                   "attention":null clears it)
//     {"t":"MOUTH","level":0.62}                                   speech loudness 0..1, ~20/s while speaking
//     {"t":"CONFIG","max_brightness":40,"screen":200}              ring cap, screen backlight 0..255
//   face -> Pi
//     {"t":"STATUS", ...}                                          twice a second
//     {"t":"EVENT","what":"boot"|"watchdog"|"link"}
// Unknown messages and fields are ignored.
//
// No heartbeat for 3 s -> "offline" (dim, half-shut eyes; the mouth a dim ember). Until the FIRST heartbeat
// after power-up it runs a DEMO: it cycles through the states and moods so the eyes and mouth can be checked
// on the bench without the Pi.
#include <Arduino.h>
#include <ArduinoJson.h>
#include <Adafruit_NeoPixel.h>
#include <LovyanGFX.hpp>
#include "ring.h"
#include "eyes.h"

#define FW_VERSION "face-0.1.0"

constexpr uint32_t WATCHDOG_MS = 3000;
constexpr uint32_t STATUS_MS = 500;
constexpr uint32_t FRAME_MS = 33;                    // ~30 fps for the eyes and the mouth
constexpr uint32_t MOUTH_HOLD_MS = 300;              // a MOUTH level counts for this long

// ---- the screen: ILI9341 on the CYD's SPI pins -------------------------------------------------------------
class LGFX : public lgfx::LGFX_Device {
  lgfx::Panel_ILI9341 panel;
  lgfx::Bus_SPI bus;
  lgfx::Light_PWM light;
 public:
  LGFX() {
    { auto c = bus.config();
      c.spi_host = HSPI_HOST; c.spi_mode = 0; c.freq_write = 40000000; c.freq_read = 16000000;
      c.pin_sclk = 14; c.pin_mosi = 13; c.pin_miso = 12; c.pin_dc = 2;
      bus.config(c); panel.setBus(&bus); }
    { auto c = panel.config();
      c.pin_cs = 15; c.pin_rst = -1; c.pin_busy = -1;
      c.panel_width = 240; c.panel_height = 320;
      c.invert = TFT_INVERT; c.rgb_order = !TFT_BGR; c.readable = true; c.bus_shared = false;
      panel.config(c); }
    { auto c = light.config();
      c.pin_bl = TFT_BL; c.invert = false; c.freq = 44100; c.pwm_channel = 7;
      light.config(c); panel.setLight(&light); }
    setPanel(&panel);
  }
};

LGFX lcd;
LGFX_Sprite canvas(&lcd);
Adafruit_NeoPixel mouth(ring::N, RING_DATA, NEO_GRB + NEO_KHZ800);

ring::Face face;                                     // what the Pi asked for
uint8_t maxBrightness = 40;                          // the mouth's cap (~15 %): plenty behind the diffuser
uint32_t lastHeartbeat = 0, heartbeatSeq = 0, badLines = 0, mouthAt = 0;
bool linkUp = false, everLinked = false;

// ---- outgoing ----------------------------------------------------------------------------------------------
static void sendEvent(const char *what) {
  JsonDocument d;
  d["t"] = "EVENT"; d["what"] = what;
  if (strcmp(what, "boot") == 0) d["fw"] = FW_VERSION;
  serializeJson(d, Serial); Serial.print('\n');
}

static void sendStatus() {
  JsonDocument d;
  d["t"] = "STATUS"; d["fw"] = FW_VERSION; d["up"] = millis(); d["link"] = linkUp;
  d["demo"] = !everLinked; d["hb"] = heartbeatSeq;
  d["state"] = ring::stateName(face.state); d["mood"] = ring::moodName(face.mood);
  if (face.has_attention) d["attention"] = face.attention_deg; else d["attention"] = nullptr;
  d["bad"] = badLines;
  serializeJson(d, Serial); Serial.print('\n');
}

// ---- incoming ----------------------------------------------------------------------------------------------
static void handle(const char *line) {
  JsonDocument d;
  if (deserializeJson(d, line)) { badLines++; return; }
  const char *t = d["t"] | "";
  if (strcmp(t, "HEARTBEAT") == 0) {
    heartbeatSeq = d["seq"] | heartbeatSeq;
    lastHeartbeat = millis();
    if (!linkUp) {
      linkUp = true;
      if (!everLinked) { everLinked = true; face = ring::Face(); face.state = ring::State::Idle; }   // demo over
      if (face.state == ring::State::Offline) face.state = ring::State::Idle;
      sendEvent("link");
    }
  } else if (strcmp(t, "FACE") == 0) {
    face.state = ring::parseState(d["state"] | (const char *)nullptr, face.state);
    face.mood = ring::parseMood(d["mood"] | (const char *)nullptr, face.mood);
    for (JsonPairConst kv : d.as<JsonObjectConst>()) {        // "attention": deg sets, null clears, absent keeps
      if (strcmp(kv.key().c_str(), "attention") != 0) continue;
      if (kv.value().is<float>()) { face.has_attention = true; face.attention_deg = kv.value(); }
      else face.has_attention = false;
    }
  } else if (strcmp(t, "MOUTH") == 0) {
    face.mouth_level = d["level"] | 0.0f;
    mouthAt = millis();
  } else if (strcmp(t, "CONFIG") == 0) {
    if (d["max_brightness"].is<int>()) { maxBrightness = constrain((int)d["max_brightness"], 0, 255); mouth.setBrightness(maxBrightness); }
    if (d["screen"].is<int>()) lcd.setBrightness(constrain((int)d["screen"], 0, 255));
  }
}

static void readSerial() {
  static char buf[512];
  static size_t len = 0;
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') { if (len) { buf[len] = 0; handle(buf); len = 0; } }
    else if (len < sizeof(buf) - 1) buf[len++] = c;
    else { len = 0; badLines++; }
  }
}

// ---- demo: until the Pi's first heartbeat, show off the states and moods ------------------------------------
static void demo(uint32_t now) {
  static const ring::State states[] = {ring::State::Idle, ring::State::Listening, ring::State::Thinking,
                                       ring::State::Speaking, ring::State::Idle, ring::State::Sleeping};
  static const ring::Mood moods[] = {ring::Mood::Neutral, ring::Mood::Warm, ring::Mood::Curious,
                                     ring::Mood::Concerned, ring::Mood::Sleepy, ring::Mood::Uncertain};
  int step = (now / 4000) % 12;                       // a new pose every 4 s
  face.state = states[step % 6];
  face.mood = moods[(step / 2) % 6];
  face.has_attention = (step % 4) == 1;
  face.attention_deg = 40 * sinf(now / 1500.0f);
  face.mouth_level = face.state == ring::State::Speaking ? 0.5f + 0.5f * sinf(now / 90.0f) * sinf(now / 37.0f) : -1;
}

// ---- output ------------------------------------------------------------------------------------------------
static void drawFrame(uint32_t now) {
  ring::Face shown = face;
  if (everLinked && !linkUp) shown.state = ring::State::Offline;
  if (everLinked && now - mouthAt > MOUTH_HOLD_MS) shown.mouth_level = -1;   // stale level: back to the pulse
  shown.has_attention = false;                        // the mouth doesn't glance - the eyes do

  ring::RGB px[ring::N];
  ring::render(shown, now, 0, px);
  for (int i = 0; i < ring::N; i++) mouth.setPixelColor(i, px[i].r, px[i].g, px[i].b);
  mouth.show();

  eyes::Look look;
  look.state = shown.state; look.mood = shown.mood;
  look.has_attention = face.has_attention; look.attention_deg = face.attention_deg;
  eyes::render(canvas, look, now);
  canvas.pushSprite(0, 0);
}

void setup() {
  Serial.begin(115200);
  lcd.init();
  lcd.setRotation(TFT_ROTATION);
  lcd.setBrightness(200);
  canvas.setColorDepth(8);                            // 320 x 240 x 1 byte = 77 KB: fits without PSRAM
  if (!canvas.createSprite(lcd.width(), lcd.height())) {
    lcd.fillScreen(TFT_RED);
    lcd.drawString("sprite: out of memory", 10, 10);
  }
  mouth.begin();
  mouth.setBrightness(maxBrightness);
  sendEvent("boot");
}

void loop() {
  static uint32_t nextFrame = 0, nextStatus = 0;
  uint32_t now = millis();
  readSerial();
  if (!everLinked) demo(now);
  if (linkUp && now - lastHeartbeat > WATCHDOG_MS) { linkUp = false; sendEvent("watchdog"); }
  if ((int32_t)(now - nextFrame) >= 0) { nextFrame = now + FRAME_MS; drawFrame(now); }
  if ((int32_t)(now - nextStatus) >= 0) { nextStatus = now + STATUS_MS; sendStatus(); }
  delay(1);
}
