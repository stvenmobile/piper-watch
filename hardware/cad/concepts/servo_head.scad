// Concept: one base box + a servo pan/tilt head (proportions only - estimates, not parts).
//
//   BASE   houses the Jetson (out of its case, on the floor, ports to the back), the 4.3" display
//          in the front wall (the L2 body's window + tapped posts, which fit it), the servo buck
//          and the bus-servo adapter. The PAN servo hangs from the middle of the lid, shaft up.
//   HEAD   a closed box that only PANS, on a thin bearing ring over the lid. The camera pod TILTS
//          inside it, driven directly by the TILT servo beside it; the head's front is a smoked
//          window tall enough for the tilt range, so the mechanism is hidden.
//
// Jetson: NVIDIA's Orin Nano devkit model (vitamins/models/, git-ignored) standing in for the
// Orin NX on Seeed's J401 carrier - measure the real board before any part is designed.
// Servos drawn as STS3215 (45.2 x 24.7 x 35, est. - check the real ones).
//
// F5 to preview. pan / tilt to move it; cutaway = true opens the base and head.
include <../params.scad>

pan     = 0;
tilt    = 15;
cutaway = true;

// ---- base -----------------------------------------------------------------------------------------
base    = [135, 120, 92];       // W, D, H (estimate: display width, Jetson depth, fan clearance)
base_r  = 12;
wall    = 2.5;
floor_t = 3;
lid_t   = 3;
disp_board  = [120.7, 70.2];    // JC4827W543 (as in l2_body.scad)
disp_active = [95.04, 53.86];
disp_glass_t = 4.4;
disp_z  = floor_t + (base[2] - floor_t - lid_t) / 2;    // display centred in the front wall
standoff = 5;                   // Jetson off the floor

// ---- servos ---------------------------------------------------------------------------------------
servo     = [45.2, 24.7, 35];   // length (shaft at one end), width, height below the horn
servo_fl  = [54, 24.7, 2.5];    // mounting flange, ~27 up from the bottom
servo_sh  = 10.5;               // shaft's distance from the near end (est.)
horn_d    = 22;

// ---- head -----------------------------------------------------------------------------------------
gap_bear = 5;                   // bearing ring between lid and head
head     = [135, 58, 54];       // W, D, H
head_r   = 12;
pod      = [90, 28, 30];        // the camera pod (as in neck_options.scad)
win      = [84, 34];            // smoked window: covers the lens over the tilt range

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

module servo_model() {          // shaft along +Z at the origin; body hangs below
    color("#1d3557") {
        translate([servo_sh - servo[0], -servo[1] / 2, -servo[2]]) cube(servo);
        translate([servo_sh - servo[0] / 2 - servo_fl[0] / 2, -servo_fl[1] / 2, -servo[2] + 27]) cube(servo_fl);
    }
    color("#b8b8b8") cylinder(d = horn_d, h = 3, $fn = 40);
}

module base_box() {
    difference() {
        linear_extrude(base[2]) rrect([base[0], base[1]], base_r);
        translate([0, 0, floor_t]) linear_extrude(base[2] - floor_t - lid_t) rrect([base[0], base[1]] - [2, 2] * wall, base_r - wall);
        // display window
        translate([0, base[1] / 2 + 1, disp_z + 2.8]) rotate([90, 0, 0]) linear_extrude(wall + 2) square(disp_active + [2, 2], center = true);
        // ports at the back
        translate([0, -base[1] / 2, floor_t + standoff + 12]) cube([96, wall * 3, 22], center = true);
        // vents: intake low on both sides, exhaust high at the back
        for (sx = [-1, 1], y = [-40 : 8 : 40]) translate([sx * base[0] / 2, y, floor_t + 20]) cube([wall * 3, 3, 26], center = true);
        // pan servo through the lid
        translate([0, 0, base[2] - lid_t - 1]) linear_extrude(lid_t + 2) square([servo[1] + 1, servo[0] + 1], center = true);
        if (cutaway) translate([0, -base[1], -1]) cube([base[0], 2 * base[1], base[2] + 2]);
    }
}

module base_contents() {
    // the display behind its window
    color("#0d1117") translate([0, base[1] / 2 - wall - disp_glass_t / 2, disp_z]) cube([105.5, disp_glass_t, 67.3], center = true);
    color("#1b2a44") translate([0, base[1] / 2 - wall - disp_glass_t - 0.8, disp_z]) cube([disp_board[0], 1.6, disp_board[1]], center = true);
    // the Jetson, ports to the back
    color("#3c6e47") translate([0, -base[1] / 2 + wall + 4 + 45.4, floor_t + standoff]) rotate([0, 0, 180])
        import("../vitamins/models/jetson_orin_nano.stl");
    // servo buck and bus-servo adapter, on the right wall above the Jetson (est. sizes)
    color("#7a5c2e") translate([base[0] / 2 - wall - 12, -10, floor_t + standoff + 45]) cube([12, 50, 30], center = true);
    color("#555") translate([base[0] / 2 - wall - 8, 28, floor_t + standoff + 45]) cube([8, 30, 22], center = true);
    // pan servo, hanging from the lid, shaft up through the middle
    translate([0, 0, base[2] + 1]) rotate([0, 0, 90]) servo_model();
}

module head_unit() {
    z0 = base[2] + gap_bear;
    color("#9aa3ad") translate([0, 0, base[2]]) difference() {                   // bearing ring (thin-section)
        cylinder(d = 90, h = gap_bear, $fn = 96); translate([0, 0, -1]) cylinder(d = 70, h = gap_bear + 2, $fn = 96);
    }
    rotate([0, 0, pan]) translate([0, 0, z0]) {
        // the head shell
        color("#2b2b2b") difference() {
            translate([0, 0, 0]) rotate([90, 0, 0]) translate([0, head[2] / 2, -head[1] / 2])
                linear_extrude(head[1]) rrect([head[0], head[2]], head_r);
            translate([0, 0, wall]) rotate([90, 0, 0]) translate([0, head[2] / 2 - wall, -head[1] / 2 + wall])
                linear_extrude(head[1] - 2 * wall) rrect([head[0], head[2]] - [2, 2] * wall, head_r - wall);
            translate([-pod[0] / 2 - 2.5 + 0, head[1] / 2 - wall - 1, head[2] / 2 - win[1] / 2]) cube([win[0] + 5, wall + 2, win[1]]);
            if (cutaway) translate([0, -head[1], -1]) cube([head[0], 2 * head[1], head[2] + 2]);
        }
        // smoked window
        color("#111", 0.6) translate([-pod[0] / 2 - 2.5, head[1] / 2 - wall, head[2] / 2 - win[1] / 2]) cube([win[0] + 5, 1.5, win[1]]);
        // the pod, offset left so pod + tilt servo sit centred; pivots on the X axis through its middle
        px = -(servo[2] + 6) / 2;
        translate([px, 2, head[2] / 2]) rotate([tilt, 0, 0]) {
            color("#444") rotate([90, 0, 0]) translate([0, 0, -pod[1] / 2]) linear_extrude(pod[1]) rrect([pod[0], pod[2]], 7);
            color("#111") translate([0, pod[1] / 2, 0]) rotate([-90, 0, 0]) cylinder(d = 11, h = 1, $fn = 32);
        }
        // tilt servo beside it, shaft on the pod's axis
        translate([px + pod[0] / 2 + 3, 2, head[2] / 2]) rotate([0, -90, 0]) rotate([0, 0, 90]) servo_model();
    }
}

base_box();
base_contents();
head_unit();
