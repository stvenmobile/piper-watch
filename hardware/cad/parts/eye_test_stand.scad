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
board_t    = 1.3;                           // MEASURED
lens_h     = 14.0;                          // MEASURED: board top -> front of the lens
block_h    = 10.6;                          // MEASURED: board top -> top of the lens holder's square block
// also MEASURED: block 14 x 14; lens barrel 9 dia (11 across its four small flanges); front:
//   connector 6 tall (allow 8 with wires), microphones 5.8; back: tallest part 3.0 (ground solder)
lens_recess = 0.5;                          // lens sits this far behind the face (protected)
z_board    = lens_h + lens_recess;          // 14.5: board front = back face of the puck
board_gap  = z_board - ring_back;           // 5.8: ring back -> board front
puck_r     = ring_od / 2 + ring_clr + 0.05 + 2.4;   // wall round the ring pocket
front_t    = 2.5;                           // front plate in the middle
comp_pocket = [44, 22];                     // clear area for the board's front parts (stays inside
                                            //   the chamber's inner wall, so no light leaks in)
lens_hole  = 16.5;                          // square: the ~15 mm lens holder passes through
lens_d     = 11;                            // MEASURED: lens barrel across its four small flanges
window_clr = 2;                             // clearance round the lens in the face window (print 2:
                                            //   the face's big flared cone showed the board and wires)
// print 1 fit: the mics and two coils on the board's front kept it off the back face
mic_d      = 6.1;                           // MEASURED
mic_gap    = 69.2;                          // MEASURED: between the mics' inner edges
mic_notch  = [mic_d + 0.7, 5.8 + 0.5];      // [diameter, depth]: mics stand 5.8 proud of the board
coil_cut   = [4, 5];                        // extends the clear pocket 4 mm left (seen from the back),
                                            //   from the mics' centreline to 5 mm above it
coil_depth = 4.5;                           // coils ~3.3 tall + clearance (stays behind the ring PCB)

// ---- snap tabs ------------------------------------------------------------------------------
tab_x      = [-18, 18];                     // top-edge tab positions along the board
bot_inset  = 3.1;                           // MEASURED: along the middle, the board's bottom edge is
                                            //   cut back this far - one bottom tab, centred, catches it
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
        // the two coils on the board's front: a bay off the left side of the pocket (as seen
        // from the back, i.e. -x), from the mics' centreline up 5 mm
        translate([-comp_pocket[0] / 2 - coil_cut[0], -0.5, z_board - coil_depth])
            cube([coil_cut[0] + 1, coil_cut[1] + 1, coil_depth + 1]);
        // semicircular notches for the microphones (they also index the board side to side)
        for (sx = [-1, 1]) translate([sx * (mic_gap / 2 + mic_d / 2), 0, z_board - mic_notch[1]])
            cylinder(d = mic_notch[0], h = mic_notch[1] + 1, $fn = 48);
        // lens holder opening through the front plate (small chamfer at the face)
        translate([0, 0, -0.01]) linear_extrude(front_t + 0.02, scale = lens_hole / (lens_hole + 1.6))
            square(lens_hole + 1.6, center = true);
    }
}

module tab(x, s, y_in, h, len = tab_len, w = tab_w, lip = tab_lip) {   // s = +1 top edge, -1 bottom
    translate([x - len / 2, 0, 0]) {
        // upright, just outside the board edge
        translate([0, s > 0 ? y_in : y_in - w, z_board]) cube([len, w, h + 0.8]);
        // lip over the board's back; its top is chamfered so the board pushes past it
        rotate([90, 0, 90]) linear_extrude(len)                   // 2D: (y, z), extruded along x
            polygon([[y_in, z_board + h], [y_in - s * lip, z_board + h], [y_in, z_board + h + 0.8]]);
    }
}

// fills the face's big flared opening (sized for the housed camera) back in, leaving a round
// window just round the lens, with a small chamfer
module window_bezel() {
    w = lens_d + 2 * window_clr;
    difference() {
        cylinder(r = 17, h = front_t, $fn = 120);
        translate([0, 0, -0.01]) cylinder(d1 = w + 1.0, d2 = w, h = 0.5 + 0.01, $fn = 96);
        translate([0, 0, 0.49]) cylinder(d = w, h = front_t, $fn = 96);
    }
}

module tabs() {
    h = board_t + 0.2 + 1.0;                 // board + play + 1.0 for solder joints on its front (print 1)
    for (x = tab_x) tab(x, 1, board[1] / 2 + board_clr, h);                 // top edge: two flexing tabs
    // bottom edge: one RIGID hook, centred (print 3: a thin flexing tab snapped off). Fit the board
    // by hooking its bottom edge under it first, then press the top edge past the top tabs.
    // print 4: at 2.4 thick it was too stiff to spring out for the board - halved to 1.2, taken
    // off the BACK (tab() keeps the board-side face at y_bot, so the hook position is unchanged).
    hook_len = 10; hook_w = 1.2; hook_lip = 0.8;
    y_bot = -(board[1] / 2 + board_clr) + bot_inset;
    tab(0, -1, y_bot, h, hook_len, hook_w, hook_lip);
    // its base: the centre is over the clear pocket, so a bracket grows from the pocket's bottom
    // wall (y = -pocket/2) under the hook's FULL width (print 3 feedback: it only reached ~1 mm
    // out). Nothing behind the lens can be in its view (the lens is 0.5 mm from the face) and the
    // board's edge is cut back here, so it's free space. 45 deg underside: prints unsupported.
    wall = -comp_pocket[1] / 2;
    rotate([90, 0, 90]) translate([0, 0, -hook_len / 2]) linear_extrude(hook_len)   // 2D: (y, z)
        polygon([[wall - 0.5, z_board], [y_bot, z_board], [y_bot, z_board - 1.5],
                 [wall - 0.5, z_board - 1.5 - (y_bot - wall + 0.5)]]);
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
    window_bezel();
    tabs();
    stem();
}

// ghosts (not printed): LED ring and camera board
%translate([0, 0, ring_back - ring_t]) difference() {
    cylinder(d = ring_od, h = ring_t); translate([0, 0, -1]) cylinder(d = ring_id, h = ring_t + 2);
}
%translate([-board[0] / 2, -board[1] / 2, z_board]) cube([board[0], board[1], board_t]);
%translate([0, 0, z_board - block_h]) linear_extrude(block_h) square(14, center = true);   // lens holder block
%translate([0, 0, z_board - lens_h]) cylinder(d = 11, h = lens_h - block_h);               // lens barrel (with flanges)
