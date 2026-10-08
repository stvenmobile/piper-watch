// Head concept v4 - ROUGH DRAFT for discussion, not a printable part.
// The 135 x 95 x 70 rounded head straight on the turntable plate:
//   * BROW: a half-cylinder ridge across the top (a half circle seen from the side) holding the
//     C920, fixed cam_tilt up, its lens in the ridge's front curve. Up there the lens is nearly
//     level with a seated person's eyes, so a small tilt covers the whole range.
//   * EYES: two round 1.28" GC9A01 colour TFTs (their colour also shows Piper's state).
//   * MOUTH: a 2.23" 128 x 32 OLED (SSD1305) - or the 1.3" 128 x 64 (mouth = "1.3").
// The camera is 94 mm wide (mic grilles at its ends), which is why the brow runs nearly the full
// width: a half circle seen from the FRONT would have to be ~104 wide and ~52 tall to hold it.
//
// Frame: origin at the centre of the turntable plate's top; +Y = front (face), +Z = up.
include <../params.scad>

hb       = [135, 70, 95];    // width (X), depth (Y), height (Z)
hb_r     = 20;               // corner radius, seen from the front
hb_wall  = 2.5;
face_y   = hb[1] / 2;
section  = false;            // cut the head's left half away (side view)

// ---- brow + camera ---------------------------------------------------------------------------
brow_r    = 30;              // ridge radius (camera corners must stay inside it)
brow_w    = cam_w + 10;      // 104
brow_y    = face_y - brow_r; // ridge axis: its front curve meets the face plane
cam_tilt  = 18;              // fixed, up. Lens ~280 mm above the desk: eyes 300-500 mm high at
                             //   300-600 mm are 1..36 deg up; 43 deg (16:9) centred at 18 covers -3..40
cam_out   = 22;              // camera's front face this far from the ridge axis (along the view)
show_cone = false;

// ---- eyes: GC9A01 1.28" round TFT modules --------------------------------------------------------
eye_pcb   = [37.5, 45, 3.2];
eye_win   = 33;
eye_top   = 18.75;           // EST: display centre below the module's top edge
eye_dx    = 32;
eye_z     = 60;

// ---- mouth: OLED -----------------------------------------------------------------------------------
mouth     = "2.23";          // "2.23" (128 x 32) or "1.3" (128 x 64)
// [module w, h], [window w, h] - EST until measured
m_pcb     = mouth == "2.23" ? [70, 32] : [35.5, 34];
m_win     = mouth == "2.23" ? [57, 15] : [31, 17];
mouth_z   = 22;

module rr2d(w, h, r) { offset(r = r) square([w - 2 * r, h - 2 * r], center = true); }

module box(sz, r) {
    rotate([-90, 0, 0]) translate([0, 0, -sz[1] / 2]) linear_extrude(sz[1]) mirror([0, 1, 0]) rr2d(sz[0], sz[2], r);
}

module brow_solid(r = brow_r) {          // half cylinder along X on the head's top
    translate([0, brow_y, hb[2] - hb_wall]) intersection() {
        rotate([0, 90, 0]) cylinder(r = r, h = brow_w - 2 * (brow_r - r), center = true, $fn = 120);
        translate([-200, -200, 0]) cube([400, 400, 200]);
    }
}

module lens_point() { translate([0, brow_y, hb[2] - hb_wall]) rotate([cam_tilt, 0, 0]) translate([0, cam_out, 0]) children(); }

module shell() {
    difference() {
        union() { translate([0, 0, hb[2] / 2]) box(hb, hb_r); brow_solid(); }
        translate([0, 0, hb[2] / 2]) box(hb - [2, 2, 2] * hb_wall, hb_r - hb_wall);
        brow_solid(brow_r - hb_wall);
        translate([0, brow_y, hb[2] - hb_wall - 1]) cube([brow_w - 2 * hb_wall, 2 * (brow_r - hb_wall), 4], center = true);
        // lens window in the brow's front curve: clears the 70 x 43 deg view
        lens_point() rotate([-90, 0, 0]) translate([0, 0, -1]) linear_extrude(12, scale = 1.9) rr2d(14, 12, 5.5);
        for (sx = [-1, 1]) translate([sx * eye_dx, face_y - hb_wall - 1, eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_win, h = 5, $fn = 96);
        translate([0, face_y - hb_wall - 1, mouth_z]) rotate([-90, 0, 0]) linear_extrude(5) rr2d(m_win[0], m_win[1], 2);
        translate([0, 0, -1]) cylinder(d = 40, h = hb_wall + 2, $fn = 64);
    }
}

module eye() {
    translate([0, face_y - hb_wall, 0]) {
        color("#101418") translate([0, -0.6, 0]) rotate([-90, 0, 0]) cylinder(d = eye_win, h = 0.6, $fn = 96);
        color("#2e6fd8") translate([0, -0.4, 0]) rotate([-90, 0, 0]) cylinder(d = 14, h = 0.5, $fn = 64);
        color("#0a0a0a") translate([0, -0.3, 0]) rotate([-90, 0, 0]) cylinder(d = 6, h = 0.5, $fn = 32);
        color("#1a5e3a") translate([-eye_pcb[0] / 2, -eye_pcb[2], -(eye_pcb[1] - eye_top)]) cube([eye_pcb[0], eye_pcb[2] - 0.6, eye_pcb[1]]);
    }
}

module mouth_oled() {
    translate([0, face_y - hb_wall, mouth_z]) {
        color("#0b0b0b") translate([-m_win[0] / 2, -0.8, -m_win[1] / 2]) cube([m_win[0], 0.8, m_win[1]]);
        // a smile, as the OLED might draw it
        color("#e8f4ff") translate([0, -0.2, 2]) rotate([90, 0, 0]) linear_extrude(0.3)
            difference() { circle(r = m_win[1] * 0.9, $fn = 64); circle(r = m_win[1] * 0.9 - 1.6, $fn = 64);
                           translate([-30, -2]) square([60, 40]); }
        color("#1d3b6e") translate([-m_pcb[0] / 2, -3.2, -m_pcb[1] / 2]) cube([m_pcb[0], 2.4, m_pcb[1]]);
    }
}

module camera() {
    color("#202020") translate([0, -cam_d, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
        hull() for (sx = [-1, 1]) translate([sx * (cam_w / 2 - cam_h / 2), 0, 0]) cylinder(d = cam_h, h = cam_d, $fn = 48);
    color("#3a3a3a") translate([0, 0.01, 0]) rotate([-90, 0, 0]) cylinder(d = 14, h = 2, $fn = 40);
    if (show_cone) color("#4a90d9", 0.6) for (a = [-21.6, 21.6]) rotate([a, 0, 0]) translate([-0.25, 0, 0]) cube([0.5, 140, 0.5]);
}

module head_brow() {
    color("#eef0f2") difference() { shell(); if (section) translate([-100, -60, -5]) cube([100, 120, 160]); }
    for (sx = section ? [1] : [-1, 1]) translate([sx * eye_dx, 0, eye_z]) eye();
    mouth_oled();
    lens_point() camera();
}

head_brow();
echo(head_top = hb[2] - hb_wall + brow_r);
