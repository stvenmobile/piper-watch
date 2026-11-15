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
oled_head = true;                               // true: tall plate carrying the 2.08" OLED (eyes) under the camera; false: the plain 30 mm plate
pl_x = 38;  pl_y = [14, 18];                    // camera plate: half-width, forward of the axle (rear/front face)
pl_z = oled_head ? [-20, 30] : [-15, 15];       // plate bottom/top relative to the axle (bottom limited by the floor at -22 deg tilt)
pl_h = pl_z[1] - pl_z[0];
lens_z = oled_head ? 18 : 0;                    // lens height above the axle (OLED head: camera on top, the "third eye")
oz = -7.5;  ox = -3.9;                          // OLED centre: height rel. the axle; active area is 3.9 mm left of the PCB centre (header end)
tsv = [-22, 10];  tsv_y = [-48.5, -48.5 + 45.22];  tsv_z = [z_ft, z_ft + 24.72];       // tilt servo body: x, y, z (shaft along X, near its back end)
tsh = [-22, tsv_y[1] - 10.11, z_ft + 12.36];    // shaft: x of the horn face, y, z
// linkage (solved: monotonic over -25 .. +45 deg; wanted -22 .. +23)
cr_s = 12;  sa0 = 75.7;                         // servo crank length, its angle at tilt 0 (from +Y, counter-clockwise seen from +X); the servo is turned end for end (shaft 13.4 behind the rod's front)
cr_h = 11;  hb0 = 255;                         // head crank length, its direction at tilt 0 (255 = down and a little back)
rod_L = 27;                                     // pin centre to pin centre (planar; about 28 with the 7 mm X offset)
show_cowl = true;  show_fov = false;  fov_v = 43;                 // draw the camera's centre ray and its vertical field of view (C920 ~43 deg, to confirm)
show_camframe = true;                               // false for the one-piece head concept (head_v5_concept.scad)
cam_dx = 0;                                       // camera stack's x shift (head_v5: lens centred on the OLED window)
xp_cam = 0;  xp_cov = 0;  xp_oled = 0;                 // exploded-view offsets for the head renders (mm along y)
tilt4 = 0;  sa4 = 75.7;                          // pose for the picture: head tilt (nose up +) and the servo angle that goes with it
pin_s = [-33.5, tsh[1] + cr_s * cos(sa4), tsh[2] + cr_s * sin(sa4)];                     // servo crank pin: the rod end's centre (5 wide: x -36 .. -31, outside the crank's pin boss)
pin_h = [-26.5, ax_y + cr_h * cos(hb0 + tilt4), ax_z + cr_h * sin(hb0 + tilt4)];         // head crank pin: rod end centre (x -29 .. -24, on the inner face of the bracket's boss)
xi_x = [27.5, 49.3];  xi_y = [-15.2, 3.4];     // XIAO ESP32-S3 pocket interior (board 21 x 17.8 + 0.4 each side; USB-C end at x min, pointing at the hub hole)
stub_d = 7.85;                                  // axle stubs into the 608 bores (8.0): 0.15 slip, like the stand's hub (CHECK on the first print)
hub_a = 35;                                     // flange screws at 35/125/215/305 deg
flange_d = 82;  flange_r = 36;                  // wider flange (the stand's is 66 / r 29): the four screws sit >= 4.5 from the cradle walls, strap posts and XIAO pocket

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
// tilt servo hold-down: two posts beside the cradle's side walls (M3 insert in each top) and a flat strap across the servo's top, 2 x M3 x 8
sb_x = [[-33, -22], [10, 21]];  sb_y = [-42, -34];  sb_t = 3;
sb_top = z_ft + (tsv_z[1] - tsv_z[0]);          // servo top face
// cowl screws: two M3 x 8 button-head screws go in from OUTSIDE, radially through the cowl wall (head in a counterbore) into M3 inserts pressed
// (cowl off) into the outer faces of two posts on the turret floor. Posts stand 0.5 inside the cowl wall, behind the head, clear of the cradle, strap posts, XIAO pocket and crank.
cs_ang = [215, 325];  cs_z = 7;  cs_in = 54.5;  cs_r0 = 46;  cs_w = 10;  cs_h = 14;
// fillets where the turret's raised features meet the floor: concave quarter-round, radius fl_r, built from thin stepped layers on the outer footprints
// (never inside the servo cradle or XIAO pocket, never across the cable openings / hub hole / flange screws, never into the cowl wall or the cowl's cheek notch)
fl_r = 2;  fl_n = 8;
module feet2d() {
    translate([tsv[0] - 3, tsv_y[0] - 3]) square([tsv[1] - tsv[0] + 6, tsv_y[1] - tsv_y[0] + 6]);              // servo cradle
    translate([xi_x[0] - 2, xi_y[0] - 2]) square([xi_x[1] - xi_x[0] + 4, xi_y[1] - xi_y[0] + 4]);              // XIAO pocket
    for (b = sb_x) translate([b[0], sb_y[0]]) square([b[1] - b[0], sb_y[1] - sb_y[0]]);                       // strap posts
    for (a = cs_ang) rotate(a) translate([cs_r0, -cs_w / 2]) square([cs_in - cs_r0, cs_w]);                  // cowl screw posts
    for (c = [ch_x, [-ch_x[1], -ch_x[0]]]) translate([c[0], ax_y - 10]) square([c[1] - c[0], 20]);              // cheeks
}
module fillet_ring2d(d) difference() {
    intersection() {
        offset(delta = d) feet2d();
        circle(r = 54.4, $fn = 160);
    }
    feet2d();
    translate([xi_x[0] - 30, xi_y[0] - 1]) square([30, xi_y[1] - xi_y[0] + 2]);                               // the XIAO plug's way out
    translate([tsv[1] - 2, xi_y[0] - 1]) square([8, 1 - xi_y[0]]);                                              // and the cable's way through the cradle's right wall
    translate([tsv[0] - 6, tsv_y[0] + 17]) square([8, 25]);                                                    // horn side opening
    translate([-60, cw_y - cw_t - 0.1]) square([120, cw_t + 0.2]);                                              // the cowl's front wall (y 5.5 .. 8)
    circle(d = 20, $fn = 48);                                                                                  // hub hole
    for (a = [hub_a : 90 : 360]) rotate(a) translate([flange_r, 0]) circle(d = 9, $fn = 24);                   // flange screws
    for (sx = [-1, 1]) translate([sx > 0 ? 38 : -54, -60]) square([16, 68]);                                    // cowl's cheek notch: no fillet behind y = 8
}
module fillets4() for (k = [0 : fl_n - 1]) {
    t = fl_r / fl_n;  z = k * t;  d = fl_r - sqrt(fl_r * fl_r - (fl_r - z - t / 2) * (fl_r - z - t / 2));
    translate([0, 0, z_ft - 0.01 + z]) linear_extrude(t + 0.01) fillet_ring2d(d);
}
module strap4() color("#6b8fb5") difference() {
    box([sb_x[0][0], sb_x[1][1]], sb_y, [sb_top, sb_top + sb_t]);
    for (b = sb_x) translate([(b[0] + b[1]) / 2, (sb_y[0] + sb_y[1]) / 2, sb_top - 1]) hole3(sb_t + 2);
}
module turret4() difference() {
    union() {
        translate([0, 0, z_floor]) linear_extrude(floor_t) intersection() { circle(r = 57.5, $fn = 160); square([116, 116], center = true); }
        // cradle for the tilt servo: low walls round its footprint, closed at the shaft end only (corners trimmed to r 54.5 inside the cowl)
        intersection() { translate([0, 0, z_ft - 1]) cylinder(r = 54.5, h = 40, $fn = 160);
        difference() {
            box([tsv[0] - 3, tsv[1] + 3], [tsv_y[0] - 3, tsv_y[1] + 3], [z_ft - 0.01, z_ft + 10]);
            box([tsv[0], tsv[1]], [tsv_y[0], tsv_y[1]], [z_ft - 1, z_ft + 11]);
            box([tsv[0] - 4, tsv[0] + 1], [tsv_y[0] + 20, tsv_y[0] + 40], [z_ft + 3, z_ft + 11]);           // the horn side open
            box([tsv[0] - 4, tsv[0] + 1], [tsh[1] - 11, tsh[1] + 11], [z_ft + 1, z_ft + 11]);                  // and round the shaft: the crank hub (d 10, centre z_ft + 12.4) swings through
            box([tsv[1] - 1, tsv[1] + 4], [xi_y[0], 0], [z_ft - 1, z_ft + 11]);                              // and at the +y end of the right wall: the XIAO's USB plug and cable come through here
        }
        }
        fillets4();
        for (a = cs_ang) rotate(a) translate([cs_r0, -cs_w / 2, z_ft - 0.01]) cube([cs_in - cs_r0, cs_w, cs_h + 0.01]);   // cowl screw posts
        for (b = sb_x) box(b, sb_y, [z_ft - 0.01, sb_top]);                                                  // hold-down posts (insert in the top)
        difference() {                                                                                       // pocket for the XIAO ESP32-S3 (hot-glued in; no holes), the USB-C end open toward -x
            box([xi_x[0] - 2, xi_x[1] + 2], [xi_y[0] - 2, xi_y[1] + 2], [z_ft - 0.01, z_ft + 5]);
            box([xi_x[0], xi_x[1]], [xi_y[0], xi_y[1]], [z_ft - 1, z_ft + 6]);
            box([xi_x[0] - 3, xi_x[0] + 0.1], [xi_y[0], xi_y[1]], [z_ft - 1, z_ft + 6]);
        }
        for (s = [-1, 1]) hull() {                                                                         // cheeks
            box(s > 0 ? ch_x : [-ch_x[1], -ch_x[0]], [ax_y - 10, ax_y + 10], [z_ft - 0.01, z_ft + 6]);
            translate([s > 0 ? ch_x[0] : -ch_x[1], ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 34, h = ch_t4, $fn = 60);
        }
    }
    for (b = sb_x) translate([(b[0] + b[1]) / 2, (sb_y[0] + sb_y[1]) / 2, sb_top - insert_m3[1]]) insert3();   // M3 inserts for the strap
    for (a = cs_ang) rotate(a) translate([cs_in + 0.01, 0, z_ft + cs_z]) rotate([0, -90, 0]) cylinder(d = insert_m3[0], h = insert_m3[1] + 0.2, $fn = 24);   // radial M3 insert bores, pressed in from the outer face
    intersection() {                                                                                      // cables down the hub: the half under the tilt servo's cradle (y < its front wall) stays solid
        translate([0, 0, z_floor - 1]) cylinder(d = 18, h = floor_t + 2, $fn = 48);
        box([-20, 20], [tsv_y[1] + 3, 20], [z_floor - 2, z_floor + floor_t + 2]);
    }
    for (a = [hub_a : 90 : 360]) rotate(a) translate([flange_r, 0, z_floor - 1]) hole3(floor_t + 2);        // 4 x M3 into the hub flange
    for (s = [-1, 1], c = cv_pts) translate([s > 0 ? ch_x[1] + 0.01 : -ch_x[1] - 0.01, ax_y + c[0], ax_z + c[1]]) rotate([0, s > 0 ? -90 : 90, 0]) cylinder(d = insert_m3[0], h = insert_m3[1] + 0.2, $fn = 24);   // M3 inserts for the cheek covers
    for (s = [-1, 1]) {                                                                                   // 608 pockets from the inner faces
        translate([s > 0 ? ch_x[0] - 0.01 : -ch_x[0] - 6.99, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = pivot_pocket + cal_hole, h = 7.01, $fn = 100);   // 608 is 7 thick: 1 mm lip left on the outer face
        translate([s > 0 ? ch_x[0] : -ch_x[1] - 1, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 12 + cal_hole, h = ch_t4 + 1, $fn = 48);
    }
}
module plate_prof() polygon([[ax_y + pl_y[0], ax_z + pl_z[0]], [ax_y + pl_y[1] - 3, ax_z + pl_z[0]], [ax_y + pl_y[1], ax_z + pl_z[0] + 3],
                             [ax_y + pl_y[1], ax_z + pl_z[1]], [ax_y + pl_y[0], ax_z + pl_z[1]]]);   // y,z section; the front-bottom edge is chamfered 3 (floor clearance)
module ext_yz(x0, x1) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) plate_prof();
module oled_cuts() translate([0, ax_y, ax_z + oz]) {                                                                        // local frame: x, y rel. the axle, z rel. the OLED centre
    translate([ox - 26.6, pl_y[0] - 2, -7.39]) cube([53.2, pl_y[1] - pl_y[0] + 4, 14.78]);                                   // window (viewing area 53.18 x 14.78)
    translate([-33.75, pl_y[0] - 1, -10.4]) cube([67.5, 2.8, 20.8]);                                                        // pocket: symmetric, 67.5 long = 1 mm short of the mounting holes (x +-36, d 2.5): takes the glass, the connector at the far end and the solder joints at the header end; 2.2 front lip
    for (sx = [-36, 36], sz = [-7.75, 7.75]) translate([sx, pl_y[0] - 1, sz]) rotate([-90, 0, 0]) cylinder(d = 1.6, h = 3.5, $fn = 16);   // M2 pilots
}
// ---- camera board on the plate's front face + the front frame that grips its lens cube --------------------------------------------
// The C920 board (82 x 23 x 1.6; the narrow middle is 17.7 wide) lies on the plate, lens cube (14 x 14 x 10.3, centred) forward. The cube's two screw
// bosses (5.1 tall, on its +-X faces) carry a 3 mm FRAME that grips the cube's top 5.2 mm in a square pocket. One M2.5 x 16 screw from the front passes the
// frame tab, the board's 4 mm edge SLOT (6 mm along from the cube, open to the bottom edge, ~5 deep) and the plate into an insert in a boss on the plate's
// rear: tightening clamps frame -> bosses -> board -> plate. (If the board is fitted the other way round, mirror slot_x.)
cb_t = 1.6;  cube_w = 14;  cube_h = 10.3;  boss_h = 5.1;  fr_t = 3;
slot_x = -15;  slot_z = lens_z - 4.8;                                       // slot centre line / the round end's centre, relative to the axle height
fr_y = pl_y[1] + cb_t + boss_h;                                              // the frame's rear face, relative to the axle's y
module cam_boss() translate([slot_x, ax_y + pl_y[0] - 4, ax_z + slot_z]) rotate([-90, 0, 0]) cylinder(d = 7.5, h = 4.01, $fn = 40);
module cam_holes() translate([slot_x, ax_y + pl_y[0] - 5, ax_z + slot_z]) rotate([-90, 0, 0]) {
    cylinder(d = 2.8 + cal_hole, h = 10, $fn = 24);                                                             // M2.5 clearance through the plate
    cylinder(d = insert_m25[0], h = insert_m25[1] + 1.5, $fn = 24);                                              // insert from the boss's rear end (y 10)
}
// EYES: the camera board's LEDs (amber SMD packages, they shine blue; D3 top-right [hidden under the cable boot in the photo, mirrored from D6] and D6 bottom-right
// in the photo) sit 30.2 mm either side of the lens and 3.1 mm off its centre line. The cover is now the whole 82 x 23 front of the head: 2.5 mm holes over
// those two LEDs, each on a short light-tight spigot, a pocket over each (unused) mic can, the lens cube through a 14.4 square hole, the screw at the board's slot.
eye_x = 30.2;  eye_z = lens_z + 3.1;  spg = 5.0;  eye_d = 3.0;  eye_seat_d = 4.8 + cal_hole;  eye_seat = 2.5;      // spigot 5.0 long: its tip stops 0.1 above the board face
module camcover() difference() {
    union() {
        translate([0, ax_y + fr_y + fr_t, ax_z]) rotate([90, 0, 0]) linear_extrude(fr_t)
            translate([0, lens_z]) offset(r = 3) square([82 - 6, 23 - 6], center = true);
        for (sx = [-1, 1]) translate([sx * eye_x, ax_y + fr_y + 0.01, ax_z + eye_z]) rotate([90, 0, 0]) cylinder(d = 5, h = spg, $fn = 32);   // spigots toward the board
    }
    translate([-cube_w / 2 - 0.2, ax_y + fr_y - 1, ax_z + lens_z - cube_w / 2 - 0.2]) cube([cube_w + 0.4, fr_t + 2, cube_w + 0.4]);   // the cube's pocket
    for (sx = [-1, 1]) {
        translate([sx * eye_x, ax_y + fr_y - spg - 1, ax_z + eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_d, h = spg + fr_t + 2, $fn = 24);   // eye holes
        translate([sx * eye_x, ax_y + fr_y + fr_t - eye_seat, ax_z + eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_seat_d, h = eye_seat + 1, $fn = 48);   // seat for the glass eye (sawn-off 5 mm LED dome, 4.7 x 3.3)
        translate([sx * 40.5, ax_y + fr_y - 1, ax_z + lens_z - 2.1]) rotate([-90, 0, 0]) cylinder(d = 11, h = 2.4, $fn = 40);              // mic can pockets
    }
    translate([12, ax_y + fr_y - 1, ax_z + lens_z - 0.8]) cube([5.9, 1 + 1.5, 9.5]);                                                       // 1.5 deep pocket for the tall white camera-cable connector
    translate([slot_x, ax_y + fr_y - 1, ax_z + slot_z]) rotate([-90, 0, 0]) cylinder(d = 2.8 + cal_hole, h = fr_t + 2, $fn = 24);          // screw
    translate([slot_x, ax_y + fr_y + fr_t - 1.5, ax_z + slot_z]) rotate([-90, 0, 0]) cylinder(d = 5.4 + cal_hole, h = 2, $fn = 32);       // head recess
}
module head4() translate([0, ax_y, ax_z]) rotate([tilt4, 0, 0]) translate([0, -ax_y, -ax_z]) {
    color("#8a8d91") difference() { union() { ext_yz(-pl_x, pl_x); if (oled_head) cam_boss(); } if (oled_head) { oled_cuts(); cam_holes(); } }   // camera plate
    for (s = [-1, 1]) color("#6b8fb5") hull() {                                                                              // arms
        translate([s > 0 ? arm_x[0] : -arm_x[1], ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 16, h = 3, $fn = 40);
        ext_yz(s > 0 ? arm_x[0] : -arm_x[1], s > 0 ? arm_x[1] : -arm_x[0]);
    }
    for (s = [-1, 1]) color("#6b8fb5") translate([s > 0 ? arm_x[1] : -ch_x[1] - 0.5, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = stub_d, h = (s > 0 ? ch_x[1] - arm_x[1] : ch_x[1] - arm_x[1] + 0.5 + (ch_x[1] - ch_x[1])) + 0.01, $fn = 24);   // axle stubs (into the 608s)
    color("#6b8fb5") difference() { hull() {                                                                                    // crank bracket on the left arm
        translate([-arm_x[1] - 0.01, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 12, h = 3.01, $fn = 32);
        translate([pin_h[0] - 2.5 - 6, ax_y + cr_h * cos(hb0), ax_z + cr_h * sin(hb0)]) rotate([0, 90, 0]) cylinder(d = 9, h = 6.01, $fn = 32);   // boss x -35 .. -29
    }
    translate([pin_h[0] - 2.5 + 0.01, ax_y + cr_h * cos(hb0), ax_z + cr_h * sin(hb0)]) rotate([0, -90, 0]) cylinder(d = insert_m3[0], h = insert_m3[1] + 0.2, $fn = 24);   // M3 insert bore from the free face
    }
    if (oled_head) color("#8a8d91") difference() {                                                                       // zip-tie tab for the OLED wires: rear face, above the PCB's left (header) end
        translate([-36, ax_y + pl_y[0] - 4, ax_z + 4]) cube([5, 4.01, 6]);
        translate([-37, ax_y + pl_y[0] - 2.8, ax_z + 5.4]) cube([7, 1.6, 3.2]);                                          // tie slot 3.2 x 1.6, along X
    }
    if (part == "v4_view" || part == "head_view") {
    translate([cam_dx, xp_cam, 0]) { color("#1b5e20") difference() {                                                                                         // camera board (82 x 23 at the lugs; from the photos), with its edge slot
        translate([-41, ax_y + pl_y[1], ax_z + lens_z - 11.5]) cube([82, cb_t, 23]);
        translate([slot_x - 2, ax_y + pl_y[1] - 1, ax_z + lens_z - 12]) cube([4, cb_t + 2, 12 + slot_z - lens_z + 2]);
    }
    color("#222") translate([-cube_w / 2, ax_y + pl_y[1] + cb_t, ax_z + lens_z - cube_w / 2]) cube([cube_w, cube_h, cube_w]);   // lens cube
    color("#222") for (s = [-1, 1]) translate([s * 8.5, ax_y + pl_y[1] + cb_t, ax_z + lens_z]) rotate([-90, 0, 0]) cylinder(d = 6.5, h = boss_h, $fn = 24);   // its bosses
    color("#111") translate([0, ax_y + pl_y[1] + cb_t + cube_h, ax_z + lens_z]) rotate([-90, 0, 0]) cylinder(d = 11, h = 3, $fn = 40);   // lens
    }
    translate([cam_dx, xp_cov, 0]) {
    if (oled_head && show_camframe) color("#d9dde2") camcover();
    if (oled_head) color("#f4f4f4") for (sx = [-1, 1]) translate([sx * eye_x, ax_y + fr_y + fr_t - eye_seat, ax_z + eye_z]) rotate([-90, 0, 0]) cylinder(d = 4.66, h = 3.3, $fn = 32);   // glass eyes (sawn-off LED domes)
    }
    if (oled_head) translate([0, ax_y - xp_oled, ax_z + oz]) {
        color("#1b5e20") translate([-37.75, pl_y[0] - 1.2, -10.3]) cube([75.5, 1.2, 20.6]);                                // OLED PCB, on the plate's rear face
        color("#050505") translate([-32.5, pl_y[0], -10.3]) cube([62.5, 1.63, 20.6]);                                      // glass, in the pocket
        color("#9fd6ff") translate([ox - 25.59, pl_y[0] + 1.64, -6.39]) cube([51.18, 0.15, 12.78]);                          // active area, lit
    }
    }
}
module crank4() color("#e8a33d") difference() {                    // hub on the horn's 4 x M3 (PCD 14) + arm to the 14 mm pin; M3 insert in the pin boss, rod end bolted on its free face
    hull() {
        translate([tsh[0] - 6, tsh[1], tsh[2]]) rotate([0, 90, 0]) cylinder(d = 20, h = 3, $fn = 48);              // hub x -28 .. -25
        translate([pin_s[0] + 2.5, pin_s[1], pin_s[2]]) rotate([0, 90, 0]) cylinder(d = 9, h = 6, $fn = 32);       // pin boss x -31 .. -25
    }
    translate([pin_s[0] + 2.5 - 0.01, pin_s[1], pin_s[2]]) rotate([0, 90, 0]) cylinder(d = insert_m3[0], h = insert_m3[1] + 0.2, $fn = 24);   // insert bore from the free face
    translate([tsh[0] - 7, tsh[1], tsh[2]]) rotate([0, 90, 0]) for (a = [45 : 90 : 360]) rotate(a) translate([sts_horn_pcd / 2, 0, 0]) cylinder(d = 3.4 + cal_hole, h = 5, $fn = 24);   // horn screws
}
module tilt_rod4() color("#c0392b") {                                // M3 threaded rod + two rose-joint rod ends (eye d 10, 5 wide, as on the test stand)
    hull() for (p = [pin_s, pin_h]) translate(p) sphere(d = 3, $fn = 12);
    for (p = [pin_s, pin_h]) translate(p) rotate([0, 90, 0]) cylinder(d = 10, h = 5, center = true, $fn = 32);
}
// ==== COWL (hides the tilt servo, crank and rod) + CHEEK COVERS ===================================================================
// The cowl is a low dome over the rear half of the turret floor (a circle segment behind y = cw_y, the cheeks' rear face), 2.5 mm wall,
// vertical to 32 mm above the floor, then a 45 deg chamfer in to a flat top at 42 (the same height as the head's top).
// Its front wall has a window for the head's crank bracket and the rod (left) and a notch for the camera cables (centre).
cw_r = 57.5;  cw_t = 2.5;  cw_h = 42;  cw_wz = 32;  cw_ch = cw_h - cw_wz;  cw_y = 8;
cowl_alpha = 1;                                 // < 1 to see through it
module cw_fp(r) intersection() { circle(r = r, $fn = 160); translate([-100, -100]) square([200, 100 + cw_y]); }
module cw_solid(r, y_front, h, ch) intersection() {
    hull() {
        translate([0, 0, z_ft]) linear_extrude(h - ch) cw_fp(r);
        translate([0, 0, z_ft + h - 0.01]) linear_extrude(0.01) cw_fp(r - ch);
    }
    translate([-100, -100, z_ft - 1]) cube([200, 100 + y_front, 200]);
}
cw_fil = 3;                                     // 45 deg fillet along the inside corner where the front wall meets the top plate (prints with the top on the bed: no overhang)
module cw_fillet() intersection() {
    translate([-60, 0, 0]) rotate([90, 0, 90]) linear_extrude(120)
        polygon([[cw_y - cw_t + 0.01, z_ft + cw_h - cw_t + 0.01], [cw_y - cw_t - cw_fil, z_ft + cw_h - cw_t + 0.01], [cw_y - cw_t + 0.01, z_ft + cw_h - cw_t - cw_fil]]);
    cw_solid(cw_r - 0.5, cw_y, cw_h, cw_ch);
}
module cowl4() color("#d9dde2", cowl_alpha) difference() {
    union() {
        difference() {
            cw_solid(cw_r, cw_y, cw_h, cw_ch);
            cw_solid(cw_r - cw_t, cw_y - cw_t, cw_h - cw_t, cw_ch);                      // hollow, front wall left 2.5 thick
        }
        cw_fillet();
    }
    translate([-42, cw_y - cw_t - 1, z_ft - 1]) cube([22, cw_t + 2, 35]);                  // window: head crank bracket + rod ends (x -42 .. -20)
    translate([-9, cw_y - cw_t - 1, z_ft - 1]) cube([18, cw_t + 2, 17]);                   // notch: the camera's cables to the hub hole
    for (a = [200, 270, 340]) rotate(a) translate([cw_r - 3, 0, z_ft + 14]) cube([8, 1.8, 10], center = true);   // vents (rear)
    for (a = cs_ang) rotate(a) translate([cw_r - cw_t - 1, 0, z_ft + cs_z]) {                                      // screw holes through the wall + head counterbore
        rotate([0, 90, 0]) cylinder(d = 3.4 + cal_hole, h = cw_t + 2, $fn = 24);
        translate([cw_t + 1 - 1.6, 0, 0]) rotate([0, 90, 0]) cylinder(d = 6.2, h = 3, $fn = 32);
    }
    for (s = [-1, 1]) hull() {                                                                 // the cheeks' round rear (608 boss, d 34) pokes behind y = cw_y: notch the front wall round it, 0.5 clear
        translate([s > 0 ? ch_x[0] - 0.5 : -ch_x[1] - 8, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 35, h = ch_t4 + 8.5, $fn = 60);   // also takes the cover, d 34
        translate([s > 0 ? ch_x[0] - 0.5 : -ch_x[1] - 0.5, ax_y - 17.5, z_ft - 1]) cube([ch_t4 + 1, 28, 7.5]);   // reaches y = 0.5 like the cylinder, so the hull is a straight prism (no tapered, unsupported stub of wall at the tips)
    }
}
// ---- cheek cover + ear -------------------------------------------------------------------------------------------------------------
// Cover: d 34 (the cheek's own), 8 thick, flat on the cheek's outer face (it also holds the head's axle pin flange in its bore); 3 x M3 x 12
// (button heads on the surface) into the cheek inserts at r 14. A square pocket in its centre takes the ear's square stalk (keeps it square),
// and an M3 heat-set insert below the pocket takes the ear's centre screw.
// Ear: 12 x 12 stalk ending in an octagonal disc (36 across flats); centre screw M3 x 18 button head, counterbored into the disc, then covered
// with a glued domed plug. Ear and plug are the same on both sides (print 2 of each).
cv_d = 34;  cv_t = 8;  cv_pts = [for (a = [90, 210, 330]) [14 * cos(a), 14 * sin(a)]];
ear_pk = 2.5;  ear_sq = 12;  ear_sq_clr = 0.15;  ear_l = 10;                  // pocket depth, stalk section, clearance per side, stalk length outside the cover
ear_af = 36;  ear_t = 5;  ear_cb = [6.4, 3.2];  ear_ch = 1;                    // octagon across flats, thickness, counterbore (d, depth), outer edge chamfer
plug_stem = 1.5;  plug_d = 10;  plug_lip = 0.4;  plug_dome = 1.1;             // plug: stem in the counterbore, 0.4 lip + 1.1 dome above the disc
show_ears = true;
module rsq4(s, r = 1) offset(r = r) square(s - 2 * r, center = true);
module cover4() color("#d9dde2") difference() {                  // local z = 0 on the cheek's outer face, outwards +z (print inner face down, as drawn)
    cylinder(d = cv_d, h = cv_t, $fn = 96);
    for (c = cv_pts) translate([-c[1], c[0], -1])                  // local (u, v) = (-dz, dy) for the right cover
        cylinder(d = 3.4 + cal_hole, h = cv_t + 2, $fn = 24);          // plain clearance hole: button-head M3 x 12 sits on the surface (the rim stays closed)
    translate([0, 0, cv_t - ear_pk]) linear_extrude(ear_pk + 1) rsq4(ear_sq + 2 * ear_sq_clr);      // square pocket
    translate([0, 0, cv_t - ear_pk - 4.6]) cylinder(d = insert_m3[0], h = 5, $fn = 24);             // centre M3 heat-set insert, pressed in from the pocket floor
}
module oct4(af, h, ch) rotate(22.5) {                                                                // flat on top, chamfered outer edge
    r = af / 2 / cos(22.5);  rc = (af / 2 - ch) / cos(22.5);
    hull() { cylinder(r = r, h = h - ch, $fn = 8); cylinder(r = rc, h = h, $fn = 8); }
}
ear_len = ear_pk + ear_l + ear_t;                                                                    // local z = 0 at the stalk's inner end (pocket floor), outwards +z
module ear4() color("#2f7fe0") difference() {
    union() {
        linear_extrude(ear_pk + ear_l + 1) rsq4(ear_sq);
        translate([0, 0, ear_pk + ear_l]) oct4(ear_af, ear_t, ear_ch);
    }
    translate([0, 0, -1]) cylinder(d = 3.4 + cal_hole, h = ear_len + 2, $fn = 24);                  // centre screw
    translate([0, 0, ear_len - ear_cb[1]]) cylinder(d = ear_cb[0], h = ear_cb[1] + 1, $fn = 32);    // head + plug counterbore
}
module plug4() color("#f4f4f4") {                                                                    // local z = 0 at the disc's outer face
    translate([0, 0, -plug_stem]) cylinder(d = ear_cb[0] - 0.2, h = plug_stem + 0.01, $fn = 32);
    cylinder(d = plug_d, h = plug_lip, $fn = 48);
    R = ((plug_d / 2) * (plug_d / 2) + plug_dome * plug_dome) / (2 * plug_dome);
    intersection() { translate([0, 0, plug_lip + plug_dome - R]) sphere(r = R, $fn = 64); translate([0, 0, plug_lip]) cylinder(d = plug_d, h = plug_dome + 0.01, $fn = 48); }
}
module ear_screw4() color("#888") translate([0, 0, ear_len - ear_cb[1]]) { cylinder(d = 5.7, h = 1.65, $fn = 24); translate([0, 0, -18]) cylinder(d = 3, h = 18, $fn = 16); }   // M3 x 18 button head
module cover_unit4() { cover4(); if (show_ears) translate([0, 0, cv_t - ear_pk]) { ear4(); ear_screw4(); translate([0, 0, ear_len]) plug4(); } }
module covers4() for (sx = [-1, 1]) translate([sx > 0 ? ch_x[1] : -ch_x[1], ax_y, ax_z]) rotate([0, sx > 0 ? 90 : -90, 0]) mirror([sx > 0 ? 0 : 1, 0, 0]) cover_unit4();

module turret_stack4() {                        // everything above the lid, stand frame
    color("#6b8fb5") base();
    color("#2b2b2b") translate([0, 0, z_case_bot - strap_t]) pan_strap();
    color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);                                                     // pillow block
    translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();                                                  // pan servo
    color("#e8a33d") hub4();
    color("#6b8fb5") turret4();
    color("#b0b6bd") translate([tsv[0], tsv_y[0], tsv_z[0]]) cube([tsv[1] - tsv[0], tsv_y[1] - tsv_y[0], tsv_z[1] - tsv_z[0]]);   // tilt servo
    color("#e8a33d") translate([tsh[0] - 3, tsh[1], tsh[2]]) rotate([0, 90, 0]) cylinder(d = sts_horn_d, h = 3, $fn = 40);        // its horn (19.2)
    strap4();
    crank4();
    tilt_rod4();
    head4();
    if (part == "v4_view") {                                                                                   // XIAO ghost, its USB-C plug (straight, 11 x 6.5 x 16) and the cable round to the hub hole
        yc = (xi_y[0] + xi_y[1]) / 2;
        color("#2e7d32") translate([xi_x[0] + 0.4, yc - 8.9, z_ft + 0.3]) cube([21, 17.8, 3.5]);
        color("#222") translate([xi_x[0] - 16, yc - 5.5, z_ft + 1.2]) cube([16.5, 11, 6.5]);
        color("#222") for (p = [[[xi_x[0] - 15.5, yc], [xi_x[0] - 15.5, 2]], [[xi_x[0] - 15.5, 2], [6, 2]]]) hull() for (q = p) translate([q[0], q[1], z_ft + 4.5]) sphere(d = 3.5, $fn = 12);
    }
    if (show_cowl) { cowl4(); covers4(); }
    if (show_fov) for (da = [-fov_v / 2, 0, fov_v / 2]) color(da == 0 ? "#ffd400" : "#ff7a00") {
        a = tilt4 + da;  lr = pl_y[1] + 13;
        l0 = [ax_y + lr * cos(tilt4) - lens_z * sin(tilt4), ax_z + lr * sin(tilt4) + lens_z * cos(tilt4)];   // the lens
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
             "; head top ~", z_pt + ax_z + pl_z[1], "; wall ", wall_h4, " tall, skirt ", z_pt - sk_z0 + 0, " tall"));
}
if (part == "v4_tub") tub4();
if (part == "v4_lid") translate([0, 0, -ledge_z]) lid4();
if (part == "v4_skirt") rotate([180, 0, 0]) skirt4s();
if (part == "v4_turret") translate([0, 0, -z_floor]) turret4();
if (part == "v4_cowl") translate([0, 0, cw_h]) rotate([180, 0, 0]) translate([0, 0, -z_ft]) cowl4();
if (part == "v4_strap") strap4();
if (part == "v4_panstrap") pan_strap();                 // the stand's pan-servo strap (2 x M3), as printed
if (part == "v4_cover") cover4();                                                                                   // print two, inner face down (the square pocket and insert bore face up)
if (part == "v4_ear") translate([0, 0, ear_t]) rotate([180, 0, 0]) translate([0, 0, -(ear_len - ear_t)]) ear4();     // print two, octagon's outer face down, stalk up
if (part == "v4_plug") for (k = [0, 1]) translate([k * 14, 0, plug_stem]) plug4();                                   // print two (one file), stem down, dome up, glued over the screw
if (part == "v4_camframe") translate([0, 0, ax_y + fr_y + fr_t]) rotate([-90, 0, 0]) camcover();       // front face down on the bed, spigots and pockets up
if (part == "v4_head") translate([0, 0, ax_y + pl_y[1]]) rotate([-90, 0, 0]) head4();                       // front face down on the bed
if (part == "v4_plate") translate([0, 0, ax_y + pl_y[1]]) rotate([-90, 0, 0])                               // fit coupon: the camera/OLED plate only (no arms)
    intersection() { head4(); translate([-pl_x, ax_y + 9, 0]) cube([2 * pl_x, 20, 300]); }

if (part == "v4_crank") translate([0, -tsh[1], 25]) rotate([0, 90, 0]) translate([0, 0, 0]) crank4();     // face x = -25 (against the horn) down, insert bore up
if (part == "v4_hub") translate([0, 0, z_flange + flange_t]) rotate([180, 0, 0]) hub4();                         // flange on the bed, inserts up (bores open at the flange's top face)
if (part == "head_view") head4();
