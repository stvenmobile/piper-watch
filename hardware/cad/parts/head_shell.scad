// Head shell - sides, back and the ARCH on top (a half cylinder across the full width and depth).
// Open at the front (the face plate, head_face.scad, closes it) and at the bottom (it slides down
// over head_floor.scad).
//   * camera: a small round window in the arch's front curve, cam_tilt up; the camera plate
//     (head_cam_plate.scad) is held by four M3 x 10 screws from outside, through the side walls,
//     into inserts in its flanges
//   * face: four tabs inside the front edge; M3 screws go from inside through them into the
//     face's inserts (reach in through the open bottom before the floor goes in)
//   * floor: hooks on at the front (the face's tongues into the floor's slots), then two M3 x 8
//     screws through the back wall into the floor's back tabs
//
// PRINT upright (as modelled: open bottom on the bed). The arch's top needs supports INSIDE
// only (tree supports, "touching build plate" off is fine - they stand on the bed through the
// open bottom); the outside surface prints clean.
include <../head.scad>
include <../head_cam.scad>

module shell_outer() {
    translate([0, -hb_d / 2, 0]) rotate([-90, 0, 0]) mirror([0, 1, 0]) linear_extrude(hb_d - face_t) low2d();
    translate([0, 0, arch_z]) arch(arch_r, hb_w);
}

module shell_inner() {
    w = hb_wall;
    // the outline inset by the wall; open at the bottom (between the rounded corners) and into the arch
    translate([0, -hb_d / 2 + w, 0]) rotate([-90, 0, 0]) mirror([0, 1, 0]) linear_extrude(hb_d) {
        offset(r = -w) low2d();
        translate([-(hb_w / 2 - hb_r), -1]) square([hb_w - 2 * hb_r, w + 2]);
        translate([-(hb_w / 2 - w), box_h - hb_r]) square([hb_w - 2 * w, hb_r]);     // up to the arch, not into its front edge
    }
    translate([0, 0, arch_z - 0.01]) arch(arch_r - w, hb_w - 2 * w);
}

module arch(r, len) {           // half cylinder along X, flat side down at z = 0
    intersection() {
        rotate([0, 90, 0]) cylinder(r = r, h = len, center = true, $fn = 160);
        translate([-len, -r - 1, 0]) cube([2 * len, 2 * r + 2, r + 1]);
    }
}

// tabs behind the face's bosses, joined to the nearest wall
module face_tabs() {
    y1 = face_y - face_t - face_boss_len;          // tab front = boss ends
    for (b = face_bosses) intersection() {
        translate([0, y1 - 3, 0]) rotate([-90, 0, 0]) mirror([0, 1, 0]) linear_extrude(3)
            hull() { translate([b[0], b[1]]) circle(d = 9, $fn = 40);
                     translate([sign(b[0]) * hb_w / 2, b[1]]) square([1, 9], center = true); }
        shell_outer();
    }
}

module face_tab_holes() {
    y1 = face_y - face_t - face_boss_len;
    for (b = face_bosses) translate([b[0], y1 - 4, b[1]]) rotate([-90, 0, 0]) cylinder(d = 3.4 + cal_hole, h = 6, $fn = 32);
}

// camera plate screws: clearance holes through the side walls
module cam_holes() {
    for (sx = [-1, 1], p = cam_mount_pts) {
        q = cam_to_head([0, p[0], p[1]]);
        translate([sx * (hb_w / 2 + 1), q[1], q[2]]) rotate([0, sx * 90, 0]) rotate([180, 0, 0])
            cylinder(d = 3.4 + cal_hole, h = hb_wall + 2, $fn = 32);
    }
}

// floor screws: clearance holes through the back wall
module floor_screw_holes() {
    for (x = back_screws) translate([x, -hb_d / 2 - 1, back_screw_z]) rotate([-90, 0, 0])
        cylinder(d = 3.4 + cal_hole, h = hb_wall + 2, $fn = 32);
}

module head_shell() {
    difference() {
        union() {
            difference() { shell_outer(); shell_inner(); }
            face_tabs();
        }
        face_tab_holes();
        cam_holes();
        floor_screw_holes();
        // camera window round the lens, with a small chamfer outside
        at_lens() rotate([-90, 0, 0]) {
            translate([0, 0, -8]) cylinder(d = cam_win, h = 10, $fn = 64);
            translate([0, 0, cam_recess - 0.6]) cylinder(d1 = cam_win, d2 = cam_win + 2.4, h = 1.2, $fn = 64);
        }
    }
}

head_shell();
