// CONCEPT: one-piece head. The camframe is merged into the head: a front wall with the lens hole, flared side walls and a visor (top plate).
// Everything behind the camera board (plate, arms, stubs, crank bracket) is head4() unchanged. Camera loads from BELOW: the lens hole, the
// mic and connector pockets are open slots to the bottom edge, the eye spigots are U-shaped.   part = "v5_view"
include <../base_v4.scad>
show_camframe = false;
cam_dx = ox;                                         // lens, eyes, board and shell centre on the OLED window's middle (the window is 3.9 off the PCB centre)
slot_x = -15 + cam_dx;                               // the camera's edge-slot screw moves with the board
fr5 = fr_y + 0.3;                                    // frame's rear face: 0.3 more room than the camframe so the board can slide up past it
z0 = lens_z - 11.5;  z1 = 32.5;  hw0 = 44;  hw1 = 58;  wt5 = 2.5;      // shell: bottom z, top z (rel. the axle), half widths at both
zr = 11.5;                                           // the rear wings start here (above the cheek discs, r 17)
module trap2d() translate([cam_dx, 0]) offset(r = 3) offset(delta = -3) polygon([[-hw0, z0], [hw0, z0], [hw1, z1], [-hw1, z1]]);   // centred on the lens
module ring2d() difference() {
    trap2d();
    offset(delta = -wt5) trap2d();
}
module walls2d() difference() { ring2d(); translate([cam_dx - hw0 + wt5, z0 - 1]) square([2 * hw0 - 2 * wt5, wt5 + 1.5]); }       // no bottom strip: open underneath
module rear2d() difference() {
    intersection() { trap2d(); translate([-100, zr]) square([200, 100]); }
    translate([-pl_x, zr - 1]) square([2 * pl_x, 29.99 - zr + 1]);                                                          // plate keeps its own face
}
module ext_y(y0, y1) translate([0, ax_y + y1, ax_z]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();         // 2D (x, z rel. axle) -> y0 .. y1 rel. axle
module front5() translate([cam_dx, 0, 0]) difference() {
    union() {
        translate([-cam_dx, 0, 0]) ext_y(fr5, fr5 + fr_t) trap2d();
        for (sx = [-1, 1]) translate([sx * eye_x, ax_y + fr5 + 0.01, ax_z + eye_z]) rotate([90, 0, 0]) cylinder(d = 5, h = spg, $fn = 32);
    }
    translate([-cube_w / 2 - 0.2, ax_y + fr5 - 1, ax_z + z0 - 1]) cube([cube_w + 0.4, fr_t + 2, lens_z + cube_w / 2 + 0.2 - z0 + 1]);   // lens hole, open to the bottom
    for (sx = [-1, 1]) {
        translate([sx * eye_x, ax_y + fr5 - spg - 1, ax_z + eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_d, h = spg + fr_t + 2, $fn = 24);
        translate([sx * eye_x - eye_d / 2, ax_y + fr5 - spg - 1, ax_z + z0 - 1]) cube([eye_d, spg + 1.01, eye_z - z0 + 1]);                     // spigot open below: the LED slides up into it
        translate([sx * eye_x, ax_y + fr5 + fr_t - eye_seat, ax_z + eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_seat_d, h = eye_seat + 1, $fn = 48);
        translate([sx * 40.5 - 5.5, ax_y + fr5 - 1, ax_z + z0 - 1]) cube([11, 2.4 + 1, lens_z - 2.1 - z0 + 1]);                                  // mic can pockets, open below
        translate([sx * 40.5, ax_y + fr5 - 1, ax_z + lens_z - 2.1]) rotate([-90, 0, 0]) cylinder(d = 11, h = 2.4, $fn = 40);
    }
    translate([12, ax_y + fr5 - 1, ax_z + z0 - 1]) cube([5.9, 1 + 1.5, lens_z + 8.7 - z0 + 1]);                                              // connector pocket, open below
    translate([slot_x - cam_dx, ax_y + fr5 - 1, ax_z + slot_z]) rotate([-90, 0, 0]) cylinder(d = 2.8 + cal_hole, h = fr_t + 2, $fn = 24);
    translate([slot_x - cam_dx, ax_y + fr5 + fr_t - 1.5, ax_z + slot_z]) rotate([-90, 0, 0]) cylinder(d = 5.4 + cal_hole, h = 2, $fn = 32);
}
module shell5() color("#8a8d91") {
    front5();
    ext_y(pl_y[1] - 0.01, fr5 + 0.01) walls2d();
    ext_y(pl_y[0], pl_y[1] + 0.01) rear2d();
}
module head5() {
    head4();
    translate([0, ax_y, ax_z]) rotate([tilt4, 0, 0]) translate([0, -ax_y, -ax_z]) shell5();
}
if (part == "v5_head") translate([0, 0, ax_y + fr5 + fr_t]) rotate([-90, 0, 0]) union() { head4(); shell5(); }   // front face down on the bed
if (part == "v5_view") { head5(); color("#6b8fb5") turret4(); if (show_cowl) cowl4(); covers4(); }
if (part == "v5_headonly") head5();
ctx = false;                                          // true: draw the turret, cheek covers and cowl round the head
if (part == "head_view") { translate([0, ax_y, ax_z]) rotate([tilt4, 0, 0]) translate([0, -ax_y, -ax_z]) shell5(); if (ctx) { color("#6b8fb5") turret4(); covers4(); if (show_cowl) cowl4(); } }
