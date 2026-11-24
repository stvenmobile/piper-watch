# Face bring-up: CrowPanel Advanced 7" ESP32-P4 (DHE04107D, V1.0)

A first test of the display before any face code: test pattern, full-screen animation speed, touch.

## Build and flash (PC, VS Code + PlatformIO)
1. Open this folder (`firmware/face_p4`) in VS Code with PlatformIO.
2. Plug the board's **USB-UART** USB-C port (it shows up as a COM port in Device Manager).
3. PlatformIO: **Upload**, then **Monitor** (115200). If it can't connect, hold BOOT, tap RESET, release BOOT.

## Orientation
Upright = the board's USB connectors on the **left** (seen from the front). Mounted the other way round,
send `R` (rotates 180°, done by the panel itself, so it costs nothing).

## What you should see
- Colour bars (white yellow cyan green magenta red blue black) on top, a grey ramp, a grid below,
  a thin orange frame round the edge, and corner squares: **red top-left, green top-right,
  blue bottom-left, white bottom-right**.
- Serial: `face: display started`, `face: touch GT911 at 0x5D ...`, then a status line.

## Commands (serial monitor)
| | |
|---|---|
| `?` | status |
| `B0`..`B100` | backlight % |
| `A` | full-screen animation; fps printed every second |
| `P` | back to the test pattern |
| `T` | touch dots on / off |
| `R` | rotate the picture 180° (toggle) |

## If it doesn't work, send Claude
- the whole serial log from reset (the boot lines include `Chip is ESP32-P4 (revision v1.x)` when flashing);
- what the screen shows: dark / backlight only / garbage / pattern in the wrong place.
