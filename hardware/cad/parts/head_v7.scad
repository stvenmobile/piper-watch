// HEAD v7: pan-only head for the 5" CrowPanel face, on a new turret top. Replaces head v6, the tilt stack
// (tilt servo, crank, cheeks, covers, ears) and the v4 turret + cowl. The base, pan servo, hub and skirt stay.
//
//   TOP      turret top: a 6 mm plate on the hub flange (the same 4 x M3) with a ring hanging 4 mm down over the
//            skirt, 1.5 mm clear of it: the 13 mm gap above the skirt is hidden. Prints plate down, ring up.
//   HEAD     one shell: front wall with the screen window (45 deg chamfer) and the camera seat, sides, top and
//            floor, all four corners rounded (r 24) seen from the front. Open at the back. 160 wide (197 over the pods) x 53 deep x ~146 tall, centred over the pan axis.
//            Prints front face down, no supports.
//   BACK     the back panel: sits flush in the open back on 4 corner bosses, 4 x M3 into heat-set inserts.
//   CAMSTRAP holds the C920's bare board on its seat (2 x M2 self-tapping), as on head v6.
// The panel (screen facing forward, USB-C ports on the left seen from the front) is held by 4 x M3 x 8 through its
// own holes into bosses behind the front wall; its glass rests on the wall's inner face. The camera looks 4 deg up.
// Width: 160 leaves only 11.5 mm beside the panel's USB-C edge, too little for the right-angle plug in the upper
// (UART) jack: the head is wider in the middle - a hollow pod each side (ear_style smooth or ribbed) gives it 30 mm
// past the board's edge. Add-ons: stepped ear cups on the pods with antenna stalks.
// part = "v7_view" | "v7_head" | "v7_back" | "v7_camstrap" | "v7_top" | "v7_ear" | "v7_ball" | "v7_stalk"
//
// Version 0.6.1 - created 2026-11-26, last modified 2026-11-27
// History:
//   0.6.1  2026-11-27  Chin 6 mm taller (floor to panel 26, H 146.3); everything above moves up with it.
//                      Ear antenna stalks 40 long (were 30).
//   0.6.0  2026-11-27  Back to built-in pods (0.4.0's idea; the bolt-on pills of 0.5.0 are dropped: they couldn't
//                      sit back from the front face). The pods now give 30 mm past the board's edge over 40+ of
//                      height for the upper (UART) jack's plug and cable.
//                      ear_style "smooth" | "ribbed". Ears (two-step cups, 30 / 20, the 1 mm front step for a
//                      second colour) with antenna stalks and balls are add-ons (v7_ear, v7_ball, v7_stalk).
//   0.5.0  2026-11-27  Ears are bolt-on parts (v7_ear, print 2): stepped pills on 3 x M3 inserts. The shell's outline
//                      and the back panel go back to the plain 160 wide head; the side walls get the openings.
//   0.4.0  2026-11-27  Hollow robot ears on both sides at the USB-C ports' height: the right-angle plug needs ~15 mm
//                      beyond the board's edge (it had 11.5). The back panel takes the ears' outline too.
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
mb = 26;                                       // floor to the panel's bottom edge (a bigger chin: was 20)
gap_b = 5;  cam_board = [82, 23];  tm = 12;    // panel -> camera board, the C920 board, top margin
H = mb + cp5_board[1] + gap_b + cam_board[1] + tm;   // 146.3
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
module body2d(off = 0) hull() {
    for (sx = [-1, 1]) translate([sx * (W / 2 - rb), hz0 + rb]) circle(r = rb - off, $fn = 96);
    for (sx = [-1, 1]) translate([sx * (W / 2 - rt), hz0 + H - rt]) circle(r = rt - off, $fn = 96);
}
// ---- ears ----------------------------------------------------------------------------------------------------------
// The head is wider in the middle: a hollow pod on each side, through the full depth (a prism along y: prints with
// no overhang, front face down; the back panel takes its outline), centred on the space a right-angle USB-C plug in
// the UPPER (UART) jack needs - with room for common cables, not just the one in hand (25 out from the board's edge,
// 7 thick, cable down ~32): inside, the pod reaches 30 past the board's edge over 40+ of height, from 9.5 above the
// jack's centre down. The left pod is the mirror image. The ears themselves are add-on parts (below).
ear_style = "smooth";                          // "ribbed" | "smooth": grooves along the pod's outer face, or none
jack = [cp5_board[0] / 2, 15.4, pz + cp5_usbc[1][1] + cp5_usbc_sz[1] / 2];   // upper jack: board edge x, centre y, z
ear_zc = jack[2] + 9.5 - 20;                   // pod centre height: the 40 tall plug + cable space, centred (z ~77.5)
ear_rib = [3, 4, 1.2, 12];                     // ribbed: grooves - count, height, depth, pitch
ear_out = jack[0] + 30 + wt + (ear_style == "ribbed" ? ear_rib[2] : 0);   // pod's outer face x (98.5, ribbed 99.7)
ear_h = 50;                                    // outer face height
ear_fl = tan(30);                              // flanks: they widen by this per mm towards the wall
ear_btn = [26, 16, 5, 10];                     // button: base d, top d (45 deg: (26 - 16) / 2 = 5 proud), height, dimple d
module ear2d() for (m = [0, 1]) mirror([m, 0]) difference() {
    offset(r = 2) offset(delta = -2) polygon([
        [W / 2 - 3, ear_zc - ear_h / 2 - (ear_out - W / 2 + 3) * ear_fl], [ear_out, ear_zc - ear_h / 2],
        [ear_out, ear_zc + ear_h / 2], [W / 2 - 3, ear_zc + ear_h / 2 + (ear_out - W / 2 + 3) * ear_fl]]);
    if (ear_style == "ribbed") for (i = [0 : ear_rib[0] - 1])
        translate([ear_out - ear_rib[2], ear_zc + (i - (ear_rib[0] - 1) / 2) * ear_rib[3] - ear_rib[1] / 2]) square([ear_rib[2] + 1, ear_rib[1]]);
}
// the head's outline seen from the front, with the pods; off > 0 = inset (the inside, the back panel)
module head2d(off = 0) offset(r = -off) offset(r = -1.5) offset(delta = 1.5) union() { body2d(0); ear2d(); }
// ---- add-ons: ear cups, antennas ----------------------------------------------------------------------------------
// EAR: a stepped "headphone" cup on each pod's outer face (decoration), 2 x M3 heat-set inserts in its back, screws
// from inside the pod. One part, print 2: the left ear is the right one turned 180 deg about the vertical, so its
// screws sit at y +9 (the right ear's at y -9 keep clear of the plug's space). A 4 mm socket in the cup's top rim
// takes an antenna stalk: 4 mm rod (dowel, brass, carbon) or the printed v7_stalk, a ball (v7_ball) glued on the tip.
// The cup's thin front step can be printed in a second colour.
cup = [[30, 8, 1.5], [20, 1, 0]];             // ear cup steps: diameter, height, top chamfer (back to front)
cup_scr = [[-6, -9], [6, -9]];                 // ear screws, cup frame (x = down, y): global y -9, z ear_zc -+ 6
sock = [4.2, 10];                              // antenna sockets: d, depth
stalk = [3.9, 40];                             // printed stalks: d, length
ball = [13, 1.5];                              // ball: d, flat cut at the bottom
module chamf_cyl(d, h, c) union() { cylinder(d = d, h = h - c, $fn = 96); translate([0, 0, h - c - 0.01]) cylinder(d1 = d, d2 = d - 2 * c, h = c + 0.01, $fn = 96); }
module cup_local() difference() {                // back face on z = 0, axis +z; "up" is -x
    union() { for (i = [0 : len(cup) - 1]) translate([0, 0, sum_h(i)]) chamf_cyl(cup[i][0], cup[i][1] + 0.01, cup[i][2]); }
    for (p = cup_scr) translate([p[0], p[1], -0.01]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
    translate([-cup[0][0] / 2 - 1, 0, cup[0][1] / 2]) rotate([0, 90, 0]) cylinder(d = sock[0], h = sock[1] + 1, $fn = 24);   // antenna socket, down from the rim
}
function sum_h(i) = i == 0 ? 0 : sum_h(i - 1) + cup[i - 1][1];
module ear_r7() translate([ear_out, 0, ear_zc]) rotate([0, 90, 0]) cup_local();   // right ear, in place
module ears7() { ear_r7(); rotate([0, 0, 180]) ear_r7(); }
module ball_local() difference() {               // flat on z = 0, socket up from it
    translate([0, 0, ball[0] / 2 - ball[1]]) sphere(d = ball[0], $fn = 64);
    translate([0, 0, -ball[0]]) cube(2 * ball[0], center = true);
    translate([0, 0, -1]) cylinder(d = sock[0], h = 7, $fn = 24);
}
module ear_holes7() {                            // in the head: screw clearance through the pods' outer walls
    for (r = [0, 180]) rotate([0, 0, r]) for (p = cup_scr)
        translate([ear_out - wt - 1, p[1], ear_zc - p[0]]) rotate([0, 90, 0]) hole3(wt + 2);
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
    ear_holes7();                                                                                          // add-ons' screws
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
        color("#8a9099") ears7();
        color("#c8a040") for (r = [0, 180]) rotate([0, 0, r]) translate([ear_out + cup[0][1], 0, ear_zc]) rotate([0, 90, 0]) cylinder(d = cup[1][0], h = cup[1][1] + 0.02, $fn = 96);   // the front step, other colour
        color("#8a9099") { for (r = [0, 180]) rotate([0, 0, r]) translate([ear_out + cup[0][1] / 2, 0, ear_zc + cup[0][0] / 2 - sock[1] + 2]) cylinder(d = stalk[0], h = stalk[1], $fn = 24); }
        color("#b0b6bf") { for (r = [0, 180]) rotate([0, 0, r]) translate([ear_out + cup[0][1] / 2, 0, ear_zc + cup[0][0] / 2 - sock[1] + 2 + stalk[1] - 5 - ball[1]]) ball_local(); }
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
if (part == "v7_ear") cup_local();                                                                         // back face down, print 2
if (part == "v7_ball") ball_local();                                                                       // flat down, print 2
if (part == "v7_stalk") for (i = [0 : 1]) translate([i * 8, 0, 0]) cylinder(d = stalk[0], h = stalk[1], $fn = 24);   // upright, 2
