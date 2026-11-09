# Robot v4: assembly run book

One step at a time. Each step has the parts and hardware it needs, what to do, and a render of what it should look like.
Photos of the real build go in this folder, named `NN_what_it_shows.jpg`, and get added under the step they belong to.
Renders (`NN_render_*.png`) come from `parts/base_v4.scad` (`part = "head_view"`).

## Done

### Step 1: camera on the camframe ✅

Part: `base_camframe_v4.3mf` (superseded by `base_head_v5.3mf`, see step 2). The webcam PCB (Logitech 210-002028-003) is fitted to the camframe: lens in its square pocket, glass eyes in the D3 and D6 seats,
mic cans in their pockets. One side is held by an M2.5 x 12 bolt through the edge slot, the mic side is hot-glued.

![Camera board, rear](01_camera_board_rear.jpg)
*01: webcam PCB, rear: M2.5 screw through the edge slot, thermal pad, chips.*

![Camera on the camframe, front](02_camera_on_camframe_front.jpg)
*02: camera on the camframe from the front. USB cable leaves at the bottom.*

## Next

### Step 2: head: insert, OLED, camera ⏭

**Part (in `out/`):** `base_head_v5.3mf` — the new one-piece head (camera frame, visor, flared sides, plate, arms and axle stubs). It replaces `base_head_v4.3mf` and `base_camframe_v4.3mf`; do not use those two or `base_plate_v4.3mf` (an old coupon).
Print it front face down, with tree supports under the lower plate and arms. Not printed yet.
**Hardware:** the camera on its camframe, the OLED (2.08", GME25664-65), 1 x M2.5 heat-set insert,
4 x M2 short self-tapping screws, 1 x **M2.5 x 16** screw, 1 x M3 heat-set insert, soldering iron, a zip tie.
**Nothing more to print for this step.**

![Head from the front](03_render_head_front.png)
*03: the finished head from the front: camera frame on the plate, the OLED window below it.*

![Head from the rear](04_render_head_rear.png)
*04: the head from the rear. The M2.5 boss in the middle, the zip-tie tab at the left, the OLED board across the bottom.*

![Exploded](05_render_head_exploded.png)
*05: exploded, from the rear: OLED, head (`base_head_v4.3mf`), camera board, camframe.*

1. **Inserts.** M2.5 insert into the boss on the rear of the plate, pressed in from the boss's rear end. M3 insert into the crank bracket on the left arm, pressed in from its free face. Check each with a screw.
2. **OLED.** Glass into the pocket from the rear (the front lip keeps it in), board flat on the plate, 4 x M2 into the corner pilot holes. Do not overtighten. Lead the wires down and zip-tie them at the tab on the head's rear, above the board's left end.
3. **Camera.** The camera slides up from below into the head, lens cube into the open lens slot, glass eyes pressed into their seats from the front. Put the **M2.5 x 16** screw through the frame, the board's edge slot, into the head's insert; it pins the board (about 0.3 mm of play front to back).
   The frame's rear face stands 7.0 mm off the plate, so a 12 mm screw would barely reach the insert; use 16 or 18.
4. **Check.** The camera does not rock, the OLED glass is flush in its window, the USB cable has a free run out of the frame bottom.

Add your photos here: `06_head_oled_fitted.jpg`, `07_head_camera_fitted.jpg`.

## After that (not detailed yet)

| Step | What | Parts still to print |
|---|---|---|
| 3 | Inserts in the turret (strap 2, cowl 2, covers 6) and hub (4) | none: `base_turret_v4.3mf` and `base_hub_v4.3mf` are printed |
| 4 | `base_hub_v4.3mf` and `base_turret_v4.3mf` on the pan stack, 4 x M3 x 8 | none |
| 5 | Tilt servo in its cradle, strap, crank on the horn | **`base_strap_v4.3mf`** (1); `base_crank_v4.3mf` is printed  |
| 6 | 608 bearings and the head into the cheeks | see the note below |
| 7 | Tilt rod (M3 rod, 2 rose joints) | none |
| 8 | XIAO, wiring, cheek covers, cowl | **`base_cover_v4.3mf`** (print 2); reprint `base_cowl_v4.3mf` only if you printed it before commit c652f5e |

**Note on step 6:** the head's printed axle stubs run from the arm through the whole cheek, and the cheeks leave a 1 mm gap, so the head cannot be put in once the cheeks are fixed. This needs a design change before step 6 (for example a separate axle pin).
