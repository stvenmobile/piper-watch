// Rough look at the two tilt drives for the CYD head (blocks, not parts):
//   opt = "A"  direct drive: the tilt servo stands on the outside of the right cheek, its horn on the head
//   opt = "B"  linkage: the tilt servo lies low in the turret; a link runs up behind the head to a crank
// Frame: tilt axle along X at the origin, +Y forward, +Z up. tilt = head angle (deg, + = up).
use <cyd_head_concept.scad>
include <../params.scad>

opt  = "A";
tilt = 0;

head_w = 95;  head_h = 77;  z_hbot = -32.3;      // from cyd_head_concept.scad
gap  = 1.5;   cht = 5;                           // cheek gap + thickness
xc   = head_w / 2 + gap;                         // cheeks' inner faces
srv  = sts_body;                                 // 45.22 x 24.72 x 32

z_floor = opt == "A" ? -44 : -64;                // turret floor top
floor_t = 4;

module servo_blk() {                             // shaft along +Z at the origin, body below, length along +X
    color("#1d3557") translate([-sts_shaft_x, -srv[1] / 2, -srv[2]]) cube(srv);
    color("#c0c0c0") cylinder(d = sts_horn_d, h = sts_horn_h, $fn = 40);
}

module turret_floor() {
    color("#555") translate([-(xc + cht), -32, z_floor - floor_t]) cube([2 * (xc + cht), 64, floor_t]);
    color("#e8a33d") translate([0, 0, z_floor - floor_t - 12]) cylinder(d = 66, h = 12, $fn = 64);    // hub flange
    color("#b0b6bd") translate([-21.5, -20, z_floor - floor_t - 12 - 7]) cube([43, 40, 7]);          // pillow block
    color("#9aa3ad") translate([-40, -40, z_floor - floor_t - 12 - 7 - 4]) cube([80, 80, 4]);        // base plate
}

module cheek(s, top_d = 16) {
    x0 = s > 0 ? xc : -xc - cht;
    color("#555") hull() {
        translate([x0, 0, 0]) rotate([0, 90, 0]) cylinder(d = top_d, h = cht, $fn = 48);
        translate([x0, -16, z_floor - 0.01]) cube([cht, 32, 6]);
    }
}

if (opt == "A") {
    rotate([tilt, 0, 0]) head();
    turret_floor();
    cheek(-1);
    cheek(1, 26);                                                                    // wider round the horn
    // the servo: shaft along -X on the axle, body standing down the outside of the right cheek
    translate([xc + cht + sts_horn_h, 0, 0]) rotate([0, -90, 0]) rotate([0, 0, -90]) servo_blk();
    // its cradle: a box round the body, on the cheek
    color("#777", 0.6) translate([xc + cht, -srv[1] / 2 - 2.5, -srv[0] + sts_shaft_x - 2.5])
        difference() { cube([srv[2] + sts_horn_h + 2.5, srv[1] + 5, srv[0] + 2]); translate([-1, 2.5, 2.5]) cube([srv[2] + sts_horn_h + 1, srv[1], srv[0]]); }
}
if (opt == "B") {
    rotate([tilt, 0, 0]) head();
    turret_floor();
    cheek(-1); cheek(1);
    // tilt servo lying under the head, shaft along +X, its disc at the right; arm and crank both 15 mm
    // pointing BACK (equal arms + link parallel to the pivots' line = head angle equals servo angle)
    z_s = z_floor + srv[1] / 2;
    x_d = head_w / 2 - 6;
    translate([x_d - sts_horn_h - srv[2], 0, z_s]) rotate([0, 90, 0]) rotate([0, 0, 90]) translate([0, 0, srv[2]]) servo_blk();
    color("#c55") translate([x_d, 0, z_s]) rotate([0, 90, 0]) cylinder(d = 32, h = 4, $fn = 48);              // disc
    arm = 15;
    A = [-arm * cos(tilt), z_s - arm * sin(tilt)];   B = [-arm * cos(tilt), -arm * sin(tilt)];
    color("#d4a017") hull() for (p = [A, B]) translate([x_d + 6, p[0], p[1]]) sphere(d = 4, $fn = 16);      // link
    color("#d4a017") hull() { translate([x_d + 6, 0, 0]) rotate([0, 90, 0]) cylinder(d = 8, h = 3, $fn = 24);   // crank
                              translate([x_d + 6, B[0], B[1]]) rotate([0, 90, 0]) cylinder(d = 7, h = 3, $fn = 24); }
}
