# Firmware

> **Design change:** the separate base ESP32 is gone. Level 2's JC4827W543R display (ESP32-S3
> N4R8, 4 MB flash, 8 MB PSRAM) will run one firmware for its screen and the pan motor (STEP
> IO 15, DIR IO 16, EN IO 6, HALL IO 7 - see `hardware/wiring.md`); that project isn't written yet.
> The head's XIAO ESP32-S3 drives the eyes and mouth. `head/` below is the earlier DevKitC bring-up.

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
