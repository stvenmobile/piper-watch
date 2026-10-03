// Head front - the face. Everything mounts to its back:
//   * two 1.3" eye OLEDs on stepped pillars (hot-glued pin tips)
//   * the C920X camera in a cradle, its lens behind the round "nose" opening
//   * the 0.91" mouth OLED in a shallow pocket (hot-glued)
// The back cover (separate part) screws onto the four inserts in the rim.
//
// Modelled in PRINT ORIENTATION: the face's outer surface lies on the bed (z = 0) and
// everything else rises from its back, so it prints without supports. In this frame
// X = across the face, Y = up the face, Z = into the head.
include <../params.scad>

// ---- overall --------------------------------------------------------------------
W       = head_size[0];      // 100  face width
H       = head_size[2];      // 100  face height
chamf   = 6;                 // corner chamfer of the face outline
t_face  = 2.5;               // face plate thickness
rim_d   = 14;                // depth of the front part's rim (the back cover is the rest)
rim_w   = 2.0;               // rim wall thickness

// ---- layout (face coordinates, origin at the face centre, +Y = up) ----------------
eye_cx     = 22;             // eye board centres at x = +/- this
eye_cy     = 30.15;          // eye board centre height (board top ends 1 mm under the rim)
eye_act_dy = 1.5;            // EST: active area sits this much above the board centre
cam_cy     = -4;             // camera centre = lens centre = nose
// Mouth placed so its window's bottom is as far from the face's bottom edge as the eye
// windows' top is from the face's top edge (robot symmetry).
eye_win_top = eye_cy + eye_act_dy + (eye_active[1] + 2 * 1.0) / 2;      // 1.0 = win_margin
mouth_cy    = -(eye_win_top) + (mouth_active[1] + 2 * 1.0) / 2;
mouth_pins = -1;             // mouth board's pin end faces -X (+1 for +X)

// ---- windows ------------------------------------------------------------------------
win_margin = 1.0;            // window this much larger than the active area, each side
nose_d     = 16;             // round lens opening at the inside face of the plate
nose_flare = 40;             // degrees: opening widens toward the outside (no vignetting)

// ---- camera cradle ------------------------------------------------------------------
cam_fit    = 0.4;
cradle_w   = 1.8;
cradle_dep = 15;             // cradle reaches this far back (camera slides in from behind)

// ---- back-cover attachment ---------------------------------------------------------
boss_d     = 7.5;            // around an M3 heat-set insert (4.1 mm bore)
bosses     = [[0, H/2 - rim_w - boss_d/2 + 0.01],      // top centre (between the eyes)
              [ 32, -H/2 + rim_w + boss_d/2 - 0.01],   // bottom, either side of the mouth
              [-32, -H/2 + rim_w + boss_d/2 - 0.01],
              [ W/2 - rim_w - boss_d/2 + 0.01, -30],   // sides
              [-W/2 + rim_w + boss_d/2 - 0.01, -30]];

// ============================================================================
module outline2d(inset = 0) {          // chamfered-square face outline
    offset(delta = -inset)
        polygon([[-W/2 + chamf, -H/2], [W/2 - chamf, -H/2], [W/2, -H/2 + chamf], [W/2, H/2 - chamf],
                 [W/2 - chamf, H/2], [-W/2 + chamf, H/2], [-W/2, H/2 - chamf], [-W/2, -H/2 + chamf]]);
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

// ---- the parts of the face ------------------------------------------------------
module plate_and_rim() {
    linear_extrude(t_face) outline2d();
    linear_extrude(rim_d) difference() { outline2d(); outline2d(rim_w); }
}

module eye_pillars(cx) {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([cx + sx * eye_holes[0] / 2, eye_cy + sy * eye_holes[1] / 2, t_face]) {
            cylinder(d = mount_boss_d, h = mount_boss_h);
            cylinder(d = mount_pin_d, h = mount_boss_h + eye_t[1] + mount_pin_out, $fn = 32);
        }
}

module mouth_pocket() {          // a low wall around the board footprint
    clr = 0.3;
    translate([0, mouth_cy, t_face]) linear_extrude(mouth_t + 0.4) difference() {
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
    for (b = bosses) translate([b[0], b[1], 0])
        difference() {
            cylinder(d = boss_d, h = rim_d);
            translate([0, 0, rim_d - insert_m3[1]]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1);
        }
}

// ---- openings through the plate --------------------------------------------------
module windows() {
    for (sx = [-1, 1])                                   // eyes
        translate([sx * eye_cx, eye_cy + eye_act_dy, -1])
            linear_extrude(t_face + 2) rrect(eye_active + [2, 2] * win_margin, 2);
    // nose: round, flaring toward the outside so the lens's wide view isn't clipped
    translate([0, cam_cy, 0]) {
        flare = t_face * tan(nose_flare);
        translate([0, 0, -0.01]) cylinder(d1 = nose_d + 2 * flare, d2 = nose_d, h = t_face + 0.02, $fn = 96);
    }
    // mouth: framed on the glass's active area (EST: centred in the glass)
    glass_dx = -mouth_pins * (mouth_glass_x + mouth_glass[0] / 2 - mouth_board[0] / 2);
    translate([glass_dx, mouth_cy, -1])
        linear_extrude(t_face + 2) rrect(mouth_active + [2, 2] * win_margin, 1.2);
}

difference() {
    union() {
        plate_and_rim();
        eye_pillars(eye_cx);
        eye_pillars(-eye_cx);
        mouth_pocket();
        camera_cradle();
        bosses_();
    }
    windows();
}

// Ghosts of the parts, for checking fit in the preview (not printed)
%for (sx = [-1, 1]) translate([sx * eye_cx, eye_cy, t_face + mount_boss_h]) translate([-eye_board[0]/2, -eye_board[1]/2, 0]) cube([eye_board[0], eye_board[1], eye_t[1]]);
%translate([0, cam_cy, t_face]) rotate([90, 0, 0]) translate([0, 0, -cam_h/2]) linear_extrude(cam_h) cam_outline();
%translate([-mouth_board[0]/2, mouth_cy - mouth_board[1]/2, t_face]) cube([mouth_board[0], mouth_board[1], mouth_t]);
