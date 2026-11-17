# Wiring

The current build (base v4): a **12 V supply** feeds two things, the **Jetson Orin NX** on its
reComputer J401 carrier in the tub and the two **STS3215 bus servos** through a Waveshare Bus Servo
Adapter (A) on the lid. Everything else (camera, head XIAO + OLED mouth, servo adapter logic,
speakerphone) runs on 5 V from the Jetson's USB ports. There's no buck converter, perfboard or
stepper any more.

> The earlier Level 2 design (19 V brick, TMC2209 stepper, perfboard, panel fuse, three-display
> head) is in this file's git history and in `hardware/kicad/`. The top-level README still
> describes parts of it.

## Overview

```text
 12 V supply ── DC jack (tub back wall) ── SPLIT BLOCK (plug zone, behind the Orin)
                                            ├─ + / − ──────────────────────────────► Orin carrier DC in (9–19 V)
                                            └─ + ── inline FUSE (5×20, 4 A) ──┐
                                               − ─────────────────────────────┴──► servo adapter DC screw terminal
                                                                                     └─ bus ─► PAN servo ─► TILT servo
        split block − = the COMMON GROUND (jack −, Orin −, servo adapter −); never fused or switched

 POWER BUTTON (momentary) ── Orin carrier button header: PWR BTN (pin 1) + GND (pin 2)

 USB to the Orin (data + 5 V):
   • servo adapter (USB-C)       - lid, straight down the lid slot
   • head XIAO ESP32-S3 (USB-C)  - mouth OLED; down the hub, out its window, down the lid slot
   • C920 camera                 - down the hub, out its window, down the lid slot
   • speakerphone
```

---

## 1. Power

### Supply

- **12 V, at least 5 A** (60 W). The Orin NX takes up to about 25 W (2.1 A at 12 V). The two
  servos draw well under 1 A each when moving and about 2.7 A each when stalled. 12 V is the
  voltage both loads accept: the carrier runs on 9–19 V, but the 12 V STS3215s must not see
  19 V, so the Jetson's old 19 V brick can't be used.
- Check the plug sizes: the supply's plug fits the tub's DC jack, and the lead from the split block
  to the carrier needs a plug that fits the carrier's DC jack.

### Connections

| From | To | Wire | Notes |
| --- | --- | --- | --- |
| DC jack + / − | split block + / − | 16–18 AWG | the block sits in the plug zone (the tub's insert bosses at the back left) |
| Split block + / − | Orin carrier DC jack | 18 AWG, DC plug pigtail | always on: the power button controls the Jetson, not this feed |
| Split block + | inline fuse holder (**4 A fast-blow**, 5 × 20 mm) | 16 AWG (the holder's own leads) | lies along the plug zone's back wall; change the fuse with the lid off |
| Fuse holder | servo adapter DC terminal **+** | 16 AWG | up through the lid slot |
| Split block − | servo adapter DC terminal **−** | 16 AWG | |
| Servo adapter | pan servo → tilt servo | the servos' own 3-pin bus leads | the tilt servo daisy-chains off the pan servo's second socket, up the hub |

- **Fuse:** start at 4 A. Two stalled servos (about 5.4 A) blow it, normal moves don't. If it
  blows on fast moves (the kit's fuses are all fast-blow), go to 5 A, no higher.
- **Servo adapter:** power goes in on the **DC screw terminal**. Its barrel jack stays on the
  board but unused; never feed both. Its USB-C is data only (and its own logic).
- **Polarity:** check + and − at the adapter's terminal with a meter before the servos are plugged
  in. Reversed 12 V kills the adapter and the servos.
- **Servo IDs:** both servos share one bus, so each needs its own ID (set one at a time with only
  that servo plugged in).

### Power button

The carrier's **12-pin button header** (read the designator on the board's silkscreen):

| Pin | Label | Pin | Label |
| --- | --- | --- | --- |
| 1 | **PWR BTN** | 2 | **GND** |
| 3 | FC REC (force recovery) | 4 | GND |
| 5 | SYS RET (reset) | 6 | GND |
| 7 | AUTO ON | 8 | DIS |
| 9 | UART TXD | 10 | UART RXD |
| 11 | LED + | 12 | LED − |

- **The button:** the Geekworm T100 case's 19 mm momentary switch with an LED ring, in a 19.2 mm hole
  in the tub's **back wall**, above the port window on the 12 V jack's side, 34 mm up. Its body
  runs forward over the carrier's HDMI port; it must stay **under 38 mm** behind the wall
  (connector included), or it hits the Dupont plug on the button header.
- Its **power leads** (the "ON" pair, 9") go to **pins 1 and 2** of the 12-pin button header (on the
  carrier, just inside the back edge, between its DC jack and HDMI port; polarity doesn't matter).
  Its **LED leads** (7") go to the 40-pin header along the carrier's right edge: **3.3 V (pin 1)**
  and **GND (pin 6)**, exactly as on the Jetson Nano. The 3.3 V rail is only up while the
  Jetson runs, so the ring shows that it's on.
- Use a **momentary** (push-to-make) button across **pins 1 and 2**, not a latching rocker.
  The Jetson's power-button input expects a press: a short press powers it on (if it's off) or
  asks the OS to shut down cleanly. A rocker held closed on this pin looks like a long press,
  which can force the module off instead of letting it shut down cleanly.
- **Auto power-on:** out of the box the carrier boots as soon as 12 V arrives. To make it wait for
  the button, jumper **pins 7 and 8** (AUTO ON - DIS, "disable auto power-on"). Confirm this on the
  J401 schematic before relying on it.
- **Recovery (flashing):** jumper pin 3 to pin 4 while powering up, then remove the jumper.
- **If you want a hard rocker anyway:** put it in the 12 V feed **before** the split block, where it
  cuts everything. Only flip it off after `sudo shutdown now` has finished, or you risk corrupting
  the NVMe.

---

## 2. Head: XIAO ESP32-S3 ↔ the mouth OLED

The head's XIAO ESP32-S3 drives the **2.08" SH1122 256 × 64 OLED mouth** over SPI. Its USB-C is
both its power and its serial link to the Orin (it shows up as `303A:1001`).

| OLED pin | XIAO pin | GPIO |
| --- | --- | --- |
| GND | GND | – |
| VCC | **3V3** (never 5V) | – |
| SCL (SPI clock) | D8 | 7 |
| SDA (SPI data) | D10 | 9 |
| RST | D1 | 2 |
| DC | D0 | 1 |
| CS | D5 | 6 |

- **Check the module's own pin labels:** these modules don't all use the same order.
- **Check VCC and GND before powering up.** A bridged or misplaced VCC/GND joint once stopped the
  XIAO from showing up on USB at all; the red charge LED still lit, so it looked powered.
- **Treat the panel gently:** the glass is thinnest where the ribbon leaves it. The first panel
  cracked there. Don't bend the ribbon sharply or press on that edge in its pocket.
- Free pins: D2 (GPIO 3, a strapping pin, keep it free), D3, D4, D6, D7, D9.
- **Flashing:** if the upload says "Wrong boot mode", hold **B**, tap **R**, release **B**, upload,
  then tap **R** to run. Bring-up test: `firmware/oled_test`.

---

## 3. Cable routes

- **Through the hub (turret → base):** the camera cable, the XIAO's USB cable and the tilt servo's
  bus lead. These are the only cables that cross the pan joint, and they cross it on the axis, so
  panning twists them a little instead of dragging them. Never route a cable through a hole away from the centre: the
  turret turns over the fixed plate and would shear it.
- **Fishing order:** with the hub out of the pillow block, feed each plug down the hub's bore and
  out of its window (the window's chamfers guide it). Fit the hub, then turn the head by hand until
  the window faces the open front of the pan servo's sleeve. The camera's cable goes with its
  JST plug unplugged at the C920 board; the XIAO's USB-C end goes to the XIAO.
- **Lid slot:** everything going down to the Orin, the hub cables and the servo adapter's USB, drops
  through the lid's slot into the plug zone.
- **Plug zone:** only 28 mm from the Orin's ports to the back wall. USB-A plugs angled 90° upward
  fit best; straight plugs barely fit with their bend.
