# Firmware

`head/` is the PlatformIO project for the controller, an **ESP32-S3 DevKitC-1 N16R8**
(16 MB flash, 8 MB octal PSRAM). It drives the STS3215 servo bus, animates the two OLED eyes
and talks to the Jetson over native USB serial.

Connect the board's **"USB"** port (native USB, not the "UART" port), then:

    cd firmware/head
    pio run -t upload        # build and flash
    pio device monitor       # serial output

The current sketch is an eye bring-up test: it reports whether each eye answers on its I2C
bus (left SDA 8 / SCL 9, right SDA 10 / SCL 11), then blinks and glances.
