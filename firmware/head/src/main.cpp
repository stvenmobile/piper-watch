// Piper-Watch head controller - bring-up skeleton.
// Proves the display works; servo bus, Jetson link and eyes come next (see README roadmap).
#include <Arduino.h>
#include <TFT_eSPI.h>

TFT_eSPI tft;

static void setLed(bool r, bool g, bool b) {
  // RGB LED is common-anode: LOW = on
  digitalWrite(LED_R, r ? LOW : HIGH);
  digitalWrite(LED_G, g ? LOW : HIGH);
  digitalWrite(LED_B, b ? LOW : HIGH);
}

void setup() {
  Serial.begin(921600);
  pinMode(LED_R, OUTPUT);
  pinMode(LED_G, OUTPUT);
  pinMode(LED_B, OUTPUT);
  setLed(false, false, true);

  tft.init();
  tft.setRotation(1);                      // landscape, 480x320
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_CYAN, TFT_BLACK);
  tft.setTextDatum(MC_DATUM);
  tft.drawString("piper-watch", tft.width() / 2, tft.height() / 2 - 16, 4);
  tft.setTextColor(TFT_DARKGREY, TFT_BLACK);
  tft.drawString("head controller bring-up", tft.width() / 2, tft.height() / 2 + 20, 2);

  Serial.println("piper-watch head: display up");
  setLed(false, true, false);
}

void loop() {
  delay(1000);
}
