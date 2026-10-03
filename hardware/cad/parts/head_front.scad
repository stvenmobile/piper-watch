// Head front - the face. Everything mounts to its back:
//   * two 1.3" eye OLEDs located by pins through their mounting holes (hot-glued pin tips)
//   * the C920X camera in a cradle, its lens behind the round "nose" opening
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
H       = head_size[2];      //  90  face height (eyes + camera, no mouth)
top_r   = 25;                // top corners: big enough to follow the eye ovals (even ~12-14 mm margin)
bot_r   = 12;                // bottom corners: as round as the full-width camera allows
t_face  = 2.5;               // face plate thickness
rim_d   = 14;                // depth of the front part's rim (the back cover is the rest)
rim_w   = 2.0;               // rim wall thickness

// ---- layout (face coordinates, origin at the face centre, +Y = up) ----------------
// Top to bottom: 15 mm margin, eye windows, 4.6 mm between the eye boards and the camera
// cradle, the camera, then just enough below it for the camera's corners to clear the
// rounded bottom corners.
eye_cx     = 22;             // eye board centres at x = +/- this
eye_cy     = 19.5;           // eye board centre height (above the face centre)
eye_act_dy = 1.5;            // EST: active area sits this much above the board centre
eye_glass_dy = 0;            // EST: glass centred on the board (vertically)
cam_cy     = -18.65;         // camera centre = lens centre = nose

// ---- windows and glass pockets ----------------------------------------------------
eye_win    = [32, 18];       // eye windows are ovals this size, on the active area: they show the whole
                             //   drawn eye (central 80x64 px) and hide only the screen's unused corners
glass_inset = 1.0;           // glass front sits this far behind the face surface
glass_clr   = 0.3;           // pocket clearance around the glass, each side (glass sizes are EST)
nose_d     = 16;             // round lens opening at the inside face of the plate
nose_flare = 40;             // degrees: opening widens toward the outside (no vignetting)

// ---- camera cradle ------------------------------------------------------------------
cam_fit    = 0.4;
cradle_w   = 1.8;
cradle_dep = 15;             // cradle reaches this far back (camera slides in from behind)

// ---- back-cover attachment: [position, direction the web runs into the corner] -------
boss_d     = 7.5;            // around an M3 heat-set insert (4.1 mm bore)
bosses = [
    [[ 44, eye_cy - 2.15], [ 1, 0]],                // beside the eye boards, below the round top
    [[-44, eye_cy - 2.15], [-1, 0]],
    [[ 38, -H/2 + 7], [ 1, -1] / sqrt(2)],          // bottom corners, under the camera
    [[-38, -H/2 + 7], [-1, -1] / sqrt(2)],
];

// ============================================================================
module outline2d(inset = 0) {          // face outline: a rounded rectangle
    offset(delta = -inset) hull()
        for (sx = [-1, 1]) {
            translate([sx * (W/2 - top_r), H/2 - top_r]) circle(r = top_r, $fn = 180);
            translate([sx * (W/2 - bot_r), -H/2 + bot_r]) circle(r = bot_r, $fn = 120);
        }
}

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

// Where the eye boards end up (their glass sunk into the plate)
eye_board_z   = glass_inset + eye_t[0];                       // board's front face

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
        translate([0, 0, t_face]) linear_extrude(cradle_dep) outline2d();   // only the front part, inside the face
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
// A display window: the 2D shape (children) cut through the plate, chamfered at the same
// angle as the nose so the opening widens toward the face surface. The chamfer only runs
// through the glass_inset layer in front of the glass.
module flared_window() {
    f = glass_inset * tan(nose_flare);                    // widening at the face, each side
    hull() {
        translate([0, 0, -0.01]) linear_extrude(0.01)
            offset(r = f) children();
        translate([0, 0, glass_inset]) linear_extrude(0.01) children();
    }
    translate([0, 0, glass_inset]) linear_extrude(t_face) children();
}

module cutouts() {
    for (sx = [-1, 1]) {                                  // eyes
        // oval window through the face (the glass pocket behind it stays rectangular)
        translate([sx * eye_cx, eye_cy + eye_act_dy, 0])
            flared_window() scale(eye_win / 2) circle(r = 1, $fn = 120);
        // pocket for the glass, from the back, leaving a glass_inset lip at the face
        translate([sx * eye_cx, eye_cy + eye_glass_dy, glass_inset])
            linear_extrude(t_face) square(eye_glass + [2, 2] * glass_clr, center = true);
    }
    // nose: round, flaring toward the outside so the lens's wide view isn't clipped
    translate([0, cam_cy, 0]) {
        flare = t_face * tan(nose_flare);
        translate([0, 0, -0.01]) cylinder(d1 = nose_d + 2 * flare, d2 = nose_d, h = t_face + 0.02, $fn = 96);
    }
}

difference() {
    union() {
        plate_and_rim();
        eye_pins(eye_cx);
        eye_pins(-eye_cx);
        camera_cradle();
        bosses_();
    }
    cutouts();
}

// Ghosts of the parts, for checking fit in the preview (not printed)
%for (sx = [-1, 1]) translate([sx * eye_cx - eye_board[0]/2, eye_cy - eye_board[1]/2, eye_board_z]) cube([eye_board[0], eye_board[1], eye_t[1]]);
%translate([0, cam_cy, t_face]) rotate([90, 0, 0]) translate([0, 0, -cam_h/2]) linear_extrude(cam_h) cam_outline();
