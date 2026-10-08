// Head concept v3 - ROUGH DRAFT for discussion, not a printable part.
// The 135 x 95 x 70 rounded head straight on the turntable plate, with two round 1.28" GC9A01
// colour TFTs as EYES and the C920 behind a dark window below them as the NOSE. The camera is
// fixed, tilted cam_tilt up inside the level head (no adjustment): it sees eyes 300-500 mm above
// the desk at 300-600 mm. The eyes' colour replaces the LED ring as Piper's state display.
//
// Frame: origin at the centre of the turntable plate's top; +Y = front (face), +Z = up.
include <../params.scad>

hb       = [135, 70, 95];    // width (X), depth (Y), height (Z)
hb_r     = 20;               // corner radius, seen from the front
hb_wall  = 2.5;
face_y   = hb[1] / 2;

// ---- eyes: GC9A01 1.28" round TFT modules ------------------------------------------------
eye_pcb   = [37.5, 45, 3.2]; // module: width, height, thickness (incl. the display)
eye_disp  = 35.3;            // round display (glass) diameter
eye_win   = 33;              // window in the face (the active area is ~32.4)
eye_top   = 18.75;           // EST: display centre below the module's top edge (header at the bottom)
eye_dx    = 32;              // eye centres at x = +/- eye_dx (64 apart)
eye_z     = 64;              // eye centre height (the pin headers then clear the tilted camera by ~3 mm)

// ---- nose: the camera ---------------------------------------------------------------------
cam_tilt  = 27;              // fixed, up. Lens ~204 mm above the desk: eyes 300-500 mm high at 300-600 mm
                             //   are 9..45 deg up; the C920's 43 deg (16:9) centred at 27 covers 5..49
lens_z    = 29;              // lens centre height: the tilted board's lower back corner clears the floor
                             //   (~4 mm) and its upper front edge passes ~3 mm in front of the eyes' pin headers
lens_back = 10.5;            // camera's front face this far behind the face's front surface
nose_win  = [30, 30];        // window: clears the view cone in 4:3 mode (~66 x 52 deg) at 27 deg up
nose_up   = 7;               // ... centred this far above the lens (the cone points up)
show_cone = false;           // draw the camera's vertical view (4:3 mode: 52 deg)
section   = false;           // cut the head's left half away

module rr2d(w, h, r) { offset(r = r) square([w - 2 * r, h - 2 * r], center = true); }

module box(sz, r) {          // rounded box: profile seen from the front, extruded front to back
    rotate([-90, 0, 0]) translate([0, 0, -sz[1] / 2]) linear_extrude(sz[1]) mirror([0, 1, 0]) rr2d(sz[0], sz[2], r);
}

module shell() {
    difference() {
        translate([0, 0, hb[2] / 2]) box(hb, hb_r);
        translate([0, 0, hb[2] / 2]) box(hb - [2, 2, 2] * hb_wall, hb_r - hb_wall);
        for (sx = [-1, 1]) translate([sx * eye_dx, face_y - hb_wall - 1, eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_win, h = 5, $fn = 96);
        translate([0, face_y - hb_wall - 1, lens_z + nose_up]) rotate([-90, 0, 0]) linear_extrude(5) rr2d(nose_win[0], nose_win[1], 9);
        translate([0, 0, -1]) cylinder(d = 40, h = hb_wall + 2, $fn = 64);      // cables down into the turntable
    }
}

module eye() {               // module behind the face, display forward
    translate([0, face_y - hb_wall, 0]) {
        color("#101418") translate([0, -0.6, 0]) rotate([-90, 0, 0]) cylinder(d = eye_win, h = 0.6, $fn = 96);
        color("#2e6fd8") translate([0, -0.4, 0]) rotate([-90, 0, 0]) cylinder(d = 14, h = 0.5, $fn = 64);     // iris
        color("#0a0a0a") translate([0, -0.3, 0]) rotate([-90, 0, 0]) cylinder(d = 6, h = 0.5, $fn = 32);      // pupil
        color("#1a5e3a") translate([-eye_pcb[0] / 2, -eye_pcb[2], -(eye_pcb[1] - eye_top)]) cube([eye_pcb[0], eye_pcb[2] - 0.6, eye_pcb[1]]);
        color("#c9a227") translate([-7.5, -eye_pcb[2] - 8, -(eye_pcb[1] - eye_top) + 1]) cube([15, 8, 2.5]);   // pin header, pointing back
    }
}

module camera() {            // C920 board, front face on y = 0, centred on the lens
    color("#202020") translate([0, -cam_d, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
        hull() for (sx = [-1, 1]) translate([sx * (cam_w / 2 - cam_h / 2), 0, 0]) cylinder(d = cam_h, h = cam_d, $fn = 48);
    color("#3a3a3a") translate([0, 0.01, 0]) rotate([-90, 0, 0]) cylinder(d = 14, h = 2, $fn = 40);
    if (show_cone) color("#4a90d9", 0.6) for (a = [-26, 26]) rotate([a, 0, 0]) translate([-0.25, 0, 0]) cube([0.5, 120, 0.5]);
}

module head_eyes() {
    color("#eef0f2") difference() { shell(); if (section) translate([-100, -60, -5]) cube([100, 120, 110]); }
    for (sx = section ? [1] : [-1, 1]) translate([sx * eye_dx, 0, eye_z]) eye();
    translate([0, face_y - lens_back, lens_z]) rotate([cam_tilt, 0, 0]) camera();
}

head_eyes();
