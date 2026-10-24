// Piper's eyes on the CYD screen: two rounded "screen-robot" eyes that blink, glance toward whoever Piper
// is tracking, wander a little when idle, and change shape with the state and mood (happy arcs, sleepy
// lids, worried brows...). Drawn into an 8-bit sprite and pushed to the screen each frame.
#pragma once
#include <LovyanGFX.hpp>
#include "ring.h"

namespace eyes {

struct Look {
  ring::State state = ring::State::Offline;
  ring::Mood mood = ring::Mood::Neutral;
  bool has_attention = false;     // a person is being tracked ...
  float attention_deg = 0;        // ... this way (ring degrees: 0 = straight ahead, + = clockwise seen from the front)
};

// Draw one frame at time t (ms) into `canvas` (320 x 240).
void render(LGFX_Sprite &canvas, const Look &look, uint32_t t);

}  // namespace eyes
