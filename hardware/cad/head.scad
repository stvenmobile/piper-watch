// Head - shared dimensions for the face plate, shell, camera plate and floor (concept:
// concepts/head_brow_concept.scad). The head sits straight on the turntable plate, no neck.
//
// Frame: origin at the centre of the turntable plate's top; +Y = front (face), +Z = up.
//
//   FACE   head_face.scad: the front of the box part - two round GC9A01 eyes and the 2.08" OLED
//          mouth, each dropped into a pocket from behind (it centres them) and hot-glued
//   SHELL  head_shell.scad: sides, back and the ARCH on top (a half cylinder across the full width
//          and depth); the camera looks out of a small window in the arch's front curve
//   CAMERA head_cam_plate.scad: holds the bare C920 board at cam_tilt, screwed inside the arch
//   FLOOR  head_floor.scad: screws to the turntable plate; the head ESP32-S3 sits on it
include <params.scad>

// ---- outline ------------------------------------------------------------------------------------
hb_w     = 135;              // width (X)
hb_d     = 70;               // depth (Y)
box_h    = 88;               // the box part (face height); the arch adds arch_r on top -> 123
hb_r     = 20;               // bottom corners, seen from the front (the top meets the arch square)
hb_wall  = 2.5;              // shell walls
arch_r   = hb_d / 2;         // 35: the arch spans the full depth; its axis runs along X at
arch_z   = box_h;            //   y = 0, z = box_h
face_t   = 3.0;              // face plate
face_y   = hb_d / 2;         // 35: front surface of the face

// ---- eyes (module dims: params.scad eye_*) ------------------------------------------------------
eye_dx    = 32;              // eye centres at x = +/- eye_dx
eye_z     = 55;              // eye centre height. Modules mount UPSIDE DOWN (pin tab up; the image
                             //   is flipped in software): the tab then points into the free space
                             //   under the arch, away from the mouth
eye_win   = 34;              // window: the 32.4 mm picture + a thin black margin of glass; hides the
                             //   glass edge and its flex cable
eye_skin  = 1.2;             // face material in front of the display
eye_pocket = eye_board_d + 0.5;     // the board drops into this and centres the display
eye_depth = eye_t + 0.3;     // pocket depth behind the skin

// ---- mouth: 2.08" OLED (params.scad oled_*) ---------------------------------------------------------
mouth_z   = 23;              // centre of the visible area: the module's lower edge clears the floor's tabs
mouth_pin = -1;              // the module's pin end points to -X (seen from the front: the left)
m_win     = oled_va + [0.6, 0.6];   // window: the visible area + 0.3 each side
m_skin    = 1.2;
// along X, from the visible area's centre: the glass's and the board's centres (pins at -X)
m_glass_dx = -mouth_pin * (oled_glass_x + oled_glass[0] / 2 - (oled_va_x + oled_va[0] / 2));   // +2.56
m_pcb_dx   = -mouth_pin * (oled_pcb[0] / 2 - (oled_va_x + oled_va[0] / 2));                     // +1.82

// ---- camera: bare C920 board, in the arch ----------------------------------------------------------
cam_tilt  = 18;              // fixed, up. Lens ~278 mm above the desk: eyes 300-500 mm high at
                             //   300-600 mm are 2..37 deg up; the 43 deg view (16:9) at 18 covers -3..40
cam_board = [80, 22];        // MEASURED (eye_test_stand.scad)
cam_board_t = 1.3;
cam_lens_h  = 14.0;          // board front -> front of the lens
cam_lens_d  = 11;            // lens barrel across its flanges
cam_win     = cam_lens_d + 2 * 2;   // window round the lens (eye test stand, print 2: small is best)
cam_recess  = 0.5;           // lens front this far inside the arch's surface
// the lens axis runs radially out of the arch at cam_tilt: lens front at arch_r - cam_recess
cam_r_lens  = arch_r - cam_recess;                  // 34.5 from the arch axis
cam_r_board = cam_r_lens - cam_lens_h;              // 20.5: board front

// ---- joints -------------------------------------------------------------------------------------------
// face plate -> shell: four M3 screws from inside, through tabs on the shell, into inserts in the
// face's bosses
face_boss_d   = 8;
face_boss_len = 9;           // behind the face's back
face_bosses   = [[-55, 14], [55, 14], [-58, 64], [58, 64]];   // (x, z): the upper pair low enough to
                                                                //   clear the camera plate's flanges

// floor: head_floor.scad. It screws DOWN into four inserts in the turntable plate (head-frame
// positions below); the shell hooks onto it at the front (two tongues on the face plate into slots
// in the floor's front tabs) and screws to it at the back (two M3 through the back wall)
floor_t      = 4.5;          // pockets underneath clear the lazy Susan's M5 nuts + bolt tips
floor_clr    = 0.4;          // gap to the shell's walls, each side
floor_x      = 47;           // half-width: the shell's open bottom is +/-47.5 (rounded corners)
floor_y      = [-hb_d / 2 + hb_wall + floor_clr, face_y - face_t - floor_clr];
floor_mounts = [[-22, -22], [22, -22], [-22, 22], [22, 22]];  // M3 down into the turntable plate
head_rot_in_pulley = 45;     // the head's frame in turntable_pulley.scad's: there the motor is at 0 deg
                             //   when the head looks ahead, and Level 2 has it at motor_a = -45, so the
                             //   head's +Y (90 deg) is at 135
floor_nuts   = [[-50.5, 0], [50.5, 0]];   // the turntable plate's M5 nuts under the floor
floor_hole_d = 40;           // cables down into the turntable's hollow tube
back_screws  = [-30, 30];    // x of the two M3 screws through the back wall
back_screw_z = 10;
tongue_x     = [-30, 30];    // the face plate's tongues
tongue       = [10, 3, 7];   // width (X), height (Z), length (Y, back from the face plate)
tongue_z     = 7;            // centre height (under the mouth's collar)
// the head ESP32-S3 (Seeed XIAO ESP32S3, 21 x 17.8): in a pocket on the floor, USB-C toward the hole
mcu          = [21.0, 17.8];
mcu_c        = [33, 0];      // centre; long axis along X, USB at the -X end

module rr2d(w, h, r) { offset(r = r) square([w - 2 * r, h - 2 * r], center = true); }

// front outline of the box part: rounded bottom corners, square top; z = 0 .. h
module low2d(w = hb_w, h = box_h, r = hb_r) {
    hull() {
        for (sx = [-1, 1]) translate([sx * (w / 2 - r), r]) circle(r = r, $fn = 96);
        translate([-w / 2, h - 1]) square([w, 1]);
    }
}

// where the lens sits: frame at the lens front, looking along +Y (rotated cam_tilt up)
module at_lens() {
    translate([0, 0, arch_z]) rotate([cam_tilt, 0, 0]) translate([0, cam_r_lens, 0]) children();
}
