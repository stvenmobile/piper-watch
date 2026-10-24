// Concept v2 (2026-10-24): the HEAD is an enclosed box that nods - its front wall carries the 2.4" CYD (the
// "eyes", above) and the C920 camera (below), so both look where Piper looks. The turret (pans) keeps the
// tilt servo low inside and grows a yoke: two cheeks outside the head's side walls with 608 bearings; the
// head turns on printed "ear" pins through them (see EARS below). Same tilt linkage as the test stand (servo disc, 40 mm link, crank
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
chamfer  = 15;                   // the front outline is an octagon: 45 deg corners this far in (corner faces
                                 //   ~21 mm; long top, bottom and sides)
win_chamfer = 7;                 // the screen's window: octagonal too, to echo the head (hides a little of the screen)
bottom_open = 70;                // the underside is open this wide (for the link, the cables and nodding)
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
yoke_gap = 1.5;                  // head side wall to cheek: filled by a boss on the head wall touching only the
                                 //   bearing's inner race
cheek    = 8;                    // the 608 (7 wide) sits in it from the inside, a 1 mm lip outside
boss_d   = 27;                   // round each 608 (22 mm OD)
brg      = [22, 8, 7];           // 608-2RS: OD, bore, width

// EARS: one printed piece per side, fitted from outside - an octagonal cap (the "ear"), a shoulder pressing only
// the bearing's inner race, and an 8 mm stub through the bearing into a keyed socket on the head wall. An M3
// through its middle (head recessed in the cap) screws into an insert inside the head wall: it clamps the ear to
// the head and spreads the stub (two slots, a bore narrowing to ~2.6 mm at its end) for a firm fit in the bearing.
ear_d    = 32;                   // cap: across the flats (octagon) - about the size of the cheek's round top
ear_t    = 4;
ear_gap  = 1;                    // cap to the cheek's outer face
key      = 5;                    // square key on the stub's inner end (into the head wall's socket)

module octagon(inset = 0) {      // the head's front outline (x across, y = height), shrunk by `inset`
    offset(delta = -inset) polygon([
        [-hw / 2 + chamfer, hz[0]], [hw / 2 - chamfer, hz[0]], [hw / 2, hz[0] + chamfer], [hw / 2, hz[1] - chamfer],
        [hw / 2 - chamfer, hz[1]], [-hw / 2 + chamfer, hz[1]], [-hw / 2, hz[1] - chamfer], [-hw / 2, hz[0] + chamfer]]);
}

module along_depth(y0, y1) {     // extrude a front outline from y0 back... to y1 (front)
    translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
}

module head_box() {
    difference() {
        along_depth(hy[0], hy[1]) octagon();
        along_depth(hy[0] + t, hy[1] - t) octagon(t);                                                    // hollow
        translate([-bottom_open / 2, hy[0] + t, hz[0] - 1]) cube([bottom_open, hy[1] - hy[0] - 2 * t, t + 2]);  // open below
        translate([2, hy[1] + 1, cyd_z]) rotate([90, 0, 0]) linear_extrude(t + 2) {          // screen window
            w = cyd_lit[0] + 2; h = cyd_lit[1] + 2; c = win_chamfer;
            polygon([[-w / 2 + c, -h / 2], [w / 2 - c, -h / 2], [w / 2, -h / 2 + c], [w / 2, h / 2 - c],
                     [w / 2 - c, h / 2], [-w / 2 + c, h / 2], [-w / 2, h / 2 - c], [-w / 2, -h / 2 + c]]);
        }
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
    // pivots: a boss on each side wall (outside: touches only the bearing's inner race; inside: the M3 insert),
    // and the ears
    for (sd = [-1, 1]) mirror([sd < 0 ? 1 : 0, 0, 0]) {
        color("#eef0f3") translate([hw / 2, 0, 0]) rotate([0, 90, 0]) cylinder(d = 12, h = yoke_gap, $fn = 32);
        color("#eef0f3") translate([hw / 2 - t - 6, 0, 0]) rotate([0, 90, 0]) cylinder(d = 11, h = 6.01, $fn = 32);
        translate([hw / 2 + yoke_gap, 0, 0]) ear();
    }
    // the crank: moulded onto the inside of the right side wall, the link's pin 15 mm from the pivot
    color("#6b8fb5") hull() for (p = [[0, 0, 13], [arm_h * cos(crank_off), arm_h * sin(crank_off), 9]])
        translate([x_link + rod_ball_w / 2 + 0.5, p[0], p[1]]) rotate([0, 90, 0])
            cylinder(d = p[2], h = hw / 2 - t - (x_link + rod_ball_w / 2 + 0.5), $fn = 32);
}

module octagon2d(w) {            // a regular octagon, `w` across the flats
    r = w / 2 / cos(22.5);
    rotate([0, 0, 22.5]) circle(r = r, $fn = 8);
}

module ear(section = false) {   // in its own frame: x = 0 at the head boss's outer face, +x outward
    stub_l = brg[2] - 0.2;                                          // through the bearing (a hair shorter: the clamp
                                                                    //   is on the inner race)
    difference() {
        union() {
            color("#f2b84b") {
                translate([-key - 1, -key / 2, -key / 2]) cube([key + 1.01, key, key]);           // key, into the socket
                rotate([0, 90, 0]) cylinder(d = brg[1], h = stub_l, $fn = 32);                  // stub
                translate([stub_l, 0, 0]) rotate([0, 90, 0]) cylinder(d = 11, h = cheek - stub_l + ear_gap + 0.01, $fn = 32);   // shoulder: through the lip, on the inner race
                translate([cheek + ear_gap, 0, 0]) rotate([0, 90, 0]) linear_extrude(ear_t) octagon2d(ear_d);  // cap
                translate([cheek + ear_gap + ear_t, 0, 0]) rotate([0, 90, 0]) difference() {    // raised ring
                    cylinder(d = 14, h = 1.2, $fn = 48); translate([0, 0, -1]) cylinder(d = 10, h = 3, $fn = 48);
                }
            }
        }
        // M3: clearance through the cap, narrowing to ~2.6 at the stub's inner end (spreads it), head recessed
        translate([-key - 2, 0, 0]) rotate([0, 90, 0]) cylinder(d1 = 2.6, d2 = 3.4, h = key + 2 + stub_l, $fn = 24);
        translate([stub_l - 0.01, 0, 0]) rotate([0, 90, 0]) cylinder(d = 3.4, h = 20, $fn = 24);
        translate([cheek + ear_gap + ear_t - 2.5, 0, 0]) rotate([0, 90, 0]) cylinder(d = 6.2, h = 5, $fn = 24);
        for (a = [0, 90]) rotate([a, 0, 0]) translate([0.5, -0.4, -6]) cube([brg[2], 0.8, 12]);   // slots
        if (section) translate([-20, -20, 0]) cube([40, 40, 20]);
    }
    color("#8a8f96") translate([cheek + ear_gap + ear_t - 2.5, 0, 0]) rotate([0, 90, 0]) cylinder(d = 5.5, h = 2.5, $fn = 24);  // M3 head
}

module yoke() {
    xo = hw / 2 + yoke_gap;
    for (s = [-1, 1]) {
        x0 = s > 0 ? xo : -xo - cheek;
        color("#d9dde3") difference() {
            hull() {
                translate([x0, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = boss_d + 8, h = cheek, $fn = 48);
                translate([x0, y_axle - 22, z_floor]) cube([cheek, 44, 6]);
            }
            translate([x0 - 1, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = 12, h = cheek + 2, $fn = 32);
        }
        color("#b8bec6") translate([s > 0 ? xo : -xo - brg[2], y_axle, z_axle]) rotate([0, 90, 0]) difference() {   // the 608
            cylinder(d = brg[0], h = brg[2], $fn = 48); translate([0, 0, -1]) cylinder(d = brg[1], h = brg[2] + 2, $fn = 32);
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

if (part == "ear") { ear(); translate([0, 45, 0]) ear(section = true); }   // openscad -D 'part="ear"': whole + cut in half
else robot();
