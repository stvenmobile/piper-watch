// Test arc for the turntable pulley (~15 min, PETG): a slice of the real part's tooth band with
// BOTH belt-clamp slots, on a thin base so it prints the same way (base on the bed, teeth up).
// The two slots have different clearances behind the belt:
//   * slot WITHOUT the notch in the base: 0.3 mm (the value used in the real part)
//   * slot WITH the notch in the base:    0.45 mm (looser)
// Check: press the belt end down into each slot from the top - it should go in with firm thumb
// pressure and not pull out by hand. Tell me which one is right (or both too tight / loose).
// Test arc 1 (one slot, 0.1 mm, belt assumed 1.38 thick) was too tight; the teeth fitted.
use <turntable_pulley.scad>
include <../params.scad>

clamp_half = 21.6;
z_cut = 8 + 24.5 - 3.2 - 1.6 - 2.2 - 1;      // just below the lower flange's chamfer
a0 = 180 - clamp_half - 12;                  // arc: the clamp plus ~3 teeth either side
a1 = 180 + clamp_half + 12;
notch_a = 180 + clamp_half + 6;              // marks the looser slot (s = +1, at 180 + 21.6)

module wedge() { polygon(concat([[0, 0]], [for (a = [a0 : 1 : a1]) 60 * [cos(a), sin(a)]])); }

intersection() {
    translate([0, 0, -z_cut]) turntable_pulley(back_clr = [0.3, 0.45]);
    linear_extrude(50) wedge();
    cylinder(r = 50, h = 50);
}
// thin base under the slice so it sits flat, with a notch beside the looser slot
difference() {
    linear_extrude(1) intersection() {
        difference() { circle(r = 34, $fn = 180); circle(r = 25, $fn = 120); }
        wedge();
    }
    rotate(notch_a) translate([34, 0, -1]) cylinder(d = 3, h = 3, $fn = 16);
}
