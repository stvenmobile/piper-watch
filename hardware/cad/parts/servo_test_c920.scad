// C920 camera holder for the servo test stand's head: bolts onto the head's bridge plate (its 4 x M3 holes),
// so the head, its link and the servo calibration don't change.
//
//   The bare C920 board (80 x 22 x 1.2; lens block 14.4 square, 11 tall; microphones 5.1 tall at the ends;
//   parts up to 2 mm on the back, the cable soldered on the back) stands UPRIGHT, facing forward: the camera
//   looks along the bridge, so "bridge level" is still "looking straight ahead".
//   HOLDER  a base on the bridge (4 x M3 down through it, nuts underneath), a grooved rail for the board's
//           bottom edge, and two posts at the ends, behind the board (clear of the microphones)
//   RAIL    the top rail: a groove over the board's top edge, 2 x M3 down into inserts in the posts
//   The rails grip only the board's top and bottom edges (2 mm), open at the back for the cable.
//
// Frame: the head's (as head() in servo_test_stand.scad): axle along X at the origin, +Y forward, +Z up.
// part = "holder" | "rail" | "view"
include <servo_test_stand.scad>
part = "view";                       // (after the include: overrides the stand's own part)

// ---- the board (MEASURED 2026-10-21) --------------------------------------------------------------
c_b      = [80, 22, 1.2];           // length (X), height (Z), thickness (Y)
c_lens   = [14.4, 11];              // lens block: square side, height above the board's front
c_mic    = [7.5, 5.1];              // microphones: diameter, height (centred on the board's ends)
c_back   = 2;                       // tallest parts on the back

// ---- holder -----------------------------------------------------------------------------------------
c_fit    = 0.2;                     // groove clearance on each face of the board
c_slack  = 0.5;                     // extra height between the grooves (the board's height is approximate)
c_grip   = 2;                       // how far the grooves reach over the board's edges
c_lip    = 1.2;                     // groove front lip thickness
c_bwall  = 2;                       // groove back wall thickness
base_t   = 3;
post     = 9;                       // posts: square, at the board's ends, behind it (insert M3 from the top)
rail_t   = 3;                       // top rail: solid above the groove

z_base   = bridge_dz + bridge[2];   // the base sits on the bridge
yb       = head_dy - 2;             // the board's back face: lens block over the bridge, screws clear
yf       = yb + c_b[2];             // ... and front face
zg       = z_base + base_t + 1;     // groove floor = the board's bottom edge
z_top    = zg + c_b[1] + c_slack;   // top groove's ceiling
xr       = c_b[0] / 2 + 0.4;        // grooves' ends (the board's ends + clearance)
gy       = [yb - c_fit, yf + c_fit];                       // groove, Y
ry       = [gy[0] - c_bwall, gy[1] + c_lip];               // rails, Y
py       = [gy[0] - post, gy[0]];                          // posts, Y (behind the board)
px       = [xr, xr + post];                                // posts, X (each side)
z_post   = z_top - c_grip - 0.01;   // post tops: the top rail sits on them
brg_holes = [for (x = [-20, 20], y = [-8, 8]) [x, head_dy + y]];   // the bridge's camera holes

module c920() {                     // the board, for the view and the clash check
    color("#2e7d32") translate([-c_b[0] / 2, yb, zg]) cube([c_b[0], c_b[2], c_b[1]]);
    color("#111") translate([-c_lens[0] / 2, yf, zg + c_b[1] / 2 - c_lens[0] / 2]) cube([c_lens[0], c_lens[1], c_lens[0]]);
    color("#999") for (s = [-1, 1]) translate([s * (c_b[0] / 2 - 1), yf, zg + c_b[1] / 2]) rotate([-90, 0, 0])
        cylinder(d = c_mic[0], h = c_mic[1], $fn = 32);
    color("#666") translate([-c_b[0] / 2 + 4, yb - c_back, zg + 3]) cube([c_b[0] - 8, c_back, c_b[1] - 6]);
}

module holder() {
    difference() {
        union() {
            hull() {                                                                         // base
                box([-bridge[0] / 2, bridge[0] / 2], [head_dy - bridge[1] / 2, head_dy + bridge[1] / 2], [z_base, z_base + base_t]);
                box([-px[1], px[1]], [py[0], ry[1]], [z_base, z_base + base_t]);
            }
            box([-xr, xr], ry, [z_base, zg + c_grip]);                                       // bottom rail
            for (s = [-1, 1]) box(s > 0 ? px : [-px[1], -px[0]], py, [z_base, z_post]);     // posts
        }
        box([-xr, xr], gy, [zg, zg + c_grip + 1]);                                           // bottom groove
        for (h = brg_holes) translate([h[0], h[1], z_base - 1]) hole3(base_t + 2);           // 4 x M3 to the bridge
        for (s = [-1, 1]) translate([s * (px[0] + post / 2), (py[0] + py[1]) / 2, z_post - insert_m3[1]]) insert3();
    }
}

module top_rail() {
    difference() {
        box([-px[1], px[1]], [py[0], ry[1]], [z_post + 0.01, z_top + rail_t]);
        box([-xr, xr], gy, [z_post - 1, z_top]);                                             // top groove
        box([-xr, xr], [ry[1] - c_lip - 0.01, ry[1] + 1], [z_post - 1, z_top - c_grip]);     // (front lip: just c_grip deep)
        box([-xr, xr], [py[0] - 1, gy[0] + 0.01], [z_post - 1, z_top - c_grip]);             // (back: just c_grip deep)
        for (s = [-1, 1]) translate([s * (px[0] + post / 2), (py[0] + py[1]) / 2, z_post - 1]) hole3(z_top + rail_t - z_post + 2);
    }
}

if (part == "holder") translate([0, 0, -z_base]) holder();                                   // base on the bed
if (part == "rail")   translate([0, 0, z_top + rail_t]) rotate([180, 0, 0]) top_rail();      // top face on the bed
if (part == "view") {
    color("#6b8fb5") head();
    color("#c55") holder();
    color("#e8a33d") top_rail();
    c920();
}
