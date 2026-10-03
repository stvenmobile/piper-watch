// Head front - the face: a round plate with the camera lens in the middle, framed by a
// glowing ring (a 24-LED WS2812-type ring behind a translucent diffuser). Everything mounts to
// its back:
//   * the LED ring, LEDs facing forward, in a pocket behind a light chamber (hot-glued). Its
//     four power pads (5 V, GND, 15 mm apart) go at the TOP and the DIN/DOUT pads at the
//     BOTTOM: header pins + Dupont plugs then point straight back above and below the camera.
//     Never at the sides - the camera's face is only 0.5 mm behind the ring there.
//   * the C920X camera in a cradle, its lens at the back of a flared opening
// The back cover (separate part) screws onto the four inserts in the rim.
//
// Light path, from the face inward: diffuser ring (separate part, ring_diffuser.scad, pressed
// in flush with the face) -> air gap where the light spreads between LEDs -> the LEDs.
// Three thin spokes cross the air gap to hold the centre of the face to the rest; they sit
// between LEDs (120 deg apart = 8 LED pitches, so if one is between LEDs, all are).
//
// Modelled in PRINT ORIENTATION: the face's outer surface lies on the bed (z = 0) and
// everything else rises from its back, so it prints without supports. In this frame
// X = across the face, Y = up the face, Z = into the head.
include <../params.scad>

// ---- overall --------------------------------------------------------------------
D       = head_size[0];      // 105  face diameter: the smallest circle around the 94 x 29 camera
t_face  = 2.5;               // face plate thickness
rim_d   = 14;                // depth of the front part's rim (the back cover is the rest)
rim_w   = 2.0;               // rim wall thickness
cam_cy  = 0;                 // camera, lens, ring and face all share one centre

// ---- LED ring and its light path (ring and diffuser sizes: params.scad) ------------
ring_clr   = 0.3;            // pocket clearance, each side
mix_gap    = 3.5;            // air between diffuser and LED tops: lets the light spread
chamber_w  = 5.7;            // light chamber width (radial): 5 mm LEDs (~0.3 clear each side); the
                             //   PCB (6.65 wide) rests on the ~0.48 mm ledges either side
spoke_w    = 1.6;            // spokes across the chamber, between LEDs
spokes     = [90 + 7.5, 210 + 7.5, 330 + 7.5];   // half a pitch off the vertical
ring_r     = (ring_od + ring_id) / 4;          // 29.5: radius of the LED centres

led_h = ring_t - 1.6;                          // LEDs stand 1.6 mm proud of the PCB
z_led = diff_t + mix_gap;                      // LED tops (5.5)
z_pcb = z_led + led_h;                         // PCB front face: rests on the chamber's edges (7.1)
z_cam = z_led + ring_t + 0.5;                  // camera's front face, just behind the ring (9.2)

// ---- lens opening ------------------------------------------------------------------------
nose_d     = 16;             // round lens opening at the camera
nose_flare = 40;             // degrees: the opening widens toward the face (no vignetting)

// ---- camera cradle ------------------------------------------------------------------
cam_fit    = 0.4;
cradle_w   = 1.8;
cradle_dep = 15;             // cradle reaches this far behind the camera's front face

// ---- back-cover attachment: [position, direction the web runs into the rim] ----------
boss_d     = 7.5;            // around an M3 heat-set insert (4.1 mm bore)
boss_r     = D/2 - rim_w - boss_d/2 + 0.5;     // centres this far out, on the diagonals
bosses = [for (a = [45, 135, 225, 315]) [boss_r * [cos(a), sin(a)], [cos(a), sin(a)]]];

// ============================================================================
module outline2d(inset = 0) { circle(d = D - 2 * inset, $fn = 240); }

module annulus(r_in, r_out) { difference() { circle(r = r_out, $fn = 180); circle(r = r_in, $fn = 180); } }

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

module ring_block() {
    // solid behind the plate from the lens out past the LED ring, back to the camera's face;
    // the light chamber, ring pocket and lens opening are cut out of it
    translate([0, 0, t_face - 0.01]) linear_extrude(z_cam - t_face + 0.01)
        circle(d = ring_od + 2 * ring_clr + 4, $fn = 180);
}

module camera_cradle() {
    // The camera outline grown into a wall, extruded over the camera's height plus a
    // top and bottom lip, open at the back so the camera slides in from behind.
    intersection() {
        translate([0, cam_cy, z_cam]) rotate([90, 0, 0])              // outline depth -> +Z
            translate([0, 0, -cam_h / 2 - cam_fit - cradle_w])
            difference() {
                linear_extrude(cam_h + 2 * (cam_fit + cradle_w))
                    offset(r = cam_fit + cradle_w) cam_outline();
                translate([0, 0, cradle_w]) linear_extrude(cam_h + 2 * cam_fit)
                    offset(r = cam_fit) cam_outline();
                translate([0, 0, -1]) linear_extrude(cam_h + 10)        // keep the face side open
                    translate([-cam_face_l / 2, -5]) square([cam_face_l, 5 + 0.01]);
            }
        translate([0, 0, z_cam]) linear_extrude(cradle_dep) outline2d();    // only the front part, inside the face
    }
    // in front of the camera, back to the face plate: a wall around its footprint
    translate([0, cam_cy, t_face - 0.01]) intersection() {
        linear_extrude(z_cam - t_face + 0.02) difference() {
            square([cam_w + 2 * (cam_fit + cradle_w), cam_h + 2 * (cam_fit + cradle_w)], center = true);
            square([cam_w + 2 * cam_fit, cam_h + 2 * cam_fit], center = true);
        }
        linear_extrude(z_cam) outline2d();
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

// ---- openings and pockets ---------------------------------------------------------
module cutouts() {
    // lens opening: flares from the lens out to the face
    flare = z_cam * tan(nose_flare);
    translate([0, cam_cy, -0.01]) cylinder(d1 = nose_d + 2 * flare, d2 = nose_d, h = z_cam + 0.02, $fn = 120);
    // diffuser seat, open at the face
    translate([0, 0, -0.01]) linear_extrude(diff_t + 0.01)
        annulus(ring_r - diff_w / 2, ring_r + diff_w / 2);
    // light chamber, down to the PCB: the LEDs sit in it and the PCB rests on its edges (the
    // seat in front is wider, so the diffuser rests on them too). Minus the spokes, which
    // fall between LEDs.
    translate([0, 0, diff_t - 0.01]) linear_extrude(z_pcb - diff_t + 0.02) difference() {
        annulus(ring_r - chamber_w / 2, ring_r + chamber_w / 2);
        for (a = spokes) rotate(a) translate([ring_r, 0]) square([chamber_w + 2, spoke_w], center = true);
    }
    // ring pocket, open at the back - also through the cradle's lips, so the ring can go in
    // from behind (before the camera)
    translate([0, 0, z_pcb]) linear_extrude(z_cam + cradle_dep + 1)
        annulus(ring_id / 2 - ring_clr, ring_od / 2 + ring_clr);
}

difference() {
    union() {
        plate_and_rim();
        ring_block();
        camera_cradle();
        bosses_();
    }
    cutouts();
}

// Ghosts of the parts, for checking fit in the preview (not printed)
%translate([0, 0, z_pcb]) linear_extrude(1.6) annulus(ring_id / 2, ring_od / 2);
%translate([0, cam_cy, z_cam]) rotate([90, 0, 0]) translate([0, 0, -cam_h/2]) linear_extrude(cam_h) cam_outline();
