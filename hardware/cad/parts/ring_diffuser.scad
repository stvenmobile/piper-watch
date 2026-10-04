// Diffuser for the face's LED ring: a flat ring pressed into the face from the front, flush
// with the surface. Print flat on the bed (no supports) in white or natural (translucent)
// PLA/PETG. Thinner = brighter, thicker = smoother: with the 3.5 mm air gap behind it, 2 mm of
// natural PETG or 1.5-2 mm of white PLA blends the 24 LEDs into one glow.
include <../params.scad>

ring_r = (ring_od + ring_id) / 4;              // radius of the LED centres

difference() {
    cylinder(r = ring_r + diff_w / 2 - diff_clr[1], h = diff_t, $fn = 180);
    translate([0, 0, -1]) cylinder(r = ring_r - diff_w / 2 + diff_clr[0], h = diff_t + 2, $fn = 180);
}
