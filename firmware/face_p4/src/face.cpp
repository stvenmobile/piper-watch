// Piper's face: RoboEyes-style eyes above a spectrum-analyser mouth. See face.h.
//
// Eyes: a port of FluxGarage RoboEyes (Copyright (C) 2024-2025 Dennis Hoelscher, GPL-3.0-or-later) to colour and to
// time-based easing - rounded rectangles that glide toward their targets, moods cut in by eyelid masks (tired / angry
// triangles from the top, a rounded "happy" mask from below), auto-blink, idle glances, the curious outer eye, and
// the laugh / confused shakes.
// Mouth: the spectrum style of piper-watch's OLED mouth - mirrored lanes, low pitches in the middle, simulated
// formants per syllable, most syllables leaning to one side, flat centre line.
//
// Everything is laid out in a 1024 x 600 design space and scaled to the real screen.
//
// Version 1.3.0 - created 2026-11-23, last modified 2026-11-26
// History:
//   1.3.0  2026-11-26  Surprise: the "O" opens wide, shrinks small and opens wide again (~1.1 s), then stays wide.
//                      Listening: a scanner sweeps the mouth's bars side to side (Knight Rider style).
//   1.2.0  2026-11-26  The mouth line bends both ways: smile curves up, frown curves down (an upside-down smile),
//                      happytalk talks on an upturned curve (the bars stay separate). Surprise: the "O" starts
//                      small, pops wide and settles back to small over ~1.2 s.
//   1.1.0  2026-11-24  Two levels of talk: talk / happytalk keep the bars to half height; the new excitedtalk mode
//                      uses the full height (and widens the eyes a little).
//   1.0.0  2026-11-23  RoboEyes-style eyes over the spectrum mouth, the mouth OLED's protocol.
#include "face.h"

#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <algorithm>

namespace face {
namespace {

// ---- screen and drawing --------------------------------------------------------------------------------------------
const float DW = 1024, DH = 600;                     // design space
const float FACE_SCALE = 0.85f;                      // the face's size on the screen (1 = fills it)
int W = 1024, H = 600;
float S = 1, OX = 0, OY = 0;                         // design -> screen: x * S + OX
uint16_t *fb = nullptr;

inline int X(float x) { return (int)lroundf(x * S + OX); }
inline int Y(float y) { return (int)lroundf(y * S + OY); }
inline int L(float d) { return (int)lroundf(d * S); }

inline uint16_t rgb(int r, int g, int b) { return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3); }
inline uint16_t mix(int r1, int g1, int b1, int r2, int g2, int b2, float t) {
  return rgb(r1 + (int)((r2 - r1) * t), g1 + (int)((g2 - g1) * t), b1 + (int)((b2 - b1) * t));
}
const uint16_t BG = 0;
const int EYE_R = 90, EYE_G = 200, EYE_B = 255;      // soft cyan

void hspan(int y, int x0, int x1, uint16_t c) {      // x0..x1 inclusive
  if (y < 0 || y >= H) return;
  if (x0 < 0) x0 = 0;
  if (x1 > W - 1) x1 = W - 1;
  uint16_t *p = fb + y * W;
  for (int x = x0; x <= x1; x++) p[x] = c;
}

void fillRect(int x, int y, int w, int h, uint16_t c) {
  for (int j = 0; j < h; j++) hspan(y + j, x, x + w - 1, c);
}

void fillRoundRect(int x, int y, int w, int h, int r, uint16_t c) {
  if (w <= 0 || h <= 0) return;
  if (r > w / 2) r = w / 2;
  if (r > h / 2) r = h / 2;
  for (int j = 0; j < h; j++) {
    float dy = 0;
    if (j < r) dy = r - j - 0.5f;
    else if (j >= h - r) dy = j - (h - r) + 0.5f;
    int in = dy > 0 ? (int)lroundf(r - sqrtf(fmaxf(0, r * r - dy * dy))) : 0;
    hspan(y + j, x + in, x + w - 1 - in, c);
  }
}

void fillTriangle(float x0, float y0, float x1, float y1, float x2, float y2, uint16_t c) {
  if (y0 > y1) { float t = y0; y0 = y1; y1 = t; t = x0; x0 = x1; x1 = t; }
  if (y1 > y2) { float t = y1; y1 = y2; y2 = t; t = x1; x1 = x2; x2 = t; }
  if (y0 > y1) { float t = y0; y0 = y1; y1 = t; t = x0; x0 = x1; x1 = t; }
  for (int y = (int)ceilf(y0); y <= (int)floorf(y2); y++) {
    float xa = y2 > y0 ? x0 + (x2 - x0) * (y - y0) / (y2 - y0) : x0, xb;
    if (y < y1) xb = y1 > y0 ? x0 + (x1 - x0) * (y - y0) / (y1 - y0) : x0;
    else        xb = y2 > y1 ? x1 + (x2 - x1) * (y - y1) / (y2 - y1) : x1;
    if (xa > xb) { float t = xa; xa = xb; xb = t; }
    hspan(y, (int)lroundf(xa), (int)lroundf(xb), c);
  }
}

void fillCircle(float cx, float cy, float r, uint16_t c) {
  for (int y = (int)floorf(cy - r); y <= (int)ceilf(cy + r); y++) {
    float d = y + 0.5f - cy, h = r * r - d * d;
    if (h < 0) continue;
    float s = sqrtf(h);
    hspan(y, (int)lroundf(cx - s), (int)lroundf(cx + s) - 1, c);
  }
}

void ellipseRing(float cx, float cy, float rx, float ry, float t, uint16_t c) {
  float ix = fmaxf(0, rx - t), iy = fmaxf(0, ry - t);
  for (int y = (int)floorf(cy - ry); y <= (int)ceilf(cy + ry); y++) {
    float d = y + 0.5f - cy;
    if (fabsf(d) >= ry) continue;
    float o = rx * sqrtf(1 - d * d / (ry * ry));
    float i = (iy > 0 && fabsf(d) < iy) ? ix * sqrtf(1 - d * d / (iy * iy)) : -1;
    if (i < 0) hspan(y, (int)lroundf(cx - o), (int)lroundf(cx + o) - 1, c);
    else { hspan(y, (int)lroundf(cx - o), (int)lroundf(cx - i) - 1, c); hspan(y, (int)lroundf(cx + i), (int)lroundf(cx + o) - 1, c); }
  }
}

void thickLine(float x0, float y0, float x1, float y1, float w, uint16_t c) {
  float len = hypotf(x1 - x0, y1 - y0);
  int steps = (int)ceilf(len) + 1;
  int s = (int)fmaxf(1, lroundf(w));
  for (int k = 0; k <= steps; k++) {
    float t = steps ? (float)k / steps : 0;
    fillRect((int)lroundf(x0 + (x1 - x0) * t - s / 2.0f), (int)lroundf(y0 + (y1 - y0) * t - s / 2.0f), s, s, c);
  }
}

// ---- small helpers ---------------------------------------------------------------------------------------------------
uint32_t rngState = 0x9E3779B9;
inline float rnd() {                                 // 0..1
  uint32_t x = rngState;
  x ^= x << 13; x ^= x >> 17; x ^= x << 5;
  rngState = x;
  return x / 4294967296.0f;
}
inline float clampf(float v, float a, float b) { return v < a ? a : v > b ? b : v; }
inline float gaussf(float x, float c, float w) { float d = (x - c) / w; return expf(-d * d); }
inline float ease(float cur, float target, float k) { return cur + (target - cur) * k; }
const float PI_F = 3.14159265f;

// ---- modes and status (the mouth OLED's protocol) --------------------------------------------------------------------
// EXCITED_TALK is last so the numeric modes 0..9 keep their old meaning
enum Mode { NEUTRAL, TALK, HAPPY_TALK, SMILE, FROWN, SURPRISE, SLEEP, HAPPY_SLEEP, RESEARCH, BLANK, EXCITED_TALK, NMODES };
const char *const MODE_NAMES[NMODES] = {"neutral", "talk", "happytalk", "smile", "frown",
                                        "surprise", "sleep", "happysleep", "research", "blank", "excitedtalk"};
enum Ind { IND_IDLE, IND_LISTENING, IND_THINKING, IND_CONFUSED, NIND };
const char *const IND_NAMES[NIND] = {"idle", "listening", "thinking", "confused"};

Mode mode = NEUTRAL;
Ind ind = IND_IDLE;
uint32_t indAt = 0, modeAt = 0;
bool demo = false;
int contrast = 160;
float liveLevel = 0;
uint32_t liveAt = 0;
float gazeX = 0, gazeY = 0;
uint32_t gazeAt = 0;
uint32_t lastCmdAt = 0;
const uint32_t AUTO_BLANK_MS = 5UL * 60 * 1000;

bool talks() { return mode == TALK || mode == HAPPY_TALK || mode == EXCITED_TALK; }
// How tall the speaking bars may get, as a share of the full height: normal talk half, excited talk all of it
float talkReach() { return mode == EXCITED_TALK ? 1.0f : 0.5f; }
bool asleep() { return mode == SLEEP || mode == HAPPY_SLEEP; }

int lookup(const char *s, const char *const *names, int count) {
  while (*s == ' ') s++;
  if (*s >= '0' && *s <= '9') { int v = atoi(s); return v < count ? v : -1; }
  char buf[16]; int n = 0;
  for (; *s && n < 15; s++) if (isalnum((unsigned char)*s)) buf[n++] = (char)tolower((unsigned char)*s);
  buf[n] = 0;
  for (int i = 0; i < count; i++) if (!strcmp(buf, names[i])) return i;
  return -1;
}

// ---- simulated speech (the OLED mouth's) -----------------------------------------------------------------------------
struct Speech {
  float segStart = 0, segLen = 0, pk = 0;
  bool voiced = false, hiss = false;
  float skew = 0;                                    // 0 = symmetric, else lean left (-) / right (+)
  int syl = 0, word = 0;
  float f[3] = {0.10f, 0.35f, 0.60f}, ft[3] = {0.10f, 0.35f, 0.60f};

  void next(float now) {
    segStart = now;
    if (voiced) {
      voiced = false;
      if (syl > 0)       segLen = 25 + rnd() * 45;
      else if (word > 0) segLen = 120 + rnd() * 260;
      else               segLen = 250 + rnd() * 300;
      return;
    }
    if (syl == 0) {
      if (word == 0) word = 3 + (int)(rnd() * 6);
      word--;
      syl = 1 + (int)(rnd() * 4);
    }
    syl--;
    voiced = true;
    segLen = 120 + rnd() * 140;
    pk = rnd() < 0.15f ? 1.0f : 0.45f + 0.55f * rnd();
    hiss = rnd() < 0.2f;
    skew = rnd() < 0.75f ? (rnd() < 0.5f ? -1 : 1) * (0.3f + 0.7f * rnd()) : 0;
    ft[0] = 0.04f + 0.16f * rnd();
    ft[1] = 0.25f + 0.30f * rnd();
    ft[2] = 0.55f + 0.30f * rnd();
  }
  void glide() { for (int k = 0; k < 3; k++) f[k] += (ft[k] - f[k]) * 0.18f; }
  float spectrum(float x, float noise) const {
    float s = hiss ? 0.25f * gaussf(x, 0.05f, 0.15f) + 0.9f * gaussf(x, 0.85f, 0.25f)
                   : 0.30f * (1 - x) + 1.00f * gaussf(x, f[0], 0.07f) + 0.75f * gaussf(x, f[1], 0.09f)
                     + 0.45f * gaussf(x, f[2], 0.10f);
    return s * (0.55f + 0.65f * noise);
  }
  float level(float now, bool on) {
    if (now - segStart >= segLen) next(now);
    if (!voiced || !on) return 0;
    float t = (now - segStart) / segLen;
    return pk * sinf(t * PI_F) * (0.85f + 0.15f * sinf(t * 31));
  }
} speech;

// ---- the eyes (RoboEyes) ---------------------------------------------------------------------------------------------
// Design units. Defaults: two 210 x 210 eyes, 150 apart, centred at y = 205.
namespace E {
const float w = 210, h = 210, r = 50, space = 150, cy = 205;
const float lookXMax = 90, lookYMax = 35;           // how far the idle glances / gaze move the eyes
const float closedH = 10;                            // a closed eye: a thin bar
const float halfLifeMs = 20;                         // RoboEyes halves the distance every frame at 50 fps
}

struct Eye {
  float w = E::w, h = 1, r = E::r;                   // current size (starts closed, opens at power-up)
  float wNext = E::w, hNext = E::h, rNext = E::r;
  float hOffset = 0;                                 // curious: the outer eye grows
  bool open = true;
  float tired = 0, angry = 0, happy = 0;             // eyelid amounts, current
} eyeL, eyeR;

float lookX = 0, lookY = 0, lookXNext = 0, lookYNext = 0;   // offset of both eyes from the centre
float spaceCur = E::space;
bool moodTired = false, moodAngry = false, moodHappy = false, curious = false;
uint32_t blinkAt = 0, idleAt = 0;
float sizeK = 1, sizeKNext = 1, radiusK = 1, radiusKNext = 1;   // surprise / listening: bigger, rounder
float lowerY = 0, lowerYNext = 0;                    // asleep: eyes drop a little
// one-shot shakes: laugh (up and down) and confused (side to side)
uint32_t laughUntil = 0, confusedUntil = 0, confusedNext = 0;
bool flickAlt = false;

void blink() {
  for (Eye *e : {&eyeL, &eyeR}) { e->hNext = 1; e->open = true; }
}

void eyesFrame(float now, float dt) {
  const float k = 1 - powf(0.5f, dt / E::halfLifeMs);

  // --- what the mode and status ask of the eyes
  const bool sleeping = asleep();
  moodHappy = mode == HAPPY_TALK || mode == SMILE;
  moodTired = mode == FROWN;
  const bool squint = ind == IND_THINKING && !moodTired;   // thinking: half-lidded, not sad
  moodAngry = false;
  sizeKNext = mode == SURPRISE ? 1.22f : mode == EXCITED_TALK ? 1.12f : ind == IND_LISTENING ? 1.08f : 1.0f;
  radiusKNext = mode == SURPRISE ? 2.0f : 1.0f;
  lowerYNext = sleeping ? 30 : 0;
  curious = !sleeping && mode != SURPRISE;

  // --- where to look: the gaze target, else per mode / status, else idle glances (RoboEyes idle mode)
  const bool gazing = gazeAt && now - gazeAt < 3000;
  if (gazing) {
    lookXNext = gazeX / 100 * E::lookXMax;
    lookYNext = gazeY / 100 * E::lookYMax;
  } else if (sleeping) {
    lookXNext = 0; lookYNext = 0;
  } else if (mode == RESEARCH) {                     // reading: eyes up, darting side to side
    if (now >= idleAt) { lookXNext = (rnd() * 2 - 1) * E::lookXMax; idleAt = (uint32_t)(now + 500 + rnd() * 700); }
    lookYNext = -E::lookYMax;
  } else if (ind == IND_THINKING) {                  // looking up, to one side then the other
    if (now >= idleAt) { lookXNext = (lookXNext > 0 ? -1 : 1) * E::lookXMax * 0.7f; idleAt = (uint32_t)(now + 1800 + rnd() * 1200); }
    lookYNext = -E::lookYMax;
  } else if (ind == IND_LISTENING) {                 // attentive: straight ahead
    lookXNext = 0; lookYNext = 0;
  } else if (now >= idleAt) {                        // idle glances; less wandering while talking
    float range = talks() ? 0.35f : 1.0f;
    lookXNext = (rnd() * 2 - 1) * E::lookXMax * range;
    lookYNext = (rnd() * 2 - 1) * E::lookYMax * range;
    idleAt = (uint32_t)(now + (talks() ? 1500 : 1000) + rnd() * 3000);
  }

  // --- blinking: auto-blink (RoboEyes autoblinker), never while asleep
  if (!sleeping && now >= blinkAt) { blink(); blinkAt = (uint32_t)(now + 1500 + rnd() * 4000); }

  // --- confused: a side-to-side shake every few seconds
  if (ind == IND_CONFUSED && now >= confusedNext) { confusedUntil = (uint32_t)now + 500; confusedNext = (uint32_t)(now + 2500 + rnd() * 1500); }

  // --- ease everything toward its target
  sizeK = ease(sizeK, sizeKNext, k);
  radiusK = ease(radiusK, radiusKNext, k);
  lowerY = ease(lowerY, lowerYNext, k * 0.5f);
  lookX = ease(lookX, lookXNext, k);
  lookY = ease(lookY, lookYNext, k);
  spaceCur = ease(spaceCur, E::space, k);
  for (int side = 0; side < 2; side++) {
    Eye &e = side ? eyeR : eyeL;
    float hDef = E::h * sizeK;
    if (sleeping) { e.hNext = E::closedH; e.open = false; }
    else if (!e.open) { e.open = true; e.hNext = hDef; }
    // curious: the outer eye grows when looking far to its side
    bool outer = side ? lookXNext > E::lookXMax * 0.7f : lookXNext < -E::lookXMax * 0.7f;
    e.hOffset = ease(e.hOffset, curious && outer ? hDef * 0.22f : 0, k);
    if (ind == IND_CONFUSED && side == 0) e.hOffset = ease(e.hOffset, -hDef * 0.18f, k);   // lopsided
    e.wNext = E::w * sizeK;
    e.rNext = E::r * radiusK;
    if (e.open && e.hNext < hDef && e.h <= 2) e.hNext = hDef;      // a blink reopens once shut (RoboEyes)
    if (e.open && e.hNext > 2) e.hNext = hDef;
    e.h = ease(e.h, e.hNext, k);
    e.w = ease(e.w, e.wNext, k);
    e.r = ease(e.r, e.rNext, k);
    e.tired = ease(e.tired, moodTired ? 0.5f : squint ? 0.18f : 0, k);
    e.angry = ease(e.angry, moodAngry ? 0.5f : 0, k);
    e.happy = ease(e.happy, moodHappy ? 0.5f : 0, k);
  }
}

void drawEyes(float now) {
  const uint16_t c = rgb(EYE_R, EYE_G, EYE_B);
  float shakeX = 0, shakeY = 0;
  flickAlt = !flickAlt;
  if (now < confusedUntil) shakeX = flickAlt ? 30 : -30;      // RoboEyes hFlicker
  if (now < laughUntil) shakeY = flickAlt ? 14 : -14;         // RoboEyes vFlicker
  const float total = eyeL.w + spaceCur + eyeR.w;
  for (int side = 0; side < 2; side++) {
    const Eye &e = side ? eyeR : eyeL;
    float h = fmaxf(1, e.h + e.hOffset);
    float x = (DW - total) / 2 + (side ? eyeL.w + spaceCur : 0) + lookX + shakeX;
    float y = E::cy - h / 2 + lookY + lowerY + shakeY;          // centred vertically as it blinks
    int sxp = X(x), syp = Y(y), sw = L(e.w), sh = std::max(1, L(h));
    fillRoundRect(sxp, syp, sw, sh, std::min(L(e.r), sh / 2), c);
    // eyelids, cut in with the background (RoboEyes): tired droops the outer corner, angry the inner one
    float tired = e.tired * h, angry = e.angry * h;
    if (tired > 0.5f) {
      if (!side) fillTriangle(sxp, syp - 1, sxp + sw, syp - 1, sxp, syp + L(tired) - 1, BG);
      else       fillTriangle(sxp, syp - 1, sxp + sw, syp - 1, sxp + sw, syp + L(tired) - 1, BG);
    }
    if (angry > 0.5f) {
      if (!side) fillTriangle(sxp, syp - 1, sxp + sw, syp - 1, sxp + sw, syp + L(angry) - 1, BG);
      else       fillTriangle(sxp, syp - 1, sxp + sw, syp - 1, sxp, syp + L(angry) - 1, BG);
    }
    // happy: a rounded mask rising from below leaves an upturned arc
    float happy = e.happy * h;
    if (happy > 0.5f)
      fillRoundRect(sxp - 2, syp + sh - L(happy) + 1, sw + 4, L(E::h * sizeK), std::min(L(e.r), sh / 2), BG);
  }
}

// ---- the mouth (spectrum) --------------------------------------------------------------------------------------------
namespace M {
const int lanes = 24;
const float width = 0.65f * (2 * E::w + E::space),  // 65 % of the eyes' span
             cy = 468, amp = 92, rest = 3.5f, barW = 10;
const float attack = 0.7f, fall = 0.05f;             // per frame at ~55 fps
const float corner = 0.35f, cornerTaper = 0.25f, gain = 1.7f;
}
float disp[M::lanes];
float loudS = 0;
float bendS = 0;                                     // the mouth line: +1 corners up (smile) .. -1 down (frown)
float joinS = 0;                                     // 0 dashes .. 1 one solid line (smile / frown at rest)
const float SMILE_BEND = 46;                         // design px the corners rise (or drop)
const float FROWN_K = 0.8f, HAPPYTALK_K = 1.0f;      // frown / happytalk bend, as a share of the smile's

float laneY(float pos) {                             // the mouth's centre line at pos (0..1 across the mouth)
  float u = fabsf(pos - 0.5f) * 2;
  return M::cy - bendS * SMILE_BEND * u * u;
}

float mouthShift() { return 0.3f * lookX; }        // the mouth follows the eyes a little

float taper(float pos) {                             // 0 at the corners
  float t = clampf(fminf(pos, 1 - pos) / M::cornerTaper, 0, 1);
  return t * t * (3 - 2 * t);
}

uint16_t laneColour(float freq, float d) {           // brighter in the middle and when tall
  float t = clampf(freq * 0.8f + (1 - d) * 0.2f, 0, 1);
  return mix(140, 225, 255, 40, 120, 255, t);
}

void drawLane(int i, float halfH, uint16_t c) {
  const float pitch = M::width / M::lanes;
  const float bw = M::barW + joinS * (pitch + 1 - M::barW);    // smile / frown: the dashes join into a solid arc
  float x = (DW - M::width) / 2 + i * pitch + (pitch - bw) / 2 + mouthShift();
  int h = std::max(1, L(halfH + joinS * 4));                    // ... and thicken
  fillRect(X(x), Y(laneY((i + 0.5f) / M::lanes)) - h, std::max(1, L(bw)), 2 * h, c);
}

void drawMouth(float now, float dt, float loudRaw) {
  const int n = M::lanes;
  const float c = (n - 1) / 2.0f;
  const float frames = dt / 18.0f;                   // attack / fall were tuned per ~18 ms frame
  const float bendTo = mode == SMILE ? 1.0f : mode == FROWN ? -FROWN_K : mode == HAPPY_TALK ? HAPPYTALK_K : 0.0f;
  const float kb = 1 - powf(0.5f, dt / 90);
  bendS = ease(bendS, bendTo, kb);
  joinS = ease(joinS, (mode == SMILE || mode == FROWN) ? 1.0f : 0.0f, kb);   // talking keeps its separate bars

  if (mode == SURPRISE) {                            // an "O": wide, shrinks small, opens wide again and stays
    const float t = (now - modeAt) / 1000.0f, smallAt = 0.45f, wideAt = 1.1f;
    const float sWide = 1.2f, sSmall = 0.45f, sRest = 1.15f;
    float s;
    if (t < smallAt) { float u = t / smallAt; s = sWide + (sSmall - sWide) * u * u * (3 - 2 * u); }
    else if (t < wideAt) { float u = (t - smallAt) / (wideAt - smallAt); s = sSmall + (sRest - sSmall) * (1 - (1 - u) * (1 - u)); }
    else s = sRest;
    s += 0.12f * loudS;                              // swells a little if she talks
    ellipseRing(X(DW / 2 + mouthShift()), Y(M::cy), L(84 * s), L(64 * s), L(15 * fminf(1, 0.5f + 0.5f * s)),
                rgb(140, 225, 255));
    return;
  }

  if (ind == IND_THINKING && !talks() && !asleep()) {   // three dots filling one by one
    int filled = ((uint32_t)(now - indAt) / 400) % 4;
    for (int k = 0; k < 3; k++) {
      float x = DW / 2 + (k - 1) * 46 + mouthShift();
      if (k < filled) fillCircle(X(x), Y(M::cy), L(11), rgb(140, 225, 255));
      else            ellipseRing(X(x), Y(M::cy), L(11), L(11), L(3), rgb(60, 130, 200));
    }
    return;
  }

  // mirrored lanes share their noise unless the syllable leans
  static float nz[M::lanes];
  for (int i = 0; i < n; i++) nz[i] = (i <= n - 1 - i || speech.skew != 0) ? rnd() : nz[n - 1 - i];
  const bool sleeping = asleep();
  const float scan = fmodf(now / 1600.0f, 1.0f) * 1.3f - 0.15f;   // research: a highlight sweeping across
  const bool scanning = ind == IND_LISTENING && !talks() && mode != RESEARCH;   // listening: Knight Rider scanner
  const float pp = fmodf((now - indAt) / 1400.0f, 2.0f);           // 1.4 s per sweep, there and back
  const float kitt = 0.04f + 0.92f * (pp < 1 ? pp : 2 - pp);      // the scanner's position, 0..1 across

  for (int i = 0; i < n; i++) {
    float pos = (i + 0.5f) / n, freq = c > 0 ? fabsf(i - c) / c : 0;
    float shape = M::corner + (1 - M::corner) * taper(pos);
    float target, reach = 1;
    if (sleeping) {
      target = loudS * 4 * (1 - 0.6f * freq);
    } else if (mode == RESEARCH) {
      target = 0.28f * gaussf(pos, scan, 0.06f);
    } else if (scanning) {
      target = 0.32f * gaussf(pos, kitt, 0.035f);     // the bars' slow fall leaves the trail behind it
    } else {
      float side = i < c ? -1.0f : i > c ? 1.0f : 0.0f, lean = speech.skew * side;
      float sp = speech.spectrum(clampf(freq - 0.15f * lean, 0, 1), nz[i]) * (1 + 0.45f * lean);
      target = M::gain * loudRaw * sp;
      reach = talkReach();                           // scaled, not clipped: the bars keep their movement
    }
    target = clampf(target * (scanning ? 1 : shape) * reach, 0, reach);   // the scanner runs to the corners
    float &d = disp[i];
    if (target > d) d += (target - d) * (1 - powf(1 - M::attack, frames));
    else            d = fmaxf(target, d - (scanning ? 0.012f : M::fall) * frames);   // scanner: a long trail
    drawLane(i, M::rest + d * M::amp, laneColour(freq, d));
  }
}

// ---- sleep: Zzz rising from above the right eye ------------------------------------------------------------------------
void drawZ(float cx, float cy, float s, uint16_t c) {
  float h = s / 2, w = fmaxf(2, s * 0.16f);
  thickLine(X(cx - h), Y(cy - h), X(cx + h), Y(cy - h), L(w), c);
  thickLine(X(cx + h), Y(cy - h), X(cx - h), Y(cy + h), L(w), c);
  thickLine(X(cx - h), Y(cy + h), X(cx + h), Y(cy + h), L(w), c);
}

void drawZzz(float now) {
  const float x0 = DW / 2 + E::space / 2 + E::w * 0.85f, y0 = E::cy - 40;
  for (int k = 0; k < 3; k++) {
    float p = fmodf(now / 3200.0f + k / 3.0f, 1.0f);
    if (p > 0.9f) continue;
    float s = 22 + 40 * p;
    drawZ(x0 + p * 170, y0 - p * 150, s, mix(EYE_R, EYE_G, EYE_B, 20, 50, 80, p));
  }
}

// ---- the demo ---------------------------------------------------------------------------------------------------------
struct Scene { Mode m; Ind i; uint32_t ms; };
const Scene SCENES[] = {
  {NEUTRAL, IND_IDLE, 5000}, {NEUTRAL, IND_LISTENING, 3000}, {NEUTRAL, IND_THINKING, 4000}, {TALK, IND_IDLE, 6000},
  {HAPPY_TALK, IND_IDLE, 5000}, {EXCITED_TALK, IND_IDLE, 5000}, {SMILE, IND_IDLE, 3000}, {FROWN, IND_IDLE, 3500}, {NEUTRAL, IND_CONFUSED, 4500},
  {SURPRISE, IND_IDLE, 3000}, {RESEARCH, IND_IDLE, 5000}, {SLEEP, IND_IDLE, 8000},
};
const int NSCENES = sizeof(SCENES) / sizeof(SCENES[0]);
int scene = -1;
uint32_t sceneAt = 0;
void (*demoOut)(const char *) = nullptr;

void setMode(Mode m, uint32_t now) {
  if (m != mode) modeAt = now;
  if (m == HAPPY_TALK && mode != HAPPY_TALK) laughUntil = now + 450;   // a little laugh as she starts
  mode = m;
}
void setInd(Ind i, uint32_t now) { if (i != ind) indAt = now; ind = i; }

void demoStep(uint32_t now) {
  if (scene < 0 || now - sceneAt >= SCENES[scene].ms) {
    scene = (scene + 1) % NSCENES;
    sceneAt = now;
    setMode(SCENES[scene].m, now);
    setInd(SCENES[scene].i, now);
    if (demoOut) {
      char b[64];
      snprintf(b, sizeof b, "mouth demo: %s / %s", MODE_NAMES[mode], IND_NAMES[ind]);
      demoOut(b);
    }
  }
}

uint32_t lastNow = 0;
bool started = false;

}  // namespace

// ---- public ---------------------------------------------------------------------------------------------------------
void begin(int width, int height, uint32_t seed) {
  W = width; H = height;
  S = fminf(W / DW, H / DH) * FACE_SCALE;
  OX = (W - DW * S) / 2;
  OY = (H - DH * S) / 2;
  rngState = seed | 1;
  for (float &d : disp) d = 0;
}

int backlight() { return mode == BLANK ? 0 : (contrast * 100 + 127) / 255; }

void draw(uint16_t *buffer, uint32_t nowMs) {
  fb = buffer;
  if (!started) { started = true; lastNow = nowMs; lastCmdAt = nowMs; }
  float dt = clampf((float)(nowMs - lastNow), 1, 60);
  lastNow = nowMs;
  const float now = (float)nowMs;

  if (demo) demoStep(nowMs);
  else if (mode != BLANK && nowMs - lastCmdAt > AUTO_BLANK_MS) setMode(BLANK, nowMs);   // nobody driving it

  // speech: the Orin's L levels while they keep coming, else simulated in talk modes
  const bool live = !demo && liveAt && nowMs - liveAt < 1500;
  float loudRaw = speech.level(now, talks() && !live);
  speech.glide();
  if (live) loudRaw = talks() ? liveLevel : 0;
  loudS += (loudRaw - loudS) * 0.25f;
  if (asleep()) loudS = 0.08f * (0.5f + 0.5f * sinf(now / 4000 * 2 * PI_F));   // slow breathing

  memset(fb, 0, (size_t)W * H * 2);
  if (mode == BLANK) return;
  eyesFrame(now, dt);
  drawEyes(now);
  drawMouth(now, dt, asleep() ? loudS : 0.5f * (loudS + loudRaw));
  if (asleep()) drawZzz(now);
}

void command(const char *s, uint32_t now, void (*out)(const char *)) {
  char b[160];
  auto report = [&]() {
    snprintf(b, sizeof b, "mouth: %s, mode %d %s, status %d %s, style spectrum, contrast %d", demo ? "DEMO" : "LIVE",
             (int)mode, MODE_NAMES[mode], (int)ind, IND_NAMES[ind], contrast);
    out(b);
  };
  auto stopDemo = [&]() { if (demo) { demo = false; out("mouth: LIVE"); } };
  lastCmdAt = now;
  if (!*s) return;
  int v = atoi(s + 1);
  switch (s[0]) {
    case 'L': case 'l': liveLevel = clampf(v, 0, 255) / 255.0f; liveAt = now; stopDemo(); break;
    case 'I': case 'i': {
      int i = lookup(s + 1, IND_NAMES, NIND);
      if (i < 0) { snprintf(b, sizeof b, "mouth: unknown status '%s'", s + 1); out(b); break; }
      setInd((Ind)i, now);
      if (i == IND_LISTENING && talks()) setMode(mode == HAPPY_TALK ? SMILE : NEUTRAL, now);
      report();
      break;
    }
    case 'M': case 'm': {
      int m = lookup(s + 1, MODE_NAMES, NMODES);
      if (m < 0) { snprintf(b, sizeof b, "mouth: unknown mode '%s'", s + 1); out(b); break; }
      stopDemo(); setMode((Mode)m, now); report();
      break;
    }
    case 'G': case 'g': {
      const char *comma = strchr(s + 1, ',');
      gazeX = clampf(v, -100, 100);
      gazeY = comma ? clampf(atoi(comma + 1), -100, 100) : 0;
      gazeAt = now;
      break;
    }
    case 'D': case 'd':
      demo = v != 0;
      demoOut = out;
      if (demo) scene = -1; else setMode(NEUTRAL, now);
      report();
      break;
    case 'S': case 's':
      static const char *const STYLES[2] = {"lips", "spectrum"};
      if (lookup(s + 1, STYLES, 2) == 0) out("mouth: this face only has the spectrum style");
      report();
      break;
    case 'C': case 'c': contrast = (int)clampf(v, 0, 255); report(); break;
    case '?': report(); break;
    default: break;
  }
}

}  // namespace face
