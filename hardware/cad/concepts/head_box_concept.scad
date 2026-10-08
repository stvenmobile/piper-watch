// Head concept v2 - ROUGH DRAFT for discussion, not a printable part.
// A rounded-rectangle head sitting straight on the turntable plate (no neck). The camera sits
// in a cradle that pivots about a horizontal axis through its lens, and is locked at one of
// three angles - 0, +10 or +20 deg (up) - by a screw through an indexing plate. The face (LED
// ring + lens opening) stays level whatever the camera's angle.
//
// Frame: origin at the centre of the turntable plate's top; +Y = front (face), +Z = up.
include <../params.scad>

hb       = [135, 70, 95];    // width (X), depth (Y), height (Z)
hb_r     = 20;               // corner radius, seen from the front
hb_wall  = 2.5;
tilts    = [0, 10, 20];      // camera positions (deg, up)
show_tilt = 10;              // the solid camera; the others are ghosts
section  = false;            // true: cut the head's left half away (side view of the camera)

face_y   = hb[1] / 2;        // front face plane
face_zc  = hb[2] / 2;        // centre of the face (lens, ring)
lens_set = 16;               // camera's front face this far behind the face's front surface: tilted
                             //   +20, its lower front edge swings ~5 mm forward - it must stay behind the ring
pivot    = [face_y - lens_set, face_zc];   // tilt axis (y, z): along X, through the lens
lens_open = 44;              // lens opening (inside the ring's 52 mm): clears the 78 x 43 deg view at 0..+20 deg
mech     = true;             // show the cradle, brackets and index plate
cheek_x  = cam_w / 2 + 2.5;  // the cradle's side plates, just outside the camera's ends
index_r  = 20;               // radius of the three index holes around the pivot

module rr2d(w, h, r) { offset(r = r) square([w - 2 * r, h - 2 * r], center = true); }

module shell() {
    difference() {
        rotate([-90, 0, 0]) translate([0, -face_zc, -hb[1] / 2]) linear_extrude(hb[1])
            rotate([0, 0, 0]) mirror([0, 1, 0]) rr2d(hb[0], hb[2], hb_r);
        rotate([-90, 0, 0]) translate([0, -face_zc, -hb[1] / 2 + hb_wall]) linear_extrude(hb[1] - 2 * hb_wall)
            mirror([0, 1, 0]) rr2d(hb[0] - 2 * hb_wall, hb[2] - 2 * hb_wall, hb_r - hb_wall);
        // lens opening and the ring's diffuser slot in the face
        translate([0, face_y - hb_wall - 1, face_zc]) rotate([-90, 0, 0]) cylinder(d = lens_open, h = hb_wall + 2, $fn = 64);
        translate([0, face_y - diff_t, face_zc]) rotate([-90, 0, 0]) difference() {
            cylinder(d = ring_od - 1, h = diff_t + 1, $fn = 120); translate([0, 0, -1]) cylinder(d = ring_id + 1, h = 5, $fn = 120);
        }
        // cable passage down through the floor into the turntable's hollow tube
        translate([0, 0, -1]) cylinder(d = 40, h = hb_wall + 2, $fn = 64);
    }
}

module camera_ghost() {     // camera, front face on y = 0 looking +Y, centred on the axis
    translate([0, -cam_d, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
        hull() for (sx = [-1, 1]) translate([sx * (cam_w / 2 - cam_h / 2), 0, 0]) cylinder(d = cam_h, h = cam_d, $fn = 48);
    translate([0, 0.01, 0]) rotate([-90, 0, 0]) cylinder(d = 14, h = 2, $fn = 40);     // lens
}

module cradle() {           // the tilting part: a U around the camera with a pivot pin each side
    difference() {
        union() {
            for (sx = [-1, 1]) translate([sx * cheek_x - 1.25, -cam_d - 2, -cam_h / 2 - 3]) cube([2.5, cam_d + 2, cam_h + 6]);
            translate([-cheek_x, -cam_d - 2, -cam_h / 2 - 3]) cube([2 * cheek_x, 2, cam_h + 6]);      // back strap
            for (sx = [-1, 1]) translate([sx * (cheek_x + 1.25), 0, 0]) rotate([0, sx * 90, 0]) cylinder(d = 5, h = 4, $fn = 24);
            // the arm that carries the locking screw, reaching down-back to the index plate
            translate([cheek_x - 1.25, 0, 0]) rotate([0, 90, 0]) linear_extrude(2.5)
                hull() { circle(d = 8, $fn = 24); rotate(-135) translate([index_r, 0]) circle(d = 7, $fn = 24); }
        }
        translate([cheek_x - 2, 0, 0]) rotate([0, 90, 0]) rotate(-135) translate([index_r, 0]) rotate([0, 90, 0]) cylinder(d = 3.2, h = 6, center = true);
    }
}

module brackets() {         // fixed: two uprights from the floor carry the pivot; one has the index holes
    for (sx = [-1, 1]) translate([sx * (cheek_x + 4.5), pivot[0], 0]) difference() {
        translate([-1.5, -22, hb_wall]) cube([3, 30, pivot[1] - hb_wall + 6]);
        translate([-5, 0, pivot[1]]) rotate([0, 90, 0]) cylinder(d = 5.2, h = 10, $fn = 24);
    }
    // index plate with three holes: 0 / +10 / +20 deg
    translate([cheek_x + 3, pivot[0], pivot[1]]) rotate([0, 90, 0]) difference() {
        hull() for (a = tilts) rotate(-135 + a) translate([index_r, 0]) circle(d = 9, $fn = 24);
        for (a = tilts) rotate(-135 + a) translate([index_r, 0]) circle(d = 2.5, $fn = 16);
    }
}

module head_box(tilt = show_tilt, ghosts = true) {
    color("#eef0f2") difference() { shell(); if (section) translate([-200, -100, -10]) cube([200, 200, 200]); }
    color("#fff2cc") translate([0, face_y - diff_t, face_zc]) rotate([-90, 0, 0]) difference() {
        cylinder(d = ring_od - 1.2, h = diff_t, $fn = 120); translate([0, 0, -1]) cylinder(d = ring_id + 1.2, h = 5, $fn = 120);
    }
    if (mech) color("#9aa3ad") difference() { brackets(); if (section) translate([-200, -100, -10]) cube([200, 200, 200]); }
    translate([0, pivot[0], pivot[1]]) rotate([tilt, 0, 0]) {
        if (mech) color("#6d7a88") cradle();
        color("#202020") camera_ghost();
    }
    if (ghosts) for (a = tilts) if (a != tilt)
        translate([0, pivot[0], pivot[1]]) rotate([a, 0, 0]) color(a < tilt ? "#4a90d9" : "#e8a33d", 0.45) camera_ghost();
}

head_box();
