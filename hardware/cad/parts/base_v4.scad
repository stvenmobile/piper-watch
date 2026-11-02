// BASE v4 - electronics box + stationary pan cylinder on the test stand's pillow-block stack.
//
//   TUB    rounded-square box (118 x 120) holding ONLY the Orin NX carrier (+ fuse/terminal block). Its top has a 45-deg-filleted LEDGE
//          (6 mm) with a pocket above it: the flat LID drops into the pocket and sits on the ledge, flush with the wall tops.
//          The Orin stands forward; its ports face a PLUG ZONE (28 mm) at the back: the 12 V jack, the power button and the fuse /
//          terminal block live there, and the lid's cable slot drops straight into it - so every cable from the head reaches an
//          Orin jack INSIDE the case. 4 corner bosses (M2.5 inserts, lid) + 4 cardinal bosses (M2.5 inserts, lid; they hold the lid down under the skirt's edge), each tied to the walls by a web.
//   LID    6 mm flat sheet + the wall (see below), cable slot over the plug zone, 8 M2.5 holes.
//   WALL   the stationary cylinder (OD 97, wall 3), printed as ONE PIECE with the lid: it rises from the lid top, 32 tall, with four
//          solid columns on its inside carrying M2.5 heat-set inserts (radial, at 90 deg).
//   SKIRT  the outer cylinder (OD 106) that slips over the wall and carries the stand's pan stack: its top is the stand's plate + servo
//          sleeve (base()), widened to a disc. Four M2.5 bolts go radially through the skirt into the wall's inserts. The pan servo
//          hangs from the plate inside the wall; the pillow block, hub and turret are the stand's, unchanged.
//   SURROUND  the rotating part of the turret: a short cylinder that hangs from the turret floor over the skirt's top.
//   The servo ADAPTER lies on the lid under the pan servo (inside the cylinder); its USB-C and 12 V leads go down the lid slot.
//
// Frame: pan axis = (0,0) = the box centre; Z = 0 under the box floor; +Y = front (cylinder/head side), back wall at Y = -60.
// part = "v4_view" | "v4_tub" | "v4_lid" (with the wall) | "v4_skirt"
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

// ---- wall / skirt ---------------------------------------------------------------------------------------------------
wall_ro = 48.5;  wall_t4 = 3;  wall_ri = wall_ro - wall_t4;  wall_h4 = 32;
sk_ri = 49;  sk_ro = 53;                       // skirt: 0.5 clear of the wall, 4 thick
sk_z0 = wall_top + 2;                          // skirt's lower edge (hovers 2 mm over the lid)
bolt_z = wall_top + 17;                        // the four radial bolts: 15 above the skirt's lower edge, 15 below the wall's top
u_gap = 16;                                    // lid top -> servo's strap (room for the plugs + the adapter)
z_pt = wall_top + u_gap + strap_t - z_case_bot;      // plate top (stand z = 0 here)
lid_pts4 = [for (sx = [-1, 1], sy = [-1, 1]) [sx * 51, sy * 52]];                   // corner screws (lid)
card_pts4 = [[52, 0], [-52, 0], [0, 52], [0, -52]];                                   // cardinal screws (lid), under the skirt's edge: countersunk

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
    union() { for (p = concat(lid_pts4, card_pts4)) boss4(p); }
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
    for (p = concat(lid_pts4, card_pts4)) translate([p[0], p[1], ledge_z - insert_m25[1]]) cylinder(d = insert_m25[0], h = insert_m25[1] + 1, $fn = 24);
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

// ==== LID + WALL (one piece) ==========================================================================================
module lid4() difference() {
    union() {
        translate([0, 0, ledge_z]) v4rr(b_in[0] - 0.5, b_in[1] - 0.5, brr - bwt - 0.25, lid_t4);
        translate([0, 0, wall_top]) cylinder(r = wall_ro, h = wall_h4, $fn = 160);                          // the wall ...
        for (a = [0, 90, 180, 270]) rotate(a) translate([wall_ri - 0.5, 0, wall_top]) cylinder(d = 9, h = bolt_z + 6 - wall_top, $fn = 32);   // ... + 4 columns
    }
    translate([0, 0, wall_top - 0.01]) difference() {                                                    // hollow inside the wall (columns stay)
        cylinder(r = wall_ri, h = wall_h4 + 1, $fn = 160);
        for (a = [0, 90, 180, 270]) rotate(a) translate([wall_ri - 0.5, 0, 0]) cylinder(d = 9, h = bolt_z + 6 - wall_top + 0.01, $fn = 32);
    }
    for (p = lid_pts4) translate([p[0], p[1], ledge_z - 1]) cylinder(d = 2.7 + cal_hole, h = lid_t4 + 2, $fn = 24);
    for (p = card_pts4) translate([p[0], p[1], ledge_z - 1]) {                                          // countersunk (heads sit under the skirt's edge)
        cylinder(d = 2.7 + cal_hole, h = lid_t4 + 2, $fn = 24);
        translate([0, 0, lid_t4 - 1.5 + 1]) cylinder(d1 = 2.7, d2 = 5.2, h = 1.5 + 0.01, $fn = 24);
    }
    translate([slot4[0][0], slot4[1][0], ledge_z - 1]) cube([slot4[0][1] - slot4[0][0], slot4[1][1] - slot4[1][0], lid_t4 + 2]);
    for (a = [0, 90, 180, 270]) rotate(a) translate([wall_ro - insert_m25[1] - 0.01, 0, bolt_z]) rotate([0, 90, 0])      // radial inserts, from the outside
        cylinder(d = insert_m25[0], h = insert_m25[1] + 1, $fn = 24);
}

// ==== SKIRT: the stand's base() + the tube and disc that carry it ======================================================
module skirt_extra4() difference() {
    union() {
        translate([0, 0, -plate_t]) cylinder(r = sk_ro, h = plate_t, $fn = 160);                          // disc under the pillow block
        translate([0, 0, sk_z0 - z_pt]) cylinder(r = sk_ro, h = z_pt - sk_z0, $fn = 160);                  // tube down over the wall
    }
    translate([0, 0, sk_z0 - z_pt - 1]) cylinder(r = sk_ri, h = z_pt - sk_z0 - plate_t + 1, $fn = 160);    // hollow
    translate([0, 0, -plate_t - 1]) linear_extrude(plate_t + 2)                                           // leave the stand's plate to base()
        translate([(plate[0][0] + plate[0][1]) / 2, (plate[1][0] + plate[1][1]) / 2])
            rrect([plate[0][1] - plate[0][0] - 0.2, plate[1][1] - plate[1][0] - 0.2], 6);
    for (a = [0, 90, 180, 270]) rotate(a) translate([sk_ri - 1, 0, bolt_z - z_pt]) rotate([0, 90, 0]) {   // 4 radial bolts: clearance + a shallow head recess
        cylinder(d = 2.7 + cal_hole, h = sk_ro - sk_ri + 2, $fn = 24);
        translate([0, 0, sk_ro - sk_ri + 1 - 1.4]) cylinder(d = 5, h = 2, $fn = 24);
    }
}
module skirt4s() { base(); skirt_extra4(); }

// ==== ghosts + view ====================================================================================================
module cutv(on = true) difference() { union() children(); if (on && cut_v4) translate([0, -300, -400]) cube([300, 600, 900]); }
module ghosts4() {
    color("#2e7d32") translate([-orin[0] / 2, orin_y - orin[1] / 2, bfl + so4]) cube(orin);
    color("#9aa0a6") translate([-35, orin_y - 25 + 2, bfl + so4 + orin[2]]) cube([70, 50, fan4]);
    color("#00897b") translate([fuse4[0], fuse4[1], bfl + so4]) cube(fuse_blk4);
    color("#2a6a3a") translate([-16.5, -8, wall_top + 2]) cube([33, 42, 12]);                  // servo adapter, lying on the lid under the servo
}
module surround4() color("#d9dde2") difference() {                                         // rotating: hangs from the turret floor over the skirt's top
    union() {
        translate([0, 0, z_pt - 12]) cylinder(r = 57.5, h = z_floor + 12, $fn = 160);
    }
    translate([0, 0, z_pt - 13]) cylinder(r = 54.5, h = z_floor + 13 - floor_t + 0.01, $fn = 160);
}
if (part == "v4_view") {
    cutv() { color("#6b8fb5") tub4(); color("#b5c4d6") lid4(); color("#8fa9c4") translate([0, 0, z_pt]) skirt_extra4(); surround4(); }
    ghosts4();
    translate([0, 0, z_pt]) assembly();
    echo(str("base ", bw, " x ", bd, " x ", wall_top, "; plate top z ", z_pt, "; turret floor top z ", z_pt + z_ft, "; axle z ", z_pt + z_axle,
             "; head top ~", z_pt + z_axle + 22, "; wall ", wall_h4, " tall, skirt ", z_pt - sk_z0 + 0, " tall"));
}
if (part == "v4_tub") tub4();
if (part == "v4_lid") translate([0, 0, -ledge_z]) lid4();
if (part == "v4_skirt") rotate([180, 0, 0]) skirt4s();
