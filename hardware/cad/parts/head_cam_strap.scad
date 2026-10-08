// Head camera strap - a flat bar across the back of the C920 board, screwed (2 x M3 x 6) onto the
// camera plate's two bosses. It lies 1.7 mm clear of the board's back parts and keeps the board
// against the plate.
//
// PRINT flat (as modelled), no supports.
include <../head_cam.scad>

strap_w = 10;
strap_t = 2.5;
z0 = cam_strap_holes[1] - cam_boss_d / 2;
z1 = cam_strap_holes[0] + cam_boss_d / 2;

module cam_strap() {
    difference() {
        translate([-strap_w / 2, z0, 0]) cube([strap_w, z1 - z0, strap_t]);
        for (z = cam_strap_holes) translate([0, z, -1]) cylinder(d = 3.4 + cal_hole, h = strap_t + 2, $fn = 32);
    }
}

cam_strap();
