// SH1122 256x64 OLED test on the XIAO ESP32-S3 (hardware SPI: SCK D8, MOSI D10).
// Shows: a border + title, then cycles a checkerboard, a contrast ramp and a pair of blinking "eyes".
#include <Arduino.h>
#include <SPI.h>
#include <U8g2lib.h>

static const int PIN_CS = D5, PIN_DC = D0, PIN_RST = D1;
U8G2_SH1122_256X64_F_4W_HW_SPI oled(U8G2_R0, PIN_CS, PIN_DC, PIN_RST);

static void title(const char *msg) {
  oled.clearBuffer();
  oled.drawFrame(0, 0, 256, 64);
  oled.setFont(u8g2_font_6x12_tr);
  oled.drawStr(6, 14, "piper-watch OLED test");
  oled.drawStr(6, 30, msg);
  oled.sendBuffer();
}

static void eyes(bool open) {
  oled.clearBuffer();
  for (int cx : {72, 184}) {
    if (open) { oled.drawFilledEllipse(cx, 32, 30, 24); oled.setDrawColor(0); oled.drawDisc(cx + 6, 28, 8); oled.setDrawColor(1); }
    else      oled.drawBox(cx - 30, 30, 60, 4);
  }
  oled.sendBuffer();
}

void setup() {
  Serial.begin(115200);
  delay(1500);
  Serial.println("oled_test: starting (SH1122 256x64, CS D5, DC D0, RST D1, SCK D8, MOSI D10)");
  oled.begin();
  oled.setContrast(200);
  title("if you can read this, it works");
  Serial.println("oled_test: init sent");
  delay(3000);
}

void loop() {
  static uint32_t n = 0;
  // 1. checkerboard (catches swapped/missing columns or rows)
  oled.clearBuffer();
  for (int y = 0; y < 64; y += 8) for (int x = 0; x < 256; x += 8) if (((x + y) / 8) % 2 == 0) oled.drawBox(x, y, 8, 8);
  oled.sendBuffer();
  Serial.printf("oled_test: pass %lu checkerboard\n", (unsigned long)n);
  delay(2000);
  // 2. contrast ramp on a full-white screen
  oled.clearBuffer(); oled.drawBox(0, 0, 256, 64); oled.sendBuffer();
  for (int c = 0; c <= 255; c += 5) { oled.setContrast(c); delay(20); }
  oled.setContrast(200);
  // 3. eyes, blinking
  for (int i = 0; i < 4; i++) { eyes(true); delay(900); eyes(false); delay(120); }
  title(("pass " + String(++n)).c_str());
  delay(1500);
}
