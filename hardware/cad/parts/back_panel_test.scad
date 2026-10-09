// Back-panel fit test: the Level 2 body's back wall round the power switch and barrel jack, cut
// straight from l2_body.scad (so it's identical to the real print) - to check before the long
// body print:
//   * XW-604B rocker: snaps into the 28 x 10 cut-out, its clips grip the 1.5 mm patch
//   * barrel jack (5.5 x 2.1 IP68, M12): 12 mm hole in the full 2.5 mm wall, flange + gasket
//     outside, nut inside - goes in without forcing, nut pulls the gasket flat
//   * fuse holder (6 x 30 mm): double-D hole - slides in, doesn't turn, ring nut tightens flat
// PRINT outer face down (as modelled here), no supports. PETG, same settings as the body.
use <l2_body.scad>

margin = 12;                       // wall kept round the two features
x0 = -50 - 18 - margin / 2;        // switch / jack centre x = -50; switch cut-out is 28 wide (+8 patch)
x1 = -20 + 7.5 + margin;          // ... to past the fuse holder (centre x = -20)
z0 = -58 - 9 - margin;             // jack centre z -58 (flange / nut ~18 across) ...
z1 = -26 + 9 + margin;             // ... switch centre z -26 (patch 18 tall)

// lay the wall flat: outer face (y = -80) on the bed
translate([0, 0, 80]) rotate([90, 0, 0])
    intersection() {
        l2_body();
        translate([x0, -81, z0]) cube([x1 - x0, 6, z1 - z0]);    // the back wall only (2.5 thick)
    }
