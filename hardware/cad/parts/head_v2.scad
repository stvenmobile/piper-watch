// Piper's head v2 - the printable parts (from concepts/real_head_v2_concept.scad).
//
// An enclosed box that nods on two printed "ears" in 608 bearings. It splits just behind the pivots:
//
//   FRONT  (head_front_v2) everything that carries load or holds the electronics, in one piece:
//          the face (octagonal screen window, the mouth opening), the top, both side walls with the
//          PIVOT BOSSES (outside: a round boss on the bearing's inner race with the ear's square key
//          socket; inside: the M3 insert), the CRANK (right side wall, 15 mm, an M3 insert for the
//          link's rod end), the CYD posts (4 x M2.5 inserts), the MOUTH CHAMBER (the LED ring's bore
//          behind the face's opening; behind it the lens holder: a square pocket the camera's cube pushes
//          into, and 2 posts with M3 inserts for the strap), and 4 corner bosses with M3 inserts for the
//          back cap. PRINT face-down, no supports.
//   CAP    (head_cap_v2) the back: a lid with the cable exit, a lip that locates it inside the front,
//          4 x M3 x 20 screws into the corner inserts. PRINT back-face down, no supports.
//   EARS   2 x the coupon's ear (parts/head_pivot_coupon.scad), M3 x 20 each into the pivot inserts.
//   DIFFUSER  white: a press fit in the face's opening, flush; a ledge round its edge holds the LED ring
//          2.2 mm back, and a tube round the lens barrel keeps the LEDs' light off the lens. PRINT face-down.
//   STRAP  across the camera board's back, behind the lens: 2 x M3 x 8 into the posts; its pad presses the
//          board, so the cube stays in its pocket. The rest of the board floats.
//
// Fits from the coupons: pivot (params.scad pivot_*), inserts (insert_m3, insert_m25).
// Frame: the tilt axle at the origin, +Y forward, +Z up, X across (+X = the CYD's USB end and the
// crank side - Piper's right... seen from the front, +X is on the LEFT).
//
// ASSEMBLY ORDER: inserts (pivots through the crank's channel on the right; crank pin; CYD posts;
// strap posts; corner bosses) -> the LED ring in from the FRONT (pads to the back, its wires through the
// slot at the top of the chamber), then the diffuser -> the camera's cube into its pocket from behind,
// the strap -> CYD glass to the window, 4 x M2.5 x 6 -> wires -> ears through the yoke's bearings -> cap.
//
// part = "all" (assembled view) | "front" | "cap" | "ears" | "diffuser" | "strap" | "coupon"
//        ("coupon": the face only - window, CYD posts, the mouth chamber and lens holder - to check them first)
include <servo_test_stand.scad>
use <head_pivot_coupon.scad>

part = "all";
section = false;                 // "all": cut in half at x = 0 to show the inside

// ---- the box (as the concept) ----------------------------------------------------------------------
hw       = 106;                  // outside width
hy       = [-28, 47];            // back face .. front face
hz       = [-44, 78];            // bottom .. top (78: 30 taller than the concept, all of it upward - lower, the
                                 //   head's back-bottom hits the tilt servo when looking down)
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
cyd_z    = 42;                   // (22 in the concept: up 10 for the mouth, 10 more between mouth and screen)
cyd_x    = -cyd_lit_dx;          // the board sits off-centre so its VIEWABLE area (the window) is centred,
                                 //   in line with the mouth: +2.25 toward the USB end
win_chamfer = 7;
cyd_post_d = 6.5;

// ---- the mouth: NeoPixel Ring 12 + diffuser in front, the camera held by its lens holder behind -------------
// Depths from the face (mm):  0 - 1.8 diffuser face | 1.8 - 4.0 air | 4.0 - 7.4 LED ring | 7.4 the cube's top
// against a lip (lens front 3.5) | 7.4 - 9.0 the chamber's back wall | to 12.4 the cube pocket (its top 5 mm,
// above the holder's screw bosses) | 17.7 the camera board's front, free | the strap behind it, on 2 posts.
// The ring and the diffuser go in from the FRONT (the face's opening is the ring's bore); the cube from behind.
cam_z    = -12;                  // lens = mouth centre (-22 before the head grew: 10 more face below the mouth)
ring     = [36.8, 23.3, 3.4];    // OD, ID, thickness (4.8 with wires pressed flat)
ring_fit = 0.25;                 // clearance round the ring in its bore
bore_d   = ring[0] + 2 * ring_fit;   // the face's opening and the ring's bore (+ cal_hole when cut)
diff_t   = 1.8;                  // the diffuser's face: flush with the face, the only material the light
                                 //   passes (more than this is too diffusing even in clear-ish filament)
diff_air = 2.2;                  // the diffuser's back -> the ring's front: a ledge round its edge
diff_ledge = 1.0;                //   ... this wide, outside the LEDs (they end at r 17.5)
ring_front = diff_t + diff_air;       // 4.0 behind the face
ring_back  = ring_front + ring[2];    // 7.4
cham_wall = 1.5;                 // the chamber round the ring (its top stays under the CYD's glass)
// the diffuser SNAPS in: 3 fingers run back beside the ring (centring it), a bump on each clicks into a pocket
// in the chamber's wall. They sit outside the ring, so the face's opening is wider than the ring's bore.
snap_a   = [30, 150, 270];       // where (deg round the mouth, from +x toward the top)
snap_w   = 8;                    // each finger's width (along the arc)
snap_t   = 1.0;                  // its thickness
snap_gap = 0.2;                  // between the ring's bore and the fingers
snap_bump = 0.4;                 // how far the bump stands out
snap_at  = [6.0, 6.8];           // the bump's depth behind the face (the fingers end at 6.8)
r_fin    = [bore_d / 2 + snap_gap, bore_d / 2 + snap_gap + snap_t];   // the fingers: inner, outer radius
open_d   = 2 * (r_fin[1] + 0.15);     // 40.0: the face's opening and the chamber's bore (+ cal_hole when cut)
diff_press = 0.3;                // the diffuser's face is drawn this much under the opening (a press fit)
back_t   = 5.0;                  // its back wall (the ring rests on it): 7.4 .. 12.4 behind the face, relieved
                                 //   over the white connector (7.6 off the board) - see conn_relief
conn_relief = [10, 20, 2.2];     // that relief: from x, to x (both sides: either end of the board may be the
                                 //   cable's), and the wall's thickness left there
wire_slot = [8, 7];              // through the back wall, for the ring's wires: width, from r 11.6 out - at the
                                 //   side (+x), beside the cube's pocket and clear of the strap posts above / below
// the C920 (MEASURED): bare board, lens holder = a 14 mm cube with two screw bosses beside it
cam_b    = [80, 22, 1.3];        // board (81 with the microphones)
cube     = [14, 10.3];           // lens holder: side, height above the board
cube_boss = 5.1;                 // its screw bosses' height: the pocket stops above them
barrel_h = 4.1;                  // the lens barrel above the cube (MEASURED; with the cube that is 14.4
lens_h   = cube[1] + barrel_h;   //   to the lens front - another measurement said 14.2)
barrel_d = 8.8;
cube_fit = 0.2;                  // clearance each side in the pocket
cube_lip = [0.8, 12];            // the lip the cube's top stops against: thickness, its hole (the barrel: 8.8,
                                 //   but 11 across four small flanges at its base)
cube_top = ring_back;            // 7.4 behind the face
lens_depth = cube_top - (lens_h - cube[1]);   // 3.5: the lens front behind the face
pcb_depth  = cube_top + cube[1];              // 17.7: the board's front behind the face
y_pcb    = hy[1] - pcb_depth;                 // ... in the head's frame
pocket_end = pcb_depth - cube_boss - 0.2;     // 12.4: the pocket's walls end just above the bosses
pocket_wall = 2.4;
lens_open = 16;                  // the diffuser's opening at the face (the C920's 78 deg view from 3.5 back)
baffle_od = 15;                  // the diffuser's tube round the barrel, back to the lip
// the strap: across the board's back behind the lens, its feet on two posts past the board's edges
strap_post = [7, 16];            // posts: diameter, centre above / below the lens (board edges at +/- 11)
strap    = [8, 2.5, 1.7];        // width, thickness, the tallest part on the board's back (MEASURED)
strap_pad = 6;                   // the bridge touches the board only in a 6 x 6 pad behind the lens

// ---- back-cap screws: corner bosses ------------------------------------------------------------------
cb_d     = 10;
cb_len   = 8;                    // front's bosses: from the split forward
cb_fillet = 2;                   //   fillets where their sides meet the corner wall
bed_chamfer = 0.6;               // the edges that print on the bed: the face (and its window) and the back
cb_pts   = [for (sx = [-1, 1], p = [[40.2, hz[1] - 12.8], [40.2, hz[0] + 12.8]]) [sx * p[0], p[1]]];

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
crank_wedge = 0.84;              // its wedge's slope: 50 deg from vertical as printed (45 reached the camera board)

// ==== FRONT ===============================================================================================
module head_front_v2() {
    difference() {
        union() {
            difference() {                                           // the shell
                along_y(y_split, hy[1]) octagon();
                along_y(y_split - 1, hy[1] - t) octagon(t);
            }
            // printed face-down, these stick out sideways from the side walls: each gets a 45 deg wedge under it
            // (toward the face) back into the wall - the same section, shifted forward by its length, at the wall
            wall_x = hw / 2 - t;
            for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) {       // pivots
                x_cyl(boss_o, hw / 2 - 0.01, hw / 2 + yoke_gap);                      // outside: on the inner race
                behind_flat() hull() {                                                // inside: the insert
                    x_teardrop(boss_in_d, wall_x - boss_in, wall_x + 0.01);
                    x_teardrop(boss_in_d, wall_x - 0.01, wall_x + 0.01, boss_in);
                }
            }
            behind_flat() hull() {                                   // the crank (right wall, +x)
                x_teardrop(boss_in_d, crank_x0, wall_x + 0.01);
                x_cyl(9, crank_x0, wall_x + 0.01, crank_pin[0], crank_pin[1]);              // (the wedge supports it)
                x_teardrop(boss_in_d, wall_x - 0.01, wall_x + 0.01, crank_wedge * (wall_x - crank_x0));
                x_cyl(9, wall_x - 0.01, wall_x + 0.01, crank_pin[0] + crank_wedge * (wall_x - crank_x0), crank_pin[1]);
            }
            for (sx = [-1, 1], sz = [-1, 1])                          // CYD posts
                y_cyl(cyd_post_d, hy[1] - t - cyd_glass, hy[1] - t + 0.01, cyd_x + sx * cyd_holes[0] / 2, cyd_z + sz * cyd_holes[1] / 2);
            mouth_chamber();
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
        translate([cyd_x + cyd_lit_dx, hy[1] + 1, cyd_z]) rotate([90, 0, 0]) linear_extrude(t + 2) oct_poly(cyd_lit[0] + 1, cyd_lit[1] + 1, win_chamfer);
        translate([cyd_x + cyd_lit_dx, 0, cyd_z]) hull() {                                   // ... its edge chamfered on the face
            along_y(hy[1] - bed_chamfer, hy[1] - bed_chamfer + 0.01) oct_poly(cyd_lit[0] + 1, cyd_lit[1] + 1, win_chamfer);
            along_y(hy[1], hy[1] + 0.01) offset(delta = bed_chamfer) oct_poly(cyd_lit[0] + 1, cyd_lit[1] + 1, win_chamfer);
        }
        bed_edge(hy[1], -1);                                                          // the face's outer edge
        mouth_chamber_cuts();
        // CYD inserts (M2.5) from the posts' ends
        for (sx = [-1, 1], sz = [-1, 1])
            y_cyl(insert_m25[0], hy[1] - t - cyd_glass - 0.01, hy[1] - t - cyd_glass + insert_m25[1], cyd_x + sx * cyd_holes[0] / 2, cyd_z + sz * cyd_holes[1] / 2);
        // corner inserts (M3) from the split
        for (p = cb_pts) y_cyl(insert_m3[0], y_split - 0.01, y_split + insert_m3[1] + 1, p[0], p[1]);
        // open below
        translate([-bottom_open / 2, y_split - 1, hz[0] - 1]) cube([bottom_open, hy[1] - t - y_split + 1, t + 2]);
    }
}

// along y from the split: the boss joined to its corner wall by straight sides at right angles to the wall,
// tangent to the boss; its front end slopes into the wall at 45 deg (printable face-down)
module corner_boss(p) {
    dir = [sign(p[0]), sign(p[1])] / sqrt(2);              // the corner wall's normal
    w = p + 9 * dir;                                        // the same circle, reaching into the wall
    intersection() {
        union() {
            along_y(y_split, y_split + cb_len) intersection() {   // filleted where the sides meet the wall
                offset(r = -cb_fillet) offset(delta = cb_fillet) union() {
                    hull() { translate(p) circle(d = cb_d); translate(w) circle(d = cb_d); }
                    difference() { octagon(); octagon(t); }
                }
                translate(p) circle(r = cb_d / 2 + 9 + cb_fillet + 1);
            }
            hull() {                                        // the slope under its front end
                y_cyl(cb_d, y_split, y_split + cb_len, p[0], p[1]);
                y_cyl(cb_d, y_split, y_split + cb_len + 2 * cb_d, w[0], w[1]);
            }
        }
        along_y(y_split, hy[1]) octagon(0.01);              // trimmed to the shell
    }
}

// in the mouth's frame: 2D (x, z) round the lens, extruded from depth d0 to d1 behind the face
module in_mouth(d0, d1) translate([0, hy[1] - d0, cam_z]) rotate([90, 0, 0]) linear_extrude(d1 - d0) children();
// an arc of an annulus r0 .. r1, w (mm, at r1) wide, centred at angle a
module arc2d(r0, r1, a, w) {
    h = w / 2 / r1 * 180 / PI;
    intersection() {
        difference() { circle(r = r1, $fn = 120); circle(r = r0, $fn = 120); }
        polygon([[0, 0], 2 * r1 * [cos(a - h), sin(a - h)], 2 * r1 * [cos(a), sin(a)], 2 * r1 * [cos(a + h), sin(a + h)]]);
    }
}

// the mouth chamber: the ring's bore behind the face's opening, its back wall with the lens holder (a lip and
// the square pocket for the camera's cube) and the strap's two posts. Solids here, cuts in mouth_chamber_cuts().
module mouth_chamber() {
    d2y = function(d) hy[1] - d;                                     // depth behind the face -> y
    pk = cube[0] + 2 * cube_fit;
    y_cyl(open_d + cal_hole + 2 * cham_wall, d2y(ring_back + back_t), hy[1] - t + 0.01, 0, cam_z);   // chamber
    y_cyl(2 * (ring[1] / 2 - 0.25), d2y(cube_top), d2y(cube_top - cube_lip[0]), 0, cam_z);                 // the lip (inside the ring)
    translate([-(pk / 2 + pocket_wall), d2y(pocket_end), cam_z - (pk / 2 + pocket_wall)])            // the pocket's walls
        cube([pk + 2 * pocket_wall, pocket_end - ring_back, pk + 2 * pocket_wall]);
    for (s = [-1, 1]) y_cyl(strap_post[0], y_pcb, d2y(ring_back) , 0, cam_z + s * strap_post[1]);    // strap posts
}
module mouth_chamber_cuts() {
    d2y = function(d) hy[1] - d;
    pk = cube[0] + 2 * cube_fit;
    y_cyl(open_d + cal_hole, d2y(ring_back), hy[1] + 1, 0, cam_z);                                  // opening + bore
    rb = (open_d + cal_hole) / 2;                                                                    // the snaps' pockets
    for (a = snap_a) in_mouth(snap_at[0] - 0.1, snap_at[1] + 0.1) arc2d(rb - 0.1, rb + snap_bump + 0.1, a, snap_w + 1.5);
    translate([-pk / 2, y_pcb - 1, cam_z - pk / 2]) cube([pk, pcb_depth - cube_top + 1, pk]);          // the cube's pocket
    y_cyl(cube_lip[1] + cal_hole, d2y(cube_top) - 0.01, d2y(cube_top - cube_lip[0]) + 0.01, 0, cam_z);           // the barrel through the lip
    translate([ring[1] / 2, d2y(ring_back + back_t) - 1, cam_z - wire_slot[0] / 2])                    // the ring's wires
        cube([wire_slot[1], back_t + 1.01, wire_slot[0]]);
    for (s = [-1, 1]) y_cyl(insert_m3[0], y_pcb - 0.01, y_pcb + insert_m3[1] + 1, 0, cam_z + s * strap_post[1]);   // strap inserts
    for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0])                                                 // over the connector
        translate([conn_relief[0], y_pcb - 1, cam_z - cam_b[1] / 2 - 0.5])
            cube([conn_relief[1] - conn_relief[0], d2y(ring_back + conn_relief[2]) - y_pcb + 1, cam_b[1] + 1]);
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
                for (p = cb_pts) hull() {                     // notched round the corner bosses and their webs
                    y_cyl(cb_d + 1 + 2 * cb_fillet, y_split - 1, y_split + lip[0] + 1, p[0], p[1]);
                    y_cyl(cb_d + 1 + 2 * cb_fillet, y_split - 1, y_split + lip[0] + 1, p[0] + 9 * sign(p[0]) / sqrt(2), p[1] + 9 * sign(p[1]) / sqrt(2));
                }
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
        bed_edge(hy[0], 1);                                                                                // the back's outer edge
    }
}

// a 45 deg chamfer round the outline's edge at the face y = yf (the side on the bed); s = the inward direction
module bed_edge(yf, s) difference() {
    along_y(min(yf, yf + s * bed_chamfer) - 1, max(yf, yf + s * bed_chamfer) + 1) offset(delta = 5) octagon();
    hull() {
        along_y(yf - 0.01, yf + 0.01) octagon(bed_chamfer);
        along_y(yf + s * bed_chamfer - 0.01, yf + s * bed_chamfer + 0.01) octagon();
        along_y(yf + s * (bed_chamfer + 1) - 0.01, yf + s * (bed_chamfer + 1) + 0.01) octagon();
    }
}

// ==== DIFFUSER (white), in its own frame: z = 0 at the face, + = into the head ===============================
// a press fit in the face's opening, flush, and it snaps in: 3 fingers beside the LED ring click into the chamber
module mouth_diffuser() {
    od = open_d + cal_hole - diff_press;
    difference() {
        union() {
            cylinder(d = od, h = diff_t);                                      // the light passes only this
            difference() {                                                     // the ledge the ring rests on
                cylinder(r = bore_d / 2 - 0.05, h = ring_front);
                translate([0, 0, -1]) cylinder(r = bore_d / 2 - 0.05 - diff_ledge, h = ring_front + 2);
            }
            for (a = snap_a) {                                                 // the fingers ...
                translate([0, 0, diff_t - 0.01]) linear_extrude(snap_at[1] - diff_t + 0.01) arc2d(r_fin[0], r_fin[1], a, snap_w);
                hull() {                                                       // ... their bumps: a ramp at the tip,
                    translate([0, 0, snap_at[0]]) linear_extrude(0.2) arc2d(r_fin[0], r_fin[1] + snap_bump, a, snap_w);
                    translate([0, 0, snap_at[1] - 0.01]) linear_extrude(0.01) arc2d(r_fin[0], r_fin[1], a, snap_w);
                }                                                              //   a square catch toward the face
            }
            cylinder(d = baffle_od, h = cube_top - cube_lip[0] - 0.2);              // the tube round the barrel, to the lip
        }
        // the view: a cone from 16 at the face to the barrel's bore at the lens front (clears the C920's
        // 78 deg diagonal), then the bore round the barrel
        translate([0, 0, -0.01]) cylinder(d1 = lens_open, d2 = cube_lip[1] + cal_hole, h = lens_depth + 0.02);
        translate([0, 0, lens_depth]) cylinder(d = cube_lip[1] + cal_hole, h = cube_top);
    }
}

// ==== CAM STRAP: across the camera board's back behind the lens, in its own frame (z = 0 at the posts' ends =
// the board's front; + = back; y = up). Its pad presses the board - and the cube into its pocket.
module cam_strap() {
    w = strap[0]; bt = strap[1];
    e = cam_b[1] / 2 + 0.5;                 // the board's edges + clearance
    pad = cam_b[2];                         // the pad's face: on the board's back
    rise = cam_b[2] + strap[2] + 0.3;       // elsewhere: clear of the parts on the board's back
    module blk(z0, z1, y0, y1) translate([-w / 2, z0, y0]) cube([w, z1 - z0, y1 - y0]);
    difference() {
        union() {
            for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) {
                blk(e + bt, strap_post[1] + strap_post[0] / 2, 0, bt);      // foot, on its post
                blk(e, e + bt, 0, rise + bt);                               // leg
            }
            blk(-e - bt, e + bt, rise, rise + bt);                         // bridge
            translate([-strap_pad / 2, -strap_pad / 2, pad]) cube([strap_pad, strap_pad, rise - pad + 0.01]);   // pad
        }
        for (s = [-1, 1]) translate([0, s * strap_post[1], -1]) cylinder(d = 3.4 + cal_hole, h = bt + 2, $fn = 24);
    }
}

// ==== views =====================================================================================================
module board_models() {
    color("#c98d1a") translate([cyd_x - cyd_b[0] / 2, hy[1] - t - cyd_glass - cyd_b[2], cyd_z - cyd_b[1] / 2]) cube([cyd_b[0], cyd_b[2], cyd_b[1]]);
    color("#0b0d10") translate([cyd_x - 58.3 / 2, hy[1] - t - cyd_glass, cyd_z - cyd_b[1] / 2]) cube([58.3, cyd_glass, cyd_b[1]]);
    color("#2e7d32") translate([-cam_b[0] / 2, y_pcb - cam_b[2], cam_z - cam_b[1] / 2]) cube([cam_b[0], cam_b[2], cam_b[1]]);
    color("#111") translate([-cube[0] / 2, y_pcb, cam_z - cube[0] / 2]) cube([cube[0], cube[1], cube[0]]);
    color("#111") for (s = [-1, 1]) y_cyl(4, y_pcb, y_pcb + cube_boss, s * (cube[0] / 2 + 2), cam_z);   // its screw bosses
    color("#222") y_cyl(barrel_d, y_pcb + cube[1], y_pcb + lens_h, 0, cam_z);
    color("#ddd") translate([12.5, y_pcb, cam_z + cam_b[1] / 2 - 4]) cube([5, 7.6, 4]);   // the white connector + wires (~15 from the lens, at an edge)
    color("#1d1d1d") difference() { y_cyl(ring[0], hy[1] - ring_back, hy[1] - ring_front, 0, cam_z); y_cyl(ring[1], hy[1] - ring_back - 1, hy[1], 0, cam_z); }
}

module assembled() {
    color("#8a8d91") head_front_v2();                  // grey matte PETG
    color("#8a8d91") head_cap_v2();
    color("#fff4e0") translate([0, hy[1], cam_z]) rotate([90, 0, 0]) mouth_diffuser();
    color("#6b8fb5") translate([0, y_pcb, cam_z]) rotate([90, 0, 0]) cam_strap();
    board_models();
    color("#8cc8ec") for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0])
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
if (part == "strap")    cam_strap();                                                                 // feet down
if (part == "coupon")   translate([0, 0, hy[1]]) rotate([-90, 0, 0]) intersection() {               // the face only
    head_front_v2();
    translate([-hw, y_pcb - 1, -hw]) cube([2 * hw, hy[1] - y_pcb + 2, 2 * hw]);
}
