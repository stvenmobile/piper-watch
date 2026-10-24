// Concept: the real Piper head (2026-10-24 plan) - the proven test-stand parts plus the planned changes, to see
// the whole thing. Real parts: base section, pillow block, hub, turret floor + tilt servo + linkage, stand-in
// head with the C920 holder, Seeed's Orin case. Planned (simple blocks, not designed yet): the mid-section box
// (side walls ~100 mm apart with 608 bearing bosses and M8 axles, a front wall carrying the 2.4" CYD), and
// the base section widened to the Orin case's 100 mm main part.
//   tilt = head angle (deg, + = up); pan = deg, + = left.
include <../parts/servo_test_c920.scad>
part = "none";
tilt = 20;
pan  = 0;

// ---- planned dimensions -----------------------------------------------------------------------------------
box_in   = 100;                  // mid-section: inside width between the side walls
wall_t   = 3;
wall_y   = [-30, 39];            // side walls run from behind the tilt servo to the front wall's face
front_t  = 2;
front_top = z_axle - 5;          // the front wall stops below the tilt axle (keeps the camera's view clear)
cyd_b    = [74, 43, 1.8];        // Guition ESP32-2432S024 (2.4" CYD), landscape
cyd_lit  = [48.96, 36.72];
brg_boss = 27;                   // 608 bearing boss on each side wall
case_dx  = 7.3;                  // the Orin case's 100 mm main part is off-centre: put its centre on the pan axis

module orin_case() {             // Seeed's printable case (meshes not in git: vitamins/models)
    translate([case_dx, 0, z_desk - 17.88]) {
        color("#2b2f36") import("../vitamins/models/seeed_orin_case_shell.stl", convexity = 6);
        color("#1c1f24") translate([0, 0, -17.88 - 2]) import("../vitamins/models/seeed_orin_case_plate.stl", convexity = 6);
    }
}

module base_section() {          // the test-stand base (legs + top plate + pan sleeve), widened later to 100 mm
    color("#9fb4c8") base();
    color("#9fb4c8") translate([0, 0, z_case_bot - strap_t]) pan_strap();
    color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);
    translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();
}

module mid_section() {           // turret floor + tilt servo + the planned box round it
    xo = box_in / 2;
    color("#e8a33d") hub();
    // the test-stand turret without its narrow cheeks (the side walls replace them)
    color("#d9dde3") intersection() { turret(); box([-x_cheek + 0.5, x_cheek - 0.5], [-60, 60], [-50, 120]); }
    color("#d9dde3") box([-xo - wall_t, xo + wall_t], [wall_y[0], wall_y[1]], [z_floor, z_ft]);            // wider floor
    for (s = [-1, 1]) {                                                                                  // side walls
        x0 = s > 0 ? xo : -xo - wall_t;
        color("#eef0f3") hull() {
            box([x0, x0 + wall_t], [wall_y[0], wall_y[1]], [z_floor, front_top]);
            translate([x0, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = brg_boss + 6, h = wall_t, $fn = 48);
        }
        color("#c8ccd2") translate([s > 0 ? xo + wall_t : -xo - wall_t - 4, y_axle, z_axle]) rotate([0, 90, 0])
            cylinder(d = brg_boss, h = 4, $fn = 48);                                                   // bearing boss
        color("#8a8f96") translate([s > 0 ? xo - 14 : -xo - wall_t - 6, y_axle, z_axle]) rotate([0, 90, 0])
            cylinder(d = 8, h = 20 + wall_t, $fn = 24);                                                 // M8 axle
    }
    // front wall with the CYD's window, and the screen showing a pair of eyes
    wz = z_floor + (front_top - z_floor) / 2 - 1;
    color("#eef0f3") difference() {
        box([-xo - wall_t, xo + wall_t], [wall_y[1] - front_t, wall_y[1]], [z_floor, front_top]);
        translate([2 - cyd_lit[0] / 2 - 1, wall_y[1] - 3, wz - cyd_lit[1] / 2 - 1]) cube([cyd_lit[0] + 2, 4, cyd_lit[1] + 2]);
    }
    color("#0b0d10") translate([2 - cyd_lit[0] / 2, wall_y[1] - front_t - 0.5, wz - cyd_lit[1] / 2]) cube([cyd_lit[0], 0.6, cyd_lit[1]]);
    color("#4cc2ff") for (s = [-1, 1]) translate([2 + s * 12, wall_y[1] - front_t + 0.2, wz + 1]) rotate([90, 0, 0])
        scale([1, 1.25, 1]) cylinder(d = 13, h = 0.3, $fn = 40);                                      // eyes
    color("#c98d1a") translate([-cyd_b[0] / 2, wall_y[1] - front_t - 4.3 - cyd_b[2], wz - cyd_b[1] / 2]) cube([cyd_b[0], cyd_b[2], cyd_b[1]]);   // its board, behind the glass
    // the tilt servo, its disc and the link
    translate([x_horn, y_srv, z_srv]) rotate([0, 90, 0]) rotate([0, 0, 90]) servo_model();
    a = servo_ang(tilt);
    translate([x_horn + disc_h, y_srv, z_srv]) rotate([a, 0, 0]) rotate([0, 90, 0]) rotate([0, 0, 90]) color("#c55") disc();
    A = [y_srv + arm_s * cos(a), z_srv + arm_s * sin(a)];
    B = [y_axle + arm_h * cos(tilt + crank_off), z_axle + arm_h * sin(tilt + crank_off)];
    color("#d4a017") hull() for (p = [A, B]) translate([x_link, p[0], p[1]]) sphere(d = 4, $fn = 16);
}

module head_assy() {             // the stand-in head (ears to be widened to reach the side walls) + the camera
    translate([0, y_axle, z_axle]) rotate([tilt, 0, 0]) {
        color("#6b8fb5") head();
        color("#c55") holder();
        color("#e8a33d") top_rail();
        c920();
    }
}

orin_case();
base_section();
rotate([0, 0, pan]) { mid_section(); head_assy(); }
