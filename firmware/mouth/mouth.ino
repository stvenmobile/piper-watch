// Arduino-toolchain entry point for Piper's mouth. All of the code is in src/main.cpp, which the Arduino build
// compiles automatically (it compiles a sketch's src/ folder). PlatformIO (ESP32-S3) ignores this file.
//
// XIAO MG24 (Sense), same OLED wiring as the ESP32-S3 (CS D5, DC D0, RST D1, SCK D8, MOSI D10, VCC 3V3):
//   arduino-cli compile -b SiliconLabs:silabs:xiao_mg24:protocol_stack=none firmware/mouth
//   arduino-cli upload  -b SiliconLabs:silabs:xiao_mg24:protocol_stack=none -p COMxx firmware/mouth
// Board package: SiliconLabs:silabs (index https://siliconlabs.github.io/arduino/package_arduinosilabs_index.json),
// library U8g2 2.35.30. No boot buttons needed: it flashes through the board's on-board debugger.
