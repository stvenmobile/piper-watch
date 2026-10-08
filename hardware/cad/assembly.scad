// Piper-Watch assembly - the real printed parts placed together, plus see-through placeholders
// for what isn't designed yet (the skirt) and the bought parts. The head is concept v2.
//
// Frame: the desk under the centre of the reComputer J4012; +Y = front (display and face),
// +Z = up. Level 2's own frame (level2.scad: origin = top of the drive deck) sits at z_l2.
// F5 previews in colour.
include <level2.scad>
use <parts/l2_body.scad>
use <parts/drive_deck.scad>
use <parts/motor_bracket.scad>
use <parts/turntable_pulley.scad>
use <vitamins/lazy_susan.scad>
use <concepts/head_eyes_concept.scad>

pan       = 0;        // head pan angle (deg) - try +/-100
cutaway   = false;    // true: cut the front-right quarter away to see inside

// ---- the stack (heights from the desk) ---------------------------------------------------------
jetson    = [130.1, 121.1, 58.1];   // reComputer J4012, measured
air_gap   = 13;                     // over the Jetson's lid (its fan draws from there)
z_skirt_top = jetson[2] + air_gap;  // 71.1: Level 2's floor sits here
z_l2      = z_skirt_top + l2_h;     // 161.1: top of the drive deck
plate_t   = 8;                      // turntable plate (turntable_pulley.scad)
z_plate_top = z_l2 + z_plate + plate_t;

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

module cut() {
    if (cutaway) difference() { children(); translate([0, 0, -300]) cube([400, 400, 900]); }
    else children();
}

// ---- reComputer J4012 (bought) ---------------------------------------------------------------
color("#2a2a2a") linear_extrude(jetson[2]) rrect([jetson[0], jetson[1]], 8);
color("#3d3d3d") for (x = [-56 : 4 : 56]) translate([x, 0, jetson[2]]) cube([2, jetson[1] - 12, 1], center = true);

// ---- skirt (PLACEHOLDER: not designed yet) -------------------------------------------------------
color("#cfd3d8", 0.35) cut() linear_extrude(z_skirt_top) difference() {
    rrect(l2_size, l2_r);
    rrect(l2_size - [2, 2] * l2_wall, l2_r - l2_wall);
    translate([0, -l2_size[1] / 2]) square([100, 10], center = true);    // open at the back for the Jetson's ports
}

// ---- Level 2 (real parts) -----------------------------------------------------------------------
translate([0, 0, z_l2]) {
    color("#d9dcdf") cut() l2_body();
    color("#c7cbd0") cut() drive_deck();
    color("#9aa3ad") rotate(motor_a) translate([motor_C, 0, 0]) bracket();
    // NEMA17 (bought), hanging under the bracket, shaft up
    color("#4a4a4a") rotate(motor_a) translate([motor_C, 0, z_motor_bottom])
        linear_extrude(nema[1]) rrect([nema[0], nema[0]], 3);
    // the display behind its window (bought): board + glass
    color("#1b2a44") translate([0, 80 - l2_wall - 4.4 - 0.8, -45]) cube([120.7, 1.6, 70.2], center = true);
    color("#0d1117") translate([0, 80 - l2_wall - 2.2, -45]) cube([105.5, 4.4, 67.3], center = true);
    // lazy Susan (bought) on the plinth; the turntable pulley turns with the head
    translate([0, 0, z_ls]) lazy_susan();
    rotate(pan) color("#e8a33d") translate([0, 0, z_plate + plate_t]) mirror([0, 0, 1]) turntable_pulley();
}

// ---- head (turns with pan): CONCEPT v3 - concepts/head_eyes_concept.scad ---------------------------
// A 135 x 95 x 70 rounded box straight on the turntable plate (no neck): two round GC9A01 eyes,
// the camera behind a nose window below them, fixed 27 deg up.
rotate(pan) translate([0, 0, z_plate_top]) head_eyes();

echo(deck_top = z_l2, plate_top = z_plate_top, head_top = z_plate_top + 95, lens_height = z_plate_top + 29);
