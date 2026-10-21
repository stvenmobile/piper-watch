# Lessons from the servo test stand

Things the test stand (`parts/servo_test_stand.scad`) taught us. Apply all of them when the real
base box, turret and head are designed from `concepts/servo_turret.scad`.

## Measurements

- **ServoCity 1" bore pillow block:** its four M4 holes are on a **32 × 32 mm square**, 22.6 mm from
  the centre. The vendor drawing showed 32 × 24, which is wrong.
- **Heat-set inserts:** **M3 bore 4.3 mm**. The 4.1 mm from the old coupon was too tight. This is now
  `insert_m3` in `params.scad`.
- **STS3215:** use the dimensions in `params.scad` (from Feetech's drawing):
  - 45.22 × 24.72 × 32 mm case, 19.2 mm disc on both faces (horn and idler);
  - shaft 10.11 mm from one end;
  - **no mounting holes**: the only threads are 4 × M3 in each disc, on a 14 mm circle. Hold the
    body in a cradle.
  - **the bottom face (the idler-disc face) is not flat**, measured from the far end (away from the
    shaft): a raised block 2 mm high, inset 2 mm from each side, from 4 to about 14.6 mm; then the
    **two 3-pin sockets**, from about 17.7 to 25 mm. The plugs go straight in, so **the cables leave
    through the bottom face**: whatever that face sits on needs an opening there and room below for
    the plugs and a cable bend (`bot_blk`, `bot_skt`).
- **Pan stack height:** with the pan servo seated on its rails, the hub's flange stood 2 mm above
  the bearing's flange (1 mm was designed). The hub tube is now 2 mm shorter (`hub_drop`), so the
  turntable rests on the bearing.

## Design rules

1. **Every insert in a fully closed round boss**, with at least 2 mm of wall all round, and at least
   0.8 mm on the side next to a servo. Inserts placed in thin walls broke out and became slots.
2. **Clear the full path of every part that moves or passes through**, not just its end. The hub's
   tube crossed the pan sleeve's front wall below the plate; the clearance had been sized for the
   servo's horn, not the hub.
3. **Support a servo's case at both ends before any strap goes on:**
   - long rails along the sides, over half the case length;
   - corner pads at the shaft end, beyond the horn and any hub opening.

   Short stops at one end let it rock.
4. **Give every cable a route through every part,** big enough for the plug (an STS3215 3-pin plug
   needs about 7.5 × 7.5 mm). The turret's servo pedestal sat on top of the hole down into the hub.
5. **Keep printed parts clear of the servo case:** the turret's strap post overlapped the tilt
   servo's case by 1 mm. Start any wall or post at the case plus clearance.
6. **Overhangs facing the bed get a 45° back:** stop rails and pads on parts printed upside down.
7. **Check the exported file, not just the preview:** slice it, or test points inside it. In this
   project the previews have hidden real faults several times. Run a clash check (intersect each
   pair of parts) after every change.

## Results on the stand (2026-10-21)

- **Both servos run cleanly from the Waveshare bus adapter at 12 V** (`tools/servo_test`):
  - every move lands within 0.3 degrees;
  - load stays at 2-3 % in every combination of pan and tilt, so the bearing, hub and linkage
    add almost no friction;
  - 12.2-12.4 V with both moving.
- **Pan** (ID 1): centred facing forward, + = left. Swept +/-170 degrees freely. Tested to
  +/-90 degrees with the tilt cable attached.
- **Tilt** (ID 2): centre = the disc's pin pointing forward; + = up. The servo's own angle limits
  are set to **servo -70 to +6.3 degrees**, which is **head about -24 (max down) to +20..25 (max up)**,
  chosen by eye for a camera on a desk. The head is level at about servo -33.
  - **Measured head angles differ from the design** at the low end: servo -53 gives head -12
    (design -20). Above servo 0 they match. Work from the measured values, not the design curve.
  - **A plain flat link on two M3 bolts works as well as rose joints** here: both pins are
    parallel, so nothing needs to swivel. Bolt each end as a pivot (snug, not clamped).
- **The tilt cable goes OUTSIDE the neck.** Routing it down through the hub was awkward. On the
  stand it leaves the turret and hangs in a loose loop behind the neck. **The real head should have:**
  - a channel inside the turret from the tilt servo's plug face (its left side, since the shaft
    points right) round to an exit at the turret's **rear centre**. On the stand the cable leaves at
    the left side, and at pan -90 that side faces forward: the loop would hang across the display.
    Exiting at the back, +/-90 swings it to the sides but never to the front (about 40-50 mm of extra
    loop each way);
  - room for a slack loop outside, behind the neck (the pan's range sets how much);
  - a slot or grommet in the base box lid, directly behind the pan axis, to take the cable down inside;
  - a cable-tie anchor at each end of the loop.

  The hub can then be solid.

## Still to prove on the stand

- Pan: does the pillow block's single bearing hold the turret without wobble? If not, use two
  stacked 6807ZZ bearings.
- Pan: how much of its range the outside tilt cable allows, which sets the real pan limit.
- Noise: STS3215 hum while holding, near the microphone.
