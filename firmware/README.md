# Firmware

- `mouth/`: Piper's mouth on the 2.08" SH1122 OLED, driven by a XIAO ESP32-S3 (PlatformIO, `platformio.ini`) or a
  XIAO MG24 (Arduino CLI, see `mouth.ino`). The serial commands are listed at the top of `mouth/src/main.cpp`;
  `mouth/sim/mouth_sim.html` is the browser simulator the mouth was designed in (`mouth_locked.json`: its settings).
- `oled_test/`: bring-up test for the OLED and its wiring (`hardware/wiring.md`, section 2).

The servos have no firmware of their own here: the Orin drives them through the Waveshare adapter
(piper-assistant `src/piper_head/servos.py`).
