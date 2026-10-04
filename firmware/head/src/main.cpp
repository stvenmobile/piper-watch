// Piper-Watch controller (ESP32-S3) - phase 1: the Jetson link and the light ring.
//
// Link: newline-delimited JSON over the native USB serial port (/dev/ttyACM0 on the Jetson).
//   Jetson -> ESP32
//     {"t":"HEARTBEAT","seq":812}                         at least every second
//     {"t":"FACE","state":"listening","mood":"warm","attention":-20}   (mood/attention optional;
//                                                          "attention":null clears it)
//     {"t":"CONFIG","max_brightness":64,"ring_offset":0}  (any subset)
//   ESP32 -> Jetson
//     {"t":"STATUS", ...}                                 twice a second
//     {"t":"EVENT","what":"boot"|"watchdog"|"link"}       when they happen
// Unknown messages and fields are ignored, so either side can be updated first.
//
// Watchdog: no HEARTBEAT for 3 s -> the ring drops to a dim amber "offline" ember (and, from
// phase 2, the motor stops).
//
// The ring (24 LEDs on RING_DATA via a 74AHCT125 level shifter) is mirrored on the board's own
// RGB LED (BOARD_RGB) as the average colour, so it can be watched on the bench before the ring
// is wired.
#include <Arduino.h>
#include <ArduinoJson.h>
#include <Adafruit_NeoPixel.h>
#include "ring.h"

#define FW_VERSION "0.2.0"

constexpr uint32_t WATCHDOG_MS = 3000;
constexpr uint32_t STATUS_MS = 500;
constexpr uint32_t FRAME_MS = 20;                    // 50 fps

Adafruit_NeoPixel ringLeds(ring::N, RING_DATA, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel boardLed(1, BOARD_RGB, NEO_GRB + NEO_KHZ800);

ring::Face face;                                     // what the Jetson asked for
uint8_t maxBrightness = 64;                          // ~25%: plenty behind the diffuser
float ringOffsetDeg = 0;                             // where LED 0 sits (0 = top, clockwise)
uint32_t lastHeartbeat = 0, heartbeatSeq = 0, framesDropped = 0;
bool linkUp = false;

// ---- outgoing --------------------------------------------------------------------------------
static void sendEvent(const char *what) {
  JsonDocument d;
  d["t"] = "EVENT";
  d["what"] = what;
  if (strcmp(what, "boot") == 0) d["fw"] = FW_VERSION;
  serializeJson(d, Serial);
  Serial.print('\n');
}

static void sendStatus() {
  JsonDocument d;
  d["t"] = "STATUS";
  d["fw"] = FW_VERSION;
  d["up"] = millis();
  d["link"] = linkUp;
  d["hb"] = heartbeatSeq;
  d["state"] = ring::stateName(face.state);
  d["mood"] = ring::moodName(face.mood);
  if (face.has_attention) d["attention"] = face.attention_deg; else d["attention"] = nullptr;
  d["bad"] = framesDropped;                          // lines that weren't valid JSON
  serializeJson(d, Serial);
  Serial.print('\n');
}

// ---- incoming ----------------------------------------------------------------------------------
static void handle(const char *line) {
  JsonDocument d;
  if (deserializeJson(d, line)) { framesDropped++; return; }
  const char *t = d["t"] | "";

  if (strcmp(t, "HEARTBEAT") == 0) {
    heartbeatSeq = d["seq"] | heartbeatSeq;
    lastHeartbeat = millis();
    if (!linkUp) {
      linkUp = true;
      if (face.state == ring::State::Offline) face.state = ring::State::Idle;
      sendEvent("link");
    }
  } else if (strcmp(t, "FACE") == 0) {
    face.state = ring::parseState(d["state"] | (const char *)nullptr, face.state);
    face.mood = ring::parseMood(d["mood"] | (const char *)nullptr, face.mood);
    // "attention": <deg> sets it, "attention": null clears it, no "attention" key leaves it alone
    for (JsonPairConst kv : d.as<JsonObjectConst>()) {
      if (strcmp(kv.key().c_str(), "attention") != 0) continue;
      if (kv.value().is<float>()) { face.has_attention = true; face.attention_deg = kv.value(); }
      else face.has_attention = false;
    }
  } else if (strcmp(t, "CONFIG") == 0) {
    if (d["max_brightness"].is<int>()) {
      maxBrightness = constrain((int)d["max_brightness"], 0, 255);
      ringLeds.setBrightness(maxBrightness);
      boardLed.setBrightness(maxBrightness);
    }
    if (d["ring_offset"].is<float>()) ringOffsetDeg = d["ring_offset"];
  }
}

static void readSerial() {
  static char buf[512];
  static size_t len = 0;
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (len) { buf[len] = 0; handle(buf); len = 0; }
    } else if (len < sizeof(buf) - 1) {
      buf[len++] = c;
    } else {                                         // overlong line: drop it
      len = 0;
      framesDropped++;
    }
  }
}

// ---- output ------------------------------------------------------------------------------------
static void drawFrame() {
  ring::RGB px[ring::N];
  ring::Face shown = face;
  if (!linkUp) shown.state = ring::State::Offline;
  ring::render(shown, millis(), ringOffsetDeg, px);

  uint32_t r = 0, g = 0, b = 0;
  for (int i = 0; i < ring::N; i++) {
    ringLeds.setPixelColor(i, px[i].r, px[i].g, px[i].b);
    r += px[i].r; g += px[i].g; b += px[i].b;
  }
  ringLeds.show();
  boardLed.setPixelColor(0, r / ring::N, g / ring::N, b / ring::N);   // bench mirror
  boardLed.show();
}

void setup() {
  Serial.begin(115200);
  Serial.setTxTimeoutMs(0);                          // never block if the Jetson isn't reading
  ringLeds.begin();
  boardLed.begin();
  ringLeds.setBrightness(maxBrightness);
  boardLed.setBrightness(maxBrightness);
  delay(300);
  sendEvent("boot");
}

void loop() {
  static uint32_t nextFrame = 0, nextStatus = 0;
  uint32_t now = millis();
  readSerial();

  if (linkUp && now - lastHeartbeat > WATCHDOG_MS) {
    linkUp = false;
    sendEvent("watchdog");
  }
  if ((int32_t)(now - nextFrame) >= 0) { nextFrame = now + FRAME_MS; drawFrame(); }
  if ((int32_t)(now - nextStatus) >= 0) { nextStatus = now + STATUS_MS; sendStatus(); }
  delay(1);
}
