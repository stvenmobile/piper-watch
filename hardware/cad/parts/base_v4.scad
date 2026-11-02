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
ledge_w = 6;  lid_t4 = 6;  ledge_z = 54;      // 60 mm box: lid underside 54 leaves ~22 mm over the Orin's fan (to confirm)
wall_top = ledge_z + lid_t4;                  // 60
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

// ==== TURRET v4 + HEAD v4 (stand frame: pan axis = origin, z = 0 at the plate top) =========================================
// The head is a VERTICAL camera plate carried 20 mm in front of the tilt axle by two arms; the axle is only 32 mm above the floor.
// The tilt servo lies behind the axle on the LEFT (x -22..10) and pulls a short, nearly horizontal rod to a crank on the left arm.
ax_y = 18;  ax_z = z_ft + 26;                   // tilt axle (along X): forward, so the lens sits ~5 mm inside the rim
ch_x = [42, 50];  ch_t4 = 8;                    // cheeks (608 pocket each), outer face r < 54.5 at y +-16
arm_x = [38, 41];                               // pivot arms, 3 thick, inside the cheeks (1 mm washer gap)
pl_x = 38;  pl_y = [14, 18];  pl_h = 30;        // camera plate: half-width, forward of the axle (rear/front face), height
tsv = [-22, 10];  tsv_y = [-48.5, -48.5 + 45.22];  tsv_z = [z_ft, z_ft + 24.72];       // tilt servo body: x, y, z (shaft along X, near its back end)
tsh = [-22, tsv_y[0] + 10.11, z_ft + 12.36];    // shaft: x of the horn face, y, z
// linkage (solved: monotonic over -25 .. +45 deg; wanted -22 .. +23)
cr_s = 14;  sa0 = 100;                          // servo crank length, its angle at tilt 0 (from +Y, counter-clockwise seen from +X)
cr_h = 17;  hb0 = 210;                          // head crank length, its direction at tilt 0 (210 = down and back)
rod_L = 44.9;                                   // pin centre to pin centre (planar; +1.5 for the 6 mm X offset)
show_fov = false;  fov_v = 43;                 // draw the camera's centre ray and its vertical field of view (C920 ~43 deg, to confirm)
tilt4 = 0;  sa4 = 100;                          // pose for the picture: head tilt (nose up +) and the servo angle that goes with it
pin_s = [-27, tsh[1] + cr_s * cos(sa4), tsh[2] + cr_s * sin(sa4)];                     // servo crank pin
pin_h = [-33, ax_y + cr_h * cos(hb0 + tilt4), ax_z + cr_h * sin(hb0 + tilt4)];         // head crank pin (moves with the head)
hub_a = 30;                                     // flange screws at 30/120/210/300 deg: none under the tilt servo

module hub4() difference() {                    // the stand's hub, its four flange inserts turned to hub_a + k*90 to clear the tilt servo
    union() {
        translate([0, 0, z_horn]) cylinder(d = hub_od, h = z_flange - z_horn + 0.01, $fn = 96);
        translate([0, 0, z_flange]) cylinder(d = flange_d, h = flange_t, $fn = 128);
    }
    translate([0, 0, z_horn + hub_end]) cylinder(d = hub_id, h = 200, $fn = 64);
    translate([0, 0, z_horn - 1]) cylinder(d = 6.5, h = hub_end + 2, $fn = 32);
    for (a = [45 : 90 : 360]) rotate(a) translate([pcd / 2, 0, z_horn - 1]) {
        hole3(hub_end + 2);
        translate([0, 0, hub_end + 1]) cylinder(d = 6.2, h = 10, $fn = 24);
    }
    translate([0, 0, z_horn + hub_end + win[1] / 2 + 1]) rotate([0, 90, 0]) linear_extrude(hub_od) square([win[1], win[0]], center = true);
    for (a = [hub_a : 90 : 360]) rotate(a) translate([flange_r, 0, z_flange + flange_t - insert_m3[1]]) insert3();
}
module turret4() difference() {
    union() {
        translate([0, 0, z_floor]) linear_extrude(floor_t) intersection() { circle(r = 57.5, $fn = 160); square([116, 116], center = true); }
        // cradle for the tilt servo: low walls round its footprint, closed at the shaft end only
        difference() {
            box([tsv[0] - 3, tsv[1] + 3], [tsv_y[0] - 3, tsv_y[1] + 3], [z_ft - 0.01, z_ft + 10]);
            box([tsv[0], tsv[1]], [tsv_y[0], tsv_y[1]], [z_ft - 1, z_ft + 11]);
            box([tsv[0] - 4, tsv[0] + 1], [tsv_y[0] + 20, tsv_y[0] + 40], [z_ft + 3, z_ft + 11]);           // the horn side open
        }
        for (s = [-1, 1]) hull() {                                                                         // cheeks
            box(s > 0 ? ch_x : [-ch_x[1], -ch_x[0]], [ax_y - 10, ax_y + 10], [z_ft - 0.01, z_ft + 6]);
            translate([s > 0 ? ch_x[0] : -ch_x[1], ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 34, h = ch_t4, $fn = 60);
        }
    }
    translate([0, 0, z_floor - 1]) cylinder(d = 18, h = floor_t + 2, $fn = 48);                          // cables down the hub
    for (a = [hub_a : 90 : 360]) rotate(a) translate([flange_r, 0, z_floor - 1]) hole3(floor_t + 2);        // 4 x M3 into the hub flange
    for (s = [-1, 1]) {                                                                                   // 608 pockets from the inner faces
        translate([s > 0 ? ch_x[0] - 0.01 : -ch_x[0] - 7.99, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = pivot_pocket + cal_hole, h = 8, $fn = 100);
        translate([s > 0 ? ch_x[0] : -ch_x[1] - 1, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 12 + cal_hole, h = ch_t4 + 1, $fn = 48);
    }
}
module head4() translate([0, ax_y, ax_z]) rotate([tilt4, 0, 0]) translate([0, -ax_y, -ax_z]) {
    color("#8a8d91") translate([-pl_x, ax_y + pl_y[0], ax_z - pl_h / 2]) cube([2 * pl_x, pl_y[1] - pl_y[0], pl_h]);           // camera plate
    for (s = [-1, 1]) color("#6b8fb5") hull() {                                                                              // arms
        translate([s > 0 ? arm_x[0] : -arm_x[1], ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 16, h = 3, $fn = 40);
        translate([s > 0 ? arm_x[0] : -arm_x[1], ax_y + pl_y[0], ax_z - pl_h / 2]) cube([3, pl_y[1] - pl_y[0], pl_h]);
    }
    for (s = [-1, 1]) color("#6b8fb5") translate([s > 0 ? arm_x[1] : -ch_x[1] - 0.5, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 8, h = (s > 0 ? ch_x[1] - arm_x[1] : ch_x[1] - arm_x[1] + 0.5 + (ch_x[1] - ch_x[1])) + 0.01, $fn = 24);   // axle stubs (into the 608s)
    color("#6b8fb5") hull() {                                                                                                  // crank bracket on the left arm
        translate([-arm_x[1] - 0.01, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 12, h = 3.01, $fn = 32);
        translate([pin_h[0] + 1, ax_y + cr_h * cos(hb0), ax_z + cr_h * sin(hb0)]) rotate([0, 90, 0]) cylinder(d = 8, h = 6, $fn = 24);
    }
    if (part == "v4_view") {
    color("#222") translate([-40, ax_y + pl_y[1], ax_z - 11]) cube([80, 10, 22]);                                          // camera board (80 x 22 to confirm)
    color("#111") translate([0, ax_y + pl_y[1] + 10, ax_z]) rotate([-90, 0, 0]) cylinder(d = 16, h = 3, $fn = 40);        // lens
    }
}
module crank4() color("#e8a33d") hull() {
    translate([tsh[0] - 3, tsh[1], tsh[2]]) rotate([0, 90, 0]) cylinder(d = 10, h = 5, $fn = 30);
    translate([pin_s[0] - 1, pin_s[1], pin_s[2]]) rotate([0, 90, 0]) cylinder(d = 7, h = 4, $fn = 24);
}
module tilt_rod4() color("#c0392b") hull() {
    translate(pin_s) rotate([0, 90, 0]) cylinder(d = 4, h = 5, center = true, $fn = 20);
    translate(pin_h) rotate([0, 90, 0]) cylinder(d = 4, h = 5, center = true, $fn = 20);
}
module turret_stack4() {                        // everything above the lid, stand frame
    color("#6b8fb5") base();
    color("#2b2b2b") translate([0, 0, z_case_bot - strap_t]) pan_strap();
    color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);                                                     // pillow block
    translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();                                                  // pan servo
    color("#e8a33d") hub4();
    color("#6b8fb5") turret4();
    color("#b0b6bd") translate([tsv[0], tsv_y[0], tsv_z[0]]) cube([tsv[1] - tsv[0], tsv_y[1] - tsv_y[0], tsv_z[1] - tsv_z[0]]);   // tilt servo
    color("#e8a33d") translate([tsh[0] - 3, tsh[1], tsh[2]]) rotate([0, 90, 0]) cylinder(d = 24, h = 3, $fn = 40);        // its horn
    crank4();
    tilt_rod4();
    head4();
    if (show_fov) for (da = [-fov_v / 2, 0, fov_v / 2]) color(da == 0 ? "#ffd400" : "#ff7a00") {
        a = tilt4 + da;  l0 = [ax_y + (pl_y[1] + 13) * cos(tilt4), ax_z + (pl_y[1] + 13) * sin(tilt4)];       // the lens
        hull() { translate([0, l0[0], l0[1]]) cube(0.8, center = true); translate([0, l0[0] + 220 * cos(a), l0[1] + 220 * sin(a)]) cube(0.8, center = true); }
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
module surround4() color("#d9dde2") difference() {                                         // rotating: hangs from the turret floor over the skirt's top
    union() {
        translate([0, 0, z_pt - 12]) cylinder(r = 57.5, h = z_floor + 12, $fn = 160);
    }
    translate([0, 0, z_pt - 13]) cylinder(r = 54.5, h = z_floor + 13 - floor_t + 0.01, $fn = 160);
}
if (part == "v4_view") {
    cutv() { color("#6b8fb5") tub4(); color("#b5c4d6") lid4(); color("#8fa9c4") translate([0, 0, z_pt]) skirt_extra4(); surround4(); }
    ghosts4();
    translate([0, 0, z_pt]) turret_stack4();
    echo(str("base ", bw, " x ", bd, " x ", wall_top, "; plate top z ", z_pt, "; turret floor top z ", z_pt + z_ft, "; axle z ", z_pt + ax_z,
             "; head top ~", z_pt + ax_z + pl_h / 2, "; wall ", wall_h4, " tall, skirt ", z_pt - sk_z0 + 0, " tall"));
}
if (part == "v4_tub") tub4();
if (part == "v4_lid") translate([0, 0, -ledge_z]) lid4();
if (part == "v4_skirt") rotate([180, 0, 0]) skirt4s();
if (part == "v4_turret") translate([0, 0, -z_floor]) turret4();
if (part == "v4_head") translate([0, 0, -(ax_z - pl_h / 2)]) head4();
