// Piper-Watch controller - face bring-up skeleton for the ESP32-S3.
// The face is a 24-LED WS2812-type ring around the camera lens (data on RING_DATA, through a
// 3.3 V -> 5 V level shifter). This demo cycles through the ring's states every few seconds;
// the pan stepper and the Jetson link (FACE message) come next (see README roadmap).
#include <Arduino.h>
#include <Adafruit_NeoPixel.h>

constexpr int RING_N = 24;
constexpr uint8_t MAX_BRIGHT = 64;                 // ~25%: plenty behind a diffuser, ~250 mA max
Adafruit_NeoPixel ring(RING_N, RING_DATA, NEO_GRB + NEO_KHZ800);

// Colours (scaled by MAX_BRIGHT through setBrightness)
constexpr uint32_t WARM = 0xFFC880;                // idle / listening / speaking: soft warm white
constexpr uint32_t COOL = 0x60A0FF;                // thinking

static uint32_t scale(uint32_t c, float k) {
  if (k <= 0) return 0;
  if (k > 1) k = 1;
  return ring.Color(((c >> 16) & 0xFF) * k, ((c >> 8) & 0xFF) * k, (c & 0xFF) * k);
}

static void fill(uint32_t c) {
  for (int i = 0; i < RING_N; i++) ring.setPixelColor(i, c);
}

// Listening: the whole ring breathes slowly
static void listening(uint32_t t) {
  fill(scale(WARM, 0.25f + 0.75f * (0.5f - 0.5f * cosf(t / 1600.0f * TWO_PI))));
}

// Thinking: a short comet runs around the ring
static void thinking(uint32_t t) {
  float head = fmodf(t / 60.0f, RING_N);
  for (int i = 0; i < RING_N; i++) {
    float d = fmodf(head - i + RING_N, RING_N);    // how far behind the head this pixel is
    ring.setPixelColor(i, scale(COOL, d < 6 ? 1.0f - d / 6 : 0.04f));
  }
}

// Speaking: a quick, slightly irregular pulse
static void speaking(uint32_t t) {
  fill(scale(WARM, 0.45f + 0.35f * sinf(t / 70.0f) + 0.2f * sinf(t / 23.0f)));
}

// Attention: a bright arc pointing toward the tracked person (angle in degrees, 0 = pixel 0)
static void attention(float angle) {
  for (int i = 0; i < RING_N; i++) {
    float a = i * 360.0f / RING_N;
    float d = fabsf(fmodf(a - angle + 540.0f, 360.0f) - 180.0f);   // 0..180 from the arc centre
    ring.setPixelColor(i, scale(WARM, d < 45 ? 1.0f - d / 60 : 0.08f));
  }
}

// Sleep: a dim ember
static void sleeping() { fill(scale(WARM, 0.03f)); }

void setup() {
  Serial.begin(115200);
  delay(1500);                      // let native USB connect
  Serial.println("piper-watch: face (LED ring) bring-up");
  ring.begin();
  ring.setBrightness(MAX_BRIGHT);
  ring.clear();
  ring.show();
  Serial.printf("PSRAM: %u KB\n", (unsigned)(ESP.getPsramSize() / 1024));
}

void loop() {
  static const char *names[] = {"listening", "thinking", "speaking", "attention", "sleeping"};
  static int last = -1;
  uint32_t now = millis();
  int state = (now / 5000) % 5;
  if (state != last) {
    Serial.printf("state: %s\n", names[state]);
    last = state;
  }
  switch (state) {
    case 0: listening(now); break;
    case 1: thinking(now); break;
    case 2: speaking(now); break;
    case 3: attention(60.0f * sinf(now / 1500.0f)); break;   // the arc sweeps as if following someone
    default: sleeping(); break;
  }
  ring.show();
  delay(20);
}
