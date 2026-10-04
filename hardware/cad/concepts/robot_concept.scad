// Whole-robot concept - ROUGH DRAFT for discussion, not a printable part.
// The reComputer J4012 sits on the desk, unmodified. Over it drops a SKIRT (full panels front and
// sides, two short returns at the back corners so the case can't move and its DC jack / USB-C
// stay clear) that carries LEVEL 2: the pan drive, ESP32, driver, buck and the CYD status
// display. On top: lazy Susan, turntable plate + ring pulley, neck, 15 deg wedge and the round
// head. Unplug the cables and the whole robot lifts straight off the Jetson.
// Origin: desk surface under the centre of the case; +Y = front (the Jetson's ports face -Y).
include <../params.scad>
use <../vitamins/lazy_susan.scad>
use <../parts/turntable_pulley.scad>

cutaway = false;          // true: cut away the front half to see inside

// ---- the Jetson ---------------------------------------------------------------------
case_sz = [130.1, 121.1, 58.1];   // measured on the desk (model: 130.1 x 121.1)
case_r  = 8;                      // EST corner radius - take the real value from the case

// ---- skirt + level 2 (draft sizes) -------------------------------------------------------
fit     = 1.0;                    // skirt clearance around the case
skirt_t = 2.5;                    // skirt wall
air_gap = 13;                     // above the Jetson's lid (its fan draws air from there)
return_len = 12;                  // back returns, measured from each back corner
deck    = [146, 146];             // level 2 footprint: covers the 140 mm lazy Susan
lvl2_h  = 55;                     // tall enough for the CYD in its front face
cyd     = [86, 50];               // 2.8" CYD board (landscape)
cyd_win = [61, 46];               // its screen

z_lvl2  = case_sz[2] + air_gap;           // underside of level 2's floor (71.1)
z_top   = z_lvl2 + lvl2_h;                // top of level 2 (126.1)
z_ls    = z_top + plinth_h;               // lazy Susan's underside (on the plinth)

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

// ---- Jetson case ----------------------------------------------------------------------
color("#2a2a2a") linear_extrude(case_sz[2]) rrect(case_sz, case_r);
color("#3a3a3a") for (x = [-58 : 4 : 58]) translate([x, 0, case_sz[2] - 0.5]) cube([2, case_sz[1] - 10, 1], center = true);
// its back panel: DC jack (left), USB / RJ45 (middle), USB-C (right) - from the STEP model
color("#888") translate([0, -case_sz[1] / 2 - 0.2, 0]) {
    translate([-48, 0, 30]) rotate([90, 0, 0]) cylinder(d = 8, h = 1);              // DC jack
    for (x = [-15, 2]) translate([x, -1, 33]) cube([13, 1, 15]);                    // USB stacks
    translate([18.5, -1, 33]) cube([16, 1, 14]);                                     // RJ45
    translate([38.5, -1, 36]) cube([8, 1, 3]);                                       // USB-C
}

// ---- skirt ------------------------------------------------------------------------------
module skirt_2d() {
    inner = case_sz + [2, 2] * fit;
    outer = inner + [2, 2] * skirt_t;
    difference() {
        rrect(outer, case_r + fit + skirt_t);
        rrect(inner, case_r + fit);
        // open back, except a return_len wrap at each corner
        translate([0, -outer[1] / 2]) square([outer[0] - 2 * (case_r + return_len), 2 * skirt_t + 4 * fit], center = true);
    }
}
color("#c9ccd0") difference() {
    linear_extrude(z_lvl2) skirt_2d();
    // vent slots high on the side panels, level with the air gap over the Jetson's lid
    for (sx = [-1, 1], y = [-40 : 10 : 40])
        translate([sx * (case_sz[0] / 2 + 3), y, case_sz[2] + air_gap / 2]) cube([10, 5, air_gap - 3], center = true);
    if (cutaway) translate([-200, 0, -1]) cube([400, 200, 400]);
}

// ---- level 2 -------------------------------------------------------------------------------
color("#c9ccd0") difference() {
    translate([0, 0, z_lvl2]) linear_extrude(lvl2_h) rrect(deck, 10);
    translate([0, 0, z_lvl2 + 3]) linear_extrude(lvl2_h - 6) rrect(deck - [6, 6], 7);        // hollow
    translate([0, 0, z_top - 4]) cylinder(d = ls_id - 4, h = 10);                         // centre opening
    translate([0, deck[1] / 2, z_lvl2 + lvl2_h / 2]) cube([cyd_win[0], 10, cyd_win[1]], center = true);
    for (sx = [-1, 1], y = [-50 : 10 : 50])                                                // level 2 vents
        translate([sx * deck[0] / 2, y, z_lvl2 + 15]) cube([10, 5, 12], center = true);
    if (cutaway) translate([-200, 0, -1]) cube([400, 200, 400]);
}
color("#c9ccd0") translate([0, 0, z_top]) difference() {                                  // plinth
    cylinder(d = ls_od, h = plinth_h); translate([0, 0, -1]) cylinder(d = plinth_id, h = 5);
}
// CYD behind its window
color("#1d3b6e") translate([0, deck[1] / 2 - 3 - 4, z_lvl2 + lvl2_h / 2]) cube([cyd[0], 2, cyd[1]], center = true);
color("#9cc4ff") translate([0, deck[1] / 2 - 2.9, z_lvl2 + lvl2_h / 2]) cube([cyd_win[0] - 2, 0.2, cyd_win[1] - 2], center = true);

// ---- drive (as in pan_drive_concept / turntable_pulley) -------------------------------------
translate([0, 0, z_ls]) lazy_susan();
// the real turntable pulley part, flipped from its print orientation (plate up, tube down)
z_plate_top = z_ls + ls_h + 8;
color("#e8a33d") translate([0, 0, z_plate_top]) mirror([0, 0, 1]) turntable_pulley();
z_belt = z_ls + ls_h - 24.5;
motor_a = -135;                                // motor in a back corner (clear of the CYD)
C = 45; r_m = 20 / PI;
rotate(motor_a) translate([C, 0, 0]) {
    color("#555") translate([0, 0, z_belt - 3 - 8 - 3 - 23]) linear_extrude(23) rrect([42.3, 42.3], 3);
    color("#bbb") translate([0, 0, z_belt - 3 - 8]) cylinder(d = 16, h = 8 + 7);
}
color("#222") translate([0, 0, z_belt - 3]) linear_extrude(6) difference() {
    hull() { circle(r = 33); rotate(motor_a) translate([C, 0]) circle(r = r_m + 1.2); }
    hull() { circle(r = 31.8); rotate(motor_a) translate([C, 0]) circle(r = r_m); }
}
// boards (placeholders): ESP32, stepper driver, buck
color("#1f6f3f") translate([-58, -35, z_lvl2 + 3]) cube([25.5, 63, 12]);
color("#7a1f9a") translate([28, 30, z_lvl2 + 3]) cube([20, 15, 12]);
color("#1f4f9f") translate([30, -10, z_lvl2 + 3]) cube([22, 43, 12]);

// ---- neck, wedge, head ------------------------------------------------------------------------
neck_h = 40;
color("#c9ccd0") translate([0, 0, z_plate_top]) difference() {
    linear_extrude(neck_h) rrect([40, 40], 4);
    translate([0, 0, -1]) cube([28, 28, neck_h + 2], center = true);
}
head_d = head_size[0]; head_depth = 45;
translate([0, 0, z_plate_top + neck_h]) rotate([-15, 0, 0]) translate([0, 0, head_d / 2 + 6]) {
    color("#c9ccd0") rotate([-90, 0, 0]) translate([0, 0, -head_depth / 2]) cylinder(d = head_d, h = head_depth);
    color("#222") translate([0, head_depth / 2, 0]) rotate([-90, 0, 0]) cylinder(d = 31, h = 0.6);   // lens opening
    color("#ffe9b8") translate([0, head_depth / 2, 0]) rotate([-90, 0, 0]) difference() {          // light ring
        cylinder(d = 65, h = 0.8); translate([0, 0, -1]) cylinder(d = 53, h = 3);
    }
}

echo(level2_floor = z_lvl2, lazy_susan_top = z_ls + ls_h, plate_top = z_plate_top,
     belt_z = z_belt, motor_bottom = z_belt - 3 - 8 - 3 - 23, head_top_approx = z_plate_top + neck_h + head_d + 6);
