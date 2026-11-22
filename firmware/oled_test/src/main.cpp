// OLED bring-up for the head's XIAO ESP32-S3: tries each likely driver / bus in turn, 5 s each, and
// says on serial (and on the screen, if it lights) which one is running. Whichever lights up is the one to use.
//   1  SH1122  256x64  hardware SPI (SCK D8, MOSI D10)
//   2  SSD1322 256x64  hardware SPI (many 2.08" / 2.4" 256x64 modules use this chip)
//   3  SH1122  256x64  software SPI on the same pins (rules out the SPI pin mapping)
//   4  SSD1322 256x64  software SPI
#include <Arduino.h>
#include <SPI.h>
#include <U8g2lib.h>

static const int PIN_CS = D5, PIN_DC = D0, PIN_RST = D1, PIN_SCK = D8, PIN_MOSI = D10;

U8G2_SH1122_256X64_F_4W_HW_SPI      a(U8G2_R0, PIN_CS, PIN_DC, PIN_RST);
U8G2_SSD1322_NHD_256X64_F_4W_HW_SPI b(U8G2_R0, PIN_CS, PIN_DC, PIN_RST);
U8G2_SH1122_256X64_F_4W_SW_SPI      c(U8G2_R0, PIN_SCK, PIN_MOSI, PIN_CS, PIN_DC, PIN_RST);
U8G2_SSD1322_NHD_256X64_F_4W_SW_SPI d(U8G2_R0, PIN_SCK, PIN_MOSI, PIN_CS, PIN_DC, PIN_RST);

struct Mode { U8G2 *g; const char *name; };
Mode modes[] = { {&a, "1 SH1122 hw SPI"}, {&b, "2 SSD1322 hw SPI"}, {&c, "3 SH1122 sw SPI"}, {&d, "4 SSD1322 sw SPI"} };

void setup() {
  Serial.begin(115200);
  delay(1500);
  Serial.println("oled_test: driver scan (CS D5, DC D0, RST D1, SCK D8, MOSI D10)");
}

void loop() {
  for (auto &m : modes) {
    Serial.printf("oled_test: trying %s\n", m.name);
    m.g->begin();
    m.g->setContrast(255);
    m.g->clearBuffer();
    m.g->drawBox(0, 0, 256, 64);                  // full white first - the most visible thing there is
    m.g->sendBuffer();
    delay(2000);
    m.g->clearBuffer();
    m.g->drawFrame(0, 0, 256, 64);
    m.g->setFont(u8g2_font_logisoso32_tr);
    m.g->drawStr(10, 48, m.name);
    m.g->sendBuffer();
    delay(3000);
    m.g->clearDisplay();
  }
}
