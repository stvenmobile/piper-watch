// Head camera mount - shared by head_cam_plate.scad, head_cam_strap.scad and head_shell.scad.
//
// LENS FRAME: origin at the front of the lens; +Y = the view direction, +Z = "up" across the
// board, X = along the board (same X as the head). at_lens() (head.scad) places it in the head:
// the lens axis runs radially out of the arch, cam_tilt up.
//
// The bare C920 board (80 x 22) lies against the plate's BACK face, lens forward through it, as on
// the eye test stand (eye_test_stand.scad - its pocket / notch / bracket layout is proven):
//   * through the plate: the lens holder (square), the board's front parts (44 x 22), the coils'
//     bay, two notches for the microphones (they also index the board side to side)
//   * behind: two bosses with M3 inserts; a flat strap (head_cam_strap.scad) screws onto them
//     across the board's back, 1.7 mm clear of its back parts
//   * at each end a FLANGE against the side wall: two M3 screws from outside the head, through
//     the wall, into inserts in the flange
include <head.scad>

cam_plate_t  = 2.5;
cam_y_board  = -cam_lens_h;                 // -14: board front = plate back face
cam_y_front  = cam_y_board + cam_plate_t;   // -11.5: plate front face
cam_z_range  = [-18, 21.5];                 // plate extent across the board (Z): inside the arch
cam_x_flange = hb_w / 2 - hb_wall;          // 65: flange outer faces against the side walls
cam_flange_t = 7;                           // thick enough for an insert (bore along X)
cam_flange_y = [-27, cam_y_front];          // flange extent along Y
cam_mount_pts = [[-21, 12], [-21, -10]];    // [y, z] of the two screws in each flange
cam_lens_hole = 16.5;                       // square, for the 14 x 14 lens holder
cam_comp     = [44, 22];                    // the board's front parts (through)
cam_coil     = [4, 5];                      // bay off the pocket's -X side, from z = 0 up
cam_mic_d    = 6.1 + 0.7;
cam_mic_x    = 69.2 / 2 + 6.1 / 2;          // 37.65: microphone centres
cam_strap_holes = [17.5, -13.9];            // Z of the strap's screws (as the stand's bracket)
cam_boss_h   = 6;                           // bosses behind the plate: the strap lies on them
cam_boss_d   = 8;

// a point in the lens frame -> head frame (matches at_lens())
function cam_to_head(p) = let(y = p[1] + cam_r_lens, z = p[2])
    [p[0], y * cos(cam_tilt) - z * sin(cam_tilt), arch_z + y * sin(cam_tilt) + z * cos(cam_tilt)];
