// Head concept v4 - ROUGH DRAFT for discussion, not a printable part.
// A 135 x 70 head straight on the turntable plate: a box with rounded bottom corners, topped by a
// half cylinder across its full width and depth - from the side the head is one arch.
//   * BROW: the arch holds the C920, fixed cam_tilt up, its lens in the arch's front curve. Up
//     there the lens is nearly level with a seated person's eyes, so a small tilt covers the range.
//     (The camera is 94 mm wide - mic grilles at its ends - so it needs the full width anyway.)
//   * EYES: two round 1.28" GC9A01 colour TFTs (their colour also shows Piper's state).
//   * MOUTH: a 2.08" 256 x 64 white OLED (SH1122, SPI - shares the eyes' bus), measured from
//     the vendor drawing (params.scad: oled_*).
//
// Frame: origin at the centre of the turntable plate's top; +Y = front (face), +Z = up.
include <../params.scad>

hb_w     = 135;              // width (X)
hb_d     = 70;               // depth (Y)
box_h    = 88;               // the box part; the arch adds hb_d / 2 on top -> 123 overall
hb_r     = 20;               // bottom corners, seen from the front (the top meets the arch square)
hb_wall  = 2.5;
face_y   = hb_d / 2;
arch_r   = hb_d / 2;         // 35: the arch spans the full depth
section  = false;            // cut the head's left half away (side view)

// ---- camera in the arch ---------------------------------------------------------------------------
cam_tilt  = 18;              // fixed, up. Lens ~278 mm above the desk: eyes 300-500 mm high at
                             //   300-600 mm are 2..37 deg up; 43 deg (16:9) centred at 18 covers -3..40
cam_out   = 27;              // camera's front face this far from the arch's axis (along the view):
                             //   its corners stay inside the arch (30.6 < 32.5), lens 8 mm in
show_cone = false;

// ---- eyes: GC9A01 1.28" round TFT modules --------------------------------------------------------
eye_pcb   = [37.5, 45, 3.2];
eye_win   = 33;
eye_top   = 18.75;           // EST: display centre below the module's top edge
eye_dx    = 32;
eye_z     = 55;              // modules mounted UPSIDE DOWN (header at the top, image flipped in software):
                             //   their boards then clear the mouth's below and the camera's edge above

// ---- mouth: OLED -----------------------------------------------------------------------------------
m_win     = oled_va + [0.6, 0.6];   // window: the visible area + 0.3 each side
mouth_z   = 20;

module rr2d(w, h, r) { offset(r = r) square([w - 2 * r, h - 2 * r], center = true); }

module low2d(w, h, r) {      // front profile of the box: rounded bottom corners, square top
    hull() {
        for (sx = [-1, 1]) translate([sx * (w / 2 - r), r]) circle(r = r, $fn = 64);
        translate([-w / 2, h - 1]) square([w, 1]);
    }
}

module body(inset = 0) {     // box + arch, shrunk by `inset` (for the hollow)
    translate([0, hb_d / 2 - inset, 0]) rotate([90, 0, 0]) linear_extrude(hb_d - 2 * inset)
        translate([0, inset]) low2d(hb_w - 2 * inset, box_h - inset + (inset > 0 ? 1 : 0), max(1, hb_r - inset));
    translate([0, 0, box_h]) intersection() {
        rotate([0, 90, 0]) cylinder(r = arch_r - inset, h = hb_w - 2 * inset, center = true, $fn = 120);
        translate([-200, -200, inset > 0 ? -1 : 0]) cube([400, 400, 200]);
    }
}

module lens_point() { translate([0, 0, box_h]) rotate([cam_tilt, 0, 0]) translate([0, cam_out, 0]) children(); }

module shell() {
    difference() {
        body();
        body(hb_wall);
        // lens window in the arch's front curve: clears the 70 x 43 deg view
        lens_point() rotate([-90, 0, 0]) translate([0, 0, -1]) linear_extrude(12, scale = 2.0) rr2d(14, 12, 5.5);
        for (sx = [-1, 1]) translate([sx * eye_dx, face_y - hb_wall - 1, eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_win, h = 5, $fn = 96);
        translate([0, face_y - hb_wall - 1, mouth_z]) rotate([-90, 0, 0]) linear_extrude(5) rr2d(m_win[0], m_win[1], 2);
        translate([0, 0, -1]) cylinder(d = 40, h = hb_wall + 2, $fn = 64);       // cables into the turntable
    }
}

module eye() {
    translate([0, face_y - hb_wall, 0]) {
        color("#101418") translate([0, -0.6, 0]) rotate([-90, 0, 0]) cylinder(d = eye_win, h = 0.6, $fn = 96);
        color("#2e6fd8") translate([0, -0.4, 0]) rotate([-90, 0, 0]) cylinder(d = 14, h = 0.5, $fn = 64);
        color("#0a0a0a") translate([0, -0.3, 0]) rotate([-90, 0, 0]) cylinder(d = 6, h = 0.5, $fn = 32);
        color("#1a5e3a") translate([-eye_pcb[0] / 2, -eye_pcb[2], -eye_top]) cube([eye_pcb[0], eye_pcb[2] - 0.6, eye_pcb[1]]);   // upside down
    }
}

module mouth_oled() {
    translate([0, face_y - hb_wall, mouth_z]) {
        color("#0b0b0b") translate([-m_win[0] / 2, -0.8, -m_win[1] / 2]) cube([m_win[0], 0.8, m_win[1]]);
        // the module, shifted so its visible area is centred in the window (pins at the left end)
        translate([-oled_va_dx, 0, 0]) {
            color("#141414") translate([-oled_pcb[0] / 2 + oled_glass_x, -oled_glass[2], -oled_glass[1] / 2])
                cube([oled_glass[0], oled_glass[2], oled_glass[1]]);
            color("#1d3b6e") translate([-oled_pcb[0] / 2, -oled_glass[2] - 1.2, -oled_pcb[1] / 2]) cube([oled_pcb[0], 1.2, oled_pcb[1]]);
        }
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
echo(head_top = box_h + arch_r, lens_z = box_h + cam_out * sin(cam_tilt));
