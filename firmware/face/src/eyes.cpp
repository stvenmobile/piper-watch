#include "eyes.h"
#include <math.h>

namespace eyes {

// The head's window shows the screen through an octagon with ~7 mm corners (~45 px): keep the eyes inside.
constexpr int W = 320, H = 240;
constexpr int EYE_W = 74, EYE_H = 92, EYE_R = 24;   // one eye, at rest
constexpr int SPACING = 124;                        // between the eyes' centres
constexpr int GAZE_X = 30, GAZE_Y = 18;             // how far the eyes move to look aside / up-down

static float clamp(float v, float lo, float hi) { return v < lo ? lo : (v > hi ? hi : v); }
static float ease(float x) { return x * x * (3 - 2 * x); }   // smoothstep 0..1

// ---- blinking and idle glances (their own clocks, independent of the messages) -------------------------
static uint32_t nextBlink = 2000, blinkStart = 0;
static float wanderX = 0, wanderY = 0, wanderToX = 0, wanderToY = 0;
static uint32_t nextWander = 3000;

static float blinkAmount(uint32_t t) {               // 1 = open, ~0 = shut
  if (t >= nextBlink && blinkStart < nextBlink) blinkStart = t;
  if (blinkStart && t - blinkStart < 180) {
    float p = (t - blinkStart) / 180.0f;               // shut and open again in 180 ms
    float v = p < 0.5f ? 1 - ease(p * 2) : ease((p - 0.5f) * 2);
    return 0.06f + 0.94f * v;
  }
  if (blinkStart && t - blinkStart >= 180 && nextBlink <= blinkStart) {
    nextBlink = t + 2500 + (esp_random() % 4000);      // every 2.5 - 6.5 s
    if (esp_random() % 6 == 0) nextBlink = t + 260;   // now and then a double blink
  }
  return 1;
}

static void wander(uint32_t t, bool active) {
  if (!active) { wanderToX = wanderToY = 0; }
  else if (t >= nextWander) {
    nextWander = t + 1500 + (esp_random() % 3500);
    wanderToX = ((int)(esp_random() % 200) - 100) / 100.0f * 0.5f;
    wanderToY = ((int)(esp_random() % 200) - 100) / 100.0f * 0.4f;
  }
  wanderX += (wanderToX - wanderX) * 0.15f;            // quick, smooth saccade toward the new spot
  wanderY += (wanderToY - wanderY) * 0.15f;
}

// ---- colours -------------------------------------------------------------------------------------------
static uint16_t eyeColour(const Look &l) {
  switch (l.state) {
    case ring::State::Offline: return lgfx::color565(40, 70, 90);
    case ring::State::Error:   return lgfx::color565(255, 120, 0);
    default: break;
  }
  switch (l.mood) {
    case ring::Mood::Warm:      return lgfx::color565(120, 220, 255);
    case ring::Mood::Concerned: return lgfx::color565(255, 170, 60);
    case ring::Mood::Sleepy:    return lgfx::color565(60, 130, 170);
    default:                    return lgfx::color565(76, 194, 255);   // Piper blue
  }
}

// One eye centred at (cx, cy): w x h, with lids cut out of it for moods. `side` = -1 left, +1 right.
static void drawEye(LGFX_Sprite &c, int cx, int cy, int w, int h, uint16_t col, const Look &l, int side) {
  if (h < 6) {                                         // shut: a line
    c.fillRoundRect(cx - w / 2, cy - 3, w, 6, 3, col);
    return;
  }
  c.fillRoundRect(cx - w / 2, cy - h / 2, w, h, min(EYE_R, h / 2), col);
  uint16_t bg = TFT_BLACK;
  switch (l.mood) {
    case ring::Mood::Warm:                             // happy: a bottom lid curving up ("smiling eyes")
      c.fillEllipse(cx, cy + h / 2 + h / 5, w * 0.75f, h * 0.45f, bg);
      break;
    case ring::Mood::Sleepy:                           // heavy top lids
      c.fillRect(cx - w / 2 - 1, cy - h / 2 - 1, w + 2, h * 0.45f, bg);
      break;
    case ring::Mood::Concerned: {                      // worried: inner corners raised (brows slope down outward)
      int x0 = cx - w / 2 - 1, x1 = cx + w / 2 + 1, top = cy - h / 2 - 1;
      int inner = side < 0 ? x1 : x0, outer = side < 0 ? x0 : x1;
      c.fillTriangle(outer, top, inner, top, outer, top + h * 0.35f, bg);
      break;
    }
    case ring::Mood::Uncertain:                        // a slight squint on one side
      if (side > 0) c.fillRect(cx - w / 2 - 1, cy - h / 2 - 1, w + 2, h * 0.22f, bg);
      break;
    default:
      break;
  }
  if (l.state == ring::State::Offline)                 // half asleep while there's no link
    c.fillRect(cx - w / 2 - 1, cy - h / 2 - 1, w + 2, h * 0.5f, bg);
}

void render(LGFX_Sprite &c, const Look &l, uint32_t t) {
  c.fillScreen(TFT_BLACK);

  // where to look: the tracked person (attention), else wander when idle/listening, thinking looks up and away
  bool idleish = l.state == ring::State::Idle || l.state == ring::State::Listening || l.state == ring::State::Speaking;
  wander(t, idleish && !l.has_attention);
  float gx = wanderX, gy = wanderY;
  if (l.has_attention) gx = clamp(l.attention_deg / 60.0f, -1, 1);           // glance toward them
  if (l.state == ring::State::Thinking) {                                       // look up and to one side, drifting
    gx = 0.6f * sinf(t / 1800.0f); gy = -0.7f;
  }

  float open = blinkAmount(t);
  float scale = 1.0f;
  if (l.state == ring::State::Listening) scale = 1.06f;                       // attentive: a little wider
  if (l.mood == ring::Mood::Curious) scale = 1.04f;
  float bob = l.state == ring::State::Speaking ? 3 * sinf(t / 130.0f) : 0;    // a little life while talking

  int w = EYE_W * scale, h = EYE_H * scale * open;
  if (l.state == ring::State::Sleeping) h = 0;                                  // shut
  int cy = H / 2 + (int)(gy * GAZE_Y + bob);
  uint16_t col = eyeColour(l);
  for (int side = -1; side <= 1; side += 2) {
    int cx = W / 2 + side * SPACING / 2 + (int)(gx * GAZE_X);
    int hh = h;
    if (l.mood == ring::Mood::Curious && side > 0) hh = h * 1.08f;            // curious: one eye a touch bigger
    drawEye(c, cx, cy, w, hh, col, l, side);
  }
  if (l.state == ring::State::Sleeping) {             // a small "zzz" drifting up
    int z = (t / 40) % 60;
    c.setTextColor(lgfx::color565(60, 130, 170));
    c.setTextSize(2);
    c.setCursor(W / 2 + 70 + z / 3, H / 2 - 20 - z);
    c.print("zzz");
  }
}

}  // namespace eyes
