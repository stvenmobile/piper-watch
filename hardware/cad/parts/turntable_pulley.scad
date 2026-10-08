// Turntable plate + ring pulley, one piece (print in PETG / PETG HF: the base runs warm on
// top of the Jetson, and PLA would creep under belt tension).
//
//   * The PLATE sits on the lazy Susan's inner ring and turns with it. Four M5 flat-head screws
//     come up through the ring's countersunk holes and through the plate, with nuts held in hex
//     pockets on the plate's top. The neck mounts on top (later).
//   * Under it, a hollow TUBE drops through the bearing into the base, with the cables to the
//     head running down its middle.
//   * At the bottom of the tube, a 100-tooth GT2 PULLEY driven by the NEMA17's 20-tooth pulley
//     (5:1). The belt is open-ended: each end goes into a slot in the CLAMP block, wraps a post
//     and doubles back on itself, teeth interlocked. The clamp faces away from the motor when
//     the head looks straight ahead, so the head can turn about +/-105 deg before the clamp
//     reaches the motor pulley.
//
// Modelled in PRINT ORIENTATION: the plate's top (neck side) on the bed, the tube rising from
// it, the teeth at the top. No supports: the flanges have 45 deg chamfers underneath, and the
// clamp slots are open at the top so the belt presses in from the end of the tube.
include <../params.scad>
include <../head.scad>            // the head's floor screws (floor_mounts, head_rot_in_pulley)

// ---- pulley -----------------------------------------------------------------------------
pulley_T   = 100;                       // teeth
PD         = pulley_T * gt2_pitch / PI; // 63.66 pitch diameter
R_od       = PD / 2 - gt2_pld;          // tooth tips (the belt's pitch line is outside them)
belt_zone  = gt2_belt_w + 0.4;          // tooth height (6 mm belt + clearance)
flange_h   = 1.6;
flange_out = 2.2;                       // flanges stand this far proud of the tooth tips

// ---- plate, tube and where the belt runs (lazy Susan + base geometry) ----------------------
plate_t    = 8;
m5_hole    = 6.0;                       // CONFIRMED (PLA, 15% gyroid, 4 walls): prints 5.4 mm (0.6 undersize);
                                        //   M5 bolts slide through smoothly, no slip. Print this part at ~15% gyroid,
                                        //   4 walls, 5 top/bottom layers.
m5_nut     = [8.0 + 0.3, 3.5];          // nut pocket [across flats + clearance, depth] (M5 nut: 8 AF, 4 thick)
plate_d    = top_plate_d;               // 112.6: touches the inner ring only
hollow_d   = 50;                        // cable passage
tube_od    = 2 * R_od + 2;              // between plate and teeth (passes the 84.8 deck opening)
belt_drop  = 24.5;                      // plate's underside -> belt centre (puts the belt below the base's top deck)
z_belt     = plate_t + belt_drop;       // belt centre, in print coordinates
z_teeth0   = z_belt - belt_zone / 2;
z_teeth1   = z_belt + belt_zone / 2;

// ---- belt clamp -----------------------------------------------------------------------------
// Each belt end presses into a straight slot that continues the belt's line off the teeth;
// the slot's inner wall has GT2 tooth spaces, so ~5 teeth lock the belt (as in Voron belt
// paths). The ends meet in a small gap in the middle of the clamp; a drop of CA glue there is
// optional.
clamp_a    = 180;                       // clamp position (deg); the motor is at 0 when the head looks ahead
clamp_half = 6 * 360 / pulley_T;        // 21.6: the belt leaves the teeth here (on a tooth space)
slot_len   = 10;                        // 5 teeth of grip per end
slot_clr   = [0.05, 0.3];               // [land side, back side] clearance around the belt's backing
                                        //   test arc 1: channel 0.83 - belt only half in
                                        //   test arc 2: channel 1.10 (this) - FITS, no looseness; 1.25 - loose
clamp_r    = 35.5;                      // clamp block outer radius
module ring_pulley_2d() {
    // tooth tips with one groove per tooth; groove = rounded GT2 tooth space
    difference() {
        circle(r = R_od, $fn = pulley_T * 4);
        for (i = [0 : pulley_T - 1]) rotate(i * 360 / pulley_T) groove_2d();
    }
}

module groove_2d() {
    hull() {
        translate([R_od - gt2_depth + gt2_tip_r, 0]) circle(r = gt2_tip_r, $fn = 24);
        translate([R_od, 0]) square([0.02, gt2_mouth], center = true);
        translate([R_od + 1, 0]) square([0.02, gt2_mouth], center = true);
    }
}

// The two clamp slots, in 2D. In each one's frame the belt leaves the pulley at y = 0 and runs
// along -s*y; x is radial. Belt land (tooth roots) on x = R_od, back at R_od + land thickness.
module clamp_slots_2d(back_clr = [slot_clr[1], slot_clr[1]]) {
    for (s = [-1, 1]) rotate(clamp_a + s * clamp_half) mirror([0, s > 0 ? 1 : 0]) {
        // backing strip
        bc = back_clr[(s + 1) / 2];
        translate([R_od - slot_clr[0], -0.01]) square([gt2_belt_t - gt2_tooth_h + slot_clr[0] + bc, slot_len + 0.01]);
        // tooth spaces every pitch along the slot (they continue the pulley's grooves)
        for (k = [0 : floor(slot_len / gt2_pitch)]) translate([0, k * gt2_pitch]) groove_2d();
    }
}

module clamp_block_2d() {
    // a solid sector over the clamp, from the tube out past the slots
    intersection() {
        circle(r = clamp_r, $fn = 180);
        rotate(clamp_a) polygon([[0, 0], [80, -80 * tan(clamp_half)], [80, 80 * tan(clamp_half)]]);
    }
}

module turntable_pulley(back_clr = [slot_clr[1], slot_clr[1]]) {
    difference() {
        union() {
            // plate
            cylinder(d = plate_d, h = plate_t, $fn = 180);
            // tube
            cylinder(d = tube_od, h = z_teeth0 - flange_h, $fn = 180);
            // lower flange, 45 deg chamfer underneath
            translate([0, 0, z_teeth0 - flange_h - flange_out])
                cylinder(r1 = R_od, r2 = R_od + flange_out, h = flange_out, $fn = 180);
            translate([0, 0, z_teeth0 - flange_h]) cylinder(r = R_od + flange_out, h = flange_h, $fn = 180);
            // teeth, with the clamp block over its sector
            translate([0, 0, z_teeth0]) linear_extrude(belt_zone) union() {
                ring_pulley_2d();
                clamp_block_2d();
            }
            // upper flange (not over the clamp, so the slots stay open from the top)
            translate([0, 0, z_teeth1]) difference() {
                cylinder(r1 = R_od, r2 = R_od + flange_out, h = flange_out, $fn = 180);
                translate([0, 0, -1]) linear_extrude(flange_out + 2) offset(r = 1) clamp_block_2d();
            }
        }
        // cable passage
        translate([0, 0, -1]) cylinder(d = hollow_d, h = 100, $fn = 120);
        // clamp slots, open at the top, down to the lower flange
        translate([0, 0, z_teeth0]) linear_extrude(belt_zone + flange_out + 1) clamp_slots_2d(back_clr);
        // M5 through-holes; hex nut pockets in the plate's top (on the bed as printed)
        for (i = [0 : ls_holes - 1]) rotate(ls_inner_rot + i * 360 / ls_holes)
            translate([ls_inner_bc / 2, 0, 0]) {
                translate([0, 0, -1]) cylinder(d = m5_hole, h = plate_t + 2, $fn = 32);
                translate([0, 0, -0.01]) rotate(30) cylinder(d = m5_nut[0] / cos(30), h = m5_nut[1], $fn = 6);
            }
        // the head: M3 heat-set inserts in the plate's top for its floor's four screws
        rotate(head_rot_in_pulley) for (m = floor_mounts) translate([m[0], m[1], -0.01])
            cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 32);
        // a small arrow in the top showing which way the head faces
        rotate(head_rot_in_pulley) translate([0, 42, -0.01]) linear_extrude(0.6)
            polygon([[-4, -3], [4, -3], [0, 4]]);
    }
}

turntable_pulley();
echo(PD = PD, tip_d = 2 * R_od, tube_od = tube_od, print_height = z_teeth1 + flange_out,
     clamp_r = clamp_r, travel_deg = 180 - acos((PD/2 - 20/PI) / 45) - clamp_half);
