// Light-ring renderer: turns Piper's state + mood (+ an optional attention direction) into a
// frame for the 24-LED ring. Pure logic - no hardware - so it is easy to reason about; main.cpp
// pushes the colours out (to the ring and, on the bench, to the board's RGB LED).
#pragma once
#include <Arduino.h>

namespace ring {

constexpr int N = 24;                      // LEDs

enum class State { Offline, Idle, Listening, Thinking, Speaking, Sleeping, Error };
enum class Mood { Neutral, Warm, Curious, Uncertain, Concerned, Sleepy };

struct RGB { uint8_t r, g, b; };

struct Face {
  State state = State::Offline;           // Offline until the Jetson's first heartbeat
  Mood mood = Mood::Neutral;
  bool has_attention = false;              // a person is being tracked ...
  float attention_deg = 0;                 // ... in this direction (0 = up, clockwise, seen from the front)
};

State parseState(const char *s, State fallback);
Mood parseMood(const char *s, Mood fallback);
const char *stateName(State s);
const char *moodName(Mood m);

// Render one frame at time t (ms). pixel0_deg: where LED 0 sits (0 = top, clockwise, from the front).
void render(const Face &f, uint32_t t, float pixel0_deg, RGB out[N]);

}  // namespace ring
