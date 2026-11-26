# Piper's face: CrowPanel Advanced ESP32-P4 (5" final head, 7" bench)

RoboEyes-style eyes above the spectrum mouth. The face scales to the screen; one build target per panel:

| env | Panel | Display | Backlight |
|---|---|---|---|
| `crowpanel_p4_5` (default) | 5" DHE04005D, 800x480 (V1.0 / V1.1: same wiring) | 16-bit parallel RGB, ~42 Hz | STC8 helper MCU, I2C 0x2F |
| `crowpanel_p4_7` | 7" DHE04107D V1.0, 1024x600 | 2-lane MIPI-DSI, EK79007 | PWM on GPIO31 |

- `src/face.cpp`, `src/face.h` - the face: eyes, mouth, moods, status, the serial protocol. Hardware-independent.
- `src/main.cpp` - serial commands, touch, the frame loop. Shared by both panels.
- `src/panel.h` - what main.cpp needs from a panel; `src/panel_5in_rgb.cpp`, `src/panel_7in_dsi.cpp` - one each.

Licence: GPL-3.0-or-later (the eyes are a port of FluxGarage RoboEyes) - see `LICENSE`.

## Build and flash (PC, VS Code + PlatformIO)
1. Open this folder (`firmware/face_p4`) in VS Code with PlatformIO.
2. Plug the board's **USB-UART** USB-C port (a COM port in Device Manager).
3. Pick the env (status bar, or `-e`), **Upload**, then **Monitor** (115200). If it can't connect, hold BOOT,
   tap RESET, release BOOT.
4. Use the socket marked **UART** (the CH340 serial chip) for upload and monitor. The **USB** socket is the
   P4's own USB: it shows a COM port only while the chip is in its bootloader, so the port vanishes when the
   board resets (an error at the end of the upload, and no serial monitor afterwards).

## Orientation
Upright = the board's USB connectors on the **left**. Mounted the other way round, send `R` (rotates 180°).
On the 7" the panel turns the picture itself; the 5" (RGB) has no such command, so the frame is copied back to
front - check `F` with and without `R`. Touch coordinates turn with the picture.

## Commands (serial monitor, one per line)
The mouth OLED's protocol - piper_assistant drives this the same way:

| | |
|---|---|
| `M<mode>` | `neutral` `talk` `happytalk` `excitedtalk` `smile` `frown` `surprise` `sleep` `happysleep` `research` `blank` |
| `I<status>` | `idle` `listening` `thinking` `confused` |
| `L<0..255>` | speech loudness (~30 Hz while speaking); without it, talk modes simulate speech |
| `G<x>,<y>` | look towards x,y (-100..100, right / down positive) for 3 s |
| `D1` / `D0` | demo loop through all modes / stop |
| `C<0..255>` | brightness |
| `?` | state |

Bench only: `B<0..100>` backlight % (overrides C), `P` test pattern on / off, `R` rotate 180°, `F` frames per second.

## What the modes look like
- **neutral**: eyes blink and glance around; the mouth is a flat dashed line
- **talk / happytalk**: spectrum bars dance with the speech, up to half their full height; happy eyes are arched (`^ ^`) and she laughs as she starts
- **excitedtalk**: the bars use their full height; the eyes open a little wider
- **smile / frown**: arched eyes / drooping outer eyelids
- **listening**: eyes slightly bigger, straight ahead
- **thinking**: half-lidded eyes looking up, side to side; three dots fill in where the mouth is
- **confused**: lopsided eyes that shake now and then
- **surprise**: big round eyes; the "O" mouth starts small, pops wide open and settles back to small (about 1.2 s)
- **research**: eyes up, darting as if reading; a highlight sweeps along the mouth
- **sleep**: closed eyes, the mouth breathing, Zzz rising
- **blank**: dark, backlight off (also after 5 minutes without commands)
