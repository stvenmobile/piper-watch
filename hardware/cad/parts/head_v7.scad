// HEAD v7: pan-only head for the 5" CrowPanel face, on a new turret top. Replaces head v6, the tilt stack
// (tilt servo, crank, cheeks, covers, ears) and the v4 turret + cowl. The base, pan servo, hub and skirt stay.
//
//   TOP      turret top: a 6 mm plate on the hub flange (the same 4 x M3) with a ring hanging 4 mm down over the
//            skirt, 1.5 mm clear of it: the 13 mm gap above the skirt is hidden. Prints plate down, ring up.
//   HEAD     one shell: front wall with the screen window (45 deg chamfer) and the camera seat, sides, top and
//            floor, all four corners rounded (r 24) seen from the front. Open at the back. 160 wide x 53 deep x ~140 tall, centred over the pan axis.
//            Prints front face down, no supports.
//   BACK     the back panel: sits flush in the open back on 4 corner bosses, 4 x M3 into heat-set inserts.
//   CAMSTRAP holds the C920's bare board on its seat (2 x M2 self-tapping), as on head v6.
// The panel (screen facing forward, USB-C ports on the left seen from the front) is held by 4 x M3 x 8 through its
// own holes into bosses behind the front wall; its glass rests on the wall's inner face. The camera looks 4 deg up.
// Width: 160 leaves 11.5 mm beside the panel's USB-C edge - room for a RIGHT-ANGLE USB-C plug, not a straight one.
// part = "v7_view" | "v7_head" | "v7_back" | "v7_camstrap" | "v7_top"
//
// Version 0.3.1 - created 2026-11-26, last modified 2026-11-26
// History:
//   0.3.1  2026-11-26  Floor cable opening matches the turret top's hole (cable_hole2d) - the old larger opening
//                      with the pointed back was covered by the top plate anyway.
//   0.3.0  2026-11-26  Back-panel bosses on gussets: each boss's front end rises from its wall at 45 deg (prints
//                      without supports, front face down) and its root on the wall is 16 wide (the boss is 8).
//   0.2.0  2026-11-26  Bottom corners rounded like the top (r 24): the flat underside is 112 wide, about the
//                      turret plate's 115. The lower back-panel bosses move in to x +-56, as the top ones.
//   0.1.2  2026-11-26  Panel bosses 0.2 short of the measured depth (5.7): the glass always seats on the wall;
//                      tighten the panel screws only until snug.
//   0.1.1  2026-11-26  Panel bosses 5.9 long (measured glass-to-board depth, params 1.1.2; was 5.7 from the model).
//   0.1.0  2026-11-26  First version, from the pan-only layout drafts. Not printed yet.
include <base_v4.scad>
use <../vitamins/crowpanel_p4_5in.scad>

part = "v7_view";

// ---- turret top -------------------------------------------------------------------------------------------------
lip_ri = sk_ro + 1.5;                          // ring: 1.5 clear of the skirt (r 53) ...
lip_ro = lip_ri + 3;                           // ... 3 thick (outer r 57.5, as the old turret floor)
lip_down = 4;                                  // ... reaches 4 mm below the skirt's top edge (z 0)
tp_t = 6;                                      // plate thickness (blind M3 inserts for the head, 5 deep)
tp_z = z_floor;                                // plate's underside: on the hub flange
cb_d = 6.4;  cb_h = 3.2;                       // counterbores for the hub screws' heads (M3 socket head 5.5 x 3)

// ---- head --------------------------------------------------------------------------------------------------------
W = 160;  D = 53;                              // width, depth (centred on the pan axis: y -26.5 .. 26.5)
wt = 2.5;                                      // shell wall
rb = 24;  rt = 24;                             // corner radii seen from the front: bottom, top
hz0 = tp_z + tp_t;                             // head's underside, on the plate
mb = 20;                                       // floor to the panel's bottom edge
gap_b = 5;  cam_board = [82, 23];  tm = 12;    // panel -> camera board, the C920 board, top margin
H = mb + cp5_board[1] + gap_b + cam_board[1] + tm;   // 140.3
yf = D / 2;  yi = yf - wt;                     // front face, front wall's inner face (the glass rests on it)
pz = hz0 + mb;                                 // panel board's bottom edge
px = -cp5_board[0] / 2;                        // panel board's left edge seen from behind (x = model x + px)
// panel, model -> head frame: x = mx + px, z = my + pz; the board's front face is at y = yi - cp5_lcd[2]
yb_front = yi - cp5_lcd[2];
boss_short = 0.2;                              // panel bosses end this far short of the board: the glass seats on the wall first
yboss = yb_front + boss_short;                 // the bosses' back ends (5.7 from the wall with the measured 5.9)
win = [cp5_active[0] + 2, cp5_active[1] + 2];  // window at the inner face: pixel area + 1 mm all round
win_c = [cp5_active_c[0] + px, cp5_active_c[1] + pz];

// camera: lens centre on the front face, axis tilted 4 deg up
cam_tilt = 4;
lens_zc = pz + cp5_board[1] + gap_b + cam_board[1] / 2;
module camf() translate([0, yf, lens_zc]) rotate([cam_tilt, 0, 0]) children();   // camera frame: origin at the lens on the front face, +y = view
// in the camera frame: lens tip y -0.5, lens (d 11) to y -3.5, lens cube (14 x 14 x 10.3) to y -13.8 = board front,
// board 1.6 thick to y -15.4; the board's two bosses (d 6.5, 5.1 tall) rest on the seat at y -8.7
cy_seat = -0.5 - 3 - cube_h + boss_h;          // -8.7
cy_bf = -0.5 - 3 - cube_h;                     // -13.8 board front face
cy_bb = cy_bf - cb_t;                          // -15.4 board back face
xcs7 = 44.5;                                   // camera strap screws (beyond the board's ends at +-41)

// back panel bosses: [x, z] centres, M3 inserts pressed in from the back
bk_d = 8;  bk_len = 8;
bk_fl = 16;                                    // gusset root width on the wall (the boss is 8)
bk_pts = [[W / 2 - rb, hz0 + wt + 4], [-(W / 2 - rb), hz0 + wt + 4],
          [W / 2 - rt, hz0 + H - wt - 4], [-(W / 2 - rt), hz0 + H - wt - 4]];
// head -> plate: 4 x M3 down through the floor into inserts in the plate (behind the panel: reachable from the back)
hp_pts = [[42, -14], [-42, -14], [42, 3], [-42, 3]];

// ---- helpers -----------------------------------------------------------------------------------------------------
module head2d(off = 0) hull() {
    for (sx = [-1, 1]) translate([sx * (W / 2 - rb), hz0 + rb]) circle(r = rb - off, $fn = 96);
    for (sx = [-1, 1]) translate([sx * (W / 2 - rt), hz0 + H - rt]) circle(r = rt - off, $fn = 96);
}
module ey(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();   // 2D (x, z) -> y0 .. y1

module bk_boss7(p) {
    lower = p[1] < hz0 + H / 2;
    sg = lower ? -1 : 1;                                                         // toward the wall
    zw = lower ? hz0 + wt : hz0 + H - wt;                                        // the wall's inner face
    so = abs(p[1] - zw) + bk_d / 2;                                              // wall face to the boss's far side (8)
    y0 = -yf + wt;
    hull() {
        translate([p[0], y0, p[1]]) rotate([-90, 0, 0]) cylinder(d = bk_d, h = bk_len, $fn = 32);
        translate([p[0] - bk_fl / 2, y0, lower ? zw - 2 : zw - 0.01]) cube([bk_fl, bk_len + so, 2.01]);   // root, 2 into the wall
    }
}

// ---- parts -------------------------------------------------------------------------------------------------------
module top7() difference() {
    union() {
        translate([0, 0, tp_z]) cylinder(r = lip_ro, h = tp_t, $fn = 160);
        translate([0, 0, -lip_down]) cylinder(r = lip_ro, h = tp_z + 0.01 + lip_down, $fn = 160);
    }
    translate([0, 0, -lip_down - 1]) cylinder(r = lip_ri, h = tp_z + lip_down + 1, $fn = 160);
    translate([0, 0, tp_z - 1]) linear_extrude(tp_t + 2) cable_hole2d();                                  // cables down the hub, as before
    for (a = [hub_a : 90 : 360]) rotate(a) translate([flange_r, 0, tp_z - 1]) {                            // 4 x M3 into the hub flange
        hole3(tp_t + 2);
        translate([0, 0, tp_t + 1 - cb_h]) cylinder(d = cb_d + cal_hole, h = cb_h + 1, $fn = 32);           // heads sunk flush
    }
    for (p = hp_pts) translate([p[0], p[1], tp_z + tp_t - insert_m3[1]]) insert3();                        // head screws: blind inserts from the top
}

module head7() difference() {
    union() {
        difference() {
            ey(-yf, yf) head2d(0);
            ey(-yf - 1, yi) head2d(wt);                                                                    // hollow, open at the back
        }
        // panel bosses: from the front wall's inner face back to the board's front face, cut clear of the glass
        difference() {
            for (h = cp5_holes) translate([h[0] + px, yi + 1, h[1] + pz]) rotate([90, 0, 0]) cylinder(d = 6.5, h = yi + 1 - yboss, $fn = 32);   // 1 mm into the wall
            translate([cp5_lcd_xy[0] + px - 0.5, yb_front - 1, cp5_lcd_xy[1] + pz - 0.5]) cube([cp5_lcd[0] + 1, cp5_lcd[2] + 2, cp5_lcd[1] + 1]);
        }
        // camera seat: a block behind the brow, its back face tilted with the camera
        intersection() {
            camf() translate([-cam_board[0] / 2 - 9, cy_seat, -cam_board[1] / 2 - 3]) cube([cam_board[0] + 18, 3 - cy_seat, cam_board[1] + 6]);
            ey(-yf, yf) head2d(0.01);
        }
        // camera strap bosses, from the seat back to the board's back face
        for (sx = [-1, 1]) camf() translate([sx * xcs7, cy_seat + 0.5, 0]) rotate([90, 0, 0]) cylinder(d = 6, h = cy_seat + 0.5 - cy_bb - 0.2, $fn = 32);
        // back panel bosses, each on a gusset to the nearest wall (floor or top): the gusset's root on the wall is
        // bk_fl wide and runs forward of the boss, so the boss's front end rises from the wall at 45 deg as printed
        // (front face down) - no supports - and the root is wider than the boss for strength
        intersection() {
            for (p = bk_pts) bk_boss7(p);
            ey(-yf, yf) head2d(0.01);                                                                      // keep it inside the shell's outer face
        }
    }
    // screen window: pixel area + 1 mm at the inner face, opening at 45 deg to the front face
    hull() {
        translate([win_c[0] - win[0] / 2, yi - 1, win_c[1] - win[1] / 2]) cube([win[0], 1.01, win[1]]);
        translate([win_c[0] - win[0] / 2 - wt, yf - 0.01, win_c[1] - win[1] / 2 - wt]) cube([win[0] + 2 * wt, 1, win[1] + 2 * wt]);
    }
    // camera: lens cube pocket through the seat, lens hole through the wall, 45 deg chamfer on the front face
    camf() {
        translate([-cube_w / 2 - 0.2, cy_bf - 1, -cube_w / 2 - 0.2]) cube([cube_w + 0.4, cube_h + 1 + 0.2, cube_w + 0.4]);
        translate([0, 1, 0]) rotate([90, 0, 0]) cylinder(d = 11 + 0.6 + cal_hole, h = 6, $fn = 48);
        translate([0, 0.01, 0]) rotate([90, 0, 0]) cylinder(d1 = 11.6 + cal_hole + 2 * wt, d2 = 11.6 + cal_hole, h = wt, $fn = 48);
        for (sx = [-1, 1]) translate([sx * xcs7, cy_bb - 1, 0]) rotate([-90, 0, 0]) cylinder(d = 1.6, h = 7.5, $fn = 16);   // M2 pilots
    }
    // panel screws: M3 x 8 cut their own thread (tap_m3), blind: they stop 1 mm short of the front face. Snug only.
    for (h = cp5_holes) translate([h[0] + px, yboss - 1, h[1] + pz]) rotate([-90, 0, 0]) cylinder(d = tap_m3[0], h = 1 + (yi - yboss) + wt - 1, $fn = 24);
    // back panel inserts
    for (p = bk_pts) translate([p[0], -yf + wt - 0.01, p[1]]) rotate([-90, 0, 0]) insert3();
    // floor: the cables' opening, the same shape as the hole in the turret top below it, and 4 x M3 clearance holes
    translate([0, 0, hz0 - 1]) linear_extrude(wt + 2) cable_hole2d();
    for (p = hp_pts) translate([p[0], p[1], hz0 - 1]) hole3(wt + 2);
}

module back7() difference() {
    ey(-yf, -yf + wt) head2d(wt + 0.25);                                                                     // 0.25 clear all round
    for (p = bk_pts) translate([p[0], -yf - 1, p[1]]) rotate([-90, 0, 0]) hole3(wt + 2);
    for (i = [-3 : 3]) translate([i * 12 - 2, -yf - 1, hz0 + H * 0.55]) cube([4, wt + 2, 30]);              // vents (the panel and the C920 make some heat)
}

module camstrap_flat() difference() {                                                                   // flat, as printed
    translate([-xcs7 - 4, -4, 0]) cube([2 * xcs7 + 8, 8, 2.5]);
    for (sx = [-1, 1]) translate([sx * xcs7, 0, -1]) cylinder(d = 2.4 + cal_hole, h = 4.5, $fn = 16);
}
module camstrap7() camf() translate([0, cy_bb, 0]) rotate([90, 0, 0]) camstrap_flat();                 // in place: against the board's back

// ---- vitamins for the view ---------------------------------------------------------------------------------------
module panel7() translate([px, yb_front - cp5_board[2], pz]) rotate([90, 0, 0]) crowpanel_p4_5in(keepout = false);
module camera7() camf() {
    color("#1b5e20") translate([-cam_board[0] / 2, cy_bb, -cam_board[1] / 2]) cube([cam_board[0], cb_t, cam_board[1]]);
    color("#222") translate([-cube_w / 2, cy_bf, -cube_w / 2]) cube([cube_w, cube_h, cube_w]);
    color("#111") translate([0, -0.5, 0]) rotate([90, 0, 0]) cylinder(d = 11, h = 3, $fn = 40);
}

// ---- output ------------------------------------------------------------------------------------------------------
show_base = true;
if (part == "v7_view") {
    if (show_base) { color("#6b8fb5") tub4(); color("#b5c4d6") lid4(); color("#3557a8") translate([0, 0, z_pt]) skirt_extra4(); }
    translate([0, 0, z_pt]) {
        color("#2a2d31") top7();
        color("#2a2d31") head7();
        color("#3a3e44") back7();
        color("#6b8fb5") camstrap7();
        panel7();
        camera7();
    }
}
if (part == "v7_top") translate([0, 0, tp_z + tp_t]) rotate([180, 0, 0]) top7();                          // plate's top face on the bed, ring up
if (part == "v7_head") translate([0, 0, yf]) rotate([-90, 0, 0]) head7();                                  // front face on the bed
if (part == "v7_back") translate([0, 0, yf]) rotate([90, 0, 0]) back7();                             // flat, outer face down
if (part == "v7_camstrap") camstrap_flat();
