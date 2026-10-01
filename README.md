# Piper-Watch

**Piper-Watch** is the eyes of [piper-assistant](https://github.com/stvenmobile/piper_assistant):
a desktop pan/tilt camera head that lets the assistant look around, find and follow
faces, and recognise the people it knows. It has a small face of its own: a 4" display
for animated robot eyes, short messages and status.

All the thinking happens on an **NVIDIA Jetson Orin NX** in a separate enclosure. The head
contains the camera, two serial bus servos, an ESP32 display board that drives the servos
and the screen, and its own power supply.

> **Status:** design phase. The servos are on order; nothing is built yet.

---

## Goals and non-goals

**Goals**
- Smooth, quiet pan/tilt tracking of a person's face, without stepping or buzzing while holding still.
- Face detection and recognition running entirely locally on the Jetson.
- A friendly physical presence: eyes that look where the camera looks, plus short text messages.
- One data cable and one power brick between the head and the rest of the system.

**Non-goals (for now)**
- Live video on the head's display. The camera view, with detection overlays, lives on
  the Jetson's **dashboard web page** instead.
- Running any AI on the ESP32.
- Battery operation.

---

## System architecture

```text
 ┌─────────────────────── Jetson Orin NX (own enclosure + own PSU) ───────────────────────┐
 │  Vision: capture → face detection → recognition → tracking → pan/tilt targets          │
 │  piper-assistant: speech in/out (Piper TTS), dialogue, events                          │
 │  Dashboard web page: camera view + boxes/names/contours (replaces the vector display)  │
 └──────────────┬───────────────────────────────────────────────┬─────────────────────────┘
                │ one USB 2.0 cable                             │ USB
                │                                               │
 ┌──────────────▼──────────── Piper-Watch head ─────────┐  ┌────▼─────────────────────┐
 │  FE1.1s USB 2.0 hub board (fed from the 5 V buck)    │  │ SP-200 speakerphone      │
 │   ├── Logitech C920X camera (stripped module)        │  │ 4-mic array, hardware AEC│
 │   └── ESP32-32E 4" display board (USB-C, CH340C)     │  │ placed away from the head│
 │          │ UART2 @ 1 Mbps (half-duplex servo bus)    │  └──────────────────────────┘
 │          ▼                                           │
 │  Waveshare Bus Servo Adapter (A) ── 12 V ──┐         │
 │          │ servo bus (daisy-chained)        │         │
 │          ├── STS3215 #1  PAN  (ID 1)        │         │
 │          └── STS3215 #2  TILT (ID 2)        │         │
 │                                            │         │
 │  12 V / 5 A brick ── fuse ── star point ───┴── 5 V / 3 A buck ── USB hub power │
 └──────────────────────────────────────────────────────┘
```

The roles are:
- **Jetson:** perception and decisions. It decides *where to look*.
- **ESP32:** real-time body. It decides *how to move there* smoothly and safely,
  reports where the head actually is, and animates the face.
- **Servos:** close their own position loop with a 12-bit magnetic encoder, and report
  position, load, voltage and temperature.

---

## Components

| Part | Role | Status |
|---|---|---|
| NVIDIA Jetson Orin NX (JetPack) | vision, recognition, assistant, dashboard | have |
| ESP32-32E 4" display, **E32R40T** ([LCDWiki](https://www.lcdwiki.com/4.0inch_ESP32-32E_Display)): ESP32-D0WD-V3, ST7796S 320×480, XPT2046 resistive touch, CH340C USB-serial, FM8002E speaker amp, RGB LED, microSD | head controller: servos, eyes, status | have |
| 2× **Feetech STS3215, 12 V / 30 kg·cm** serial bus servos: 360° magnetic encoder (4096 steps, 0.088°), position/load/voltage/temperature feedback, 1 Mbps half-duplex TTL bus | pan and tilt | **ordered** |
| Waveshare **Bus Servo Adapter (A)**: 9–12.6 V input, powers the servo bus and converts it to plain TX/RX for the ESP32 | servo bus interface | needed |
| Logitech **C920X**, stripped to the core module (about 9 × 3 × 2.5 cm) | camera | have |
| **SP-200** USB speakerphone (5 V): 4-mic array, hardware echo cancellation, USB Audio Class | microphone/speaker, connected to the Jetson | have |
| 5.5" (140 mm) aluminium lazy Susan bearing | pan base, carries all vertical load | have / needed |
| Idler bearing (e.g. 608) and 3D-printed tilt yoke and camera housing | tilt axis | to design |
| **12 V / 5 A** power brick, inline 5 A fuse, 1000 µF / 25 V capacitor | head power | needed |
| **5 V / 3 A** buck converter | USB hub power | needed |
| **FE1.1s 4-port USB 2.0 hub board** (~$5–7) with external 5V/GND pads and a cuttable "Disable USB Power" jumper (e.g. [Circuitneato](https://circuitneato.com/how-to-use-the-fe1-1s-usb-hub/), or generic "FE1.1s hub module" listings) | one cable to the Jetson | needed |

---

## Power

The servos are the 12 V version, so **the servo bus runs directly from the 12 V brick**
through the Bus Servo Adapter, with no converter in that path. Only the 5 V USB side
needs a buck converter.

```text
12 V / 5 A brick ── 5 A fuse ──┬── 1000 µF ── Bus Servo Adapter (A) ── STS3215 pan + tilt
                               │
                               └── 5 V / 3 A buck ── FE1.1s hub (5V pads) ──┬── ESP32 display (USB-C)
                                                                            └── C920X camera
GND: all grounds meet at one star point at the brick input.
```

**Why this layout**
- **Isolation:** the display and camera get their 5 V from their own regulator, never from
  the servo rail, so servo current spikes can't reset the ESP32 or glitch the camera. They also
  don't depend on the Jetson's USB ports for power.
- **Efficiency:** the biggest load (the servos) has no conversion losses at all. The 5 V buck
  only carries about 1 A.
- **One cable:** the hub merges the camera and ESP32 onto a single USB cable to the Jetson.

**USB hub: FE1.1s board**
- **Power:** wire the 5 V buck to the board's **5V/GND pads**. It runs self-powered, at
  500 mA per port (2 A total), which covers the display (~0.3 A) and the camera (~0.5 A).
- **Stop back-feeding:** **cut the "Disable USB Power" jumper** (the name and position vary by
  maker). Otherwise the buck's 5 V flows back up the cable into the Jetson's USB port.
- **Check it before connecting the Jetson:** with only the external 5 V applied, measure the
  upstream port's VBUS pin. It must read **0 V**.
- **Fallback:** the Waveshare USB-HUB-4U (metal case, 5 V DC jack, ~$15–20) works too, but its
  back-feeding behaviour isn't documented, so do the same VBUS check first.

**Power budget (estimates)**

| Load | Typical | Peak |
|---|---|---|
| 2× STS3215 at 12 V, holding | ~0.2 A | |
| 2× STS3215 at 12 V, moving | ~0.5–1.5 A | ~5–6 A if both stall |
| ESP32 display, backlight on (5 V) | ~0.3 A | |
| C920X camera (5 V) | ~0.4 A | ~0.5 A |
| **12 V input total** | **~0.5–2 A** | **~6 A** |

Normal tracking stays well inside 5 A. The peak only happens if both servos stall at
once (jammed, or pushing against a hard stop). Protection:
- Set each servo's **protection current and overload limits** in its EEPROM (see Servo setup),
  so a stall is cut back long before it threatens the brick.
- The **5 A fuse** protects the wiring if something does go wrong.
- If you prefer headroom over settings, a 12 V / 6–8 A brick costs about the same.

**The 1000 µF capacitor** at the adapter input absorbs current spikes when the servos
start moving, so the 12 V line doesn't dip.

---

## Wiring and pins (E32R40T)

The servo bus uses **UART2** on the board's 4-pin **I2C connector** (IO25/IO32), which
isn't otherwise needed. That leaves the microSD card and the SPI header free, and keeps the
USB-C port (UART0 via the CH340C) for the Jetson link and for flashing.

| Signal | ESP32 pin | Board connector | Goes to |
|---|---|---|---|
| Servo bus TX | **IO25** (UART2 TX) | I2C header "SCL" | Bus Servo Adapter **RX** |
| Servo bus RX | **IO32** (UART2 RX) | I2C header "SDA" | Bus Servo Adapter **TX** |
| Ground | GND | I2C header GND | Bus Servo Adapter GND |
| *(do not connect)* | VCC | I2C header VCC | the adapter has its own supply |
| Jetson link | IO1/IO3 (UART0) | USB-C via CH340C | USB hub → Jetson |
| Status LED | IO22 / IO16 / IO17 | on board | red / green / blue (active low) |
| Speaker | IO26 (DAC), IO4 (amp enable, active low) | 2-pin speaker header | optional chirps |
| Free | IO21, IO18, IO19, IO23 | SPI header | spare (IO18/19/23 are shared with the SD card) |
| Free, input only | IO35, IO39 | 2-pin expansion | spare |

Display (ST7796S) and touch (XPT2046) use their fixed on-board pins: IO15 CS, IO2 DC,
IO14 SCK, IO13 MOSI, IO12 MISO, IO27 backlight, IO33 touch CS, IO36 touch IRQ.

Set the Bus Servo Adapter's jumper for an external UART controller (not its own USB port).
The adapter handles the half-duplex direction switching, so the ESP32 just uses normal TX/RX.

---

## Servo setup (one-time)

1. **Give each servo its own ID.** New STS3215s all ship as ID 1, so connect them **one at a time**:
   leave the pan servo as **ID 1**, and set the tilt servo to **ID 2**. Use Feetech's FD software,
   or the Bus Servo Adapter's USB mode, or a small ESP32 sketch. Only then daisy-chain them.
2. **Centre:** with the head assembled at its rest pose, write the middle-position calibration
   so that **2048 = straight ahead / level** on both servos.
3. **Angle limits in the servo's EEPROM**, so they hold even if the software misbehaves:
   - **Pan:** about ±150° from centre (the camera cable sets the real limit; see Mechanics).
   - **Tilt:** about −30° to +45°, to suit the yoke.
4. **Protection:** set the protection current, overload torque and temperature limits, and enable
   the overload behaviour that drops torque instead of fighting.
5. **Speed and acceleration:** set sensible defaults. The ESP32 overrides them per move.

Library: Feetech's **SCServo** (`SMS_STS` class) for Arduino-ESP32, at 1 Mbps.

---

## Motion control

- The Jetson sends **targets** (pan/tilt angle plus a speed hint) at up to 30–50 Hz.
- The ESP32 clamps them to the soft limits, smooths them (a velocity and acceleration
  limit, so tracking looks natural rather than snappy), and writes goal position, speed
  and acceleration to both servos in one **SYNC WRITE** packet.
- The ESP32 reads back **actual position, load, voltage and temperature** at about 50 Hz,
  timestamps them, and reports them to the Jetson. The Jetson uses the timestamp to work out
  where the camera was pointing when each video frame was taken. This is what keeps tracking
  stable while the head is moving.
- **Watchdog:**
  - no message from the Jetson for **1 s** → hold position;
  - for **10 s** → ease back to the rest pose, then release torque (quiet when idle);
  - over-temperature or overload reported by a servo → stop and report.
- **Power-up:** bus servos don't jump on power-up. The ESP32 reads where they are and
  starts from there.

---

## Jetson ↔ ESP32 protocol (draft)

- **Link:** USB serial (`/dev/ttyUSB0` on the Jetson, CH340C), **921600 baud**.
- **Framing:** binary messages, **COBS**-framed with a **CRC-16**, each with a type byte and a
  sequence number. Unknown types are ignored, so either side can be updated first.

| Direction | Message | Contents |
|---|---|---|
| Jetson → ESP32 | `HEARTBEAT` | sequence, Jetson time |
| Jetson → ESP32 | `LOOK` | pan°, tilt°, max speed, mode (track / glance / rest) |
| Jetson → ESP32 | `EYES` | expression (idle, listening, thinking, speaking, happy, sleepy, …), gaze x/y |
| Jetson → ESP32 | `TEXT` | short message, style, how long to show it |
| Jetson → ESP32 | `CONFIG` | soft limits, smoothing, display brightness, etc. |
| ESP32 → Jetson | `STATUS` | actual pan/tilt, load, voltage, temperature, ESP32 time, flags |
| ESP32 → Jetson | `EVENT` | touch, button, watchdog/fault, boot |

The message set stays small: no video or vector data crosses this link.

---

## The head's display

The 4" screen is the head's face, not a monitor:
- **Animated robot eyes:** blinking, expressions, and a **gaze that leads the motion**.
  The pupils glance toward a face before the head turns, which reads as very lifelike.
- **Short text messages:** a name when someone is recognised, reminders, and so on.
- **Status:** link to the Jetson, servo temperatures, warnings. Touch can wake it or
  show this page.

The ESP32 has no PSRAM, so it can't hold a full 320×480 16-bit frame (307 KB). Draw the eyes
into **sprites** with TFT_eSPI, either 8-bit or 4-bit palette, covering only the eye region,
and push only what changed. This gives smooth animation without flicker.

The live camera view, with boxes, names and contours, goes on the Jetson's **dashboard web page**.

---

## Vision pipeline (Jetson)

- **Capture:** C920X via V4L2, MJPEG at 720p30 (1080p if needed). Once mounted, **lock focus and
  exposure** with `v4l2-ctl`, because autofocus hunting looks bad while tracking.
- **Face detection:** SCRFD or a YOLOv8-face model under **TensorRT**.
- **Recognition:** **ArcFace** embeddings (InsightFace), matched against a local gallery.
  **Enrolment** is a short guided capture of several angles. Embeddings stay on the Jetson, and
  a "forget me" command deletes a person.
- **Tracking:** keep a track ID per face. Turn the face's position in the image into pan/tilt
  targets using the camera's field of view and the head pose *at the time of that frame*
  (from `STATUS`). Add a deadband in the middle of the image so the head isn't constantly
  making tiny corrections.
- **Behaviour (piper-assistant):** who to look at (speaker, newcomer, recognised person),
  idle glances, a rest pose, and eye expressions that match the conversation.

---

## Mechanics

- **Pan:** the lazy Susan carries all of the head's weight. The pan servo only *turns* it,
  through a coupling at the centre, so there's no sideways load on the servo shaft.
- **Tilt:** a yoke on the turntable. The tilt servo drives one side through its 25T horn;
  an idler bearing supports the other side on the same axis. Keep the camera's centre of mass
  close to the tilt axis so the servo isn't holding a constant load.
- **Cables:** the camera's USB cable runs through the centre with a **service loop** sized for
  ±150° of pan. The soft limits keep it from winding further. Avoid slip rings for USB 2.0.
- **Noise:** the STS3215s are quiet when holding still. If movement noise still reaches the
  speakerphone, have piper-assistant pause or flag speech recognition while the head moves.

---

## Repository layout

```text
firmware/head/   PlatformIO project for the E32R40T head controller (ESP32)
jetson/          Jetson-side Python: vision, tracking, head link, dashboard
hardware/        CAD for printed parts, wiring diagrams
docs/            design notes, protocol spec
tools/           servo ID / calibration helpers, bench tests
```

Face images and embeddings are never committed (`jetson/data/` is git-ignored), because this
repository is public.

---

## Roadmap

1. **Bench:** ESP32 + Bus Servo Adapter + one servo. Set IDs, read position, move by serial command.
2. **Head v1:** printed yoke and housing, both servos, limits, watchdog, `STATUS` reporting.
3. **Eyes:** sprite-based eye animation and the `EYES` / `TEXT` messages.
4. **Vision:** detection and tracking on the Jetson closing the loop through `LOOK`.
5. **Recognition:** enrolment, gallery, names on the display and in the assistant.
6. **Dashboard:** camera view with overlays on the Jetson's web page.

## Open questions

- Final pan range, which depends on the cable routing.
- Enclosure layout and how the display is mounted relative to the camera.
