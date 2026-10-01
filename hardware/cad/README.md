# CAD (OpenSCAD)

All printed parts are parametric OpenSCAD models. Every dimension lives in
[`params.scad`](params.scad); change a number there and every part follows.

```text
params.scad          dimensions, clearances, printer settings (EST = estimate, to be measured)
vitamins/            simple models of bought parts (lazy Susan, STS3215, ...) for fit checks
parts/               printable parts, one file each
assembly.scad        everything together, to check fit and range of motion
export.sh            render parts/ to out/*.3mf for Bambu Studio
```

## Setup

1. Install an OpenSCAD **development snapshot** (openscad.org → Downloads → Development
   Snapshots), not the old 2021.01 release.
2. *Edit → Preferences → Advanced → Backend:* **Manifold**. Full renders take seconds instead of minutes.
3. Later parts will use the **BOSL2** library (rounded edges, screw holes, attachments). Install
   it into OpenSCAD's library folder (*File → Show Library Folder*) as `BOSL2`.

In OpenSCAD, **F5** previews (fast, for looking), **F6** renders (exact), and **F7** exports
the rendered part.

## Print first

1. **`parts/tolerance_coupon.scad`**: tells us the hole clearance and heat-set insert bore that
   work on this printer with PETG. Update `clr_hole`, `insert_m3` and `insert_m4`.
2. **`parts/ls_gauge.scad`**: a 2 mm ring with slotted holes and tick marks. Lay it on the
   real lazy Susan and read off the true bolt-circle diameters (the numbers next to the ticks).
   Update `ls_outer_bc`, `ls_inner_bc` and `ls_hole_d`.

Then every later part (pan base, turntable top, tilt yoke, camera cradle, box) is built on
measured numbers.

## Printing defaults (A1, 0.4 mm nozzle, PETG)

- At least 4 walls (about 1.8 mm) on load-bearing parts.
- Orient parts so the load runs along the layers, not across them.
- Use M3/M4 brass heat-set inserts where screws go in more than once.
