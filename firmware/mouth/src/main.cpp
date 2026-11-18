// Piper's mouth: a spectrum display on the 2.08" SH1122 256x64 OLED, driven by the XIAO ESP32-S3.
//
// No scrolling. The width is split into frequency bands, one bar each, and every bar rises and falls on its own like an
// audio spectrum analyser. By default the layout is "centre-out": the lowest band is in the middle and higher bands fan
// out to both edges, so the shape is symmetric and reads as a mouth. Bars are drawn symmetric about the centre line.
//
// For now the spectrum is simulated: a speech generator makes syllables / words / sentence pauses, and each syllable
// gets its own spectral shape (a few "formant" peaks that glide between syllables, sometimes a hissy "s" that lights
// the high bands). Bars attack fast and fall back slowly, with optional peak-hold ticks.
//
// Modes:
//   DEMO  (at power-up) - the simulated speech drives everything.
//   LIVE  - the Orin sends loudness levels; they replace the demo's loudness, the spectral shape is still simulated.
//           No level for 1.5 s -> silence.
//
// Serial commands (one per line, from the Orin or the PlatformIO monitor):
//   L<0..255>   loudness for this frame (e.g. "L180"); switches to LIVE
//   D1 / D0     demo on / off
//   G<n>        gain in percent (default 100)
//   B<n>        pixels per band, 2..16 (default 6 -> 42 bands); the bar is 1 px narrower, leaving a gap
//   O<0/1>      layout: 1 = centre-out mirrored (default), 0 = low on the left -> high on the right
//   Y<0/1>      bars: 1 = symmetric about the centre line (default), 0 = growing up from the bottom
//   P<0/1>      peak-hold ticks off / on (default on)
//   F<n>        fall speed in percent of full height per frame, 1..30 (default 6)
//   C<0..255>   contrast (default 160)
//   ?           print the current settings
#include <Arduino.h>
#include <SPI.h>
#include <U8g2lib.h>

static const int PIN_CS = D5, PIN_DC = D0, PIN_RST = D1;
U8G2_SH1122_256X64_F_4W_HW_SPI oled(U8G2_R0, PIN_CS, PIN_DC, PIN_RST);

static const int W = 256, H = 64, MID = H / 2;
static const uint32_t FRAME_MS = 25;                // 40 frames per second
static const int MAX_BANDS = W / 2;

static int bandPx = 6, nb = W / 6;
static bool centreOut = true, symmetric = true, peaks = true, demo = true;
static int gainPct = 100, fallPct = 6, contrast = 160;
static float disp[MAX_BANDS], peak[MAX_BANDS];      // shown level 0..1 and peak-hold level, per bar
static uint32_t peakAt[MAX_BANDS];
static float liveLevel = 0;
static uint32_t liveAt = 0;

static float rnd() { return random(10000) / 10000.0f; }
static float gauss(float x, float c, float w) { float d = (x - c) / w; return expf(-d * d); }

// ---- simulated speech --------------------------------------------------------------------------------------------------
// Loudness: a sentence is 3..8 words, a word 1..4 syllables; a syllable is a raised-sine envelope of 120..260 ms.
// Spectrum: each syllable picks targets for three formant peaks (f = 0 lowest band .. 1 highest) and the current peaks
// glide towards them, so the shape morphs instead of jumping. ~20 % of syllables are fricatives: energy up high.
struct Speech {
  uint32_t segStart = 0, segLen = 0;
  float pk = 0;
  bool voiced = false, hiss = false;
  int sylLeft = 0, wordLeft = 0;
  float f[3] = {0.10f, 0.35f, 0.60f}, ft[3] = {0.10f, 0.35f, 0.60f};

  void next(uint32_t now) {
    segStart = now;
    if (voiced) {                                       // a syllable just ended -> a gap
      voiced = false;
      if (sylLeft > 0)       segLen = random(25, 70);
      else if (wordLeft > 0) segLen = random(120, 380);
      else                   segLen = random(100) < 25 ? random(2500, 5000) : random(700, 1500);
      return;
    }
    if (sylLeft == 0) {
      if (wordLeft == 0) wordLeft = random(3, 9);
      wordLeft--;
      sylLeft = random(1, 5);
    }
    sylLeft--;
    voiced = true;
    segLen = random(120, 260);
    pk = 0.45f + 0.55f * rnd();
    if (random(100) < 15) pk = 1.0f;
    hiss = random(100) < 20;
    ft[0] = 0.04f + 0.16f * rnd();                      // F1: low
    ft[1] = 0.25f + 0.30f * rnd();                      // F2: middle
    ft[2] = 0.55f + 0.30f * rnd();                      // F3: upper middle
  }

  float level(uint32_t now) {                           // loudness 0..1
    if (now - segStart >= segLen) next(now);
    if (!voiced) return 0;
    float t = (now - segStart) / (float)segLen;
    return pk * sinf(t * PI) * (0.85f + 0.15f * sinf(t * 31.0f));
  }

  void glide() { for (int k = 0; k < 3; k++) f[k] += (ft[k] - f[k]) * 0.18f; }

  // Relative energy at frequency x (0..1), roughly 0..1, with per-band, per-frame noise so bars dance.
  float spectrum(float x) const {
    float s;
    if (hiss) s = 0.25f * gauss(x, 0.05f, 0.15f) + 0.9f * gauss(x, 0.85f, 0.25f);
    else      s = 0.30f * (1.0f - x) + 1.00f * gauss(x, f[0], 0.07f) + 0.75f * gauss(x, f[1], 0.09f)
                  + 0.45f * gauss(x, f[2], 0.10f);
    return s * (0.55f + 0.65f * rnd());
  }
} speech;

// ---- drawing ----------------------------------------------------------------------------------------------------------
static float bandFreq(int i) {                          // which frequency (0..1) bar i shows
  if (!centreOut) return nb > 1 ? i / (float)(nb - 1) : 0;
  float c = (nb - 1) / 2.0f;
  return c > 0 ? fabsf(i - c) / c : 0;
}

static void drawBar(int x, int w, float v) {
  if (symmetric) {
    int h = (int)(v * (MID - 3) + 0.5f);                // leave room for the peak ticks
    if (h <= 0) oled.drawHLine(x, MID, w);              // silence: a dashed centre line
    else        oled.drawBox(x, MID - h, w, 2 * h + 1);
  } else {
    int h = (int)(v * (H - 3) + 0.5f);
    oled.drawBox(x, H - 1 - h, w, h + 1);
  }
}

static void drawPeak(int x, int w, float v) {
  if (v < 0.03f) return;
  if (symmetric) {
    int h = (int)(v * (MID - 3) + 0.5f) + 2;
    oled.drawHLine(x, MID - h, w);
    oled.drawHLine(x, MID + h, w);
  } else {
    oled.drawHLine(x, H - 1 - (int)(v * (H - 3) + 0.5f) - 2, w);
  }
}

static void frame(float loud) {
  uint32_t now = millis();
  speech.glide();
  float fall = fallPct / 100.0f;
  int barW = max(1, bandPx - 1);
  int x0 = (W - nb * bandPx) / 2;
  oled.clearBuffer();
  for (int i = 0; i < nb; i++) {
    float target = constrain(loud * speech.spectrum(bandFreq(i)), 0.0f, 1.0f);
    if (target > disp[i]) disp[i] += (target - disp[i]) * 0.7f;      // fast attack
    else                  disp[i] = max(target, disp[i] - fall);     // slow fall
    if (disp[i] >= peak[i]) { peak[i] = disp[i]; peakAt[i] = now; }
    else if (now - peakAt[i] > 350) peak[i] = max(0.0f, peak[i] - 0.025f);
    int x = x0 + i * bandPx;
    drawBar(x, barW, disp[i]);
    if (peaks) drawPeak(x, barW, peak[i]);
  }
  oled.sendBuffer();
}

// ---- serial -----------------------------------------------------------------------------------------------------------
static char line[24];
static int lineLen = 0;

static void setBand(int px) {
  bandPx = constrain(px, 2, 16);
  nb = min(MAX_BANDS, W / bandPx);
  memset(disp, 0, sizeof(disp));
  memset(peak, 0, sizeof(peak));
}

static void report() {
  Serial.printf("mouth: %s, %d bands of %d px, %s, %s, peaks %s, fall %d%%, gain %d%%, contrast %d\n",
                demo ? "DEMO" : "LIVE", nb, bandPx, centreOut ? "centre-out" : "low->high",
                symmetric ? "symmetric" : "bottom-up", peaks ? "on" : "off", fallPct, gainPct, contrast);
}

static void command(const char *s) {
  int v = atoi(s + 1);
  switch (s[0]) {
    case 'L': case 'l':
      liveLevel = constrain(v, 0, 255) / 255.0f;
      liveAt = millis();
      if (demo) { demo = false; Serial.println("mouth: LIVE"); }
      break;
    case 'D': case 'd': demo = v != 0; report(); break;
    case 'G': case 'g': gainPct = constrain(v, 10, 400); report(); break;
    case 'B': case 'b': setBand(v); report(); break;
    case 'O': case 'o': centreOut = v != 0; report(); break;
    case 'Y': case 'y': symmetric = v != 0; report(); break;
    case 'P': case 'p': peaks = v != 0; report(); break;
    case 'F': case 'f': fallPct = constrain(v, 1, 30); report(); break;
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

// ---- main -------------------------------------------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  SPI.begin();
  oled.setBusClock(20000000);
  oled.begin();
  oled.setContrast(contrast);
  randomSeed(esp_random());
  setBand(bandPx);
  report();
}

void loop() {
  static uint32_t next = 0;
  readSerial();
  uint32_t now = millis();
  if ((int32_t)(now - next) < 0) return;
  next = now + FRAME_MS;

  float loud = speech.level(now);                       // always run the generator: it also moves the formants
  if (!demo) loud = (now - liveAt < 1500) ? liveLevel : 0;
  frame(loud * gainPct / 100.0f);
}
