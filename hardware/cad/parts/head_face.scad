// Head face plate - the front of the head's box part: two round 1.28" GC9A01 eyes and the 2.08"
// OLED mouth. Each display drops into a pocket on the back, which centres it behind its window,
// and is held with a few dabs of hot glue round the pocket's rim (on the board, never the glass
// or the flex cable). Wires solder straight to the pads (no headers).
//   * eyes: round board pocket (37.5 + 0.5) + a slot for the pin tab, pointing UP (modules upside
//     down - flip the image in software); 34 mm window through a 1.2 mm skin
//   * mouth: stepped pocket - glass, then board; 53.8 x 15.4 window
//   * four bosses with M3 heat-set inserts: the shell's tabs screw into them from inside
//   * two tongues at the bottom: they hook into the floor's front tabs
//
// PRINT face down (as modelled: the face's front on the bed), no supports. PETG, 4 walls.
include <../head.scad>

module face_body() {
    // the plate: front at y = face_y
    translate([0, face_y, 0]) rotate([90, 0, 0]) linear_extrude(face_t) low2d();
    // collars behind the displays, deep enough for their pockets
    for (sx = [-1, 1]) translate([sx * eye_dx, face_y - face_t, eye_z]) rotate([90, 0, 0])
        linear_extrude(eye_skin + eye_depth - face_t + 0.01)
            hull() { circle(d = eye_pocket + 4, $fn = 96);
                     translate([-(eye_tab[0] + 4) / 2, 0]) square([eye_tab[0] + 4, eye_board_d / 2 + eye_tab[1] + 2]); }
    m_depth = m_skin + oled_glass[2] + 0.2 + 1.2 + 0.2;
    translate([m_pcb_dx, face_y - face_t, mouth_z]) rotate([90, 0, 0])
        linear_extrude(m_depth - face_t + 0.01) square([oled_pcb[0] + 4.5, oled_pcb[1] + 4.5], center = true);
    // tongues that hook into the floor's front tabs
    for (x = tongue_x) translate([x - tongue[0] / 2, face_y - face_t - tongue[2], tongue_z - tongue[1] / 2])
        cube([tongue[0], tongue[2] + 0.01, tongue[1]]);
    // bosses for the shell's screws
    for (b = face_bosses) translate([b[0], face_y - face_t + 0.01, b[1]]) rotate([90, 0, 0])
        cylinder(d = face_boss_d, h = face_boss_len, $fn = 40);
}

module face_cuts() {
    // eyes: window (0.5 mm chamfer at the front), then the board pocket + tab slot
    for (sx = [-1, 1]) translate([sx * eye_dx, face_y, eye_z]) rotate([90, 0, 0]) {
        translate([0, 0, -0.01]) cylinder(d1 = eye_win + 1.0, d2 = eye_win, h = 0.51, $fn = 120);
        cylinder(d = eye_win, h = eye_skin + 0.01, $fn = 120);
        translate([0, 0, eye_skin]) linear_extrude(eye_depth + 5) {
            circle(d = eye_pocket, $fn = 120);
            translate([-(eye_tab[0] + 0.5) / 2, 0]) square([eye_tab[0] + 0.5, eye_board_d / 2 + eye_tab[1] + 0.5]);
        }
    }
    // mouth: window, the glass's recess, then the board's
    translate([0, face_y, mouth_z]) rotate([90, 0, 0]) {
        translate([0, 0, -0.01]) linear_extrude(0.51, scale = [m_win[0] / (m_win[0] + 1), m_win[1] / (m_win[1] + 1)])
            rr2d(m_win[0] + 1, m_win[1] + 1, 1.5);
        linear_extrude(m_skin + 0.01) rr2d(m_win[0], m_win[1], 1);
        translate([m_glass_dx, 0, m_skin]) linear_extrude(oled_glass[2] + 0.2 + 0.01)
            square([oled_glass[0] + 0.5, oled_glass[1] + 0.5], center = true);
        translate([m_pcb_dx, 0, m_skin + oled_glass[2] + 0.2]) linear_extrude(10)
            square([oled_pcb[0] + 0.5, oled_pcb[1] + 0.5], center = true);
    }
    // insert bores in the bosses
    for (b = face_bosses) translate([b[0], face_y - face_t - face_boss_len - 0.01, b[1]]) rotate([-90, 0, 0])
        cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 32);
}

module head_face() { difference() { face_body(); face_cuts(); } }

// as printed: front face on the bed
rotate([-90, 0, 0]) translate([0, -face_y, 0]) head_face();

// ghosts (not printed): the displays in their pockets
%rotate([-90, 0, 0]) translate([0, -face_y, 0]) {
    for (sx = [-1, 1]) translate([sx * eye_dx, face_y - eye_skin, eye_z]) rotate([90, 0, 0])
        linear_extrude(eye_t) { circle(d = eye_board_d, $fn = 96);
                                translate([-eye_tab[0] / 2, 0]) square([eye_tab[0], eye_board_d / 2 + eye_tab[1]]); }
    translate([m_pcb_dx, face_y - m_skin - oled_glass[2] - 0.2, mouth_z]) rotate([90, 0, 0])
        linear_extrude(1.2) square(oled_pcb, center = true);
}
