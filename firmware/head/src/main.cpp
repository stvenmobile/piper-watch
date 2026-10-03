// Piper-Watch controller - eye bring-up skeleton for the ESP32-S3.
// Two SH1106 OLEDs, one per I2C bus (they share address 0x3C). The eyes blink and
// glance around; servo bus and Jetson link come next (see README roadmap).
#include <Arduino.h>
#include <Wire.h>
#include <U8g2lib.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C     eyeL(U8G2_R0, U8X8_PIN_NONE);   // Wire  (I2C0)
U8G2_SH1106_128X64_NONAME_F_2ND_HW_I2C eyeR(U8G2_R0, U8X8_PIN_NONE);   // Wire1 (I2C1)

static void drawEye(U8G2 &eye, int lookX, int lookY, int openness) {
  // openness: 0 = closed .. 100 = fully open
  eye.clearBuffer();
  int h = 44 * openness / 100;
  if (h < 3) {
    eye.drawBox(24, 30, 80, 4);                         // closed: a line
  } else {
    eye.drawRBox(24, 32 - h / 2, 80, h, h < 16 ? h / 2 : 8);
    eye.setDrawColor(0);                                // pupil (black) inside the eye
    eye.drawDisc(64 + lookX, 32 + lookY * h / 44, 9);
    eye.setDrawColor(1);
  }
  eye.sendBuffer();
}

static bool beginEye(U8G2 &eye, TwoWire &bus, int sda, int scl, const char *name) {
  bus.begin(sda, scl, 400000);
  bus.beginTransmission(0x3C);
  bool found = bus.endTransmission() == 0;
  Serial.printf("%s eye (SDA %d, SCL %d): %s\n", name, sda, scl, found ? "found at 0x3C" : "NOT FOUND");
  eye.begin();
  eye.setBusClock(400000);
  return found;
}

void setup() {
  Serial.begin(115200);
  delay(1500);                      // let native USB connect
  Serial.println("piper-watch: eye bring-up");
  beginEye(eyeL, Wire, EYE_L_SDA, EYE_L_SCL, "left");
  beginEye(eyeR, Wire1, EYE_R_SDA, EYE_R_SCL, "right");
  Serial.printf("PSRAM: %u KB\n", (unsigned)(ESP.getPsramSize() / 1024));
}

void loop() {
  static uint32_t nextBlink = millis() + 2500, nextLook = 0;
  static int lookX = 0, lookY = 0;
  uint32_t now = millis();

  if (now >= nextLook) {                       // glance somewhere new now and then
    lookX = random(-22, 23);
    lookY = random(-8, 9);
    nextLook = now + random(800, 2500);
  }
  if (now >= nextBlink) {                      // quick blink
    for (int o : {60, 20, 0, 20, 60, 100}) {
      drawEye(eyeL, lookX, lookY, o);
      drawEye(eyeR, lookX, lookY, o);
      delay(18);
    }
    nextBlink = now + random(2500, 6000);
  }
  drawEye(eyeL, lookX, lookY, 100);
  drawEye(eyeR, lookX, lookY, 100);
  delay(30);
}
