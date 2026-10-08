// Head camera plate - holds the bare C920 board in the arch, cam_tilt up, with its lens 0.5 mm
// inside the arch's window. See head_cam.scad for the layout. Fit: board onto the back face (mics
// into their notches), strap over it (head_cam_strap.scad, 2 x M3 into the bosses), USB wires round
// the board's top edge; then the plate into the shell from below, and four M3 x 10 screws from
// outside through the side walls into the flanges.
//
// PRINT front face down (as modelled in print orientation below): bosses and flanges stand up,
// no supports.
include <../head_cam.scad>

module cam_plate() {               // in the LENS frame
    difference() {
        union() {
            // the plate
            translate([-cam_x_flange + cam_flange_t, cam_y_board, cam_z_range[0]])
                cube([2 * (cam_x_flange - cam_flange_t), cam_plate_t, cam_z_range[1] - cam_z_range[0]]);
            // flanges against the side walls
            for (sx = [-1, 1]) translate([sx > 0 ? cam_x_flange - cam_flange_t : -cam_x_flange, cam_flange_y[0], cam_z_range[0]])
                cube([cam_flange_t, cam_flange_y[1] - cam_flange_y[0], cam_z_range[1] - cam_z_range[0]]);
            // strap bosses behind the plate
            for (z = cam_strap_holes) translate([0, cam_y_board + 0.01, z]) rotate([90, 0, 0])
                cylinder(d = cam_boss_d, h = cam_boss_h + 0.01, $fn = 40);
        }
        // lens holder, the board's front parts, coils, microphones: through the plate
        translate([0, cam_y_board - 1, 0]) rotate([-90, 0, 0]) linear_extrude(cam_plate_t + 2) {
            square(cam_lens_hole, center = true);
            square(cam_comp, center = true);
            translate([-cam_comp[0] / 2 - cam_coil[0], -0.5]) square([cam_coil[0] + 1, cam_coil[1] + 1]);
            for (sx = [-1, 1]) translate([sx * cam_mic_x, 0]) circle(d = cam_mic_d, $fn = 40);
        }
        // strap inserts (bore from the boss tops)
        for (z = cam_strap_holes) translate([0, cam_y_board - cam_boss_h - 0.01, z]) rotate([-90, 0, 0])
            cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 32);
        // flange inserts (bore from the outer faces, along X)
        for (sx = [-1, 1], p = cam_mount_pts) translate([sx * (cam_x_flange + 0.01), p[0], p[1]])
            rotate([0, -sx * 90, 0]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 32);
    }
}

// as printed: front face (lens frame +Y side) down
rotate([-90, 0, 0]) translate([0, -cam_y_front, 0]) cam_plate();

// ghost: the board in place
%rotate([-90, 0, 0]) translate([0, -cam_y_front, 0])
    translate([-cam_board[0] / 2, cam_y_board - cam_board_t, -cam_board[1] / 2]) cube([cam_board[0], cam_board_t, cam_board[1]]);
