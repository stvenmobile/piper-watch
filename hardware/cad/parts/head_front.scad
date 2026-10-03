// Head front - the face. Everything mounts to its back:
//   * two 1.3" eye OLEDs located by pins through their mounting holes (hot-glued pin tips)
//   * the C920X camera in a cradle, its lens behind the round "nose" opening
//   * the 0.91" mouth OLED in a shallow pocket (hot-glued)
// The glass of each display sits in a pocket cut into the back of the plate, so it is only
// glass_inset (1 mm) behind the face surface. The back cover (separate part) screws onto the
// four inserts in the rim.
//
// Modelled in PRINT ORIENTATION: the face's outer surface lies on the bed (z = 0) and
// everything else rises from its back, so it prints without supports. In this frame
// X = across the face, Y = up the face, Z = into the head.
include <../params.scad>

// ---- overall --------------------------------------------------------------------
W       = head_size[0];      // 100  face width
H       = head_size[2];      // 110  face height
chamf   = 6;                 // top corner chamfers
chin_x  = 15;                // chin: bottom corners cut as 30-60-90 triangles -
chin_y  = chin_x * tan(60);  //   15 mm in along the bottom, ~26 mm up the side
t_face  = 2.5;               // face plate thickness
rim_d   = 14;                // depth of the front part's rim (the back cover is the rest)
rim_w   = 2.0;               // rim wall thickness

// ---- layout (face coordinates, origin at the face centre, +Y = up) ----------------
eye_cx     = 22;             // eye board centres at x = +/- this
eye_cy     = 30.15;          // eye board centre height (above the face centre)
eye_act_dy = 1.5;            // EST: active area sits this much above the board centre
eye_glass_dy = 0;            // EST: glass centred on the board (vertically)
cam_cy     = -4;             // camera centre = lens centre = nose
// Mouth placed so its window's bottom is as far from the face's bottom edge as the eye
// windows' top is from the face's top edge (robot symmetry).
eye_win_top = eye_cy + eye_act_dy + (eye_active[1] + 2 * 1.0) / 2;      // 1.0 = win_margin
mouth_cy    = -(eye_win_top) + (mouth_active[1] + 2 * 1.0) / 2;
mouth_pins = -1;             // mouth board's pin end faces -X (+1 for +X)

// ---- windows and glass pockets ----------------------------------------------------
win_margin  = 1.0;           // window this much larger than the active area, each side
glass_inset = 1.0;           // glass front sits this far behind the face surface
glass_clr   = 0.3;           // pocket clearance around the glass, each side (glass sizes are EST)
mouth_glass_t = 1.5;         // EST: glass part of the mouth module's 2.6 mm
nose_d     = 16;             // round lens opening at the inside face of the plate
nose_flare = 40;             // degrees: opening widens toward the outside (no vignetting)

// ---- camera cradle ------------------------------------------------------------------
cam_fit    = 0.4;
cradle_w   = 1.8;
cradle_dep = 15;             // cradle reaches this far back (camera slides in from behind)

// ---- back-cover attachment: [position, direction the web runs into the corner] -------
boss_d     = 7.5;            // around an M3 heat-set insert (4.1 mm bore)
jaw        = [W/2 - chin_x, -H/2];                 // where the chin cut meets the bottom edge
bosses = [
    [[ 44, H/2 - 9], [ 1,  1]],                     // top corners, clear of the eye boards
    [[-44, H/2 - 9], [-1,  1]],
    [[ 31, -H/2 + 7], [ 4, -7] / norm([4, -7])],    // bottom, tucked into the jaw corners
    [[-31, -H/2 + 7], [-4, -7] / norm([4, -7])],
];

// ============================================================================
module outline2d(inset = 0) {          // face outline: chamfered top, 30-60-90 chin
    offset(delta = -inset)
        polygon([[-W/2 + chin_x, -H/2], [W/2 - chin_x, -H/2], [W/2, -H/2 + chin_y],
                 [W/2, H/2 - chamf], [W/2 - chamf, H/2], [-W/2 + chamf, H/2],
                 [-W/2, H/2 - chamf], [-W/2, -H/2 + chin_y]]);
}

module rrect(size, r) { offset(r = r) square([size[0] - 2*r, size[1] - 2*r], center = true); }

// Camera outline seen from above, as in camera_pod.scad: flat face on y = 0, back at y = cam_d
end_r = 8; end_y = 15; back_a = 33;
module cam_outline() {
    hull() {
        translate([-cam_face_l / 2, 0]) square([cam_face_l, 0.01]);
        for (sx = [-1, 1]) translate([sx * (cam_w / 2 - end_r), end_y]) circle(r = end_r);
        intersection() {
            scale([back_a / cam_d, 1]) circle(r = cam_d, $fn = 180);
            translate([-cam_w, 0]) square([2 * cam_w, cam_d]);
        }
    }
}

// Where the display boards end up (their glass sunk into the plate)
eye_board_z   = glass_inset + eye_t[0];                       // board's front face
mouth_board_z = max(t_face, glass_inset + mouth_glass_t);
mouth_glass_dx = -mouth_pins * (mouth_glass_x + mouth_glass[0] / 2 - mouth_board[0] / 2);

// ---- the parts of the face ------------------------------------------------------
module plate_and_rim() {
    linear_extrude(t_face) outline2d();
    linear_extrude(rim_d) difference() { outline2d(); outline2d(rim_w); }
}

module eye_pins(cx) {
    // the board rests on the plate (or a sliver of standoff); pins locate it, glue holds it
    for (sx = [-1, 1], sy = [-1, 1])
        translate([cx + sx * eye_holes[0] / 2, eye_cy + sy * eye_holes[1] / 2, t_face - 0.01]) {
            if (eye_board_z > t_face) cylinder(d = mount_boss_d, h = eye_board_z - t_face + 0.01);
            cylinder(d = mount_pin_d, h = eye_board_z - t_face + eye_t[1] + mount_pin_out, $fn = 32);
        }
}

module mouth_pocket() {          // a low wall around the board footprint
    clr = 0.3;
    translate([0, mouth_cy, t_face - 0.01])
        linear_extrude(mouth_board_z - t_face + (mouth_t - mouth_glass_t) + 0.4) difference() {
            square([mouth_board[0] + 2*clr + 2.4, mouth_board[1] + 2*clr + 2.4], center = true);
            square([mouth_board[0] + 2*clr, mouth_board[1] + 2*clr], center = true);
            // gap at the pin end so the wires can leave
            translate([mouth_pins * (mouth_board[0] / 2), 0]) square([6, mouth_board[1] - 2], center = true);
        }
}

module camera_cradle() {
    // The camera outline grown into a wall, extruded over the camera's height plus a
    // top and bottom lip, open at the back so the camera slides in from behind.
    intersection() {
        translate([0, cam_cy, t_face]) rotate([90, 0, 0])             // outline depth -> +Z
            translate([0, 0, -cam_h / 2 - cam_fit - cradle_w])
            difference() {
                linear_extrude(cam_h + 2 * (cam_fit + cradle_w))
                    offset(r = cam_fit + cradle_w) cam_outline();
                translate([0, 0, cradle_w]) linear_extrude(cam_h + 2 * cam_fit)
                    offset(r = cam_fit) cam_outline();
                translate([0, 0, -1]) linear_extrude(cam_h + 10)        // keep the face side open
                    translate([-cam_face_l / 2, -5]) square([cam_face_l, 5 + 0.01]);
            }
        translate([-W, -H, t_face]) cube([2 * W, 2 * H, cradle_dep]);  // only the front part
    }
}

module bosses_() {
    // Each boss is a column for an M3 insert, webbed into its corner walls for stiffness
    for (b = bosses) {
        p = b[0]; dir = b[1];
        difference() {
            linear_extrude(rim_d) intersection() {
                outline2d();
                hull() {
                    translate(p) circle(d = boss_d);
                    translate(p + 10 * dir) circle(d = boss_d);
                }
            }
            translate([p[0], p[1], rim_d - insert_m3[1]]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1);
        }
    }
}

// ---- openings and pockets in the plate ---------------------------------------------
module cutouts() {
    for (sx = [-1, 1]) {                                  // eyes
        // window through the plate, framing the active area
        translate([sx * eye_cx, eye_cy + eye_act_dy, -1])
            linear_extrude(t_face + 2) rrect(eye_active + [2, 2] * win_margin, 2);
        // pocket for the glass, from the back, leaving a glass_inset lip at the face
        translate([sx * eye_cx, eye_cy + eye_glass_dy, glass_inset])
            linear_extrude(t_face) square(eye_glass + [2, 2] * glass_clr, center = true);
    }
    // nose: round, flaring toward the outside so the lens's wide view isn't clipped
    translate([0, cam_cy, 0]) {
        flare = t_face * tan(nose_flare);
        translate([0, 0, -0.01]) cylinder(d1 = nose_d + 2 * flare, d2 = nose_d, h = t_face + 0.02, $fn = 96);
    }
    // mouth: window on the active area (EST: centred in the glass) + glass pocket
    translate([mouth_glass_dx, mouth_cy, -1])
        linear_extrude(t_face + 2) rrect(mouth_active + [2, 2] * win_margin, 1.2);
    translate([mouth_glass_dx, mouth_cy, glass_inset])
        linear_extrude(t_face) square(mouth_glass + [2, 2] * glass_clr, center = true);
}

difference() {
    union() {
        plate_and_rim();
        eye_pins(eye_cx);
        eye_pins(-eye_cx);
        mouth_pocket();
        camera_cradle();
        bosses_();
    }
    cutouts();
}

// Ghosts of the parts, for checking fit in the preview (not printed)
%for (sx = [-1, 1]) translate([sx * eye_cx - eye_board[0]/2, eye_cy - eye_board[1]/2, eye_board_z]) cube([eye_board[0], eye_board[1], eye_t[1]]);
%translate([0, cam_cy, t_face]) rotate([90, 0, 0]) translate([0, 0, -cam_h/2]) linear_extrude(cam_h) cam_outline();
%translate([-mouth_board[0]/2, mouth_cy - mouth_board[1]/2, mouth_board_z]) cube([mouth_board[0], mouth_board[1], mouth_t - mouth_glass_t]);
