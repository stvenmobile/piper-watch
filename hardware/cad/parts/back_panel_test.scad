// Back-panel fit test: the Level 2 body's back wall round the switch, fuse holder and barrel jack,
// cut straight from l2_body.scad (so it's identical to the real print) - to check before the long
// body print:
//   * rocker switch (body 12.3 x 17.1, upright): snaps into the plain 12.6 x 17.4 cut-out in the
//     2.5 mm wall and stays put; ON at the top
//   * fuse holder (6 x 30 mm): double-D hole - slides in, doesn't turn, ring nut tightens flat
//   * barrel jack (5.5 x 2.1 IP68, 11.2 mm thread): 11.5 mm hole, flange + gasket outside, nut
//     inside - goes in without forcing, nut pulls the gasket flat; its nut clears the fuse's
// PRINT outer face down (as modelled here), no supports. PETG, same settings as the body.
use <l2_body.scad>

margin = 8;                        // wall kept round the features
x0 = -40 - 11 - margin;            // fuse / jack column at x = -40 (fuse ring nut ~20 across) ...
x1 = 5;                            // ... switch at x = -10 (flange 14.8 wide); stops short of the cable exit
z0 = -58 - 9 - margin;             // jack centre z -58 (flange / nut ~18 across) ...
z1 = -36 + 10 + margin;            // ... fuse centre z -36 (ring nut ~20)

// lay the wall flat: outer face (y = -80) on the bed
translate([0, 0, 80]) rotate([90, 0, 0])
    intersection() {
        l2_body();
        translate([x0, -81, z0]) cube([x1 - x0, 6, z1 - z0]);    // the back wall only (2.5 thick)
    }
