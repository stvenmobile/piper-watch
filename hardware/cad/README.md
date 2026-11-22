# CAD (OpenSCAD)

All printed parts are parametric OpenSCAD models.

```text
params.scad                 shared dimensions: clearances, heat-set insert bores, the STS3215, the pillow block
parts/servo_test_stand.scad the pan stack's geometry (plate, sleeve, hub, stop rails); base_v4.scad builds on it
parts/base_v4.scad          tub, lid + wall, skirt, pan strap, hub, turret, tilt strap, crank, cowl, cheek covers, ears
parts/head_v6.scad          the head: front, back, straps, axle pins
parts/lens_flange.scad, parts/oled_washers.scad   small head extras
parts/prototype/            calibration coupons (tolerances, fit, the servo adapter's holes)
vitamins/                   simple models of bought parts, for fit checks
docs/build_photos/          the assembly run book (README.md), its photos and renders
concepts/TEST_STAND_LESSONS.md   what the servo test stand taught (design rules for the pan/tilt stack)
export.sh                   renders every printable part to out/<name>.3mf
```

Most parts come out of one source file through its `part` variable (the list is at the top of `base_v4.scad`
and `head_v6.scad`); `export.sh` knows which file name goes with which part:

    ./export.sh                    # everything
    ./export.sh base_turret_v4     # one part

`out/` is not committed: run `export.sh` to make the printable files.

## Setup

1. Install an OpenSCAD **development snapshot** (openscad.org → Downloads → Development Snapshots), not the old
   2021.01 release.
2. *Edit → Preferences → Advanced → Backend:* **Manifold**. Full renders take seconds instead of minutes.

In OpenSCAD, **F5** previews (fast, for looking), **F6** renders (exact), and **F7** exports the rendered part.

## Print first

`parts/prototype/tolerance_coupon.scad` and `fit_calibration.scad` tell you the hole clearance and heat-set insert
bores that work on your printer; put them into `params.scad` (`cal_hole`, `insert_m3`, `insert_m25`) before the long prints.

## Printing defaults (A1, 0.4 mm nozzle, PETG)

- At least 4 walls (about 1.8 mm) on load-bearing parts.
- Orient parts so the load runs along the layers, not across them.
- Use M3/M2.5 brass heat-set inserts where screws go in more than once.

## Before changing the pan stack

The cables between the turret and the base pass the turret floor's hole, the hub's 19 mm bore and its window into
a 20.6 mm gap over the pan servo: already the tightest point of the build (see the run book, step 3.9). Don't
make any of these smaller.
