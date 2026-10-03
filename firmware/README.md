# Firmware

`head/` is the PlatformIO project for the controller, an **ESP32-S3 DevKitC-1 N16R8**
(16 MB flash, 8 MB octal PSRAM). It drives the STS3215 servo bus, animates the two OLED eyes
and talks to the Jetson over native USB serial.

Connect the board's **"USB"** port (native USB, not the "UART" port), then:

    cd firmware/head
    pio run -t upload        # build and flash
    pio device monitor       # serial output

The current sketch is a face bring-up test: it reports whether each display answers (eyes on
I2C0 at 0x3C / 0x3D, SDA 8 / SCL 9; mouth on I2C1 at 0x3C, SDA 10 / SCL 11), then the eyes blink
and glance while the mouth alternates between talking and smiling.
