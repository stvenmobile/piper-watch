// Drive deck - the top of Level 2. Everything that turns hangs from it, so the whole drive
// (deck + lazy Susan + turntable pulley + neck + head, and the motor on its bracket) lifts out
// of the body as one unit after four corner screws.
//
//   * Plinth for the lazy Susan's OUTER ring: four M5 flat-head screws down through the ring's
//     countersinks and the deck, nuts in hex pockets underneath. (The inner ring carries the
//     turntable pulley and is reached from below through the big centre hole while assembling.)
//   * Two radial slots for the motor bracket: loosen the two M3 screws from above, slide the
//     bracket outward to tension the belt, tighten. They sit outside the lazy Susan, so they can
//     be reached with everything assembled.
//   * Four corner screws (M3) into heat-set inserts in the body's corner posts.
//
// PRINT as modelled: underside on the bed (the nut pockets open onto it), no supports. PETG.
include <../level2.scad>

m3_clear = 3.6;                       // drawn; prints ~3.0-3.3 (hole_shrink)
m5_clear = 6.0;                       // drawn; prints ~5.4 (confirmed on the turntable pulley)
m5_nut   = [8.0 + 0.3, 4.0];          // pocket: across flats + clearance, depth
corner_screw = l2_size[0] / 2 - 9;    // corner screw positions (x and y)
slot_u   = 31;                        // bracket screws: radial offset from the motor axis
slot_v   = 12;                        //   and either side of the motor's radial line

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

module drive_deck() {
    difference() {
        union() {
            translate([0, 0, -deck_t]) linear_extrude(deck_t) rrect(l2_size, l2_r);
            linear_extrude(plinth_h) difference() {                 // plinth: outer ring only
                circle(d = ls_od, $fn = 180);
                circle(d = plinth_id, $fn = 180);
            }
        }
        // centre hole: the pulley hangs through; reach the inner ring's bolts from below
        translate([0, 0, -deck_t - 1]) cylinder(d = deck_hole, h = deck_t + plinth_h + 2, $fn = 180);
        // lazy Susan outer-ring bolts + nut pockets underneath
        // the bolt circle is scaled up by the printer's measured X/Y shrinkage, so the holes land
        // on the metal bearing's holes (128 mm -> drawn 128.6, prints ~128)
        for (i = [0 : ls_holes - 1]) rotate(i * 360 / ls_holes) translate([ls_outer_bc * cal_xy / 2, 0, 0]) {
            translate([0, 0, -deck_t - 1]) cylinder(d = m5_clear, h = deck_t + plinth_h + 2, $fn = 32);
            translate([0, 0, -deck_t - 0.01]) rotate(30) cylinder(d = m5_nut[0] / cos(30), h = m5_nut[1], $fn = 6);
        }
        // motor bracket slots (radial, for belt tension)
        rotate(motor_a) for (v = [-slot_v, slot_v])
            hull() for (du = [-tension_travel, tension_travel])
                translate([motor_C + slot_u + du, v, -deck_t - 1]) cylinder(d = m3_clear, h = deck_t + 2, $fn = 24);
        // corner screws into the body
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * corner_screw, sy * corner_screw, -deck_t - 1]) cylinder(d = m3_clear, h = deck_t + 2, $fn = 24);
    }
}

drive_deck();
