# Wiring

Two boards carry Piper-Watch's wiring: the **perfboard** on Level 2's floor (stepper driver and
power) and the **XIAO ESP32-S3** in the head (the three displays). Everything talks to the Jetson
over USB; no Wi-Fi or Bluetooth is used, so the XIAO's external antenna stays unplugged (the radio
is never turned on).

> The top-level README's electrical section describes the earlier servo design (USB hub, LED
> ring). This file is the current design.

## Overview

```text
 BACK PANEL / FLOOR (back-left)                       PERFBOARD (70 x 50, Level 2 floor)
 19 V ── jack ──► FLOOR SPLIT BLOCK (always on) ──┬──► spade leads ──────────────────────► Jetson DC in
                                                  └──► panel FUSE (3 A slow) ──► rocker SWITCH ──► J1 + ──► VM rail
                                                                                                     ├─ TMC2209 VM (+100 µF) ──► J3 ──► NEMA17
                                                                                                     └─ J6 19V/GND ──► LM2596 buck (floor) ──► J6 5V
        split block − = the COMMON GROUND (jack −, Jetson −, perfboard J1 −)

 USB to the Jetson (data, and power for the boards' logic):
   • head XIAO ESP32-S3   - eyes + mouth          (through the turntable's hollow)
   • C920 camera board    - original cable        (through the turntable's hollow)
   • base ESP32-S3        - stepper, Hall sensor  (stays in Level 2)
```

The 19 V is split by a screw terminal block screwed to Level 2's floor: one pair of spade leads goes to the Jetson; the other goes through the panel fuse and the switch (both on the back panel, right beside the block) to the perfboard's J1. The fuse and switch cover **only the head side**  (stepper and buck), and the fuse can be changed from outside. The Jetson's feed never passes through the perfboard or the switch, so switching the head off never pulls the Jetson's power; it's protected by the 19 V supply's own current limit.

All grounds are common. The system's **common ground** is the split block's − terminal: the jack's −, the Jetson's − and the perfboard's J1 − all land there. On the perfboard, one ground point (★) gathers the board's grounds and returns to the split block through J1 −: the buck's input and output, the TMC2209's motor and logic grounds, and the base ESP32's GND. The ground is never switched or fused.

---

## 1. Perfboard: stepper driver + power (Level 2 floor)

The perfboard carries the TMC2209 and the terminals; one switched, fused 19 V feed comes in on J1. The buck is the larger Seloky LM2596S (66 × 36, with voltmeter) on its own M3 bosses beside it, wired to J6. The perfboard sits on four M2.5 inserts (holes 66 × 46).

### Power

| From                   | To                                                               | Notes                                                                                                                                |
| ---------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Jack + / −             | floor split block + / −                                          | 16–20 AWG, spade terminals (M3.5 screws); the Jetson's spade leads land here too                                                     |
| Split block +          | panel fuse holder (6 × 30 mm, **3 A slow-blow**) → rocker switch | 20 AWG; block to the holder's **end** contact, its **side** contact to the switch, so the exposed end of an unscrewed cap isn't live |
| Switch                 | J1 + → perfboard **VM rail**                                     | 20 AWG                                                                                                                               |
| Split block −          | J1 − → the board's ground point (★)                              | 20 AWG; the split block's − is the **common ground**                                                                                 |
| VM rail                | TMC2209 **VM**                                                   | short, 20–22 AWG                                                                                                                     |
| VM rail ↔ board ground | **100 µF / 50 V** electrolytic (35 V is the minimum)             | right at the driver's VM/GND pins, polarity!                                                                                         |
| VM rail / board ground | J6 **19V / GND** → LM2596 **IN+ / IN−**                          |                                                                                                                                      |
| LM2596 **OUT+**        | J6 **5V** → perfboard **5 V rail** (Hall only)                   | **set to 5.0 V with a meter before connecting anything**; OUT− is the same as IN−                                                    |

### Layout (70 × 50 perfboard) and parts

Top view, back of the case at the top. Power and motor leads land on screw terminals (J1, J3, J6);
the low-current logic (J4 to the ESP32, J5 to the Hall sensor) plugs onto 2.54 mm pin headers with
multi-pin Dupont housings. Everything is along the back and left edges only (the front faces the
display; the right edge is 2.5 mm from the wall).

```text
 back of the case
     J1 19V in (switched, fused)       J3 motor
 ┌○──[ +   − ]────────────────────[2B 2A 1A 1B]──────○┐
 │[J6 19V]                                            │
 │[   GND]                                            │
 │[   5V ]           C1      ┌ VM GND 2B 2A 1A 1B VDD GND ┐
 │ J4 ▶● STEP                │          TMC2209           │
 │     ● DIR                 └ EN MS1 MS2 PDN UART CLK STEP DIR ┘
 │     ● EN
 │     ● HALL
 │     ● 3V3
 │     ● GND
 │ J5 ▶● 5V      R1 10k       ★ board ground point
 │     ● GND
 │     ● OUT                                          │
 └○───────────────────────────────────────────────────○┘
     front (display)          ▶ = pin 1 (mark it on the board and on the housing)
```

**Headers and Dupont housings (J4, J5):**

- Dupont housings aren't keyed: mark **pin 1** (STEP on J4, 5V on J5) on the board and on the
  housing (paint pen or a dot of nail polish), or glue a small plastic strip beside the header so
  the housing only fits one way. Reversed, J4 would tie STEP and DIR to GND and 3V3.
- A dab of hot glue on the housing's side stops it working loose and still peels off.
- Leave a little slack so a tug pulls on the bundle, not the pins.
- J1, J3 and J6 stay screw terminals: the 19 V current and a motor plug that could work loose with
  the driver powered (which can kill the TMC2209) don't belong on Dupont pins.

Connections not shown above (insulated wire on the underside):

- **Ground → the board's ground point (★):** J1 −, J6 GND, both TMC2209 GND pins, C1 −, J4 GND, J5 GND.
- **3V3** (from the ESP32 via J4): TMC2209 VDD, MS1, MS2 (1/16 microstepping), and R1's top end.
- **Signals:** J4 STEP/DIR/EN → TMC2209 STEP/DIR/EN; J5 OUT → J4 HALL, with R1 from that line to 3V3.
- **5 V:** J6 5V → J5 5V.
- **Motor:** TMC2209 2B/2A/1A/1B → J3 (straight up, same order).

| Ref | Part                                | Notes                                                             |
| --- | ----------------------------------- | ----------------------------------------------------------------- |
| J1  | 2-way 5.08 mm screw terminal        | + from the switch (switched, fused 19 V); − from the split block  |
| J3  | 4-way 5.08 mm screw terminal        | motor coils                                                       |
| J4  | 1 × 6 2.54 mm pin header            | to the base ESP32: STEP, DIR, EN, HALL, 3V3, GND (6-pin Dupont)   |
| J5  | 1 × 3 2.54 mm pin header            | Hall sensor: 5V, GND, OUT (3-pin Dupont)                          |
| J6  | 3-way 5.08 mm screw terminal        | to the buck: 19V (switched, fused), GND out; 5V back              |
| U1  | BTT TMC2209 on 2 × 8 female headers | so it can be swapped; check the pin labels against its silkscreen |
| F1  | 6 × 30 mm (3AG) **3 A slow-blow**   | in the **panel** holder on the back wall, not on the board        |
| C1  | 100 µF / 50 V electrolytic          | at U1's VM/GND                                                    |
| R1  | 10 kΩ                               | Hall OUT pull-up to 3V3                                           |

Use 20 AWG wire or solder-filled tracks for the 19 V and ground runs (J1, VM, J6 19V/GND); thin
wire is fine for the logic and the 5 V Hall feed.

### TMC2209 (BTT, STEP/DIR mode) ↔ base ESP32-S3

| TMC2209 pin                  | Goes to                   | Notes                                                  |
| ---------------------------- | ------------------------- | ------------------------------------------------------ |
| VM / GND (motor side)        | VM rail / board ground    |                                                        |
| VIO (VDD) / GND (logic side) | ESP32 **3V3** / ESP32 GND | logic at 3.3 V: no level shifting needed               |
| STEP                         | ESP32 **GPIO 4**          |                                                        |
| DIR                          | ESP32 **GPIO 5**          |                                                        |
| EN                           | ESP32 **GPIO 6**          | LOW = motor enabled                                    |
| MS1, MS2                     | VIO (both HIGH)           | **1/16 microstepping** (the firmware will assume this) |
| PDN/UART, CLK, INDEX, DIAG   | unconnected               | UART tuning can come later                             |
| 1A, 1B / 2A, 2B              | NEMA17 coil 1 / coil 2    | find the pairs with a meter (≈ 2–3 Ω across a coil)    |

**Current:** set Vref to about **0.7 V** (≈ 0.9 A RMS on the BTT board's formula) before connecting
the motor. Measure between the trim pot and GND with the driver powered and the motor unplugged.
Never plug or unplug the motor while VM is live.

### Homing sensor (A3144 Hall, on the motor bracket)

| A3144 pin (flat face toward you, left → right) | Goes to                                           |
| ---------------------------------------------- | ------------------------------------------------- |
| 1 VCC                                          | 5 V rail (the A3144 needs 4.5 V or more)          |
| 2 GND                                          | board ground                                      |
| 3 OUT                                          | ESP32 **GPIO 7**, with a **10 kΩ pull-up to 3V3** |

The output is open-collector, so the pull-up sets its high level. Pull it up to **3V3, never to
5 V**, which would push 5 V into the ESP32's pin.

### The base ESP32-S3

- It's powered by its USB cable from the Jetson. **Don't** also connect the buck's 5 V to its 5V
  pin: two 5 V sources would fight, and the buck could back-feed the Jetson's USB port.
- The **level shifter** planned for the LED ring isn't needed any more (the ring is retired).

---

## 2. Head: XIAO ESP32-S3 ↔ eyes and mouth

All three displays share one SPI bus (clock, data, DC, reset) and each has its own chip select.
Only the selected display listens, so sharing DC and reset is fine. The firmware resets all three
together at start-up.

### Pin map

| Signal                                                | XIAO pin | GPIO | Left eye (GC9A01) | Right eye (GC9A01) | Mouth (SH1122 OLED) |
| ----------------------------------------------------- | -------- | ---- | ----------------- | ------------------ | ------------------- |
| 3.3 V                                                 | 3V3      | –    | VCC               | VCC                | VCC                 |
| GND                                                   | GND      | –    | GND               | GND                | GND                 |
| SPI clock                                             | D8       | 7    | SCL               | SCL                | SCL (pin 3)         |
| SPI data                                              | D10      | 9    | SDA               | SDA                | SDA (pin 4)         |
| DC                                                    | D0       | 1    | DC                | DC                 | DC (pin 6)          |
| Reset                                                 | D1       | 2    | RST               | RST                | RST (pin 5)         |
| CS left eye                                           | D3       | 4    | CS                | –                  | –                   |
| CS right eye                                          | D4       | 5    | –                 | CS                 | –                   |
| CS mouth                                              | D5       | 6    | –                 | –                  | CS (pin 7)          |
| Eye backlight (only if the modules have a BL/BLK pin) | D6       | 43   | BL                | BL                 | –                   |

Free: D2 (GPIO 3), D7 (GPIO 44) and D9 (GPIO 8). GPIO 3 is an ESP32-S3 strapping pin, so it's
deliberately left unused. "Left" and "right" are as seen from the front.

### Notes

- **Power:** the displays run from the XIAO's **3V3** pin. Two eyes plus the OLED draw roughly
  150–250 mA, well within the XIAO's regulator, and everything stays at 3.3 V logic. The XIAO
  itself is powered over USB from the Jetson.
- **Wire:** thin flexible silicone wire, 26–28 AWG. Solder straight to the display pads, no
  headers: the eyes mount upside down, so their pads are at the top, just under the arch, and
  headers would crowd the camera.
- **Route:** from each display down the inside of the face to the floor, then to the XIAO beside
  the cable hole. Keep about 10 cm per eye and 8 cm for the mouth; a little slack lets you lift the
  face plate off. A dab of hot glue on the face's back keeps the bundle tidy.
- **SPI speed:** the GC9A01 runs happily at 40–80 MHz and the SH1122 at about 10 MHz. The firmware
  sets each device's speed, so they share the bus without trouble.
- **Check the labels:** confirm each module's pin labels on arrival. Some GC9A01 modules have a
  BL/BLK backlight pin; others tie the backlight on.
- **Image orientation:** the eyes are mounted upside down, so the firmware rotates their image 180°.

---

## Open questions

- **The 4.3" JC4827 display in Level 2's front** (it has its own ESP32-S3): either its own USB to
  the Jetson (data and power, a third cable, but it doesn't move), or Wi-Fi with power from the
  buck. If it goes on USB, the buck only feeds the Hall sensor, and that can come from the base
  ESP32's 5V pin instead, so the buck could be dropped.
