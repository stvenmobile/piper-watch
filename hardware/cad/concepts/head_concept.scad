// CONCEPT ONLY - proportions and look, not a printable part.
// Pan-only robot head: a faceted box head (front face + screw-on back) sitting on a
// swappable 15 degree wedge, on a hollow neck, on the turntable, on a cylinder base.
// Face: two 1.3" SH1106 eyes, the C920X lens as a round "nose", a 2.08" SH1122 mouth.
include <../params.scad>

explode = 0;                // try 40: pulls the back cover off to show the two-part head
wedge_a = 15;               // head tilt (degrees up) - set by the swappable wedge

head    = [100, 40, 100];   // width, depth, height
chamfer = 6;
front_d = 14;               // depth of the front (face) part; the back cover is the rest
eye_win = [31, 17];         // EST: 1.3" active area ~29.4 x 14.7 + margin
eye_gap = 14;
eye_z   = 27;
nose_d  = 16;               // round lens opening (chamfered inside so it doesn't vignette)
nose_z  = 0;
mouth_w = [54, 15];         // SH1122 active 51.2 x 12.8 + margin
mouth_z = -30;

neck    = [40, 40, 30];     // chamfered square neck; inside opening 28 x 28 for the wiring
neck_in = 28;
base_d  = 146;
base_h  = 80;
plate_t = 6;                // turntable top plate (on the lazy Susan's inner ring)

module chamfer_box(s, c) {
    hull() {
        translate([-s[0]/2 + c, -s[1]/2, -s[2]/2]) cube([s[0] - 2*c, s[1], s[2]]);
        translate([-s[0]/2, -s[1]/2, -s[2]/2 + c]) cube([s[0], s[1], s[2] - 2*c]);
    }
}
module rwin(w, h, r = 3) {   // rounded window through a face (along Y)
    rotate([90, 0, 0]) linear_extrude(30, center = true)
        offset(r = r) square([w - 2*r, h - 2*r], center = true);
}

// Head, origin at the centre of its bottom face; front faces -Y
module head_front() {
    color("dimgray") difference() {
        intersection() {
            translate([0, 0, head[2]/2]) chamfer_box(head, chamfer);
            translate([-head[0], -head[1]/2 - 1, -1]) cube([2*head[0], front_d + 1, head[2] + 2]);
        }
        translate([0, -head[1]/2, head[2]/2]) {
            // panel line around the face
            translate([0, -14.4, 0]) difference() { rwin(head[0] - 14, head[2] - 14, 6); rwin(head[0] - 16, head[2] - 16, 5); }
            for (sx = [-1, 1]) translate([sx * (eye_win[0] + eye_gap)/2, 0, eye_z]) rwin(eye_win[0], eye_win[1]);
            translate([0, 0, nose_z]) rotate([90, 0, 0]) cylinder(d = nose_d, h = 30, center = true);
            translate([0, 0, mouth_z]) rwin(mouth_w[0], mouth_w[1], 2);
        }
    }
    // what shows through the windows
    translate([0, -head[1]/2 + 2.6, head[2]/2]) {
        for (sx = [-1, 1]) translate([sx * (eye_win[0] + eye_gap)/2, 0, eye_z]) color("white") cube([29.4, 0.5, 14.7], center = true);
        translate([0, 0, nose_z]) rotate([90, 0, 0]) color("#202030") cylinder(d = 11, h = 0.5);
        translate([0, 0, mouth_z]) color("white") cube([51.2, 0.5, 12.8], center = true);
    }
}
module head_back() {
    color("#5a5a5a") difference() {
        intersection() {
            translate([0, 0, head[2]/2]) chamfer_box(head, chamfer);
            translate([-head[0], -head[1]/2 + front_d, -1]) cube([2*head[0], head[1], head[2] + 2]);
        }
        translate([-(head[0] - 6)/2, -head[1]/2 + front_d - 1, 2]) cube([head[0] - 6, head[1] - front_d - 2, head[2] - 4]);
    }
}
module head() {
    head_front();
    translate([0, explode, 0]) head_back();
}

// Wedge: a hollow block whose top is cut at wedge_a
module wedge() {
    color("gray") difference() {
        hull() {
            translate([-neck[0]/2, -neck[1]/2, 0]) cube([neck[0], neck[1], 4]);
            translate([0, 0, 4]) rotate([-wedge_a, 0, 0]) translate([-neck[0]/2, -neck[1]/2, 0]) cube([neck[0], neck[1], 0.01]);
        }
        translate([0, 0, -1]) cube([neck_in, neck_in, 40], center = true);
    }
}

// ---- assembly, bottom up -------------------------------------------------------------
color("dimgray") cylinder(d = base_d, h = base_h);                         // base
translate([0, 0, base_h]) color("silver") cylinder(d = ls_od, h = ls_h);   // lazy Susan
translate([0, 0, base_h + ls_h]) color("gray") cylinder(d = top_plate_d, h = plate_t);
z_neck = base_h + ls_h + plate_t;
translate([0, 0, z_neck]) color("gray") difference() {                    // hollow neck
    translate([0, 0, neck[2]/2]) chamfer_box(neck, 4);
    cube([neck_in, neck_in, 3 * neck[2]], center = true);
}
translate([0, 0, z_neck + neck[2]]) {
    wedge();
    translate([0, 0, 4]) rotate([-wedge_a, 0, 0]) head();
}
