// Piper's mouth: a scrolling "sound wave" on the 2.08" SH1122 256x64 OLED, driven by the XIAO ESP32-S3.
//
// Each frame (30 per second) one new vertical bar enters at the right edge and the rest scroll left. A bar is drawn
// symmetric about the centre line; its half-height comes from the current speech loudness, with some bar-to-bar
// jitter so a syllable looks like a spiky cluster rather than a smooth bump. Silence is a row of dots.
//
// Modes:
//   DEMO  (at power-up) - plays made-up speech by itself: syllables, words, sentence pauses, idle stretches.
//   LIVE  - the Orin streams loudness levels over the USB serial link; no level for 1.5 s -> idle dots.
//
// Serial commands (one per line, from the Orin or the PlatformIO monitor):
//   L<0..255>   a loudness level for this frame (e.g. "L180"); switches to LIVE. Send at ~30 Hz while speaking,
//               timed to when that slice of audio reaches the speaker (not when it is generated).
//   D1 / D0     demo on / off
//   G<n>        gain in percent applied to incoming levels (default 100)
//   S<n>        bar spacing in pixels, 2..8 (default 3)
//   C<0..255>   contrast (default 160)
//   ?           print the current settings
#include <Arduino.h>
#include <SPI.h>
#include <U8g2lib.h>

static const int PIN_CS = D5, PIN_DC = D0, PIN_RST = D1;
U8G2_SH1122_256X64_F_4W_HW_SPI oled(U8G2_R0, PIN_CS, PIN_DC, PIN_RST);

static const int W = 256, H = 64, MID = H / 2, MAXH = MID - 1;   // half-height 0..31
static const uint32_t FRAME_MS = 33;                             // ~30 bars per second
static const int MAX_BARS = W / 2 + 1;

static uint8_t bars[MAX_BARS];      // half-heights, [0] = oldest (left), newest at [nbars - 1]
static int spacing = 3, nbars = W / 3 + 1;
static int gainPct = 100, contrast = 160;
static bool demo = true;
static float liveLevel = 0;         // 0..1, last level received
static uint32_t liveAt = 0;         // millis() of the last level

// ---- bar shaping ----------------------------------------------------------------------------------------------------
// level 0..1 -> half-height. Quiet stays dots/ticks; loud bars spread between ~55 % and 100 % of the envelope, with an
// occasional extra-tall spike, like the reference picture.
static uint8_t shape(float level) {
  if (level < 0.04f) return random(100) < 12 ? 1 : 0;                      // silence: dots, the odd tick
  float j = 0.55f + 0.45f * (random(1000) / 1000.0f);
  if (random(100) < 8) j = 1.15f;                                          // spike
  float h = level * j * MAXH;
  if (h < 1) h = 1;
  return (uint8_t)min((float)MAXH, h);
}

static void push(uint8_t h) {
  memmove(bars, bars + 1, nbars - 1);
  bars[nbars - 1] = h;
}

static void draw() {
  oled.clearBuffer();
  int x0 = W - 1 - (nbars - 1) * spacing;                                  // newest bar on the right edge
  for (int i = 0; i < nbars; i++) {
    int x = x0 + i * spacing;
    if (x < 0) continue;
    int h = bars[i];
    if (h == 0) oled.drawPixel(x, MID);
    else        oled.drawVLine(x, MID - h, 2 * h + 1);
  }
  oled.sendBuffer();
}

// ---- demo speech ----------------------------------------------------------------------------------------------------
// A tiny state machine: a sentence is 3..8 words, a word 1..4 syllables. A syllable is a raised-sine envelope of
// 120..260 ms with its own peak; short dips between syllables, longer gaps between words and sentences, and now and
// then a few seconds of idle.
struct Demo {
  uint32_t segStart = 0, segLen = 0;
  float peak = 0;
  bool voiced = false;
  int sylLeft = 0, wordLeft = 0;

  void next(uint32_t now) {
    segStart = now;
    if (voiced) {                                       // a syllable just ended -> a gap
      voiced = false;
      if (sylLeft > 0)       segLen = random(25, 70);           // inside a word
      else if (wordLeft > 0) segLen = random(120, 380);         // between words
      else                   segLen = random(100) < 25 ? random(2500, 5000) : random(700, 1500);   // end of sentence
      peak = 0;
      return;
    }
    if (sylLeft == 0) {                                 // start a new word (and maybe a new sentence)
      if (wordLeft == 0) wordLeft = random(3, 9);
      wordLeft--;
      sylLeft = random(1, 5);
    }
    sylLeft--;
    voiced = true;
    segLen = random(120, 260);
    peak = 0.35f + 0.65f * (random(1000) / 1000.0f);
    if (random(100) < 15) peak = 1.0f;                  // stressed syllable
  }

  float level(uint32_t now) {
    if (now - segStart >= segLen) next(now);
    if (!voiced) return 0.02f;
    float t = (now - segStart) / (float)segLen;         // 0..1 across the syllable
    float env = sinf(t * PI);
    return peak * env * (0.8f + 0.2f * sinf(t * 37.0f));    // a little flutter inside the syllable
  }
} demoGen;

// ---- serial ---------------------------------------------------------------------------------------------------------
static char line[24];
static int lineLen = 0;

static void setSpacing(int s) {
  spacing = constrain(s, 2, 8);
  nbars = min(MAX_BARS, W / spacing + 1);
  memset(bars, 0, sizeof(bars));
}

static void report() {
  Serial.printf("mouth: %s, gain %d%%, spacing %d (%d bars), contrast %d\n",
                demo ? "DEMO" : "LIVE", gainPct, spacing, nbars, contrast);
}

static void command(const char *s) {
  int v = atoi(s + 1);
  switch (s[0]) {
    case 'L': case 'l':
      liveLevel = constrain(v * gainPct / 100, 0, 255) / 255.0f;
      liveAt = millis();
      if (demo) { demo = false; Serial.println("mouth: LIVE"); }
      break;
    case 'D': case 'd': demo = v != 0; report(); break;
    case 'G': case 'g': gainPct = constrain(v, 10, 400); report(); break;
    case 'S': case 's': setSpacing(v); report(); break;
    case 'C': case 'c': contrast = constrain(v, 0, 255); oled.setContrast(contrast); report(); break;
    case '?': report(); break;
    default: break;
  }
}

static void readSerial() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (lineLen) { line[lineLen] = 0; command(line); lineLen = 0; }
    } else if (lineLen < (int)sizeof(line) - 1) {
      line[lineLen++] = c;
    }
  }
}

// ---- main -----------------------------------------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  SPI.begin();
  oled.setBusClock(20000000);
  oled.begin();
  oled.setContrast(contrast);
  randomSeed(esp_random());
  setSpacing(spacing);
  draw();
  report();
}

void loop() {
  static uint32_t next = 0;
  readSerial();
  uint32_t now = millis();
  if ((int32_t)(now - next) < 0) return;
  next = now + FRAME_MS;

  float level;
  if (demo)                       level = demoGen.level(now);
  else if (now - liveAt < 1500)   level = liveLevel;        // hold the last level between messages
  else                            level = 0;                // the Orin went quiet: idle dots
  push(shape(level));
  draw();
}
