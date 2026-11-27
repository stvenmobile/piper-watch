// CrowPanel Advanced 5" ESP32-P4 (Elecrow DHE04005D) - simple model for fit checks (not printed).
// Dimensions: params.scad, cp5_* (taken from Elecrow's STEP model, 2026-11-26).
// Origin = a corner of the board's BACK face; X along the long side; screen faces -Z (see params.scad).
// Seen from the front, X is mirrored: the USB-C edge is on the left.
//
// Version 1.0.1 - created 2026-11-26, last modified 2026-11-26
// History:
//   1.0.1  2026-11-26  Pixel area drawn at its measured size and position (cp5_active_c).
//   1.0.0  2026-11-26  First version: board, LCD, pixel area, holes, back keep-out, edge features.
include <../params.scad>

module crowpanel_p4_5in(camera = false, keepout = true) {
    // board with its 4 holes
    color("darkgreen") difference() {
        translate([0, 0, -cp5_board[2]])
            cube(cp5_board);
        for (h = cp5_holes)
            translate([h[0], h[1], -cp5_board[2] - 1]) cylinder(d = cp5_hole_d, h = cp5_board[2] + 2);
    }
    // LCD module on the front, with the (estimated) pixel area
    color("black")
        translate([cp5_lcd_xy[0], cp5_lcd_xy[1], -cp5_board[2] - cp5_lcd[2]]) cube(cp5_lcd);
    color("royalblue")
        translate([cp5_active_c[0] - cp5_active[0] / 2, cp5_active_c[1] - cp5_active[1] / 2, -cp5_board[2] - cp5_lcd[2] - 0.01])
            cube([cp5_active[0], cp5_active[1], 0.01]);
    // back: everything stays inside this block
    if (keepout)
        color("gray", 0.25) translate([0, 0, 0]) cube([cp5_board[0], cp5_board[1], cp5_back_h]);
    // edge features
    color("silver") for (u = cp5_usbc) translate(u) cube(cp5_usbc_sz);
    color("white") for (b = cp5_buttons) translate(b) cube(cp5_button_sz);
    color("silver") for (e = cp5_edge_x0) translate([e[0], e[1], e[2]]) cube([e[3], e[4], e[5]]);
    color("white") translate([cp5_conn_r[0], cp5_conn_r[1], cp5_conn_r[2]])
        cube([cp5_conn_r[3], cp5_conn_r[4], cp5_conn_r[5]]);
    color("tan") translate([cp5_cam_conn[0], cp5_cam_conn[1], cp5_cam_conn[2]])
        cube([cp5_cam_conn[3], cp5_cam_conn[4], cp5_cam_conn[5]]);
    if (camera)
        color("orange") translate([cp5_cam[0], cp5_cam[1], cp5_cam[2]]) cube([cp5_cam[3], cp5_cam[4], cp5_cam[5]]);
}

crowpanel_p4_5in();
