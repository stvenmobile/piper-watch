// Piper's mouth: the "envelope" human mouth on the 2.08" SH1122 256x64 OLED, driven by the XIAO ESP32-S3.
//
// A port of firmware/mouth/sim/mouth_sim.html with the locked settings from sim/mouth_locked.json (2026-11-18).
// The mouth is 40 vertical lanes across the middle 48 % of the screen:
//   - still lips: a top lip with a Cupid's bow (two towers and a U at the centre) and a full, rounded bottom lip;
//   - talking: an outline made of a few soft bumps that wander (the main opening stays near the centre) opens the lanes;
//     each lane splits into an upper and lower "tooth" with a gap that grows with the lane; the corners close;
//   - mood: the centre line bends - corners up for a smile, down for a frown; a smile also thins the lips;
//   - sleep: closed relaxed lips that breathe slowly, with three Z's rising from the right corner;
//   - surprise: an oval "O" with towers on its upper lip that pops open (and swells if Piper talks).
//
// At power-up it runs a DEMO loop through all of that. Serial commands (one per line, from the Orin or the monitor):
//   L<0..255>    loudness for this frame (~30 Hz while speaking); stops the demo. No level for 1.5 s -> silent.
//   E<-100..100> mood: -100 frown .. 0 neutral .. 100 smile; stops the demo
//   X<0|1|2>     expression: 0 normal, 1 sleep, 2 surprise; stops the demo
//   D1 / D0      demo on / off
//   C<0..255>    contrast (default 160)
//   ?            print the current state
#include <Arduino.h>
#include <SPI.h>
#include <U8g2lib.h>

static const int PIN_CS = D5, PIN_DC = D0, PIN_RST = D1;
U8G2_SH1122_256X64_F_4W_HW_SPI oled(U8G2_R0, PIN_CS, PIN_DC, PIN_RST);

static const int W = 256, H = 64, MID = H / 2;
static const uint32_t FRAME_MS = 25;                       // 40 frames per second, as in the simulator

// ---- locked settings (sim/mouth_locked.json) --------------------------------------------------------------------------
namespace K {
const float width = 48, follow = 25, height = 100;
const int lanes = 40, gap = 1;
const int bumps = 3;
const float morph = 7, reshape = 450, bw = 22, drift = 7, excur = 12, excurSize = 22, side = 45, tex = 15;
const float cgap = 6, cgapLane = 60, corner = 25;
const float topBody = 100, towerUp = 3, towerTop = 2, topCurve = 8, uW = 5, uDepth = 40, uRound = 20;
const float botMax = 10, botFull = 28, botRound = 2, botRoundW = 30, lipKeep = 100;
const float bendPx = 9, bendCurve = 22, stretch = 25, moodSpeed = 8;
const float zSize = 11, zTime = 3200, breath = 8;
const float oW = 38, oH = 20, oLip = 7, oTower = 3, oDip = 2, oPop = 22;
const int oTowerBars = 2;
}  // namespace K

enum Expr : uint8_t { NORMAL = 0, SLEEP = 1, SURPRISE = 2 };

// ---- state ------------------------------------------------------------------------------------------------------------
static bool demo = true;
static int contrast = 160;
static float moodT = 0, moodS = 0;                         // target and smoothed mood, -100..100
static Expr expr = NORMAL;
static float loudS = 0;                                    // smoothed loudness 0..1
static float liveLevel = 0;
static uint32_t liveAt = 0;
static float oScale = 0;
static int gapHalf = 0;

// ---- small helpers ----------------------------------------------------------------------------------------------------
static inline float rnd() { return esp_random() / 4294967296.0f; }
static inline float clampf(float v, float a, float b) { return v < a ? a : v > b ? b : v; }
static inline float gaussf(float x, float c, float w) { float d = (x - c) / w; return expf(-d * d); }
static inline int jround(float v) { return (int)floorf(v + 0.5f); }   // JavaScript's Math.round

static inline void px(int x, int y) { if (x >= 0 && x < W && y >= 0 && y < H) oled.drawPixel(x, y); }
static void vrun(int x, int y0, int y1) {                  // a vertical run y0..y1 inclusive, clipped to the screen
  if (x < 0 || x >= W) return;
  if (y0 < 0) y0 = 0;
  if (y1 > H - 1) y1 = H - 1;
  if (y0 <= y1) oled.drawVLine(x, y0, y1 - y0 + 1);
}

// ---- simulated speech: syllables, words, short pauses ---------------------------------------------------------------
struct Speech {
  float segStart = 0, segLen = 0, pk = 0;
  bool voiced = false;
  int syl = 0, word = 0;

  void next(float now) {
    segStart = now;
    if (voiced) {
      voiced = false;
      if (syl > 0)       segLen = 25 + rnd() * 45;
      else if (word > 0) segLen = 120 + rnd() * 260;
      else               segLen = 250 + rnd() * 300;      // "talk non-stop": short sentence breaks
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
  }

  float level(float now, bool on) {
    if (now - segStart >= segLen) next(now);
    if (!voiced || !on) return 0;
    float t = (now - segStart) / segLen;
    return pk * sinf(t * PI) * (0.85f + 0.15f * sinf(t * 31));
  }
} speech;

// ---- the talking outline: a few soft bumps that wander --------------------------------------------------------------
// Bump 0 is the main opening: near the centre, drifting a little, now and then a bigger shift to one side.
struct Bump { float c = 0.5f, w = 0.2f, a = 0, ct = 0.5f, wt = 0.2f, at = 0, until = 0; };
static Bump bump[K::bumps];
static float texv[K::lanes];

static void bumpNew(Bump &b, float now, int idx) {
  auto pm = [] { return rnd() * 2 - 1; };
  if (idx == 0) {
    b.ct = 0.5f + pm() * K::drift / 100;
    if (rnd() < K::excur / 100) b.ct = 0.5f + (pm() >= 0 ? 1 : -1) * K::excurSize / 100 * (0.7f + 0.6f * rnd());
    b.at = 0.8f + 0.2f * rnd();
    b.wt = K::bw / 100 * (0.8f + 0.5f * rnd());
  } else {
    b.ct = 0.5f + pm() * 0.38f;
    b.at = K::side / 100 * (0.4f + 0.6f * rnd());
    b.wt = K::bw / 100 * (0.6f + 0.8f * rnd());
  }
  b.until = now + K::reshape * (0.5f + rnd());
}

static void envFrame(float now, float loud, float out[K::lanes]) {
  const float m = K::morph / 100;
  for (int k = 0; k < K::bumps; k++) {
    Bump &b = bump[k];
    if (now >= b.until) bumpNew(b, now, k);
    b.c += (b.ct - b.c) * m; b.w += (b.wt - b.w) * m; b.a += (b.at - b.a) * m;
  }
  for (int i = 0; i < K::lanes; i++) {
    float x = i / (float)(K::lanes - 1);
    float s = 0.12f;
    for (int k = 0; k < K::bumps; k++) s += bump[k].a * gaussf(x, bump[k].c, bump[k].w);
    texv[i] += ((1 - K::tex / 100 + K::tex / 100 * rnd()) - texv[i]) * 0.4f;
    out[i] = clampf(fminf(1, s) * texv[i] * loud, 0, 1);
  }
}

// ---- the lips ---------------------------------------------------------------------------------------------------------
// pos 0..1 across the mouth.
static float restBot(float pos) {                          // full body + a narrow rounded dome in the middle
  float u = fabsf(pos - 0.5f) * 2;
  float r = fminf(K::botRound, K::botMax - 1), w = K::botRoundW / 100;
  float body = 1 + (K::botMax - 1 - r) * (1 - powf(u, K::botFull / 10));
  return body + r * powf(fmaxf(0, 1 - u / w), 1.3f);
}

static float restTop(float pos) {                          // body mirroring the bottom lip + towers + a U at the centre
  float d = fabsf(pos - 0.5f);
  float uw = K::uW / 100, tt = K::towerTop / 100;
  float body = fmaxf(1, K::topBody / 100 * restBot(pos));
  float peak = body + K::towerUp;
  if (d <= uw) return peak * (1 - K::uDepth / 100 * (1 - powf(d / uw, K::uRound / 10)));
  if (d <= uw + tt) return peak;
  float t = clampf((0.5f - d) / (0.5f - uw - tt), 0, 1);
  return body + K::towerUp * powf(t, K::topCurve / 10);
}

static float taper(float pos) {                            // 0 at the corners -> the gap closes there
  float t = clampf(fminf(pos, 1 - pos) / (K::corner / 100), 0, 1);
  return t * t * (3 - 2 * t);
}

static int centreY(float pos) {                            // the centre line, bent by the mood
  float u = fabsf(pos - 0.5f) * 2;
  return MID - jround(moodS / 100 * K::bendPx * powf(u, K::bendCurve / 10));
}

// One lane: h is its talking half-height. The gap grows with h; lips sit on top of the speech.
static void vbar(int x, int w, int h, float pos) {
  int cy = centreY(pos);
  float t = taper(pos);
  float k = K::cgapLane / 100, e = k * h / (1 + k);
  int g = jround(t * (gapHalf + e));
  float keep = 1 - (1 - K::lipKeep / 100) * fminf(1, loudS * 3);
  int sp = max(0, h - jround(t * e));
  float thin = 1 - K::stretch / 100 * fmaxf(0, moodS) / 100;
  int top = jround(sp + restTop(pos) * keep * thin), bot = jround(sp + restBot(pos) * keep * thin);
  top = min(top, 31 - g); bot = min(bot, 31 - g);
  for (int xx = x; xx < x + w; xx++) {
    if (g <= 0) { vrun(xx, cy - top, cy + bot); continue; }
    if (top > 0) vrun(xx, cy - g - top, cy - g - 1);
    if (bot > 0) vrun(xx, cy + g, cy + g + bot - 1);
  }
}

// ---- sleep: Zzz -------------------------------------------------------------------------------------------------------
static void line(float fx0, float fy0, float fx1, float fy1) {      // Bresenham
  int x0 = jround(fx0), y0 = jround(fy0), x1 = jround(fx1), y1 = jround(fy1);
  int dx = abs(x1 - x0), dy = -abs(y1 - y0), sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, err = dx + dy;
  for (;;) {
    px(x0, y0);
    if (x0 == x1 && y0 == y1) break;
    int e2 = 2 * err;
    if (e2 >= dy) { err += dy; x0 += sx; }
    if (e2 <= dx) { err += dx; y0 += sy; }
  }
}

static void drawZ(float cx, float cy, int s) {
  float h = jround(s / 2.0f), l = cx - h, r = cx + h, t = cy - h, b = cy + h;
  int passes = s >= 9 ? 2 : 1;                             // 2 px strokes once big enough
  for (int k = 0; k < passes; k++) { line(l, t + k, r, t + k); line(l, b - k, r, b - k); line(r - k, t, l - k, b); }
}

static void drawZzz(float now, int MW) {                   // three Z's rising from the right corner, staggered
  float xs = W / 2.0f + MW / 2.0f - 6, ys = MID - 9;
  for (int k = 0; k < 3; k++) {
    float p = fmodf(now / K::zTime + k / 3.0f, 1.0f);
    if (p > 0.9f) continue;
    int s = jround(K::zSize * (0.4f + 0.6f * p));
    drawZ(xs + p * (W - xs - K::zSize / 2 - 2), ys - p * (ys - K::zSize / 2 - 1), s);
  }
}

// ---- surprise: the "O" ------------------------------------------------------------------------------------------------
static void drawO(int pitch, int barW) {
  float target = 1 + 0.12f * loudS;
  oScale += (target - oScale) * K::oPop / 100 + (oScale < 1 ? 0.02f : 0);
  float a = K::oW * fminf(oScale, 1.15f), b = fminf(31, K::oH * fminf(oScale, 1.1f)), t = K::oLip;
  float ai = fmaxf(0, a - t), bi = fmaxf(0, b - t);
  int lanesO = ((int)floorf(2 * a / pitch)) | 1;
  int xL = jround(W / 2.0f - lanesO * pitch / 2.0f);
  float kc = (lanesO - 1) / 2.0f;
  for (int i = 0; i < lanesO; i++) {
    float xc = xL + i * pitch + barW / 2.0f, dx = xc - W / 2.0f;
    if (fabsf(dx) >= a) continue;
    int yo = jround(b * sqrtf(1 - (dx / a) * (dx / a)));
    int yi = fabsf(dx) < ai ? jround(bi * sqrtf(1 - (dx / ai) * (dx / ai))) : 0;
    float k = fabsf(i - kc), up = 0;                       // upper lip: centre dip, towers, a half-height step
    if (k < 0.5f) up = -K::oDip;
    else if (k <= K::oTowerBars) up = K::oTower;
    else if (k <= K::oTowerBars + 1) up = jround(K::oTower / 2);
    int yoTop = min(MID, yo + jround(up * fminf(oScale, 1)));
    for (int xx = xL + i * pitch; xx < xL + i * pitch + barW; xx++) {
      if (yoTop >= yi) vrun(xx, MID - yoTop, MID - yi);
      vrun(xx, MID + yi, MID + yo);
    }
  }
}

static void setExpr(Expr e) {
  if (e == SURPRISE && expr != SURPRISE) oScale = 0.25f;
  expr = e;
}

// ---- the demo: a loop through the moods and expressions, talking and still ------------------------------------------
struct Scene { int mood; Expr ex; bool talk; uint32_t ms; const char *name; };
static const Scene scenes[] = {
  {0,    NORMAL,   true,  6000,  "neutral, talking"},
  {0,    NORMAL,   false, 1500,  "neutral, still"},
  {100,  NORMAL,   true,  6000,  "smile, talking"},
  {100,  NORMAL,   false, 2500,  "smile, still"},
  {0,    NORMAL,   false, 1500,  "neutral, still"},
  {-100, NORMAL,   true,  5000,  "frown, talking"},
  {-100, NORMAL,   false, 2500,  "frown, still"},
  {0,    SURPRISE, false, 2000,  "surprise"},
  {0,    SURPRISE, true,  3000,  "surprise, talking"},
  {0,    NORMAL,   true,  4000,  "neutral, talking"},
  {0,    SLEEP,    false, 10000, "sleep"},
};
static const int NSCENES = sizeof(scenes) / sizeof(scenes[0]);
static int scene = -1;
static uint32_t sceneAt = 0;

static bool demoStep(uint32_t now) {                       // returns whether the current scene is talking
  if (scene < 0 || now - sceneAt >= scenes[scene].ms) {
    scene = (scene + 1) % NSCENES;
    sceneAt = now;
    moodT = scenes[scene].mood;
    setExpr(scenes[scene].ex);
    Serial.printf("mouth demo: %s\n", scenes[scene].name);
  }
  return scenes[scene].talk;
}

// ---- one frame --------------------------------------------------------------------------------------------------------
static void frame(uint32_t nowMs) {
  float now = nowMs;
  bool talking = demo ? demoStep(nowMs) : false;
  float loudRaw = speech.level(now, talking);
  if (!demo) loudRaw = (nowMs - liveAt < 1500) ? liveLevel : 0;
  loudS += (loudRaw - loudS) * K::follow / 100;

  const int MW = jround(W * K::width / 100);
  const int n = K::lanes, pitch = max(1, MW / n), barW = max(1, pitch - K::gap), x0 = (W - n * pitch) / 2;
  float mt = moodT;
  if (expr == SLEEP) {                                     // closed, relaxed, slowly breathing
    mt = 0;
    loudS = K::breath / 100 * (0.5f + 0.5f * sinf(now / 4000 * 2 * PI));
  }
  moodS += (mt - moodS) * K::moodSpeed / 100;
  gapHalf = jround(K::cgap / 2);
  const float amp = (MID - 2 - gapHalf) * K::height / 100;
  static float v[K::lanes];
  envFrame(now, loudS, v);

  oled.clearBuffer();
  if (expr == SURPRISE) {
    drawO(pitch, barW);
  } else {
    for (int i = 0; i < n; i++)
      vbar(x0 + i * pitch, barW, jround(fminf(MID - 1 - gapHalf, v[i] * amp)), (i + 0.5f) / n);
  }
  if (expr == SLEEP) drawZzz(now, MW);
  oled.sendBuffer();
}

// ---- serial -----------------------------------------------------------------------------------------------------------
static char lineBuf[24];
static int lineLen = 0;

static void report() {
  static const char *names[] = {"normal", "sleep", "surprise"};
  Serial.printf("mouth: %s, mood %d, expression %s, contrast %d\n",
                demo ? "DEMO" : "LIVE", (int)moodT, names[expr], contrast);
}

static void stopDemo() {
  if (demo) { demo = false; Serial.println("mouth: LIVE"); }
}

static void command(const char *s) {
  int v = atoi(s + 1);
  switch (s[0]) {
    case 'L': case 'l': liveLevel = constrain(v, 0, 255) / 255.0f; liveAt = millis(); stopDemo(); break;
    case 'E': case 'e': moodT = constrain(v, -100, 100); stopDemo(); report(); break;
    case 'X': case 'x': setExpr((Expr)constrain(v, 0, 2)); stopDemo(); report(); break;
    case 'D': case 'd':
      demo = v != 0;
      if (demo) scene = -1; else { moodT = 0; setExpr(NORMAL); }
      report();
      break;
    case 'C': case 'c': contrast = constrain(v, 0, 255); oled.setContrast(contrast); report(); break;
    case '?': report(); break;
    default: break;
  }
}

static void readSerial() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (lineLen) { lineBuf[lineLen] = 0; command(lineBuf); lineLen = 0; }
    } else if (lineLen < (int)sizeof(lineBuf) - 1) {
      lineBuf[lineLen++] = c;
    }
  }
}

// ---- main -------------------------------------------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  SPI.begin();
  oled.setBusClock(20000000);
  oled.begin();
  oled.setContrast(contrast);
  for (int i = 0; i < K::lanes; i++) texv[i] = 1;
  for (int k = 0; k < K::bumps; k++) bumpNew(bump[k], millis(), k);
  report();
}

void loop() {
  static uint32_t next = 0;
  readSerial();
  uint32_t now = millis();
  if ((int32_t)(now - next) < 0) return;
  next = now + FRAME_MS;
  frame(now);
}
