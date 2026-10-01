# Firmware

`head/` is the PlatformIO project for the head controller, an LCDWiki **E32R40T**
(ESP32-32E, ST7796S 320×480, XPT2046 touch). It drives the STS3215 servo bus, animates the eyes
and talks to the Jetson over USB serial.

    cd firmware/head
    pio run -t upload        # build and flash
    pio device monitor       # 921600 baud
