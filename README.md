# Piper-Watch

**Piper-Watch** is the eyes of [piper-assistant](https://github.com/stvenmobile/piper_assistant):
a desktop pan/tilt robot head that lets the assistant look around, find and follow
faces, and recognise the people it knows. The head has a face in three sections: two small
OLED **eyes** on top, the camera as the **nose** in the middle, and a wide OLED **mouth** below.

All the thinking happens on an **NVIDIA Jetson Orin NX** in a separate enclosure. Piper-Watch
itself is a compact two-part unit: a **shallow cylindrical base** (power, an ESP32-S3 controller,
the pan servo) carrying a lazy Susan, and a **head** on top that pans and tilts. Anything richer
than eyes - text, status, the camera view - goes on the Jetson's dashboard web page.

> **Status:** design phase. The servos are on order; nothing is built yet.

---

## Goals and non-goals

**Goals**
- Smooth, quiet pan/tilt tracking of a person's face, without stepping or buzzing while holding still.
- Face detection and recognition running entirely locally on the Jetson.
- A friendly physical presence: a face whose eyes look where the camera looks and whose mouth
  moves when Piper speaks.
- Compact: a footprint barely larger than the 140 mm lazy Susan, about 20-23 cm tall.
- One data cable and one power brick between the head and the rest of the system.

**Non-goals (for now)**
- A display on the unit. Text, status and the camera view with detection overlays live on
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
 ┌──────────────▼──────────── Piper-Watch ──────────────┐  ┌────▼─────────────────────┐
 │  FE1.1s USB 2.0 hub board (fed from the 5 V buck)    │  │ SP-200 speakerphone      │
 │   ├── Logitech C920X camera (stripped) - the "nose"  │  │ 4-mic array, hardware AEC│
 │   └── ESP32-S3 DevKitC-1 N16R8 (native USB)          │  │ placed away from the head│
 │          ├── I2C0 → left eye + mouth, I2C1 → right eye │  └────────────────────────┘
 │          │ UART1 @ 1 Mbps (half-duplex servo bus)    │
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
- **ESP32-S3:** real-time body. It decides *how to move there* smoothly and safely,
  reports where the head actually is, and animates the face.
- **Servos:** close their own position loop with a 12-bit magnetic encoder, and report
  position, load, voltage and temperature.

---

## Components

| Part | Role | Status |
|---|---|---|
| NVIDIA Jetson Orin NX (JetPack) | vision, recognition, assistant, dashboard | have |
| **ESP32-S3 DevKitC-1 N16R8** (16 MB flash, 8 MB octal PSRAM, native USB) | controller: servo bus, eyes, link to the Jetson | have |
| 2× **1.3" SH1106 OLED**, 128×64, I2C (4-pin) | the eyes | have |
| **2.23" SSD1305 OLED**, 128×32, white, I2C/SPI (set to I2C, address 0x3D) | the mouth | ordering |
| 2× **Feetech STS3215, 12 V / 30 kg·cm** serial bus servos: 360° magnetic encoder (4096 steps, 0.088°), position/load/voltage/temperature feedback, 1 Mbps half-duplex TTL bus | pan and tilt | **ordered** |
| Waveshare **Bus Servo Adapter (A)**: 9–12.6 V input, powers the servo bus and converts it to plain TX/RX for the ESP32 | servo bus interface | needed |
| Logitech **C920X**, housing partly stripped (94 × 24.1 × 29 mm) | camera - the head's "nose" | have |
| **SP-200** USB speakerphone (5 V): 4-mic array, hardware echo cancellation, USB Audio Class | microphone/speaker, connected to the Jetson | have |
| 5.5" (140 mm) aluminium lazy Susan bearing | pan base, carries all vertical load | have / needed |
| 608ZZ (servo side) and 6803-2RS (cable side) bearings, 3D-printed base, turret, cheeks and head | tilt axis, enclosure | 608 have, 6803 ordering; camera pod fit-tested |
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
                               └── 5 V / 3 A buck ── FE1.1s hub (5V pads) ──┬── ESP32-S3 (native USB) ── 3.3 V → OLED eyes
                                                                            └── C920X camera
GND: all grounds meet at one star point at the brick input.
```

**Why this layout**
- **Isolation:** the ESP32-S3, eyes and camera get their 5 V from their own regulator, never
  from the servo rail, so servo current spikes can't reset the ESP32 or glitch the camera. They
  also don't depend on the Jetson's USB ports for power.
- **Efficiency:** the biggest load (the servos) has no conversion losses at all. The 5 V buck
  only carries about 1 A.
- **One cable:** the hub merges the camera and the ESP32-S3 onto a single USB cable to the Jetson.

**USB hub: FE1.1s board**
- **Power:** wire the 5 V buck to the board's **5V/GND pads**. It runs self-powered, at
  500 mA per port (2 A total), which covers the ESP32-S3 with its three OLEDs (~0.2 A) and
  the camera (~0.5 A).
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
| ESP32-S3 + three OLEDs (5 V) | ~0.2 A | |
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

## Wiring and pins (ESP32-S3 DevKitC-1 N16R8)

Pins avoid the ones the N16R8 module and board use internally: GPIO 26-32 (flash),
33-37 (octal PSRAM), 19/20 (native USB), 43/44 (UART0, the board's "UART" port) and the
strapping pins 0, 3, 45, 46.

| Signal | ESP32-S3 pin | Goes to |
|---|---|---|
| Servo bus TX | **GPIO 17** (UART1 TX) | Bus Servo Adapter **RX** |
| Servo bus RX | **GPIO 18** (UART1 RX) | Bus Servo Adapter **TX** |
| Ground | GND | Bus Servo Adapter GND (do not connect its supply to the S3) |
| Left eye SDA / SCL | **GPIO 8 / GPIO 9** (I2C0) | left SH1106 OLED |
| Right eye SDA / SCL | **GPIO 10 / GPIO 11** (I2C1) | right SH1106 OLED |
| Mouth SDA / SCL | shares **I2C0** (GPIO 8 / 9) at address **0x3D** | SSD1305 OLED |
| Mouth reset | **GPIO 12** | SSD1305 RES (it stays blank unless reset is driven or tied high) |
| Display power | 3V3 / GND | all three OLEDs (~20-30 mA each) |
| Jetson link + flashing | native USB (the board's **"USB"** port, GPIO 19/20) | USB hub → Jetson, appears as `/dev/ttyACM0` |
| Status LED | on-board RGB (GPIO 48 on v1.0 boards, GPIO 38 on v1.1) | link / fault indication |

**The eyes get one I2C bus each.** SH1106 modules normally share address 0x3C, so two on one
bus would clash; two buses also let both eyes update at the same time. **The mouth shares the
left eye's bus at 0x3D**: on the SSD1305 board, move its jumpers/resistors from SPI to I2C and pull
its DC pin high to select 0x3D. The display wires run about 40-50 cm, from the base, through the
pan centre and the tilt pivot, so:
- run each bus at **400 kHz** (try 1 MHz once it works);
- twist each data wire with a ground wire, or use a thin multi-core cable;
- add **2.2-4.7 kΩ pull-ups** to 3.3 V at the ESP32 end (the modules' own pull-ups are weak for a
  long run).

Set the Bus Servo Adapter's jumper for an external UART controller (not its own USB port).
The adapter handles the half-duplex direction switching, so the ESP32 just uses normal TX/RX.

---

## Servo setup (one-time)

1. **Give each servo its own ID.** New STS3215s all ship as ID 1, so connect them **one at a time**:
   leave the pan servo as **ID 1**, and set the tilt servo to **ID 2**. Use Feetech's FD software,
   or the Bus Servo Adapter's USB mode, or a small ESP32 sketch. Only then daisy-chain them.
2. **Zero before assembly, then centre.** Before fitting a horn or coupling, power each servo and
   command it to **2048 (mid position)**. Only then attach the turntable coupling / camera pod with
   the head pointing **straight ahead and level**. That way the mechanism's centre is the servo's
   centre and nothing is under strain at rest. Afterwards, fine-tune with the middle-position
   calibration so that **2048 = straight ahead / level** exactly. The bench firmware has a
   `center` command for this.
3. **Angle limits in the servo's EEPROM**, so they hold even if the software misbehaves:
   - **Pan:** about ±150° from centre (the camera cable sets the real limit; see Mechanics).
   - **Tilt:** **±30°** (the mechanism clears ±40°, so the limit can be widened without reprinting).
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
- **Don't force the head while it's powered.** The STS3215 has no slip clutch: twisting a head
  that is holding position by hand fights the motor and can strip its gears. Two defences:
  - the servo-side **overload and current limits** (Servo setup, step 4) drop torque instead of
    fighting;
  - **torque is released when idle** (watchdog above). To move the head by hand on purpose, release
    torque first (a command from the Jetson or the dashboard), and turn it gently.

---

## Jetson ↔ ESP32 protocol (draft)

- **Link:** the ESP32-S3's native USB serial (`/dev/ttyACM0` on the Jetson). Native USB ignores
  the baud setting and runs at full USB speed.
- **Framing:** binary messages, **COBS**-framed with a **CRC-16**, each with a type byte and a
  sequence number. Unknown types are ignored, so either side can be updated first.

| Direction | Message | Contents |
|---|---|---|
| Jetson → ESP32 | `HEARTBEAT` | sequence, Jetson time |
| Jetson → ESP32 | `LOOK` | pan°, tilt°, max speed, mode (track / glance / rest) |
| Jetson → ESP32 | `FACE` | expression (idle, listening, thinking, speaking, happy, surprised, sleepy, …), gaze x/y, optional speech level for the mouth |
| Jetson → ESP32 | `CONFIG` | soft limits, smoothing, eye brightness, etc. |
| ESP32 → Jetson | `STATUS` | actual pan/tilt, load, voltage, temperature, ESP32 time, flags |
| ESP32 → Jetson | `EVENT` | watchdog/fault, boot |

The message set stays small: no video or vector data crosses this link.

---

## The face

Three OLEDs make a face in three sections:

| Section | Part | Shows |
|---|---|---|
| **Eyes** (top) | 2× 1.3" SH1106, 128×64 | eyes and pupils, blinking, expressions |
| **Nose** (middle) | the C920X camera | - (it's the camera) |
| **Mouth** (bottom) | 2.23" SSD1305, 128×32 | smile, neutral, "o", and **talking** animation while Piper speaks |

The ESP32-S3 animates them from a single expression state:
- **Expressions:** idle, listening, thinking, speaking, happy, surprised, sleepy, ... (`FACE` message).
  Eyes and mouth change together, so one message sets the whole face.
- **Talking:** while Piper's TTS is playing, the Jetson sends `FACE speaking` (optionally with the
  speech's loudness envelope) and the mouth moves with it.
- **Blinking** at natural, slightly random intervals.
- **A gaze that leads the motion:** the pupils glance toward a face just before the head turns,
  which reads as very lifelike.
- **Sleep:** eyes close, the mouth goes flat and the screens dim when idle, which also protects the
  OLEDs from burn-in.

Each eye is a 1 KB frame and the mouth 512 bytes, sent over I2C (about 10-25 ms per frame), so
animation runs smoothly at 20-30 fps. Everything else - text, status, the live camera view with
boxes and names - goes on the Jetson's **dashboard web page**.

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
- **Base:** a shallow cylinder about 15 cm across and 8 cm tall, a little larger than the
  lazy Susan. It holds the ESP32-S3, Bus Servo Adapter, 5 V buck and USB hub, with the pan servo
  in the middle and the power input and USB cable at the back.
- **Head:** the camera pod grown into a face, about 95-100 mm wide × 95-100 mm tall × 30 mm deep,
  in three sections: eye windows on top, the camera (nose) in the middle, the mouth window below.
  Built as a **front face plate** with the three windows plus a **back shell** holding the camera
  cradle and display mounts, screwed together. The tilt axis runs through the camera, so the view
  stays steady when the head nods and the weight above and below the axis roughly balances.
- **Tilt:** a turret on the turntable with two cheeks; the head pivots between them on
  **a bearing in each cheek**, so the bearings carry the pod and the servo only turns it:
  - **Servo side: 608ZZ** (8 × 22 × 7). The pod's stub axle runs in the 608, and the STS3215 drives
    it through a **misalignment-tolerant coupling** (pins in slots), never rigidly - a rigid joint
    plus the servo's own bearings would over-constrain the axis and bind.
  - **Cable side: 6803-2RS** thin-section (17 × 26 × 5). The head's axle is a 17 mm tube the camera's
    USB-A plug passes straight through, so the camera cable and the eye wires thread through the
    pivot with no slot.
  - **Range:** soft limits **±30°** (the head rests a little above level, about +10-15°, to meet a
    seated person's eyes); the mechanism physically clears **±40°**.
  - Keep the camera's centre of mass on the tilt axis so the servo isn't holding a constant load.
  - Bearing seats are press fits; a small seat coupon sets the exact bore for this printer.
- **Cables:** the camera's USB cable runs through the centre with a **service loop** sized for
  ±150° of pan. The soft limits keep it from winding further. Avoid slip rings for USB 2.0.
- **Noise:** the STS3215s are quiet when holding still. If movement noise still reaches the
  speakerphone, have piper-assistant pause or flag speech recognition while the head moves.

---

## Repository layout

```text
firmware/head/   PlatformIO project for the ESP32-S3 controller (servos, eyes, Jetson link)
jetson/          Jetson-side Python: vision, tracking, head link, dashboard
hardware/        CAD for printed parts, wiring diagrams
docs/            design notes, protocol spec
tools/           servo ID / calibration helpers, bench tests
```

Face images and embeddings are never committed (`jetson/data/` is git-ignored), because this
repository is public.

---

## Roadmap

1. **Bench:** ESP32-S3 + Bus Servo Adapter + one servo, plus the three OLEDs. Set IDs, read position,
   move by serial command; bring up both eyes and the mouth.
2. **Head v1:** printed base, turret, cheeks and head; both servos, limits, watchdog, `STATUS` reporting.
3. **Face:** expressions, blinking, gaze that leads the motion, a talking mouth, and the `FACE` message.
4. **Vision:** detection and tracking on the Jetson closing the loop through `LOOK`.
5. **Recognition:** enrolment, gallery, names on the dashboard and in the assistant.
6. **Dashboard:** camera view with overlays on the Jetson's web page.

## Open questions

- Final pan range, which depends on the cable routing.
- Face layout: eye spacing and window sizes relative to the camera nose and the mouth
  (needs caliper measurements of the OLED boards and their active areas).
- Pan drive: central direct drive or offset belt (affects cable routing through the base).
