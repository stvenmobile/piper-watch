// Test arc for the turntable pulley (~10 min, PETG): a slice of the real part's tooth band with
// one belt-clamp slot, on a thin base so it prints the same way (base on the bed, teeth up).
// Check: (1) wrap a short length of belt over the teeth - it should seat fully, teeth in
// every space, without rocking or binding; (2) press the belt end down into the clamp slot from
// the top - snug, and it shouldn't pull out by hand. Too tight or loose -> adjust gt2_* in
// params.scad (tooth spaces) or slot_clr in turntable_pulley.scad (clamp), then reprint.
use <turntable_pulley.scad>
include <../params.scad>

pulley_T = 100;
z_cut    = 8 + 24.5 - 3.2 - 1.6 - 2.2 - 1;   // just below the lower flange's chamfer
a0 = 180 - 21.6 - 25;                        // arc: 25 deg of teeth + the clamp's lower half
a1 = 180 + 4;

intersection() {
    translate([0, 0, -z_cut]) turntable_pulley();
    linear_extrude(50) polygon(concat([[0, 0]], [for (a = [a0 : 1 : a1]) 60 * [cos(a), sin(a)]]));
    translate([0, 0, 0]) cylinder(r = 50, h = 50);
}
// thin base under the slice so it sits flat and the flange chamfer prints as in the real part
linear_extrude(1) intersection() {
    difference() { circle(r = 34, $fn = 180); circle(r = 25, $fn = 120); }
    polygon(concat([[0, 0]], [for (a = [a0 : 1 : a1]) 60 * [cos(a), sin(a)]]));
}
