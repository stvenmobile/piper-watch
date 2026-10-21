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

## Still to prove on the stand

- Pan: does the pillow block's single bearing hold the turret without wobble? If not, use two
  stacked 6807ZZ bearings.
- Tilt: linkage play with the rose joints; the servo angles for head −20° / +20° / +60°
  (design: −53° / 0° / +54°).
- Noise: STS3215 hum while holding, near the microphone.
