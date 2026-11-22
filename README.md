# Piper-Watch

**Piper-Watch** is the body of [piper-assistant](https://github.com/stvenmobile/piper_assistant): a small
desktop robot with a head that turns (pan) and nods (tilt), a camera to see who is there, and an OLED
**mouth** that shows what Piper is doing and how she "feels".

Everything is built around a **Jetson Orin NX** on a Seeed **reComputer J401** carrier, which sits inside
the printed base and runs all the software (speech, vision, the head link). Two **STS3215** bus servos
move the head; the Orin drives them directly over USB through a Waveshare bus servo adapter. A
**XIAO ESP32-S3** in the turret drives the mouth.

> **Status:** being built. The base (tub, lid, servo adapter, power) and the head are assembled; the pan
> stack, turret and tilt linkage are next (run book step 3). The mouth firmware is done and driven by
> piper-assistant.

> **Build warning - cable routing is extremely tight.** The camera's and the XIAO's USB cables and the
> tilt servo's lead all pass through the pan joint: the turret floor, the hub's **19 mm** bore, and the
> hub's cable window, which opens into a **20.6 mm** gap over the pan servo. A moulded USB-A plug will
> not make that turn. Route the cables **small end first, from below**, with a pull cord (run book step
> 3.9), or pull them through bare and fit solder-on USB-A plugs afterwards. If you change any of those
> dimensions, check that the cables still go through before you print.

---

## How it fits together

```text
             HEAD (tilts)   webcam board (lens + two LED "eyes" behind glass domes), 2.08" OLED mouth
                │  tilt: 27 mm rod from the tilt servo's crank
             TURRET (pans)  tilt servo (STS3215, ID 2), XIAO ESP32-S3 (mouth), cowl, cheeks with 608 bearings
                │  hub through a 1" pillow-block bearing; the cables go down its bore
             SKIRT          pan servo (STS3215, ID 1) hanging under the plate, in a sleeve
                │  slips over the round wall, 4 x M2.5
             LID + WALL     Waveshare Bus Servo Adapter (A) on standoffs; cable slot into the tub
             TUB            reComputer J401 carrier + Orin NX, 12 V split block, DC jack, power button,
                            Wi-Fi antennas; the USB plugs go into the Orin from outside, through the back wall
```

| Part | Role |
| --- | --- |
| Jetson **Orin NX** on a Seeed **reComputer J401** carrier | runs piper-assistant: speech, vision, the head link, the dashboard |
| 2 x Feetech **STS3215** (12 V bus servos) | pan (ID 1) and tilt (ID 2), daisy-chained |
| **Waveshare Bus Servo Adapter (A)** | the servos' bus, on USB to the Orin; 12 V in on its screw terminal |
| ServoCity **1" bore pillow block** | the pan bearing: carries the turret and head |
| **XIAO ESP32-S3** (or XIAO MG24) | drives the mouth; USB serial to the Orin |
| 2.08" **SH1122** OLED, 256 x 64 (GME25664-65) | the mouth |
| Logitech webcam board (210-002028-003), out of its housing | the camera |
| **12 V, at least 5 A** supply | the Orin and the servos ([wiring](hardware/wiring.md)) |
| Printed parts, PETG | see the [run book](hardware/cad/docs/build_photos/README.md) |

The speakerphone (SP-200) also plugs into the Orin, away from the head.

## Building it

- **[Run book](hardware/cad/docs/build_photos/README.md):** what to print, the hardware for each step,
  and the assembly from the tub up, with photos and renders.
- **[Wiring](hardware/wiring.md):** power (12 V split, fuse, power button), the mouth OLED's pins, cable routes.
- **CAD:** parametric OpenSCAD in [hardware/cad/](hardware/cad/); `hardware/cad/export.sh` renders every
  printable part to `hardware/cad/out/`.
- **Servo setup:** [tools/servo_test](tools/servo_test) sets IDs, centres and the tilt limits (bench, over the adapter's USB).

## Software

- **The mouth:** [firmware/mouth](firmware/mouth). Modes (neutral, talk, happytalk, smile, frown, surprise,
  sleep, happysleep, research, blank) and a status symbol, set by one-line serial commands from the Orin.
  `firmware/oled_test` is the OLED's bring-up test.
- **Everything else runs in piper-assistant:** the head link (`src/piper_head/link.py`) drives the mouth, `src/piper_head/servos.py`
  the pan and tilt servos (limits and home in its `config.yaml`, `head.servos`), and `src/piper_vision` the camera.

## Repository layout

```text
firmware/mouth/        the mouth: XIAO + SH1122 OLED (PlatformIO for the ESP32-S3, Arduino CLI for the MG24); sim/ is its browser simulator
firmware/oled_test/    OLED bring-up test
hardware/wiring.md     power, the mouth's pins, cable routes
hardware/cad/          OpenSCAD: parts/ (sources), out/ (exported .3mf, not committed), docs/build_photos/ (the run book)
tools/servo_test/      STS3215 bench tools (IDs, centring, limits, moves)
docs/                  datasheets (the OLED)
```
