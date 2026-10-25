// Piper's head v2 - the printable parts (from concepts/real_head_v2_concept.scad).
//
// An enclosed box that nods on two printed "ears" in 608 bearings. It splits just behind the pivots:
//
//   FRONT  (head_front_v2) everything that carries load or holds the electronics, in one piece:
//          the face (octagonal screen window, the mouth opening), the top, both side walls with the
//          PIVOT BOSSES (outside: a round boss on the bearing's inner race with the ear's square key
//          socket; inside: the M3 insert), the CRANK (right side wall, 15 mm, an M3 insert for the
//          link's rod end), the CYD posts (4 x M2.5 inserts), the MOUTH + CAMERA BLOCK, and 4 corner
//          bosses with M3 inserts for the back cap. PRINT face-down, no supports.
//   CAP    (head_cap_v2) the back: a lid with the cable exit, a lip that locates it inside the front,
//          4 x M3 x 20 screws into the corner inserts. PRINT back-face down, no supports.
//   EARS   2 x the coupon's ear (parts/head_pivot_coupon.scad), M3 x 20 each into the pivot inserts.
//   DIFFUSER  white: fills the mouth opening flush with the face, a rim behind the wall, three legs
//          the LED ring rests on (3 mm air gap: 12 dots blur into a glow), and a short baffle round
//          the lens. PRINT face-down.
//   CAM CLIPS 2 x a U-channel across the back of the camera board (x = +/-30, beside the ring), each
//          2 x M3 into inserts in the camera block's back face; their legs locate the board up/down.
//
// Fits from the coupons: pivot (params.scad pivot_*), inserts (insert_m3, insert_m25).
// Frame: the tilt axle at the origin, +Y forward, +Z up, X across (+X = the CYD's USB end and the
// crank side - Piper's right... seen from the front, +X is on the LEFT).
//
// ASSEMBLY ORDER: inserts (pivots through the crank's channel on the right; crank pin; CYD posts;
// camera block; corner bosses) -> diffuser in from behind, ring onto its legs (pads to the back, a dab
// of glue), camera board onto the block's back face (lens forward) and its two clips -> CYD glass to
// the window, 4 x M2.5 x 6 -> wires -> ears through the yoke's bearings into the side walls -> cap.
//
// part = "all" (assembled view) | "front" | "cap" | "ears" | "diffuser" | "clips" | "coupon"
//        ("coupon": the face only - window, CYD posts, mouth + camera block - to check them first)
include <servo_test_stand.scad>
use <head_pivot_coupon.scad>

part = "all";
section = false;                 // "all": cut in half at x = 0 to show the inside

// ---- the box (as the concept) ----------------------------------------------------------------------
hw       = 106;                  // outside width
hy       = [-28, 47];            // back face .. front face
hz       = [-44, 48];            // bottom .. top
t        = 2.5;                  // walls
chamfer  = 15;                   // octagon corners
y_split  = -12;                  // FRONT | CAP (behind the pivot bosses and the crank)
bottom_open = 70;                // the underside is open this wide (link, cables, nodding)
lip      = [4, 1.6, 0.2];        // the cap's lip into the front: depth, thickness, clearance

// ---- pivots (as the coupon's wall piece) -------------------------------------------------------------
yoke_gap = 1.5;                  // the outside boss: wall to the cheek, on the bearing's inner race only
boss_o   = 12;                   //   its diameter
boss_in  = 6;                    // the insert boss inside the wall
boss_in_d = 18;                  // (the coupon's was 11: bigger for strength) - flat at the back where
                                 //   the cap's lip comes in
boss_flat = y_split + lip[0] + 0.3;
key_len  = 5;                    // the ear's key length (coupon); its socket 0.5 deeper

// ---- the screen: Guition ESP32-2432S024 (MEASURED) -------------------------------------------------
cyd_b    = [74, 43, 1.8];
cyd_holes = [68, 36];            // 4 x 3 mm holes, centres (centred on the board)
cyd_glass = 4.3;                 // board front -> glass front: the posts' length
cyd_lit  = [48.8, 39];           // viewable area
cyd_lit_dx = -2.25;              // its centre from the board's centre (+x = the USB end)
cyd_z    = 22;
win_chamfer = 7;
cyd_post_d = 6.5;

// ---- the mouth: NeoPixel Ring 12 + diffuser, and the camera behind -----------------------------------
cam_z    = -21;                  // lens = mouth centre
ring     = [36.8, 23.3, 3.4];    // OD, ID, thickness (4.8 with wires pressed flat)
ring_fit = 0.25;                 // clearance round the ring in its bore
bore_d   = ring[0] + 2 * ring_fit;   // + cal_hole when cut
mouth_d  = 34;                   // the face's opening (+ 0.3 and cal_hole when cut)
diff_air = 3;                    // diffuser's back -> the ring's front... measured from the rim's back
rim_t    = 1.5;
diff_t   = 1.8;                  // the diffuser's face: flush with the face, the only material the light
                                 //   passes (more than this is too diffusing even in clear-ish filament)
diff_collar = 0.6;               // a thin collar at its edge reaches back to the rim behind the wall
ring_front = t + rim_t + diff_air;    // 7.0 behind the face
ring_back  = ring_front + ring[2];    // 10.4
lens_hole = 19;                  // through the diffuser: the C920's view from 5.4 mm back
baffle   = [22, 8.3];            // the lens baffle: OD, and how far behind the face it ends (the lens
                                 //   holder's square block starts at 8.8)
cam_b    = [80, 22, 1.3];        // bare C920 board (MEASURED)
lens_h   = 14.0;                 // board front -> lens front (MEASURED)
conn_clr = 9;                    // board front parts (connector 6, 8 with wires) + 1 -> behind the ring
y_cam    = hy[1] - (ring_back + conn_clr);   // board FRONT face: 27.6 (19.4 behind the face)
blk_x    = 34;                   // camera block: x +/- (the board's microphones stand at 34.6 .. 40.7)
blk_z    = [-42, 0];             //   z range (the CYD's glass starts at 0.5)
comp     = [52, 22];             // its back face: the clear pocket for the board's front parts
clip_x   = 30;                   // the clips' centres (on the block's rest strips, x 26 .. 34)
clip_hole = 17.5;                // their holes: +/- this from the lens (board edge + 6.5)
clip     = [8, 2.5, 3.0, 0.5];   // width, thickness, bridge rise above the block's face, leg clearance

// ---- back-cap screws: corner bosses ------------------------------------------------------------------
cb_d     = 10;
cb_len   = 8;                    // front's bosses: from the split forward
cb_pts   = [for (sx = [-1, 1], p = [[40.2, 35.2], [40.2, -31.2]]) [sx * p[0], p[1]]];

$fn = 48;

// ---- helpers -------------------------------------------------------------------------------------------
module octagon(inset = 0) {
    offset(delta = -inset) polygon([
        [-hw / 2 + chamfer, hz[0]], [hw / 2 - chamfer, hz[0]], [hw / 2, hz[0] + chamfer], [hw / 2, hz[1] - chamfer],
        [hw / 2 - chamfer, hz[1]], [-hw / 2 + chamfer, hz[1]], [-hw / 2, hz[1] - chamfer], [-hw / 2, hz[0] + chamfer]]);
}
module along_y(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();   // (x, z) outline
module x_cyl(d, x0, x1, y = 0, z = 0) translate([x0, y, z]) rotate([0, 90, 0]) cylinder(d = d, h = x1 - x0);
module y_cyl(d, y0, y1, x = 0, z = 0) translate([x, y1, z]) rotate([90, 0, 0]) cylinder(d = d, h = y1 - y0);
// printed face-down, "down" is +Y: a horizontal boss gets a teardrop point toward the face
module x_teardrop(d, x0, x1, y = 0, z = 0) hull() {
    x_cyl(d, x0, x1, y, z);
    translate([x0, y + d / 2 * sqrt(2) - 0.5, z - 0.5]) cube([x1 - x0, 0.5, 1]);
}
module behind_flat() intersection() { children(); translate([-hw, boss_flat, -hw]) cube([2 * hw, 2 * hw, 2 * hw]); }
module oct_poly(w, h, c) polygon([[-w / 2 + c, -h / 2], [w / 2 - c, -h / 2], [w / 2, -h / 2 + c], [w / 2, h / 2 - c],
                                  [w / 2 - c, h / 2], [-w / 2 + c, h / 2], [-w / 2, h / 2 - c], [-w / 2, -h / 2 + c]]);
module rrect2(w, h, r) offset(r) square([w - 2 * r, h - 2 * r], center = true);

crank_pin = [arm_h * cos(crank_off), arm_h * sin(crank_off)];   // (y, z) of the link's pin
crank_x0  = x_link + rod_ball_w / 2 + 0.5;                       // the crank's inner face (the rod end's side)

// ==== FRONT ===============================================================================================
module head_front_v2() {
    difference() {
        union() {
            difference() {                                           // the shell
                along_y(y_split, hy[1]) octagon();
                along_y(y_split - 1, hy[1] - t) octagon(t);
            }
            for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) {       // pivots
                x_cyl(boss_o, hw / 2 - 0.01, hw / 2 + yoke_gap);                      // outside: on the inner race
                behind_flat() x_teardrop(boss_in_d, hw / 2 - t - boss_in, hw / 2 - t + 0.01);   // inside: the insert
            }
            behind_flat() hull() {                                   // the crank (right wall, +x)
                x_teardrop(boss_in_d, crank_x0, hw / 2 - t + 0.01);
                x_teardrop(9, crank_x0, hw / 2 - t + 0.01, crank_pin[0], crank_pin[1]);
            }
            for (sx = [-1, 1], sz = [-1, 1])                          // CYD posts
                y_cyl(cyd_post_d, hy[1] - t - cyd_glass, hy[1] - t + 0.01, sx * cyd_holes[0] / 2, cyd_z + sz * cyd_holes[1] / 2);
            translate([0, 0, 0]) cam_block();
            for (p = cb_pts) corner_boss(p);
        }
        // pivots: the key socket from the outside boss in, and the M3 insert at the inner end
        for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) {
            k = pivot_key_sock;
            translate([hw / 2 + yoke_gap - key_len - 0.5, -k / 2, -k / 2]) cube([key_len + 0.5 + 1, k, k]);
            x_cyl(insert_m3[0], hw / 2 - t - boss_in - 0.01, hw / 2 - t - boss_in + insert_m3[1]);
            x_cyl(3.4 + cal_hole, hw / 2 - t - boss_in - 1, hw / 2 + 2);
        }
        x_cyl(6.5, crank_x0 - 1, hw / 2 - t - boss_in + 0.01);        // right: reach the pivot insert through the crank
        x_cyl(insert_m3[0], crank_x0 - 0.01, crank_x0 + insert_m3[1] + 1, crank_pin[0], crank_pin[1]);   // crank pin insert
        // the face: screen window, mouth opening
        translate([cyd_lit_dx, hy[1] + 1, cyd_z]) rotate([90, 0, 0]) linear_extrude(t + 2) oct_poly(cyd_lit[0] + 1, cyd_lit[1] + 1, win_chamfer);
        y_cyl(mouth_d + 0.3 + cal_hole, hy[1] - t - 1, hy[1] + 1, 0, cam_z);
        // CYD inserts (M2.5) from the posts' ends
        for (sx = [-1, 1], sz = [-1, 1])
            y_cyl(insert_m25[0], hy[1] - t - cyd_glass - 0.01, hy[1] - t - cyd_glass + insert_m25[1], sx * cyd_holes[0] / 2, cyd_z + sz * cyd_holes[1] / 2);
        // corner inserts (M3) from the split
        for (p = cb_pts) y_cyl(insert_m3[0], y_split - 0.01, y_split + insert_m3[1] + 1, p[0], p[1]);
        // open below
        translate([-bottom_open / 2, y_split - 1, hz[0] - 1]) cube([bottom_open, hy[1] - t - y_split + 1, t + 2]);
    }
}

module corner_boss(p) {          // along y from the split, sloped into the corner walls (printable face-down)
    dir = [sign(p[0]), sign(p[1])] / sqrt(2);
    hull() {
        y_cyl(cb_d, y_split, y_split + cb_len, p[0], p[1]);
        y_cyl(1, y_split, y_split + cb_len + 11, p[0] + 6 * dir[0], p[1] + 6 * dir[1]);
    }
}

// the mouth + camera block: from the face's inside to the camera board's front face
module cam_block() {
    difference() {
        translate([0, y_cam, 0]) rotate([-90, 0, 0]) linear_extrude(hy[1] - t - y_cam + 0.01)
            translate([0, -(blk_z[0] + blk_z[1]) / 2]) rrect2(2 * blk_x, blk_z[1] - blk_z[0], 3);
        y_cyl(bore_d + cal_hole, y_cam - 1, hy[1], 0, cam_z);                                  // ring + diffuser bore
        translate([-comp[0] / 2, y_cam - 1, cam_z - comp[1] / 2]) cube([comp[0], hy[1] - ring_back - y_cam + 1, comp[1]]);   // board's front parts
        for (sx = [-1, 1], sz = [-1, 1])                                                      // clip inserts
            y_cyl(insert_m3[0], y_cam - 0.01, y_cam + insert_m3[1] + 1, sx * clip_x, cam_z + sz * clip_hole);
    }
}

// ==== CAP ===================================================================================================
module head_cap_v2() {
    difference() {
        union() {
            difference() {
                along_y(hy[0], y_split) octagon();
                along_y(hy[0] + t, y_split + 1) octagon(t);
            }
            difference() {                                           // the lip, inside the front
                along_y(y_split - 0.01, y_split + lip[0]) octagon(t + lip[2]);
                along_y(y_split - 1, y_split + lip[0] + 1) octagon(t + lip[2] + lip[1]);
                for (p = cb_pts) y_cyl(cb_d + 1, y_split - 1, y_split + lip[0] + 1, p[0], p[1]);
            }
            for (p = cb_pts) intersection() {                         // screw tubes
                y_cyl(8, hy[0], y_split, p[0], p[1]);
                along_y(hy[0], y_split) octagon();
            }
        }
        for (p = cb_pts) {
            y_cyl(3.4 + cal_hole, hy[0] - 1, y_split + 1, p[0], p[1]);
            y_cyl(6.2 + cal_hole, hy[0] - 1, hy[0] + 3, p[0], p[1]);                          // head recess
        }
        translate([-bottom_open / 2, hy[0] + t, hz[0] - 1]) cube([bottom_open, y_split - hy[0], t + 2]);   // open below
        translate([-15, hy[0] - 1, hz[0] - 1]) cube([30, t + 2, 16]);                                     // cable exit
    }
}

// ==== DIFFUSER (white), in its own frame: z = 0 at the face, + = into the head ===============================
module mouth_diffuser() {
    difference() {
        union() {
            cylinder(d = mouth_d, h = diff_t);                                // the light passes only this
            difference() {                                                     // a thin collar to the wall's back,
                union() {                                                      //   then the rim behind the wall
                    cylinder(d = mouth_d, h = t);
                    translate([0, 0, t]) cylinder(d = bore_d - 0.3, h = rim_t);
                }
                translate([0, 0, -1]) cylinder(d = mouth_d - 2 * diff_collar, h = t + rim_t + 2);
            }
            for (a = [90, 210, 330]) rotate([0, 0, a])                         // legs: the ring rests on them
                translate([ring[0] / 2 - 1.6, -1, t]) cube([1.4, 2, ring_front - t]);
            cylinder(d = baffle[0], h = baffle[1]);                            // lens baffle
        }
        translate([0, 0, -1]) cylinder(d = lens_hole, h = baffle[1] + 2);
    }
}

// ==== CAM CLIP: a U-channel across the camera board's back, in its own frame (z = 0 at the block's face) ======
module cam_clip() {
    w = clip[0]; bt = clip[1]; rise = clip[2]; c = clip[3];
    e = cam_b[1] / 2;                       // board edge from the lens
    h = rise + bt;
    module blk(z0, z1, y0, y1) translate([-w / 2, z0, y0]) cube([w, z1 - z0, y1 - y0]);
    difference() {
        union() {
            for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) {
                blk(e + c + bt, clip_hole + 4, 0, bt);       // foot
                blk(e + c, e + c + bt, 0, h);                // leg
            }
            blk(-e - c - bt, e + c + bt, rise, h);           // bridge
        }
        for (s = [-1, 1]) translate([0, s * clip_hole, -1]) cylinder(d = 3.4 + cal_hole, h = bt + 2, $fn = 24);
    }
}

// ==== views =====================================================================================================
module board_models() {
    color("#c98d1a") translate([-cyd_b[0] / 2, hy[1] - t - cyd_glass - cyd_b[2], cyd_z - cyd_b[1] / 2]) cube([cyd_b[0], cyd_b[2], cyd_b[1]]);
    color("#0b0d10") translate([-58.3 / 2, hy[1] - t - cyd_glass, cyd_z - cyd_b[1] / 2]) cube([58.3, cyd_glass, cyd_b[1]]);
    color("#2e7d32") translate([-cam_b[0] / 2, y_cam - cam_b[2], cam_z - cam_b[1] / 2]) cube([cam_b[0], cam_b[2], cam_b[1]]);
    color("#111") translate([-7.2, y_cam, cam_z - 7.2]) cube([14.4, 10.6, 14.4]);
    color("#222") y_cyl(11, y_cam + 10.6, y_cam + lens_h, 0, cam_z);
    color("#1d1d1d") difference() { y_cyl(ring[0], hy[1] - ring_back, hy[1] - ring_front, 0, cam_z); y_cyl(ring[1], hy[1] - ring_back - 1, hy[1], 0, cam_z); }
}

module assembled() {
    color("#eef0f3") head_front_v2();
    color("#d9dde3") head_cap_v2();
    color("#fff4e0") translate([0, hy[1], cam_z]) rotate([90, 0, 0]) mouth_diffuser();
    color("#6b8fb5") for (sx = [-1, 1]) translate([sx * clip_x, y_cam, cam_z]) rotate([90, 0, 0]) cam_clip();
    board_models();
    color("#f2b84b") for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0])
        translate([hw / 2 + yoke_gap + 13, 0, 0]) rotate([0, -90, 0]) ear(pivot_stub, 1, pivot_key);   // its z = 13: the boss
}

if (part == "all") {
    if (section) difference() { assembled(); translate([-200, -100, -100]) cube([200, 200, 200]); }
    else assembled();
}
if (part == "front")    translate([0, 0, hy[1]]) rotate([-90, 0, 0]) head_front_v2();               // face on the bed
if (part == "cap")      translate([0, 0, -hy[0]]) rotate([90, 0, 0]) head_cap_v2();                  // back on the bed
if (part == "ears")     for (i = [0, 1]) translate([i * 38, 0, 0]) ear(pivot_stub, 1, pivot_key);    // cap-down
if (part == "diffuser") mouth_diffuser();                                                            // face-down
if (part == "clips")    for (i = [0, 1]) translate([i * 16, 0, 0]) cam_clip();                      // feet down
if (part == "coupon")   translate([0, 0, hy[1]]) rotate([-90, 0, 0]) intersection() {               // the face only
    head_front_v2();
    translate([-hw, y_cam - 1, -hw]) cube([2 * hw, hy[1] - y_cam + 2, 2 * hw]);
}
