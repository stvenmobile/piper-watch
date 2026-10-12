// Tap coupon: which hole size lets an M3 screw cut a good thread straight into PETG (the Level 2
// body's display posts and breakout bosses use tap_m3 from params.scad). Three bosses, the same
// height as the body's (6 mm deep holes), drawn at 2.8 / 2.9 / 3.0 - they print ~0.4 smaller.
// Screw an M3 x 8 into each: pick the one that goes in firmly by hand with a screwdriver and holds
// without the boss splitting, and set tap_m3 to it.
// PRINT flat, as modelled, PETG, the body's settings.
include <../params.scad>

sizes = [2.8, 2.9, 3.0];
difference() {
    union() {
        translate([-20, -7, 0]) cube([40, 14, 1.6]);                     // base
        for (i = [0 : 2]) translate([(i - 1) * 13, 0, 0]) cylinder(d = 8, h = 7.5, $fn = 40);
    }
    for (i = [0 : 2]) translate([(i - 1) * 13, 0, 7.5 - 6]) cylinder(d = sizes[i], h = 7, $fn = 24);
    for (i = [0 : 2]) translate([(i - 1) * 13, -5.6, 1.2]) linear_extrude(1)        // its size, engraved
        text(str(sizes[i]), size = 2.4, halign = "center", valign = "center");
}
