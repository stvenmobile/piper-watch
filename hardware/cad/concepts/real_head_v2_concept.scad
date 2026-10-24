// Concept v2 (2026-10-24): the HEAD is an enclosed box that nods - its front wall carries the 2.4" CYD (the
// "eyes", above) and the C920 camera (below), so both look where Piper looks. The turret (pans) keeps the
// tilt servo low inside and grows a yoke: two cheeks outside the head's side walls with 608 bearings; the
// head turns on M8 bolts through them. Same tilt linkage as the test stand (servo disc, 40 mm link, crank
// on the axle), so the same angles. Draft blocks for proportions and clearances, not parts yet.
// The MOUTH: an Adafruit NeoPixel Ring 12 round the camera lens, behind a white diffuser ring flush with the
// face (animated while Piper speaks).
//   tilt = head angle (deg, + = up; 0 = looking level); pan = deg, + = left.
include <../parts/servo_test_stand.scad>
part = "none";
tilt = 0;
pan  = 0;
rod_c = 75;                      // longer link than the test stand's 40: lifts the head's pivot 35 mm so the
                                 //   nodding head's lower edges clear the tilt servo below it
show_cutaway = false;            // true: the head's near side wall removed to show inside

// ---- the head (frame: the tilt axle at the origin, +Y forward, +Z up) ---------------------------------------
hw       = 106;                  // outside width
hy       = [-28, 47];            // back face .. front face (from the axle)
hz       = [-44, 48];            // bottom edge .. top (from the axle)
t        = 2.5;                  // walls
cyd_b    = [74, 43, 1.8];        // Guition ESP32-2432S024 (2.4"), landscape
cyd_lit  = [48.96, 36.72];
cyd_z    = 22;                   // screen centre (from the axle)
cam_z    = -21;                  // camera lens centre = the mouth's centre
cam_b    = [80, 22, 1.2];
cam_back = 4.5;                  // lens this far behind the face: the board's front connector (8 mm with its plug) clears
                                 //   the ring by 1.6 mm; the 21 mm hole is far too shallow to cut into the view
// mouth: Adafruit NeoPixel Ring 12 (OD 36.8, ID 23.3, 3.4 thick; 4.8 with its wires pressed flat behind)
ring     = [36.8, 23.3, 3.4, 4.8];
diff_t   = 2;                    // white diffuser ring, flush with the face
air      = 3.5;                  // gap between the diffuser and the LEDs: blends 12 dots into a glow

// ---- the yoke on the turret ----------------------------------------------------------------------------------
yoke_gap = 1.5;                  // head side wall to cheek (a washer)
cheek    = 5;
boss_d   = 27;                   // round each 608 (22 mm OD)

module head_box() {
    difference() {
        translate([-hw / 2, hy[0], hz[0]]) cube([hw, hy[1] - hy[0], hz[1] - hz[0]]);
        translate([-hw / 2 + t, hy[0] + t, hz[0] - 1]) cube([hw - 2 * t, hy[1] - hy[0] - 2 * t, hz[1] - hz[0] - t + 1]);  // hollow, open below
        translate([2 - cyd_lit[0] / 2 - 1, hy[1] - t - 1, cyd_z - cyd_lit[1] / 2 - 1]) cube([cyd_lit[0] + 2, t + 2, cyd_lit[1] + 2]);  // screen
        translate([0, hy[1] - t - 1, cam_z]) rotate([-90, 0, 0]) cylinder(d = ring[0] + 1, h = t + 2, $fn = 64);  // mouth
        translate([-15, hy[0] - 1, hz[0] - 1]) cube([30, t + 2, 16]);                                           // cable exit, back
        if (show_cutaway) translate([hw / 2 - t - 1, hy[0] - 1, hz[0] - 1]) cube([t + 2, hy[1] - hy[0] + 2, hz[1] - hz[0] + 2]);
    }
}

module head() {
    color("#eef0f3") head_box();
    // inside the front wall: the CYD (glass to the wall) and the camera board (lens block to the wall)
    color("#0b0d10") translate([2 - cyd_lit[0] / 2, hy[1] - t - 0.3, cyd_z - cyd_lit[1] / 2]) cube([cyd_lit[0], 0.6, cyd_lit[1]]);
    color("#4cc2ff") for (s = [-1, 1]) translate([2 + s * 12, hy[1] - t + 0.4, cyd_z + 1]) rotate([90, 0, 0])
        scale([1, 1.25, 1]) cylinder(d = 13, h = 0.3, $fn = 40);                                           // eyes
    color("#c98d1a") translate([-cyd_b[0] / 2, hy[1] - t - 4.3 - cyd_b[2], cyd_z - cyd_b[1] / 2]) cube([cyd_b[0], cyd_b[2], cyd_b[1]]);
    cam_y = hy[1] - 14 - cam_back;                                                // camera board's front face
    color("#2e7d32") translate([-cam_b[0] / 2, cam_y - cam_b[2], cam_z - cam_b[1] / 2]) cube([cam_b[0], cam_b[2], cam_b[1]]);
    color("#111") translate([-7.2, cam_y, cam_z - 7.2]) cube([14.4, 10.6, 14.4]);
    color("#222") translate([0, cam_y + 10.6, cam_z]) rotate([-90, 0, 0]) cylinder(d = 11, h = 14 - 10.6, $fn = 32);   // lens
    // the mouth: diffuser ring in the face, an air gap, then the LED ring facing forward
    color("#fff4e0") translate([0, hy[1] - diff_t, cam_z]) rotate([-90, 0, 0]) difference() {
        cylinder(d = ring[0] + 1, h = diff_t, $fn = 64);
        translate([0, 0, -1]) cylinder(d = ring[1] - 2, h = diff_t + 2, $fn = 48);
    }
    color("#ff9a3c", 0.55) for (i = [0 : 11]) rotate([0, 0, 0]) translate([0, hy[1] + 0.05, cam_z]) rotate([-90, 0, 0])
        rotate([0, 0, i * 30]) translate([(ring[0] + ring[1]) / 4, 0, 0]) cylinder(d = 5, h = 0.2, $fn = 16);   // glow
    color("#1d1d1d") translate([0, hy[1] - diff_t - air - ring[2], cam_z]) rotate([-90, 0, 0]) difference() {
        cylinder(d = ring[0], h = ring[2], $fn = 64);
        translate([0, 0, -1]) cylinder(d = ring[1], h = ring[2] + 2, $fn = 48);
    }
    // the axle: an M8 through the side walls (out through the yoke's bearings), and the crank on it
    color("#8a8f96") rotate([0, 90, 0]) cylinder(d = 8, h = hw + 2 * (yoke_gap + cheek) + 12, center = true, $fn = 24);
    color("#6b8fb5") hull() {                                                       // crank: the link's pin 15 mm out
        translate([x_link + rod_ball_w / 2 + 0.5, 0, 0]) rotate([0, 90, 0]) cylinder(d = 14, h = 4, $fn = 32);
        translate([x_link + rod_ball_w / 2 + 0.5, arm_h * cos(crank_off), arm_h * sin(crank_off)]) rotate([0, 90, 0]) cylinder(d = 8, h = 4, $fn = 24);
    }
}

module yoke() {
    xo = hw / 2 + yoke_gap;
    for (s = [-1, 1]) {
        x0 = s > 0 ? xo : -xo - cheek;
        color("#d9dde3") hull() {
            translate([x0, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = boss_d + 8, h = cheek, $fn = 48);
            translate([x0, y_axle - 22, z_floor]) cube([cheek, 44, 6]);
        }
    }
    color("#d9dde3") translate([-xo - cheek, y_axle - 22, z_floor]) cube([2 * (xo + cheek), 44, floor_t]);  // floor out to the cheeks
}

module turret_parts() {
    color("#e8a33d") hub();
    color("#d9dde3") intersection() { turret(); box([-x_cheek + 0.5, x_cheek - 0.5], [-60, 60], [-50, 120]); }   // without its old cheeks
    yoke();
    translate([x_horn, y_srv, z_srv]) rotate([0, 90, 0]) rotate([0, 0, 90]) servo_model();
    a = servo_ang(tilt);
    translate([x_horn + disc_h, y_srv, z_srv]) rotate([a, 0, 0]) rotate([0, 90, 0]) rotate([0, 0, 90]) color("#c55") disc();
    A = [y_srv + arm_s * cos(a), z_srv + arm_s * sin(a)];
    B = [y_axle + arm_h * cos(tilt + crank_off), z_axle + arm_h * sin(tilt + crank_off)];
    color("#d4a017") hull() for (p = [A, B]) translate([x_link, p[0], p[1]]) sphere(d = 4, $fn = 16);
}

module orin_case() {
    translate([7.3, 0, z_desk - 17.88]) {
        color("#2b2f36") import("../vitamins/models/seeed_orin_case_shell.stl", convexity = 6);
        color("#1c1f24") translate([0, 0, -17.88 - 2]) import("../vitamins/models/seeed_orin_case_plate.stl", convexity = 6);
    }
}

module base_section() {
    color("#9fb4c8") base();
    color("#9fb4c8") translate([0, 0, z_case_bot - strap_t]) pan_strap();
    color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);
    translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();
}

module robot() {
    orin_case();
    base_section();
    rotate([0, 0, pan]) {
        turret_parts();
        translate([0, y_axle, z_axle]) rotate([tilt, 0, 0]) head();
    }
}

robot();
