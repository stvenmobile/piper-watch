# Piper-Watch

**Piper-Watch** is the eyes of [piper-assistant](https://github.com/stvenmobile/piper_assistant):
a desktop robot head that turns to look around, finds and follows
faces, and recognises the people it knows. The head has a face in three sections: two small
OLED **eyes** on top, the camera as the **nose** in the middle, and a small OLED **mouth** below.

All the thinking happens on an **NVIDIA Jetson Orin NX** in a separate enclosure. Piper-Watch
itself is a compact two-part unit: a **shallow cylindrical base** (power, an ESP32-S3 controller,
the pan servo) carrying a lazy Susan, and a **head** on a short neck that turns left and right.
There is deliberately **no tilt motor**: the head is fixed at a 15° upward angle by a swappable
wedge, which suits seated conversation. Anything richer
than eyes - text, status, the camera view - goes on the Jetson's dashboard web page.

> **Status:** design phase. The servos are on order; nothing is built yet.

---

## Goals and non-goals

**Goals**
- Smooth, quiet tracking of a person's face (pan), without stepping or buzzing while holding still.
- Simple and stable: one servo, no tilt joint, everything wired inside.
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
 │  Vision: capture → face detection → recognition → tracking → pan target + eye gaze     │
 │  piper-assistant: speech in/out (Piper TTS), dialogue, events                          │
 │  Dashboard web page: camera view + boxes/names/contours (replaces the vector display)  │
 └──────────────┬───────────────────────────────────────────────┬─────────────────────────┘
                │ one USB 2.0 cable                             │ USB
                │                                               │
 ┌──────────────▼──────────── Piper-Watch ──────────────┐  ┌────▼─────────────────────┐
 │  FE1.1s USB 2.0 hub board (fed from the 5 V buck)    │  │ SP-200 speakerphone      │
 │   ├── Logitech C920X camera (stripped) - the "nose"  │  │ 4-mic array, hardware AEC│
 │   └── ESP32-S3 DevKitC-1 N16R8 (native USB)          │  │ placed away from the head│
 │          ├── I2C0 → both eyes, I2C1 → mouth          │  └──────────────────────────┘
 │          │ UART1 @ 1 Mbps (half-duplex servo bus)    │
 │          ▼                                           │
 │  Waveshare Bus Servo Adapter (A) ── 12 V ──┐         │
 │          │ servo bus (daisy-chained)        │         │
 │          └── STS3215  PAN  (ID 1)          │         │
 │                                            │         │
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
| 2× **1.3" SH1106 OLED**, 128×64, I2C (4-pin), white (Hosyond): board 35.5 × 33.7, holes 30.3 × 28.0 | the eyes | ordered |
| **0.91" SSD1306 OLED**, 128×32, I2C (4-pin) | the mouth | have |
| *(option)* **2.08" SH1122 OLED**, 256×64, 16 grey levels, SPI; module 75.5 × 19.35 mm, active 51.18 × 12.78 mm | a bigger mouth later | ordered |
| **Feetech STS3215, 12 V / 30 kg·cm** serial bus servo: 360° magnetic encoder (4096 steps, 0.088°), position/load/voltage/temperature feedback, 1 Mbps half-duplex TTL bus (2 ordered; the second is a spare) | pan | **ordered** |
| Waveshare **Bus Servo Adapter (A)**: 9–12.6 V input, powers the servo bus and converts it to plain TX/RX for the ESP32 | servo bus interface | needed |
| Logitech **C920X**, housing partly stripped (94 × 24.1 × 29 mm) | camera - the head's "nose" | have |
| **SP-200** USB speakerphone (5 V): 4-mic array, hardware echo cancellation, USB Audio Class | microphone/speaker, connected to the Jetson | have |
| 5.5" (140 mm) aluminium lazy Susan bearing | pan base, carries all vertical load | have / needed |
| 3D-printed base, turntable plate, hollow neck, 15° wedge, and a two-part head (face front + screw-on back) | enclosure | camera pod fit-tested |
| Silicone hook-up wire, ~2 mm, very flexible (6 colours) | display wiring through the neck | have |
| **12 V / 5 A** power brick, inline 5 A fuse, 1000 µF / 25 V capacitor | head power | needed |
| **5 V / 3 A** buck converter | USB hub power | needed |
| **FE1.1s 4-port USB 2.0 hub board** (~$5–7) with external 5V/GND pads and a cuttable "Disable USB Power" jumper (e.g. [Circuitneato](https://circuitneato.com/how-to-use-the-fe1-1s-usb-hub/), or generic "FE1.1s hub module" listings) | one cable to the Jetson | needed |

---

## Power

The servos are the 12 V version, so **the servo bus runs directly from the 12 V brick**
through the Bus Servo Adapter, with no converter in that path. Only the 5 V USB side
needs a buck converter.

```text
12 V / 5 A brick ── 5 A fuse ──┬── 1000 µF ── Bus Servo Adapter (A) ── STS3215 pan servo
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
| STS3215 at 12 V, holding | ~0.1 A | |
| STS3215 at 12 V, moving | ~0.3–0.8 A | ~3 A if it stalls |
| ESP32-S3 + three OLEDs (5 V) | ~0.2 A | |
| C920X camera (5 V) | ~0.4 A | ~0.5 A |
| **12 V input total** | **~0.4–1.2 A** | **~3.5 A** |

Normal tracking stays well inside 5 A, and even a full stall of the single servo (jammed, or
pushing against a hard stop) stays under it. Protection:
- Set each servo's **protection current and overload limits** in its EEPROM (see Servo setup),
  so a stall is cut back long before it threatens the brick.
- The **5 A fuse** protects the wiring if something does go wrong.

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
| Eyes SDA / SCL | **GPIO 8 / GPIO 9** (I2C0) | both SH1106 eyes: left at **0x3C**, right at **0x3D** (move the right module's address resistor) |
| Mouth SDA / SCL | **GPIO 10 / GPIO 11** (I2C1) | 0.91" SSD1306 mouth at 0x3C |
| Display power | 3V3 / GND | all three OLEDs (~20 mA each) |
| Jetson link + flashing | native USB (the board's **"USB"** port, GPIO 19/20) | USB hub → Jetson, appears as `/dev/ttyACM0` |
| Status LED | on-board RGB (GPIO 48 on v1.0 boards, GPIO 38 on v1.1) | link / fault indication |

**Two I2C buses, six wires.** The eyes share I2C0: SH1106 modules default to 0x3C, so the right
eye's address-select resistor (marked like 0x78 / 0x7A on the back) is moved to make it 0x3D. The
mouth has I2C1 to itself. (If the eye modules lack that resistor, the eyes get a bus each and the
mouth moves to a third, software I2C bus on two spare GPIOs.) The display wires run about 40-50 cm,
from the base up through the lazy Susan and the neck into the head - six thin wires (3.3 V, GND,
two SDA/SCL pairs) plus the camera cable - so:
- run both buses at **400 kHz** (try 1 MHz once it works);
- twist each data wire with a ground wire, or use a thin multi-core cable;
- add **2.2-4.7 kΩ pull-ups** to 3.3 V at the ESP32 end (the modules' own pull-ups are weak for a
  long run).

Set the Bus Servo Adapter's jumper for an external UART controller (not its own USB port).
The adapter handles the half-duplex direction switching, so the ESP32 just uses normal TX/RX.

---

## Servo setup (one-time)

1. **ID:** the pan servo stays at the factory **ID 1** (the spare can be set to ID 2 if it is ever
   added). Use Feetech's FD software, the Bus Servo Adapter's USB mode, or a small ESP32 sketch.
2. **Zero before assembly, then centre.** Before fitting a horn or coupling, power each servo and
   command it to **2048 (mid position)**. Only then attach the turntable coupling with the head
   pointing **straight ahead**. That way the mechanism's centre is the servo's
   centre and nothing is under strain at rest. Afterwards, fine-tune with the middle-position
   calibration so that **2048 = straight ahead** exactly. The bench firmware has a
   `center` command for this.
3. **Angle limits in the servo's EEPROM**, so they hold even if the software misbehaves:
   - **Pan:** about ±150° from centre (the camera cable sets the real limit; see Mechanics).
4. **Protection:** set the protection current, overload torque and temperature limits, and enable
   the overload behaviour that drops torque instead of fighting.
5. **Speed and acceleration:** set sensible defaults. The ESP32 overrides them per move.

Library: Feetech's **SCServo** (`SMS_STS` class) for Arduino-ESP32, at 1 Mbps.

---

## Motion control

- The Jetson sends **targets** (pan angle plus a speed hint) at up to 30–50 Hz.
- The ESP32 clamps them to the soft limits, smooths them (a velocity and acceleration
  limit, so tracking looks natural rather than snappy), and writes goal position, speed
  and acceleration to the servo.
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
| Jetson → ESP32 | `LOOK` | pan°, max speed, mode (track / glance / rest) |
| Jetson → ESP32 | `FACE` | expression (idle, listening, thinking, speaking, happy, surprised, sleepy, …), gaze x/y, optional speech level for the mouth |
| Jetson → ESP32 | `CONFIG` | soft limits, smoothing, eye brightness, etc. |
| ESP32 → Jetson | `STATUS` | actual pan, load, voltage, temperature, ESP32 time, flags |
| ESP32 → Jetson | `EVENT` | watchdog/fault, boot |

The message set stays small: no video or vector data crosses this link.

---

## The face

Three OLEDs make a face in three sections:

| Section | Part | Shows |
|---|---|---|
| **Eyes** (top) | 2× 1.3" SH1106, 128×64 | eyes and pupils, blinking, expressions |
| **Nose** (middle) | the C920X camera | - (it's the camera) |
| **Mouth** (bottom) | 0.91" SSD1306, 128×32 (the 2.08" SH1122 is a drop-in option later) | smile, neutral, "o", and **talking** animation while Piper speaks |

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

Each eye is a 1 KB frame and the mouth 512 bytes, over I2C (about 10-25 ms per frame), so
animation runs smoothly at 20-30 fps.

**Mounting - no screws.** The eyes sit glass-forward behind their windows on four **stepped
pillars** on the back of the face plate: the board rests on a small standoff (so the glass sits just
clear of the face) and a pin through each mounting hole sticks out for a **dab of hot glue**. The
0.91" mouth has no mounting holes, so it drops into a **shallow pocket**, also held with hot glue.
Glue holds well and peels off if a screen ever needs replacing. Everything else - text, status, the live camera view with
boxes and names - goes on the Jetson's **dashboard web page**.

---

## Vision pipeline (Jetson)

- **Capture:** C920X via V4L2, MJPEG at 720p30 (1080p if needed). Once mounted, **lock focus and
  exposure** with `v4l2-ctl`, because autofocus hunting looks bad while tracking.
- **Face detection:** SCRFD or a YOLOv8-face model under **TensorRT**.
- **Recognition:** **ArcFace** embeddings (InsightFace), matched against a local gallery.
  **Enrolment** is a short guided capture of several angles. Embeddings stay on the Jetson, and
  a "forget me" command deletes a person.
- **Tracking:** keep a track ID per face. Turn the face's **horizontal** position into a pan
  target using the camera's field of view and the head pose *at the time of that frame* (from
  `STATUS`), with a deadband so the head isn't constantly making tiny corrections. **Vertically**
  there is no motor: the camera's ±21° view around its fixed 15° tilt covers seated faces, the
  eyes' pupils glance up or down toward the face, and the Jetson can crop the 1080p frame to
  centre on it.
- **Behaviour (piper-assistant):** who to look at (speaker, newcomer, recognised person),
  idle glances, a rest pose, and eye expressions that match the conversation.

---

## Mechanics

Pan only - no tilt motor. Bottom to top:

- **Base:** a shallow cylinder about 146 mm across and 8 cm tall, just larger than the lazy Susan.
  It holds the ESP32-S3, Bus Servo Adapter, 5 V buck and USB hub, with the pan servo in the middle
  and the power input and USB cable at the back. Its top has the raised plinth (outer ring only)
  with M5 heat-set inserts.
- **Pan:** the lazy Susan carries all the weight above it. The pan servo only *turns* the
  turntable plate (on the inner ring) through a coupling at the centre, so there's no sideways
  load on the servo shaft. Soft limits about ±150°.
- **Neck:** a short hollow, chamfered square column (about 40 × 40 mm outside, **28 × 28 mm inside**)
  on the turntable plate. Every wire to the head runs inside it.
- **Wedge:** a small printed block between neck and head, hollow for the wires, that sets the
  head's fixed **15° upward tilt** for seated conversation. To change the angle, print another
  wedge (10°, 20°, ...) and swap it - two or three screws. There's no hinge, so nothing can creep.
- **Head:** about 100 × 100 mm, 40 mm deep, faceted (chamfered edges), in two parts:
  - **Front (the face):** carries everything. Two **eye windows** on top, a small **round "nose"
    opening** for the camera lens in the middle (about 16 mm, chamfered inside so it doesn't clip
    the camera's view), and the **mouth window** below. The OLEDs and the camera mount to its back.
  - **Back cover:** encloses the electronics and wiring and **screws onto the front** (M3 screws into
    heat-set inserts). Assembly and repair: mount the parts to the face, plug in, feed the wires
    down through the wedge and neck, screw on the back.
- **Cables:** the camera's USB cable plus the display wiring (six 2 mm silicone hook-up wires:
  3.3 V, GND, eyes SDA/SCL, mouth SDA/SCL) run from the head down the neck, through the lazy
  Susan's 89 mm opening, into the base, with a **service loop** in the base for the ±150° of pan.
  Nothing is visible from outside. Avoid slip rings for USB 2.0.
- **Noise:** the STS3215 is quiet when holding still. If movement noise still reaches the
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
2. **Head v1:** printed base, turntable plate, neck, wedge and two-part head; pan servo, limits,
   watchdog, `STATUS` reporting.
3. **Face:** expressions, blinking, gaze that leads the motion, a talking mouth, and the `FACE` message.
4. **Vision:** detection and tracking on the Jetson closing the loop through `LOOK`.
5. **Recognition:** enrolment, gallery, names on the dashboard and in the assistant.
6. **Dashboard:** camera view with overlays on the Jetson's web page.

## Open questions

- Final pan range, which depends on the cable routing.
- Face layout: eye spacing and window sizes relative to the camera nose and the mouth
  (needs caliper measurements of the OLED boards and their active areas).
- Eye bus: confirm the new eye modules have the address-select resistor (then both share I2C0).
- Pan drive: central direct drive or offset belt (affects cable routing through the base).
