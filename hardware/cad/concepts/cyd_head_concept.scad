// Concept: the real head = a Guition ESP32-2432S024 (2.4" CYD) for the eyes + the bare C920 board below
// it, in a compact open frame on a yoke - the tilt axle through the head's middle so it's balanced.
// Proportions only (blocks), to agree the layout before the real parts.
//
// Frame: tilt axle along X at the origin, +Y forward, +Z up. tilt = head angle (deg, + = up).
include <../params.scad>

tilt = 0;

// ---- CYD ESP32-2432S024 (MEASURED 2026-10-21; landscape, USB-C at one end) -----------------------------
cyd_b     = [74, 43, 1.8];        // board: long (X), short (Z), thickness
cyd_holes = [68, 36];             // 4 x 3 mm holes, centres
cyd_glass = 4.3;                  // board front -> glass front
cyd_back  = 7;                    // EST: tallest back parts (JST, USB-C, ESP32 module) - TO MEASURE
cyd_act   = [49, 37];             // 2.4" 320x240 active area (nominal)
// ---- C920 bare board (MEASURED) -------------------------------------------------------------------------
cam_b     = [80, 22, 1.2];
cam_lens  = [14.4, 11];           // lens block side, height above the board
cam_mic   = [7.5, 5.1];

face_t    = 2;                    // front plate
gap       = 4;                    // between the screen's board and the camera board
margin    = 4;
head_w    = max(cyd_b[0], cam_b[0] + 7) + 2 * margin;            // mics overhang the camera board ~3.5
head_h    = cyd_b[1] + gap + cam_b[1] + 2 * margin;
y_face    = 14;                   // front face of the plate (forward of the axle)
z_bot     = -head_h * 0.42;       // axle about 42 % up from the bottom (the screen is the heavier part)

z_cam     = z_bot + margin;                         // camera board bottom
z_cyd     = z_cam + cam_b[1] + gap;                 // screen board bottom
y_cyd     = y_face - face_t - cyd_glass;            // screen board front (glass flush behind the plate)
y_cam     = y_face - cam_lens[1];                   // camera board front (lens ~flush with the face)

cheek_gap = 1.5;                  // washer
cheek_t   = 5;

module head() {
    // front plate with the two windows
    color("#d9d9d9") difference() {
        translate([-head_w / 2, y_face - face_t, z_bot]) cube([head_w, face_t, head_h]);
        translate([-cyd_act[0] / 2 - 1, y_face - 3, z_cyd + cyd_b[1] / 2 - cyd_act[1] / 2 - 1]) cube([cyd_act[0] + 2, 4, cyd_act[1] + 2]);
        translate([0, y_face - 3, z_cam + cam_b[1] / 2]) rotate([-90, 0, 0]) cylinder(d = 15, h = 4, $fn = 48);
    }
    // side frames (where the axle goes)
    color("#d9d9d9") for (s = [-1, 1]) translate([s > 0 ? head_w / 2 - 3 : -head_w / 2, -14, z_bot]) cube([3, y_face - face_t + 14, head_h]);
    // the screen
    color("#c98d1a") translate([-cyd_b[0] / 2, y_cyd - cyd_b[2], z_cyd]) cube([cyd_b[0], cyd_b[2], cyd_b[1]]);
    color("#111") translate([-cyd_b[0] / 2, y_cyd, z_cyd + 3]) cube([cyd_b[0], cyd_glass, cyd_b[1] - 6]);
    color("#777") translate([-cyd_b[0] / 2 + 6, y_cyd - cyd_b[2] - cyd_back, z_cyd + 4]) cube([cyd_b[0] - 12, cyd_back, cyd_b[1] - 8]);
    // the camera
    color("#2e7d32") translate([-cam_b[0] / 2, y_cam - cam_b[2], z_cam]) cube([cam_b[0], cam_b[2], cam_b[1]]);
    color("#111") translate([-cam_lens[0] / 2, y_cam, z_cam + cam_b[1] / 2 - cam_lens[0] / 2]) cube([cam_lens[0], cam_lens[1], cam_lens[0]]);
    color("#999") for (s = [-1, 1]) translate([s * (cam_b[0] / 2 - 1), y_cam, z_cam + cam_b[1] / 2]) rotate([-90, 0, 0])
        cylinder(d = cam_mic[0], h = cam_mic[1], $fn = 32);
}

module yoke() {   // the cheeks only, to show the width; the turret below is the test stand's, redrawn later
    color("#555") for (s = [-1, 1]) {
        x0 = s > 0 ? head_w / 2 + cheek_gap : -head_w / 2 - cheek_gap - cheek_t;
        hull() {
            translate([x0, 0, 0]) rotate([0, 90, 0]) cylinder(d = 16, h = cheek_t, $fn = 48);
            translate([x0, -12, -70]) cube([cheek_t, 24, 6]);
        }
    }
    color("#e8a33d") for (s = [-1, 1]) translate([s * (head_w / 2 - 4), 0, 0]) rotate([0, 90, 0]) cylinder(d = 4, h = 12, center = true, $fn = 16);
}

rotate([tilt, 0, 0]) head();
yoke();
echo(str("head ", head_w, " W x ", head_h, " H; yoke outside ", head_w + 2 * (cheek_gap + cheek_t), "; lens ",
         z_cam + cam_b[1] / 2, " / screen centre ", z_cyd + cyd_b[1] / 2, " from the axle"));
