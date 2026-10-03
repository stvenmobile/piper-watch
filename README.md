# Piper-Watch

**Piper-Watch** is the eyes of [piper-assistant](https://github.com/stvenmobile/piper_assistant):
a desktop robot head that turns to look around, finds and follows
faces, and recognises the people it knows. The face is deliberately not a cartoon: a round
face with the camera lens in the middle, framed by a **glowing LED ring** that shows what Piper
is doing (listening, thinking, speaking) and who it is paying attention to.

All the thinking happens on an **NVIDIA Jetson Orin NX** in a separate enclosure. Piper-Watch
itself is a compact two-part unit: a **shallow cylindrical base** (power, an ESP32-S3 controller,
the pan servo) carrying a lazy Susan, and a **head** on a short neck that turns left and right.
There is deliberately **no tilt motor**: the head is fixed at a 15° upward angle by a swappable
wedge, which suits seated conversation. Anything richer than the ring - text, status, the
camera view - goes on the Jetson's dashboard web page.

> **Status:** design phase. The servos are on order; nothing is built yet.

---

## Goals and non-goals

**Goals**
- Smooth, quiet tracking of a person's face (pan), without stepping or buzzing while holding still.
- Simple and stable: one servo, no tilt joint, everything wired inside.
- Face detection and recognition running entirely locally on the Jetson.
- A calm, clearly-a-device presence: the light ring shows Piper's state and points toward the
  person it is attending to, so it reads as an assistant, not a camera that silently watches.
  No eyes or mouth to anthropomorphise (and Piper's voice comes from the speakerphone anyway).
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
 │  Vision: capture → face detection → recognition → tracking → pan target + ring state   │
 │  piper-assistant: speech in/out (Piper TTS), dialogue, events                          │
 │  Dashboard web page: camera view + boxes/names/contours (replaces the vector display)  │
 └──────────────┬───────────────────────────────────────────────┬─────────────────────────┘
                │ one USB 2.0 cable                             │ USB
                │                                               │
 ┌──────────────▼──────────── Piper-Watch ──────────────┐  ┌────▼─────────────────────┐
 │  FE1.1s USB 2.0 hub board (fed from the 5 V buck)    │  │ SP-200 speakerphone      │
 │   ├── Logitech C920X camera (stripped) - the "nose"  │  │ 4-mic array, hardware AEC│
 │   └── ESP32-S3 DevKitC-1 N16R8 (native USB)          │  │ placed away from the head│
 │          ├── GPIO 8 → level shifter → 24-LED ring    │  └──────────────────────────┘
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
| **ESP32-S3 DevKitC-1 N16R8** (16 MB flash, 8 MB octal PSRAM, native USB) | controller: pan motor, LED ring, link to the Jetson | have |
| **24-LED WS2812-type ring**: OD 65.6, ID 52.3, 3.2 mm with LEDs; through-hole pads 2× 5 V, 2× GND, DIN, DOUT | the face's light ring | have |
| **74AHCT125** (or a single-gate 74AHCT1G125) level shifter | ESP32 3.3 V data → 5 V ring | needed (~$1) |
| Translucent ring, printed (`ring_diffuser.scad`) in white or natural PLA/PETG | diffuser in front of the LEDs | print |
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
                               └── 5 V / 3 A buck ── FE1.1s hub (5V pads) ──┬── ESP32-S3 (native USB); 5 V → LED ring
                                                                            └── C920X camera
GND: all grounds meet at one star point at the brick input.
```

**Why this layout**
- **Isolation:** the ESP32-S3, LED ring and camera get their 5 V from their own regulator, never
  from the servo rail, so servo current spikes can't reset the ESP32 or glitch the camera. They
  also don't depend on the Jetson's USB ports for power.
- **Efficiency:** the biggest load (the servos) has no conversion losses at all. The 5 V buck
  only carries about 1 A.
- **One cable:** the hub merges the camera and the ESP32-S3 onto a single USB cable to the Jetson.

**USB hub: FE1.1s board**
- **Power:** wire the 5 V buck to the board's **5V/GND pads**. It runs self-powered, at
  500 mA per port (2 A total), which covers the ESP32-S3 (~0.1 A) and the camera (~0.5 A).
  The LED ring is wired to the buck directly, not through the hub.
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
| ESP32-S3 (5 V) | ~0.1 A | |
| LED ring (5 V), brightness capped at ~25% | ~0.05–0.25 A | ~1.4 A if driven full white (the firmware never does) |
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
| LED ring data | **GPIO 8** → 74AHCT125 (powered from 5 V) → ring **DIN** | 24-LED ring; DOUT unused |
| LED ring power | 5 V buck / GND | ring 5 V and GND pads (use both pairs) |
| Jetson link + flashing | native USB (the board's **"USB"** port, GPIO 19/20) | USB hub → Jetson, appears as `/dev/ttyACM0` |
| Status LED | on-board RGB (GPIO 48 on v1.0 boards, GPIO 38 on v1.1) | link / fault indication |

**Three wires to the head.** The ring needs only 5 V, GND and one data wire, running about
40-50 cm from the base up through the lazy Susan and the neck (plus the camera cable), so:
- **level-shift the data** to 5 V at the ESP32 end (74AHCT125): WS2812-type LEDs want a 5 V
  logic high, and 3.3 V straight down a long wire is unreliable;
- add a **330 Ω resistor** in series with the data line at the shifter output, and a
  **470-1000 µF** capacitor across 5 V/GND at the ring;
- twist the data wire with a ground wire.

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
| Jetson → ESP32 | `FACE` | state (idle, listening, thinking, speaking, sleeping, error, …), attention direction, colour/brightness |
| Jetson → ESP32 | `CONFIG` | soft limits, smoothing, ring brightness limit, etc. |
| ESP32 → Jetson | `STATUS` | actual pan, load, voltage, temperature, ESP32 time, flags |
| ESP32 → Jetson | `EVENT` | watchdog/fault, boot |

The message set stays small: no video or vector data crosses this link.

---

## The face

A round face (about 105 mm across - the smallest circle around the camera) with the camera lens
in the middle, framed by a glowing ring. The ring is a 24-LED WS2812-type ring behind a
translucent diffuser, and the ESP32-S3 animates it from a single state (`FACE` message):

| State | Ring |
|---|---|
| **Idle** | a steady, soft warm glow |
| **Listening** | slow "breathing" |
| **Thinking** | a short comet running around the ring |
| **Speaking** | a quick, slightly irregular pulse while Piper's TTS plays |
| **Attention** | a brighter arc pointing toward the person being tracked |
| **Sleeping** | a dim ember |
| **Error** | amber flashes |

Brightness is capped at about 25%: plenty behind the diffuser, easy on the 5 V supply, and a
soft warm-white ring also lights the person's face a little, which helps detection in a dim
room. (No red ring - that reads as HAL 9000.)

**Light path.** From the face inward: a 2 mm **diffuser ring** (printed in white or natural
filament, pressed in flush with the face) → a 3.5 mm **air gap** where each LED's light spreads
into its neighbours → the LEDs, facing forward. The ring sits in a pocket behind the gap, held
with a few dabs of hot glue. Its four power pads (15 mm apart) go at the **top** and the two data
pads at the **bottom**; single header pins soldered into the pads take Dupont plugs, which point
straight back above and below the camera (never at the sides, where the camera is right
behind the ring).
Three thin spokes cross the air gap to hold the centre of the face; they fall between LEDs.
The camera sits just behind the ring, its lens at the bottom of a flared opening (16 mm at
the lens, 31 mm at the face, so it doesn't clip the view). Everything else - text, status, the
live camera view with boxes and names - goes on the Jetson's **dashboard web page**.

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
  there is no motor: the camera's ±21° view around its fixed 15° tilt covers seated faces, and
  the Jetson can crop the 1080p frame to centre on it.
- **Behaviour (piper-assistant):** who to look at (speaker, newcomer, recognised person),
  idle glances, a rest pose, and ring states that match the conversation.

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
- **Head:** round, about 105 mm across and about 45 mm deep, in two parts:
  - **Front (the face):** carries everything: the flared lens opening in the middle, the LED ring
    and its diffuser around it, and the camera cradle behind.
  - **Back cover:** encloses the electronics and wiring and **screws onto the front** (M3 screws into
    heat-set inserts). Assembly and repair: mount the parts to the face, plug in, feed the wires
    down through the wedge and neck, screw on the back.
- **Cables:** the camera's USB cable plus the ring wiring (three 2 mm silicone hook-up wires:
  5 V, GND, data) run from the head down the neck, through the lazy
  Susan's 89 mm opening, into the base, with a **service loop** in the base for the ±150° of pan.
  Nothing is visible from outside. Avoid slip rings for USB 2.0.
- **Noise:** the STS3215 is quiet when holding still. If movement noise still reaches the
  speakerphone, have piper-assistant pause or flag speech recognition while the head moves.

---

## Repository layout

```text
firmware/head/   PlatformIO project for the ESP32-S3 controller (pan motor, LED ring, Jetson link)
jetson/          Jetson-side Python: vision, tracking, head link, dashboard
hardware/        CAD for printed parts, wiring diagrams
docs/            design notes, protocol spec
tools/           servo ID / calibration helpers, bench tests
```

Face images and embeddings are never committed (`jetson/data/` is git-ignored), because this
repository is public.

---

## Roadmap

1. **Bench:** ESP32-S3 + pan motor driver, plus the LED ring through its level shifter. Move by
   serial command; bring up the ring states.
2. **Head v1:** printed base, turntable plate, neck, wedge and two-part head; pan servo, limits,
   watchdog, `STATUS` reporting.
3. **Face:** ring states, the attention arc that follows the tracked person, and the `FACE` message.
4. **Vision:** detection and tracking on the Jetson closing the loop through `LOOK`.
5. **Recognition:** enrolment, gallery, names on the dashboard and in the assistant.
6. **Dashboard:** camera view with overlays on the Jetson's web page.

## Open questions

- Final pan range, which depends on the cable routing.
- Diffuser: filament and thickness for an even glow (print a test ring first).
- Pan drive: central direct drive or offset belt (affects cable routing through the base).
