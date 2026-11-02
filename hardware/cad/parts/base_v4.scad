// BASE v4 - electronics box + stationary pan cylinder on the test stand's pillow-block stack.
//
//   TUB    rounded-square box (118 x 120) holding ONLY the Orin NX carrier (+ fuse/terminal block). Its top has a 45-deg-filleted LEDGE
//          (6 mm) with a pocket above it: the flat LID drops into the pocket and sits on the ledge, flush with the wall tops.
//          The Orin stands forward; its ports face a PLUG ZONE (28 mm) at the back: the 12 V jack, the power button and the fuse /
//          terminal block live there, and the lid's cable slot drops straight into it - so every cable from the head reaches an
//          Orin jack INSIDE the case. 4 corner bosses (M2.5 inserts, lid) + 4 cardinal bosses (M2.5 inserts, ring), each tied to the walls by a web.
//   LID    6 mm flat sheet, cable slot over the plug zone, 8 M2.5 holes.
//   RING   the stationary cylinder (OD 109, wall 4) on the lid; 4 inward lugs bolt it (M2.5) through the lid into the cardinal
//          bosses; 4 inserts on its top take the cap.
//   CAP    the stand's base() (plate + sleeve for the hanging pan servo + stop rails) widened to a disc that sits on the ring (M2.5 x 4).
//          The ServoCity pillow block, hub and turret are the stand's, unchanged.
//   The servo ADAPTER lies on the lid under the pan servo (inside the cylinder); its USB-C and 12 V leads go down the lid slot.
//
// Frame: pan axis = (0,0) = the box centre; Z = 0 under the box floor; +Y = front (cylinder/head side), back wall at Y = -60.
// part = "v4_view" | "v4_tub" | "v4_lid" | "v4_ring" | "v4_cap"
include <servo_test_stand.scad>

part = "v4_view";
base_legs = false;
tilt = 0;
cut_v4 = false;                               // slice the view open on x > 0

// ---- box --------------------------------------------------------------------------------------------------------------
bw = 118;  bd = 120;  bwt = 3;  bfl = 4;  brr = 14;
b_in = [bw - 2 * bwt, bd - 2 * bwt];          // 112 x 114
ledge_w = 6;  lid_t4 = 6;  ledge_z = 34;      // heatsink top ~31.6 -> lid underside 34
wall_top = ledge_z + lid_t4;                  // 40
vx = b_in[0] / 2;  vy = b_in[1] / 2;          // inner half sizes 56 x 57

// ---- Orin carrier, plug zone ------------------------------------------------------------------------------------------
orin = [100, 80, 1.6];  orin_y = 11;          // centre y: back edge at -29, front edge at 51 (6 mm to the front wall)
orin_h = [86, 58];  so4 = 6;  fan4 = 20;
orin_pts = [for (sx = [-1, 1], sy = [-1, 1]) [sx * orin_h[0] / 2, orin_y + sy * orin_h[1] / 2]];
fuse4 = [-52, -56];  fuse_blk4 = [30, 20, 14];
fuse_pts4 = [[fuse4[0] + 5, fuse4[1] + 10], [fuse4[0] + 25, fuse4[1] + 10]];
slot4 = [[-18, 18], [-44, -30]];              // lid cable slot (x range, y range): over the plug zone, inside the cylinder
jack_y4 = -47;  jack_z4 = 18;  jack_d4 = 11.5;     // 12 V barrel jack, left wall
btn_y4 = -31;   btn_z4 = 14;   btn_d4 = 12.5;      // power button (to J42 - verify the pins on the carrier), left wall

// ---- ring / cap -------------------------------------------------------------------------------------------------------
ring_ro = 54.5;  ring_ri = 50.5;
u_gap = 16;                                    // lid top -> servo's strap (room for the plugs + the adapter)
z_pt = wall_top + u_gap + strap_t - z_case_bot;      // plate top (stand z = 0 here)
ring_top = z_pt - plate_t;                     // the cap sits on it
ring_h = ring_top - wall_top;
lug_r = 47.5;  cap_r = 47.5;
lid_pts4 = [for (sx = [-1, 1], sy = [-1, 1]) [sx * 51, sy * 52]];                   // corner screws (lid)
ring_pts4 = [[lug_r, 0], [-lug_r, 0], [0, lug_r], [0, -lug_r]];                       // cardinal bosses (ring)

module v4rr(w, d, r, h) linear_extrude(h) offset(r = r) square([w - 2 * r, d - 2 * r], center = true);
module strip4(p) {                             // wall strips beside a boss: one per wall it is near
    if (abs(p[0]) > 40) translate([sign(p[0]) * (vx + 1.5), p[1]]) square([3, 18], center = true);
    if (abs(p[1]) > 40) translate([p[0], sign(p[1]) * (vy + 1.5)]) square([18, 3], center = true);
}
module boss4(p, d = 10, depth = 12) hull() {   // boss + solid web into the wall(s), tapering to a root 'depth' lower
    translate([0, 0, ledge_z - 0.01]) linear_extrude(0.01) hull() { translate(p) circle(d = d, $fn = 40); strip4(p); }
    translate([0, 0, ledge_z - depth]) linear_extrude(0.01) hull() { translate(p) circle(d = 0.01); strip4(p); }
}
module bosses4() intersection() {
    union() { for (p = concat(lid_pts4, ring_pts4)) boss4(p); }
    translate([0, 0, bfl]) v4rr(bw - 1, bd - 1, brr - 0.5, wall_top);
}

// ==== TUB =============================================================================================================
module cavity4() {
    translate([0, 0, bfl]) v4rr(b_in[0], b_in[1], brr - bwt, ledge_z - ledge_w - bfl + 0.01);          // below the funnel
    hull() {                                                                                            // 45 deg fillet under the ledge
        translate([0, 0, ledge_z - ledge_w]) v4rr(b_in[0], b_in[1], brr - bwt, 0.01);
        translate([0, 0, ledge_z - 0.01]) v4rr(b_in[0] - 2 * ledge_w, b_in[1] - 2 * ledge_w, 5, 0.01);
    }
    translate([0, 0, ledge_z - 0.02]) v4rr(b_in[0], b_in[1], brr - bwt, wall_top - ledge_z + 1);       // the lid's pocket
}
module tub4() difference() {
    union() {
        difference() { v4rr(bw, bd, brr, wall_top); cavity4(); }
        bosses4();
        for (p = orin_pts) translate([p[0], p[1], bfl - 0.01]) cylinder(d = 8, h = so4 + 0.01, $fn = 40);
        for (p = fuse_pts4) translate([p[0], p[1], bfl - 0.01]) cylinder(d = 7, h = so4 + 0.01, $fn = 40);
    }
    for (p = concat(lid_pts4, ring_pts4)) translate([p[0], p[1], ledge_z - insert_m25[1]]) cylinder(d = insert_m25[0], h = insert_m25[1] + 1, $fn = 24);
    for (p = orin_pts) translate([p[0], p[1], bfl + so4 - insert_m3[1]]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
    for (p = fuse_pts4) translate([p[0], p[1], bfl + so4 - insert_m3[1]]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
    // back wall: service window over the Orin's ports (trapezoid, 45 deg top corners)
    translate([0, -vy + 1, 0]) rotate([90, 0, 0]) linear_extrude(6) polygon([[-47, 8], [47, 8], [37, 18], [-37, 18]]);
    // left wall: 12 V jack, power button, inlet slots over the heatsink; right wall: inlet slots
    translate([-bw / 2 - 1, jack_y4, jack_z4]) rotate([0, 90, 0]) cylinder(d = jack_d4, h = bwt + 2, $fn = 40);
    translate([-bw / 2 - 1, btn_y4, btn_z4]) rotate([0, 90, 0]) cylinder(d = btn_d4, h = bwt + 2, $fn = 40);
    for (i = [0 : 5]) {
        translate([-bw / 2 - 1, -10 + i * 7, 12]) cube([bwt + 2, 2.6, 18]);
        translate([bw / 2 - bwt - 1, -10 + i * 7, 12]) cube([bwt + 2, 2.6, 18]);
    }
}

// ==== LID =============================================================================================================
module lid4() difference() {
    translate([0, 0, ledge_z]) v4rr(b_in[0] - 0.5, b_in[1] - 0.5, brr - bwt - 0.25, lid_t4);
    for (p = concat(lid_pts4, ring_pts4)) translate([p[0], p[1], ledge_z - 1]) cylinder(d = 2.7 + cal_hole, h = lid_t4 + 2, $fn = 24);
    translate([slot4[0][0], slot4[1][0], ledge_z - 1]) cube([slot4[0][1] - slot4[0][0], slot4[1][1] - slot4[1][0], lid_t4 + 2]);
}

// ==== RING (stationary cylinder) ======================================================================================
module ring4() difference() {
    union() {
        translate([0, 0, wall_top]) difference() { cylinder(r = ring_ro, h = ring_h, $fn = 160); translate([0, 0, -1]) cylinder(r = ring_ri, h = ring_h + 2, $fn = 160); }
        for (a = [0, 90, 180, 270]) rotate(a) hull() {                                      // bottom lugs (bolts down into the bosses)
            translate([lug_r, 0, wall_top]) cylinder(d = 9, h = 4, $fn = 32);
            translate([ring_ri + 0.5, 0, wall_top]) cylinder(d = 14, h = 4, $fn = 32);
        }
        for (a = [45, 135, 225, 315]) rotate(a) hull() {                                    // top bumps (inserts for the cap)
            translate([cap_r, 0, ring_top - 8]) cylinder(d = 8, h = 8, $fn = 32);
            translate([ring_ri + 0.5, 0, ring_top - 8]) cylinder(d = 12, h = 8, $fn = 32);
        }
    }
    for (p = ring_pts4) translate([p[0], p[1], wall_top - 1]) cylinder(d = 2.7 + cal_hole, h = 6, $fn = 24);
    for (a = [45, 135, 225, 315]) rotate(a) translate([cap_r, 0, ring_top - insert_m25[1]]) cylinder(d = insert_m25[0], h = insert_m25[1] + 1, $fn = 24);
}

// ==== CAP: the stand's base() + the disc that closes the ring =========================================================
module cap4() {
    base();                                                                                 // plate, sleeve, stop rails (stand frame: plate top z = 0)
    difference() {
        translate([0, 0, -plate_t]) cylinder(r = ring_ro, h = plate_t, $fn = 160);
        translate([0, 0, -plate_t - 1]) linear_extrude(plate_t + 2)
            translate([(plate[0][0] + plate[0][1]) / 2, (plate[1][0] + plate[1][1]) / 2])
                rrect([plate[0][1] - plate[0][0] - 0.2, plate[1][1] - plate[1][0] - 0.2], 6);   // leaves the stand's plate (it overlaps by 0.1)
        for (a = [45, 135, 225, 315]) rotate(a) translate([cap_r, 0, -plate_t - 1]) cylinder(d = 2.7 + cal_hole, h = plate_t + 2, $fn = 24);
    }
}

// ==== ghosts + view ====================================================================================================
module cutv(on = true) difference() { union() children(); if (on && cut_v4) translate([0, -300, -400]) cube([300, 600, 900]); }
module ghosts4() {
    color("#2e7d32") translate([-orin[0] / 2, orin_y - orin[1] / 2, bfl + so4]) cube(orin);
    color("#9aa0a6") translate([-35, orin_y - 25 + 2, bfl + so4 + orin[2]]) cube([70, 50, fan4]);
    color("#00897b") translate([fuse4[0], fuse4[1], bfl + so4]) cube(fuse_blk4);
    color("#2a6a3a") translate([-16.5, -8, wall_top + 2]) cube([33, 42, 12]);                  // servo adapter, lying on the lid under the servo
}
module skirt4() color("#d9dde2") difference() {                                              // rotating skirt: hangs from the turret floor over the ring
    translate([0, 0, ring_top - 11]) cylinder(r = 57.5, h = z_pt + z_floor - (ring_top - 11), $fn = 160);
    translate([0, 0, ring_top - 12]) cylinder(r = 56, h = z_pt + z_floor - (ring_top - 12) - floor_t, $fn = 160);
}
if (part == "v4_view") {
    cutv() { color("#6b8fb5") tub4(); color("#b5c4d6") lid4(); color("#8fa9c4") ring4(); color("#6b8fb5") translate([0, 0, z_pt]) cap4(); skirt4(); }
    ghosts4();
    translate([0, 0, z_pt]) assembly();
    echo(str("base ", bw, " x ", bd, " x ", wall_top, "; plate top z ", z_pt, "; turret floor top z ", z_pt + z_ft, "; axle z ", z_pt + z_axle,
             "; head top ~", z_pt + z_axle + 22, "; ring height ", ring_h));
}
if (part == "v4_tub") tub4();
if (part == "v4_lid") translate([0, 0, -ledge_z]) lid4();
if (part == "v4_ring") translate([0, 0, -wall_top]) ring4();
if (part == "v4_cap") rotate([180, 0, 0]) cap4();
