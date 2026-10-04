#include "ring.h"
#include <math.h>
#include <string.h>

namespace ring {

static const char *STATE_NAMES[] = {"offline", "idle", "listening", "thinking", "speaking", "sleeping", "error"};
static const char *MOOD_NAMES[] = {"neutral", "warm", "curious", "uncertain", "concerned", "sleepy"};

State parseState(const char *s, State fallback) {
  if (!s) return fallback;
  for (int i = 0; i < 7; i++) if (strcmp(s, STATE_NAMES[i]) == 0) return (State)i;
  return fallback;
}
Mood parseMood(const char *s, Mood fallback) {
  if (!s) return fallback;
  for (int i = 0; i < 6; i++) if (strcmp(s, MOOD_NAMES[i]) == 0) return (Mood)i;
  return fallback;
}
const char *stateName(State s) { return STATE_NAMES[(int)s]; }
const char *moodName(Mood m) { return MOOD_NAMES[(int)m]; }

// ---- mood: base colour, brightness and tempo ------------------------------------------------
struct MoodLook { float r, g, b, level, tempo; };
static MoodLook look(Mood m) {
  switch (m) {
    case Mood::Warm:      return {1.00f, 0.66f, 0.36f, 1.10f, 1.0f};   // warmer, a little brighter
    case Mood::Curious:   return {0.55f, 0.75f, 1.00f, 1.00f, 1.0f};   // cool tint (+ shimmer)
    case Mood::Uncertain: return {1.00f, 0.78f, 0.50f, 0.60f, 0.7f};   // dimmer, slower
    case Mood::Concerned: return {1.00f, 0.50f, 0.05f, 1.00f, 1.0f};   // amber
    case Mood::Sleepy:    return {1.00f, 0.58f, 0.28f, 0.35f, 0.6f};   // dim ember
    default:              return {1.00f, 0.78f, 0.50f, 1.00f, 1.0f};   // neutral: soft warm white
  }
}

static float clamp01(float v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

// angular distance in degrees, 0..180
static float angDist(float a, float b) {
  float d = fmodf(fabsf(a - b), 360.0f);
  return d > 180 ? 360 - d : d;
}

void render(const Face &f, uint32_t t, float pixel0_deg, RGB out[N]) {
  MoodLook L = look(f.mood);
  float tt = t * L.tempo;                                  // mood sets the tempo
  float k[N];                                              // per-LED brightness 0..1

  switch (f.state) {
    case State::Offline: {                                 // no Jetson: very dim amber ember
      float v = 0.03f + 0.03f * (0.5f + 0.5f * sinf(t / 2500.0f * TWO_PI));
      for (int i = 0; i < N; i++) k[i] = v;
      L = {1.0f, 0.45f, 0.05f, 1.0f, 1.0f};
      break;
    }
    case State::Idle: {                                    // steady soft glow, a slow drift
      float v = 0.32f + 0.06f * sinf(tt / 6000.0f * TWO_PI);
      for (int i = 0; i < N; i++) k[i] = v;
      break;
    }
    case State::Listening: {                               // whole ring breathes
      float v = 0.25f + 0.75f * (0.5f - 0.5f * cosf(tt / 1600.0f * TWO_PI));
      for (int i = 0; i < N; i++) k[i] = v;
      break;
    }
    case State::Thinking: {                                // a comet runs round
      float head = fmodf(tt / 60.0f, (float)N);
      for (int i = 0; i < N; i++) {
        float d = fmodf(head - i + N, (float)N);           // how far behind the head
        k[i] = d < 6 ? 1.0f - d / 6.0f : 0.05f;
      }
      break;
    }
    case State::Speaking: {                                // quick, slightly irregular pulse
      float v = 0.45f + 0.35f * sinf(tt / 70.0f) + 0.20f * sinf(tt / 23.0f);
      for (int i = 0; i < N; i++) k[i] = clamp01(v);
      break;
    }
    case State::Sleeping: {
      for (int i = 0; i < N; i++) k[i] = 0.04f;
      break;
    }
    case State::Error: {                                   // amber flashes, 2 per second
      float v = ((t / 250) % 2) ? 0.7f : 0.06f;
      for (int i = 0; i < N; i++) k[i] = v;
      L = {1.0f, 0.45f, 0.0f, 1.0f, 1.0f};
      break;
    }
  }

  // curious: a slow shimmer travelling round the ring
  if (f.mood == Mood::Curious && f.state != State::Error && f.state != State::Offline)
    for (int i = 0; i < N; i++) k[i] *= 0.85f + 0.15f * sinf(tt / 900.0f + i * TWO_PI / N);

  // attention: a brighter arc toward the tracked person, the rest dimmed a little
  bool show_attention = f.has_attention &&
      (f.state == State::Idle || f.state == State::Listening || f.state == State::Speaking);
  if (show_attention)
    for (int i = 0; i < N; i++) {
      float a = pixel0_deg + i * 360.0f / N;
      float d = angDist(a, f.attention_deg);
      float arc = d < 45 ? 1.0f - d / 60.0f : 0.0f;
      k[i] = fmaxf(k[i] * 0.6f, arc * fmaxf(k[i], 0.5f) * 1.4f);
    }

  for (int i = 0; i < N; i++) {
    float v = clamp01(k[i] * L.level);
    out[i] = {(uint8_t)(255 * L.r * v), (uint8_t)(255 * L.g * v), (uint8_t)(255 * L.b * v)};
  }
}

}  // namespace ring
