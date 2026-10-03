// Piper-Watch controller - face bring-up skeleton for the ESP32-S3.
// I2C0: both SH1106 eyes (left 0x3C, right 0x3D). I2C1: the 0.91" SSD1306 mouth (0x3C).
// The eyes blink and glance around and the mouth "talks"; servo bus and Jetson link come
// next (see README roadmap).
#include <Arduino.h>
#include <Wire.h>
#include <U8g2lib.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C         eyeL(U8G2_R0, U8X8_PIN_NONE);   // Wire  (I2C0) 0x3C
U8G2_SH1106_128X64_NONAME_F_HW_I2C         eyeR(U8G2_R0, U8X8_PIN_NONE);   // Wire  (I2C0) 0x3D
U8G2_SSD1306_128X32_UNIVISION_F_2ND_HW_I2C mouth(U8G2_R0, U8X8_PIN_NONE);  // Wire1 (I2C1) 0x3C

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

static void drawMouth(int open) {
  // open: 0 = closed smile line .. 12 = wide open
  mouth.clearBuffer();
  if (open < 2) {
    for (int x = 24; x < 104; x++) {                    // gentle smile curve
      int y = 16 + (x - 64) * (x - 64) / 260;
      mouth.drawBox(x, 32 - y - 2, 1, 3);
    }
  } else {
    mouth.drawRBox(30, 16 - open, 68, 2 * open, open > 4 ? 4 : open);
  }
  mouth.sendBuffer();
}

static bool probe(TwoWire &bus, uint8_t addr, const char *name) {
  bus.beginTransmission(addr);
  bool found = bus.endTransmission() == 0;
  Serial.printf("%-5s at 0x%02X: %s\n", name, addr, found ? "found" : "NOT FOUND");
  return found;
}

void setup() {
  Serial.begin(115200);
  delay(1500);                      // let native USB connect
  Serial.println("piper-watch: face bring-up");

  Wire.begin(EYES_SDA, EYES_SCL, 400000);
  Wire1.begin(MOUTH_SDA, MOUTH_SCL, 400000);
  probe(Wire, 0x3C, "left");
  probe(Wire, 0x3D, "right");
  probe(Wire1, 0x3C, "mouth");

  eyeL.setI2CAddress(0x3C << 1);
  eyeR.setI2CAddress(0x3D << 1);
  mouth.setI2CAddress(0x3C << 1);
  for (U8G2 *d : {(U8G2 *)&eyeL, (U8G2 *)&eyeR, (U8G2 *)&mouth}) {
    d->begin();
    d->setBusClock(400000);
  }
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

  // "talk" for 3 s, then smile for 3 s
  bool talking = (now / 3000) % 2 == 0;
  drawMouth(talking ? (int)(6 + 5 * sin(now / 90.0)) : 0);
  delay(30);
}
