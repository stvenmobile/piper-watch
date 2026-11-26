// Piper's face for a colour screen: RoboEyes-style eyes above a spectrum-analyser mouth.
//
// Hardware-independent: it draws into an RGB565 frame buffer and takes text commands, so the same code runs on the
// CrowPanel P4 (main.cpp) and in a desktop renderer for previews.
//
// The eyes are a port of the FluxGarage RoboEyes library (Copyright (C) 2024-2025 Dennis Hoelscher, GPL-3.0-or-later,
// https://github.com/FluxGarage/RoboEyes), so this face firmware is GPL-3.0-or-later too - see LICENSE in this folder.
#pragma once
#include <stdint.h>

namespace face {

// Size the face to the screen (any size; it is laid out for 1024x600 and scaled).
void begin(int width, int height, uint32_t seed);

// Draw one frame for time nowMs into fb (width*height RGB565, row-major).
void draw(uint16_t *fb, uint32_t nowMs);

// One command line (without newline), the same protocol as piper-watch's mouth OLED:
//   M<mode>   neutral talk happytalk smile frown surprise sleep happysleep research blank excitedtalk  (or 0..10)
//             talk / happytalk: bars to half height; excitedtalk: full height
//   I<status> idle listening thinking confused  (or 0..3)
//   L<0..255> speech loudness, ~30 Hz while speaking (else talk modes simulate speech)
//   G<x>,<y>  look towards x,y (-100..100 each; right / down positive) for the next 3 s
//   D1 / D0   demo loop on / off
//   S<style>  accepted for compatibility (only "spectrum" here)
//   C<0..255> brightness (the mouth's contrast)
//   ?         state
// Replies (and the demo's progress) go to `out`.
void command(const char *line, uint32_t nowMs, void (*out)(const char *));

// What the backlight should be, 0..100 (0 while blank).
int backlight();

}  // namespace face
