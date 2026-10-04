// Eye test stand: holds the bare C920 board behind the 24-LED ring (with its diffuser), so the
// camera is protected and the ring + camera can be wired to the Jetson and tested before the
// head exists. The front uses the face's own cut-outs (head_front.scad: diffuser seat, light
// chamber with spokes, ring pocket), so it also tests the face's optics.
//
//   * LED ring: pushed in from the back into its pocket (power pads at the top, data at the
//     bottom - their pins come straight out the back, clear of the camera board).
//   * Camera board (80 x 22, bare): snaps onto the back between four small tabs, lens side
//     forward, 5.8 mm behind the ring's back, so the lens (14.0 mm tall) sits 0.5 mm behind the
//     face; only its round barrel passes through the front plate. Route the USB wires from the board's front
//     connector round its long edge to the back (gap between the tabs in the middle).
//   * Stem: ends in a 1/4"-20 nut pocket for a camera tripod, or plugs into eye_test_foot.scad.
//
// PRINT face-down (as modelled: front face on the bed), no supports. The stem lies flat.
include <../params.scad>
use <head_front.scad>

// ---- ring / board positions (match head_front.scad) --------------------------------------
ring_clr   = 0.25;
ring_back  = 2.0 + 3.5 + ring_t;            // diffuser + air gap + ring = 8.7: back of the ring PCB
board      = [80, 22];                      // bare C920 board (measured)
board_t    = 1.6;                           // EST
lens_h     = 14.0;                          // MEASURED: board top -> front of the lens
block_h    = 10.6;                          // MEASURED: board top -> top of the lens holder's square block
lens_recess = 0.5;                          // lens sits this far behind the face (protected)
z_board    = lens_h + lens_recess;          // 14.5: board front = back face of the puck
board_gap  = z_board - ring_back;           // 5.8: ring back -> board front
puck_r     = ring_od / 2 + ring_clr + 0.05 + 2.4;   // wall round the ring pocket
front_t    = 2.5;                           // front plate in the middle
comp_pocket = [44, 22];                     // clear area for the board's front parts (stays inside
                                            //   the chamber's inner wall, so no light leaks in)
lens_hole  = 16.5;                          // square: the ~15 mm lens holder passes through

// ---- snap tabs ------------------------------------------------------------------------------
tab_x      = [-18, 18];                     // tab positions along the board (top and bottom edges)
tab_len    = 6;
tab_w      = 1.2;                           // thin, so they flex
tab_lip    = 0.5;                           // hooks over the board's back
board_clr  = 0.15;                          // each side, top/bottom

// ---- stem -------------------------------------------------------------------------------------
stem       = [16, 16];                      // cross-section (x, z)
stem_len   = 45;                            // below the puck
nut_14     = [11.11 + 0.3, 5.6 + 0.3];      // 1/4"-20 nut: 7/16" across flats, 7/32" thick
screw_14   = 6.6;

module puck() {
    difference() {
        cylinder(r = puck_r, h = z_board, $fn = 180);
        cutouts();                                                  // the face's ring optics
        // clear pocket for the board's front parts, from the front plate back
        translate([0, 0, front_t]) linear_extrude(z_board) square(comp_pocket, center = true);
        // lens holder opening through the front plate (small chamfer at the face)
        translate([0, 0, -0.01]) linear_extrude(front_t + 0.02, scale = lens_hole / (lens_hole + 1.6))
            square(lens_hole + 1.6, center = true);
    }
}

module tabs() {
    h = board_t + 0.2;                       // board sits under the lip with a little play
    for (x = tab_x, s = [-1, 1]) translate([x - tab_len / 2, 0, 0]) {
        y_in = s * (board[1] / 2 + board_clr);                    // tab's inner face
        // upright, just outside the board edge
        translate([0, s > 0 ? y_in : y_in - tab_w, z_board]) cube([tab_len, tab_w, h + 0.8]);
        // lip over the board's back; its top is chamfered so the board pushes past it
        rotate([90, 0, 90]) linear_extrude(tab_len)               // 2D: (y, z), extruded along x
            polygon([[y_in, z_board + h], [y_in - s * tab_lip, z_board + h], [y_in, z_board + h + 0.8]]);
    }
}

module stem() {
    difference() {
        // starts in the puck's outer wall only: clear of the ring pocket and of the ring's data pins
        translate([-stem[0] / 2, -puck_r - stem_len, 0]) cube([stem[0], stem_len + 1.5, stem[1]]);
        // 1/4"-20 nut pocket + screw hole in the end
        translate([0, -puck_r - stem_len - 0.01, stem[1] / 2]) rotate([-90, 0, 0]) {
            rotate(30) cylinder(d = nut_14[0] / cos(30), h = nut_14[1], $fn = 6);
            cylinder(d = screw_14, h = 18, $fn = 32);
        }
    }
}

union() {
    puck();
    tabs();
    stem();
}

// ghosts (not printed): LED ring and camera board
%translate([0, 0, ring_back - ring_t]) difference() {
    cylinder(d = ring_od, h = ring_t); translate([0, 0, -1]) cylinder(d = ring_id, h = ring_t + 2);
}
%translate([-board[0] / 2, -board[1] / 2, z_board]) cube([board[0], board[1], board_t]);
%translate([0, 0, z_board - block_h]) linear_extrude(block_h) square(15, center = true);   // lens holder block
%translate([0, 0, z_board - lens_h]) cylinder(d = 9.5, h = lens_h - block_h);              // lens barrel
