# Piper-Watch

**Piper-Watch** is the eyes of [piper-assistant](https://github.com/stvenmobile/piper_assistant):
a desktop robot head that turns to look around, finds and follows faces, and recognises the
people it knows. The head has two round display **eyes**, an OLED **mouth** and the camera as its
**nose**, so it can show what Piper is doing (listening, thinking, speaking) and who it is paying
attention to.

All the thinking happens on an **NVIDIA Jetson Orin NX** (a Seeed **reComputer J4012**), and
Piper-Watch sits right on top of it. **Level 2** - a 160 × 160 mm box over the reComputer -
holds the power wiring, the pan motor and a 4.3" display on its front. On top of Level 2, a lazy
Susan carries the **head**, which turns left and right. There is deliberately **no tilt motor**:
the camera is fixed 18° up, which suits a person sitting at the desk.

> **Status:** being built. Level 2's drive (deck, lazy Susan, belt and motor) has been built and
> test-fitted, its perfboard is laid out and the body is printing; the head's parts are printed.
> The firmware for the current design isn't written yet.

---

## Goals and non-goals

**Goals**

- Smooth, quiet tracking of a person's face (pan), without buzzing while holding still.
- Simple and stable: one motor, no tilt joint, everything wired inside.
- Face detection and recognition running entirely locally on the Jetson.
- A friendly, clearly-a-device presence: the eyes and mouth show Piper's state and look toward
  the person it is attending to, so it reads as an assistant, not a camera that silently watches.
- Compact: the footprint of the reComputer it sits on.
- One power supply for everything: the Jetson's own 19 V brick.

**Non-goals (for now)**

- Running any AI on the ESP32s.
- Battery operation.

---

## System architecture

```text
            ┌──────────────────────────── HEAD (turns) ─────────────────────────────┐
            │  XIAO ESP32-S3 ── SPI ──► two GC9A01 round eyes + SH1122 OLED mouth   │
            │  C920 camera board (the nose), fixed 18° up                            │
            └──────────┬──────────────────────────┬─────────────────────────────────┘
                       │ USB                       │ USB        (down the turntable's hollow tube)
            ┌──────────┼──────────────────────────┼─────── LEVEL 2 (fixed) ──────────────────────┐
            │          │                          │                                               │
            │  JC4827W543R 4.3" display (front) ── its own ESP32-S3 ──► TMC2209 ──► NEMA17 ── belt ── turntable
            │          │  1 frame/s camera view,   ▲ A3144 Hall (homing)                          │
            │          │  status page on a tap     │                                               │
            │  19 V jack ─ split block ─┬─ fuse ─ switch ─ perfboard (TMC2209 + 5 V buck)          │
            │                           └─ Jetson DC in                                            │
            └──────────┼──────────────────────────┼─────────────┬────────────────────────────────┘
                       │ USB                       │ USB         │ 19 V
            ┌──────────▼──────────────────────────▼─────────────▼────────────────────────────────┐
            │  reComputer J4012 (Jetson Orin NX)                                                   │
            │  vision: capture → face detection → recognition → tracking → pan target + face state │
            │  piper-assistant: speech in/out, dialogue; head link service; dashboard web page     │
            └──────────────────────────────────────────────────────────────────────────────────────┘
                 SP-200 USB speakerphone on the Jetson, placed away from the head
```

The roles are:

- **Jetson:** perception and decisions. It decides *where to look* and *what face to show*.
- **Level 2's display ESP32-S3:** the real-time body. It decides *how to move there* smoothly
  and safely, keeps track of where the head is, and runs the 4.3" screen.
- **Head XIAO ESP32-S3:** animates the eyes and mouth from the state it's sent.

Everything talks to the Jetson over USB; no Wi-Fi or Bluetooth is used.

---

## Components

| Part | Role |
| --- | --- |
| Seeed **reComputer J4012** (Jetson Orin NX, JetPack), with its 19 V brick | vision, recognition, assistant, dashboard; its brick powers everything |
| **Guition JC4827W543R** 4.3" 480 × 272 display with its own **ESP32-S3** (N4R8, native USB) | Level 2's front screen, and the pan motor's controller |
| **NEMA17** stepper (42.3 × 33.4 mm), 20-tooth GT2 pulley, 6 mm GT2 belt | pan motor; 5 : 1 onto the printed 100-tooth ring pulley |
| **BTT TMC2209** driver (STEP/DIR mode, 1/16 microstepping) | quiet stepper drive |
| **A3144** Hall switch + a magnet on the ring pulley | homing |
| 5.5" (140 mm) aluminium lazy Susan bearing | pan bearing, carries all the weight above it |
| **Seeed XIAO ESP32-S3** | the head's controller |
| 2 × 1.28" round **GC9A01** TFT (240 × 240) | the eyes |
| 2.08" **SH1122** OLED (256 × 64) | the mouth |
| Logitech **C920** camera board (out of its housing) | the nose - vision |
| **SP-200** USB speakerphone: 4-mic array, hardware echo cancellation | microphone and speaker, on the Jetson |
| 19 V panel jack (5.5 × 2.1, IP68), 2-way barrier strip, 6 × 30 mm panel fuse holder (3 A slow-blow), snap-in rocker switch | power entry on Level 2's back |
| LM2596S buck (set to 5.0 V), 70 × 50 perfboard, screw terminals, 100 µF / 35 V, 2 × 10 kΩ | the perfboard |
| Printed parts (PETG): Level 2 body and drive deck, motor bracket, ring pulley, head face, shell, camera plate and floor | enclosure and drive |

---

## Power

Everything runs from the **Jetson's own 19 V brick**. The 19 V comes in through a panel jack on
Level 2's back and is split on a barrier strip on Level 2's floor:

```text
19 V brick ── jack ── split block ──┬──────────────────────────────────────► Jetson DC in (always on)
                                    └── fuse (3 A slow) ── switch ── perfboard J1 ──┬── TMC2209 VM (+100 µF) ── NEMA17
                                                                                    └── LM2596 buck ── 5 V ── Hall sensor
split block − = the common ground (jack −, Jetson −, perfboard −)

Logic power comes over USB from the Jetson: Level 2's display (~260 mA), the head XIAO and its
three displays, and the camera.
```

- **The switch and fuse cover only the head side** (motor and buck). The Jetson's feed never
  passes through them, so switching the head off never cuts the Jetson.
- **The motor runs straight from 19 V:** the TMC2209 chops it down to the coil current, so
  there's no converter in that path.
- **The buck only feeds the Hall sensor** (it needs 5 V). Nothing with a USB link is fed from it,
  so nothing can back-feed the Jetson's USB ports.

The details - every wire, the perfboard layout and its wiring list - are in
[hardware/wiring.md](hardware/wiring.md).

---

## Wiring and pins

The full wiring is in [hardware/wiring.md](hardware/wiring.md), with KiCad schematics and the
perfboard drawings in [hardware/kicad/](hardware/kicad/). In short:

| Signal | Level 2 display (ESP32-S3) | Goes to |
| --- | --- | --- |
| STEP | IO 15 (connector P3) | TMC2209 STEP, through perfboard J4 |
| DIR | IO 16 (P3) | TMC2209 DIR |
| EN | IO 6 (P3) | TMC2209 EN (LOW = on); a 10 kΩ pull-up keeps the motor off while the ESP32 boots |
| HALL | IO 7 (P3) | A3144 output, 10 kΩ pull-up to 3.3 V |
| 3.3 V / GND | P4 | TMC2209 logic side, pull-ups |
| Jetson link + flashing | native USB (USB-C) | the Jetson |

The head's XIAO drives the two eyes and the mouth on one SPI bus with a chip select each; its
pins are in wiring.md's head section.

---

## Motion control

- **Drive:** the NEMA17 turns a 20-tooth pulley; the belt turns the 100-tooth ring pulley under
  the turntable, 5 : 1. With 1/16 microstepping that's **16,000 steps per turn** of the head
  (0.0225° each) - far finer than tracking needs, and the reduction gives plenty of torque.
- **Quiet:** the TMC2209 runs in StealthChop (its default in STEP/DIR mode), so holding still
  is silent and slow moves are close to it.
- **Step pulses come from hardware** (the S3's RMT/MCPWM), not the CPU, so drawing the screen
  can't make the pan stutter.
- **Homing:** at start-up the head turns slowly until the Hall sensor sees the magnet on the
  ring pulley; that's the zero. After that the position is counted in steps. Each time the
  head passes home the count is checked, so a missed step is caught and corrected.
- The Jetson sends **targets** (pan angle plus a speed hint) at up to 30–50 Hz. The ESP32 clamps
  them to the soft limits (about ±150°, set by the cables) and smooths them with a velocity and
  acceleration limit, so tracking looks natural rather than snappy.
- The ESP32 reports the **actual position** about 50 times a second, timestamped, so the Jetson
  knows where the camera was pointing when each video frame was taken. This is what keeps
  tracking stable while the head is moving.
- **Watchdog:**
  - no message from the Jetson for **1 s** → hold position;
  - for **10 s** → ease back to the rest pose, then disable the driver (silent, no holding current);
  - a fault (homing fails, the count is off at home) → stop and report.
- **Turning the head by hand:** with the driver disabled it turns freely through the belt.
  With the driver enabled, forcing it just skips steps (no gears to strip); the next pass over
  home corrects the count.

---

## Jetson ↔ ESP32 protocol (draft)

- **Link:** each ESP32-S3's native USB serial (`/dev/ttyACM*` on the Jetson). Native USB ignores
  the baud setting and runs at full USB speed.
- **Messages:** newline-delimited **JSON**, one object per line, each with a `"t"` (type) field.
  Unknown types and fields are ignored, so either side can be updated first.
- The **head link service** in piper-assistant (`src/piper_head/link.py`) is the one program that
  talks to the ESP32s. It sends heartbeats, forwards messages from the assistant and the vision
  service, and re-sends the last face state whenever a device (re)connects.

| Direction | Message | Contents | Device |
| --- | --- | --- | --- |
| Jetson → ESP32 | `HEARTBEAT` | sequence | both |
| Jetson → ESP32 | `FACE` | state (idle, listening, thinking, speaking, sleeping, error, offline), mood, attention direction | head |
| Jetson → ESP32 | `LOOK` | pan°, max speed, mode (track / glance / rest) | Level 2 |
| Jetson → ESP32 | `CONFIG` | soft limits, smoothing, brightness, etc. | both |
| Jetson → ESP32 | `FRAME` | a camera frame for the 4.3" screen, about once a second, in small chunks | Level 2 |
| Jetson → ESP32 | `HEALTH` | Jetson temperatures, load, memory, uptime - for the status page | Level 2 |
| ESP32 → Jetson | `STATUS` | actual pan, homed, ESP32 time, flags | Level 2 |
| ESP32 → Jetson | `EVENT` | boot, watchdog, fault, homed | both |

Frames are sent in small chunks so a `LOOK` never waits behind one.

---

## The face

The head's front has two round **GC9A01 eyes** and a 2.08" **OLED mouth**; the camera looks out
of a small window in the arch above them. The XIAO animates them from the `FACE` state and mood:
the eyes blink, glance and look toward the person being tracked (`attention`), and the mouth
moves while Piper's speech plays. The eyes are mounted upside down (their pin tabs point up into
the arch), so their image is rotated 180° in software.

**Level 2's 4.3" display** shows a camera view about once a second - greyscale, or a line drawing
of what the camera sees - and, on a tap, a **status page**: the Jetson's temperatures, load,
memory and uptime, Piper's state, and the motor's (homed, position). The full camera view with
boxes and names is on the Jetson's **dashboard web page**.

---

## Vision pipeline (Jetson)

- **Capture:** C920 via V4L2, MJPEG at 720p30 (1080p if needed). Once mounted, **lock focus and
  exposure** with `v4l2-ctl`, because autofocus hunting looks bad while tracking.
- **Face detection:** SCRFD or a YOLOv8-face model under **TensorRT**.
- **Recognition:** **ArcFace** embeddings (InsightFace), matched against a local gallery.
  **Enrolment** is a short guided capture of several angles. Embeddings stay on the Jetson, and
  a "forget me" command deletes a person.
- **Tracking:** keep a track ID per face. Turn the face's **horizontal** position into a pan
  target using the camera's field of view and the head's position *at the time of that frame*
  (from `STATUS`), with a deadband so the head isn't constantly making tiny corrections.
  **Vertically** there is no motor: the camera's view at its fixed 18° covers faces from about
  3° below to 40° above it, which takes in a seated person at 30–60 cm.
- **Behaviour (piper-assistant):** who to look at (speaker, newcomer, recognised person), idle
  glances, a rest pose, and face states that match the conversation.

---

## Mechanics

Pan only - no tilt motor. Bottom to top:

- **reComputer J4012** on the desk (130 × 121 × 58 mm).
- **Skirt** (not designed yet): carries Level 2 over the reComputer with an air gap above it.
- **Level 2 body:** a 160 × 160 mm rounded box, about 9 cm tall, printed in one piece.
  - Front: the 4.3" display behind a window, screwed to four tapped posts.
  - Back: the 19 V jack, fuse holder and rocker switch, and a low cable exit for the Jetson's
    19 V and the USB cables.
  - Floor: the 19 V split block, the 5 V buck and the perfboard. Vents high on both sides.
  - Corners: solid columns with heat-set inserts for the drive deck's four screws.
- **Drive deck:** Level 2's lid. Everything that turns hangs from it, so the whole drive lifts
  out of the body as one unit after four screws:
  - the lazy Susan's outer ring is screwed to a plinth on top;
  - the printed 100-tooth **ring pulley** is fixed to the inner ring and hangs through the deck,
    with a 50 mm hollow tube down its middle for the cables;
  - the NEMA17 hangs from a **sliding bracket** in the back-right corner; two slots let it slide
    out to tension the belt, reachable from above with everything assembled. The Hall sensor
    sits on the bracket, next to the ring pulley's magnet.
- **Head:** a box 135 mm wide, 70 deep and 88 tall with a half-round **arch** on top (123 mm in
  all), straight on the turntable plate - no neck:
  - **face plate:** the two eyes and the mouth, each dropped into a pocket from behind;
  - **shell:** sides, back and the arch; the camera plate holds the bare C920 board inside the
    arch at its fixed 18°;
  - **floor:** screws to the turntable plate and carries the XIAO; the cables go down through
    a hole in it into the ring pulley's hollow tube.
- **Cables:** the XIAO's and the camera's USB cables run down the hollow tube into Level 2 and
  out of the back, with a service loop for the ±150° of pan. Avoid slip rings for USB 2.0.
- **Noise:** the drive is quiet, but if movement noise still reaches the speakerphone,
  piper-assistant can pause or flag speech recognition while the head moves.

All the CAD is parametric OpenSCAD in [hardware/cad/](hardware/cad/).

---

## Repository layout

```text
firmware/head/   earlier ESP32-S3 DevKitC bring-up; to be replaced by the head (XIAO: eyes and
                 mouth) and Level 2 (display: screen and pan motor) firmware
jetson/          Jetson-side Python (vision, tracking); the head link service lives in piper-assistant
hardware/cad/    OpenSCAD models of every printed part, export.sh -> out/*.3mf
hardware/kicad/  KiCad schematics, the perfboard layout and its wiring drawings
hardware/wiring.md   the wiring: power, perfboard, motor, Hall sensor, head
docs/            design notes, datasheets
tools/           bench and calibration helpers
```

Face images and embeddings are never committed (`jetson/data/` is git-ignored), because this
repository is public.

---

## Roadmap

1. **Level 2 build:** print the body, wire the perfboard, fit everything, set the buck and the
   driver's current.
2. **Level 2 firmware:** STEP/DIR from hardware pulses, homing, soft limits, the watchdog,
   `LOOK` / `STATUS` over USB.
3. **Level 2 screen:** the status page on a tap, then the 1 frame/s camera view.
4. **Head firmware:** the XIAO drives the eyes and mouth from `FACE`: states, moods, blinks,
   glances toward the tracked person.
5. **Vision:** detection and tracking on the Jetson, closing the loop through `LOOK`.
6. **Recognition:** enrolment, gallery, names on the dashboard and in the assistant.
7. **Dashboard:** the camera view with overlays on the Jetson's web page.

## Open questions

- The final pan range, which depends on the cable routing through the hollow tube.
- The skirt between the reComputer and Level 2: its height and the airflow over the Jetson.
- The head link service with two ESP32s: telling them apart (USB serial number, or a hello
  `EVENT` at boot) and routing each message to the right one.
- The frame format for the 4.3" screen: greyscale JPEG or a line drawing, and the chunk size.
