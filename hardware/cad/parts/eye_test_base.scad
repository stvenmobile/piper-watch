// Round desk base for eye_test_stand.scad: a hex pillar that drops into the stem's 1/4"-20 nut
// pocket, plus a pin up the screw hole above it so the stand doesn't wobble. The eye stands
// upright (no tilt - eye_test_foot.scad is the tilted alternative).
// PRINT as modelled (disc on the bed), no supports.
include <../params.scad>

base_d   = 80;
base_t   = 5;
chamfer  = 1.5;                 // round the top edge
foot     = 0.5;                 // small bottom chamfer (elephant's foot)

// The stand's pocket (eye_test_stand.scad: nut_14 = 11.41 across flats x 5.9 deep, then a
// 6.6 screw hole 12 mm further). Both printed sideways in the stem, so they come out ~0.4 small.
hex_af   = 10.9;                // across flats as drawn: prints ~10.8 in a ~11.0 pocket
hex_h    = 5.6;                 // just under the pocket depth, so the stem end sits on the disc
pin_d    = 6.0;                 // prints ~5.9 in a ~6.2 hole
pin_h    = 10;                  // above the hex (the hole goes 12.1)
lead     = 0.6;                 // lead-in chamfers

$fn = 96;

module disc() {
    hull() {
        cylinder(d = base_d - 2 * foot, h = 0.01);
        translate([0, 0, foot]) cylinder(d = base_d, h = base_t - foot - chamfer);
        translate([0, 0, base_t - 0.01]) cylinder(d = base_d - 2 * chamfer, h = 0.01);
    }
}

module hex(af, h) {
    d = af / cos(30);
    hull() {
        cylinder(d = d, h = h - lead, $fn = 6);
        cylinder(d = d - 2 * lead / cos(30), h = h, $fn = 6);
    }
}

module pin() {
    hull() {
        cylinder(d = pin_d, h = pin_h - lead);
        cylinder(d = pin_d - 2 * lead, h = pin_h);
    }
}

union() {
    disc();
    translate([0, 0, base_t - 0.01]) {
        hex(hex_af, hex_h + 0.01);
        translate([0, 0, hex_h]) pin();
    }
}
