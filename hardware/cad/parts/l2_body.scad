// Level 2 body: floor + four walls, open at the top (the drive deck screws on as the lid).
//
//   FRONT  the JC4827W543 4.3" display: window over its active area; the board's four corner
//          ears screw (M3) to posts behind the wall, holding the glass against it.
//   BACK   (left)  XW-604B snap-in rocker switch on a 1.5 mm patch (its clips need a thin panel),
//                  5.5 x 2.1 IP68 panel jack (M12 thread, 12 mm hole): flange + gasket outside, nut inside
//          (right) cable exit, low under the motor: Jetson 19 V, ESP32 USB, camera USB
//          (big enough for a USB-A plug and the barrel plug to pass), two zip-tie anchors
//   LEFT   ESP32-S3 breakout (70 x 80, holes 32 x 72.5) standing 5 mm off the wall, USB to the back
//   FLOOR  bosses for a 50 x 70 perfboard (stepper driver + 100 uF, fuse, level shifter) in the
//          front-right; bosses for the 19 -> 5 V buck (Seloky LM2596S, 66 x 36, holes 54 x 31) in
//          the front-left, input end to the back; four screws down into the skirt
//   CORNERS posts with M3 inserts for the drive deck's screws
//   VENTS  tall narrow slots high on both sides (no bridging)
//
// Frame: the deck frame (level2.scad) - deck top z = 0, so the body runs z = -l2_h .. -deck_t.
// PRINT floor-down, no supports (the display window's top edge is a ~100 mm bridge). PETG.
include <../level2.scad>

z_bot   = -l2_h;                 // -90: underside of the floor
z_top   = -deck_t;               // -4: the deck sits on the walls
floor_t = 3;
z_floor = z_bot + floor_t;       // -87: top of the floor
half    = l2_size[0] / 2;        // 80
inner   = half - l2_wall;        // 77.5: inside faces of the walls

m3_clear  = 3.4 + cal_hole;      // prints ~3.35 (PETG)
post_d    = 8;
corner_xy = half - 9;            // deck screws (match drive_deck.scad)

// ---- display (JC4827W543, measured from its STEP model + spec) ---------------------------------
disp_board  = [120.7, 70.2];
disp_holes  = [112.6, 62.1];
disp_glass_t = 4.4;              // glass/backlight in front of the board: MEASURED on the fit test (the
                                 //   STEP model's 5.0 left the glass 0.6 mm off the wall; now flush)
disp_active = [95.04, 53.86];
disp_win    = disp_active + [2, 2];      // 1 mm round the active area
disp_zc     = (z_bot + 0) / 2;           // board (and glass) centred on the whole front face incl. the deck: -45
disp_win_dz = 2.8;               // the active area sits this far ABOVE the board's centre (vendor photo:
                                 //   top margin ~3.9, bottom ~9.6 - the wide margin is at the bottom)

// ---- back panel ------------------------------------------------------------------------------
switch_cut  = [28, 10];          // XW-604B snap-in cut-out
switch_xz   = [-50, -26];        // centre (x, z) on the back wall
switch_patch = 1.5;              // wall thickness for its clips
jack_d      = 12.3 + cal_hole;  // 12 mm thread + 0.3 clearance; prints ~12.3
jack_xz     = [-50, -58];
exit_slot   = [32, 16];          // cable exit (w x h), rounded
exit_xz     = [22, z_floor + 3 + 8];

// ---- left wall: ESP32-S3 breakout (ESP32-S3-TA-44P: 70 x 80, holes 32 x 72.5) --------------------
brk_holes   = [72.5, 32];        // along y, along z
brk_zc      = z_floor + 3 + 35;  // board 70 tall, 3 above the floor
brk_standoff = 5;

// ---- floor: 50 x 70 perfboard, front-right ----------------------------------------------------
pb_holes    = [66, 46];          // x, y hole spacing (2 mm in from the edges): the 70 side runs left-right
pb_c        = [40, 36];          // centre (x, y): clear of the display's back (y < 66) and the motor (y > -2)
pb_boss_h   = 6;

// ---- floor: 19 -> 5 V buck (Seloky LM2596S with voltmeter: 66 x 36 x 14, holes 54 x 31 MEASURED) ----
buck_board  = [36, 66];          // x, y: long side runs front-back
buck_holes  = [31, 54];          // x, y hole spacing
buck_c      = [-35, 28];         // centre: clear of the breakout (x > -60), the perfboard (x < 5) and
                                 //   the display's back (y < 66); input terminals face the back
buck_boss_h = 6;                 // its underside has pin stubs (~3 mm)

// ---- body <-> skirt screws: along the sides, outside the reComputer (x +/-65) -------------------
skirt_pts   = [[-71, -45], [-71, 45], [71, -45], [71, 5]];   // clear of the breakout (left, |y| < 40),
                                 //   the perfboard (right front) and the motor (right back)

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

module shell() {
    difference() {
        translate([0, 0, z_bot]) linear_extrude(z_top - z_bot) rrect(l2_size, l2_r);
        translate([0, 0, z_floor]) linear_extrude(z_top - z_floor + 1) rrect(l2_size - [2, 2] * l2_wall, l2_r - l2_wall);
    }
}

module adds() {
    // corner posts for the deck screws (merge into the corner walls)
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * corner_xy, sy * corner_xy, z_floor - 0.01])
        cylinder(d = post_d, h = z_top - z_floor + 0.01, $fn = 32);
    // display posts: wall's inside face -> the board's front (glass thickness)
    for (sx = [-1, 1], sz = [-1, 1]) translate([sx * disp_holes[0] / 2, inner + 0.01, disp_zc + sz * disp_holes[1] / 2])
        rotate([90, 0, 0]) cylinder(d = 7, h = disp_glass_t + 0.01, $fn = 32);
    // breakout bosses on the left wall
    for (sy = [-1, 1], sz = [-1, 1]) translate([-inner - 0.01, sy * brk_holes[0] / 2, brk_zc + sz * brk_holes[1] / 2])
        rotate([0, 90, 0]) cylinder(d = 7, h = brk_standoff + 0.01, $fn = 32);
    // perfboard bosses
    for (sx = [-1, 1], sy = [-1, 1]) translate([pb_c[0] + sx * pb_holes[0] / 2, pb_c[1] + sy * pb_holes[1] / 2, z_floor - 0.01])
        cylinder(d = 7, h = pb_boss_h + 0.01, $fn = 32);
    // buck bosses
    for (sx = [-1, 1], sy = [-1, 1]) translate([buck_c[0] + sx * buck_holes[0] / 2, buck_c[1] + sy * buck_holes[1] / 2, z_floor - 0.01])
        cylinder(d = 7, h = buck_boss_h + 0.01, $fn = 32);
    // zip-tie anchors beside the cable exit: little arches on the floor
    for (x = [exit_xz[0] - exit_slot[0] / 2 - 8, exit_xz[0] + exit_slot[0] / 2 + 8])
        translate([x, -inner + 10, z_floor - 0.01]) difference() {
            translate([-3, -4, 0]) cube([6, 8, 6]);
            translate([-4, -2, -0.01]) cube([8, 4, 3.5]);
        }
    // bosses round the floor screws into the skirt
    for (p = skirt_pts) translate([p[0], p[1], z_floor - 0.01]) cylinder(d = 9, h = 2, $fn = 32);
}

module cuts() {
    // display window: a 45 deg bevel through the whole wall, from the face down to the glass
    // (fit test: the opening at the glass is right - the border is even all round)
    translate([0, half + 0.01, disp_zc + disp_win_dz]) rotate([90, 0, 0]) hull() {
        linear_extrude(0.01) square(disp_win + [2, 2] * (l2_wall + 0.02), center = true);
        translate([0, 0, l2_wall + 0.02]) linear_extrude(0.01) square(disp_win, center = true);
    }
    // display post screws (M3 heat-set inserts from behind)
    for (sx = [-1, 1], sz = [-1, 1]) translate([sx * disp_holes[0] / 2, inner - disp_glass_t - 0.01, disp_zc + sz * disp_holes[1] / 2])
        rotate([-90, 0, 0]) cylinder(d = insert_m3[0], h = insert_m3[1], $fn = 24);
    // switch: cut-out on a thinned patch
    translate([switch_xz[0], -half, switch_xz[1]]) {
        translate([-switch_cut[0] / 2, -1, -switch_cut[1] / 2]) cube([switch_cut[0], l2_wall + 2, switch_cut[1]]);
        translate([-switch_cut[0] / 2 - 4, switch_patch, -switch_cut[1] / 2 - 4]) cube([switch_cut[0] + 8, l2_wall, switch_cut[1] + 8]);
    }
    // barrel jack: plain hole in the full wall - flange + gasket outside, nut inside
    translate([jack_xz[0], -half, jack_xz[1]]) rotate([-90, 0, 0])
        translate([0, 0, -1]) cylinder(d = jack_d, h = l2_wall + 2, $fn = 48);
    // cable exit
    translate([exit_xz[0], -half - 1, exit_xz[1]]) rotate([-90, 0, 0]) linear_extrude(l2_wall + 2)
        offset(r = 6) square(exit_slot - [12, 12], center = true);
    // breakout boss holes (M3 inserts)
    for (sy = [-1, 1], sz = [-1, 1]) translate([-inner + brk_standoff - insert_m3[1] + 0.01, sy * brk_holes[0] / 2, brk_zc + sz * brk_holes[1] / 2])
        rotate([0, 90, 0]) cylinder(d = insert_m3[0], h = insert_m3[1], $fn = 24);
    // perfboard boss holes (M3 inserts)
    for (sx = [-1, 1], sy = [-1, 1]) translate([pb_c[0] + sx * pb_holes[0] / 2, pb_c[1] + sy * pb_holes[1] / 2, z_floor + pb_boss_h - insert_m3[1]])
        cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
    // buck boss holes (M3 inserts)
    for (sx = [-1, 1], sy = [-1, 1]) translate([buck_c[0] + sx * buck_holes[0] / 2, buck_c[1] + sy * buck_holes[1] / 2, z_floor + buck_boss_h - insert_m3[1]])
        cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
    // deck screw inserts in the corner posts
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * corner_xy, sy * corner_xy, z_top - insert_m3[1]])
        cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
    // floor screws down into the skirt (heads inside, countersunk a little)
    for (p = skirt_pts) translate([p[0], p[1], z_bot - 1]) {
        cylinder(d = m3_clear, h = floor_t + 4, $fn = 24);
        translate([0, 0, floor_t + 1 - 1.2]) cylinder(d1 = m3_clear, d2 = 6.6, h = 1.21, $fn = 24);
    }
    // vents: tall narrow slots high on both sides
    for (sx = [-1, 1], y = [-55 : 9 : 55]) translate([sx * (half - l2_wall / 2), y, -18])
        cube([l2_wall + 2, 3.2, 16], center = true);
}

module l2_body() { difference() { union() { shell(); adds(); } cuts(); } }

l2_body();

// ghosts (not printed): display, breakout, perfboard, motor
%translate([0, inner - disp_glass_t - 1.6 / 2, disp_zc]) cube([disp_board[0], 1.6, disp_board[1]], center = true);
%translate([0, inner - disp_glass_t / 2, disp_zc]) cube([105.5, disp_glass_t, 67.3], center = true);
%translate([-inner + brk_standoff + 6, 0, brk_zc]) cube([12, 80, 70], center = true);
%translate([pb_c[0], pb_c[1], z_floor + pb_boss_h + 0.8]) cube([70, 50, 1.6], center = true);
%translate([buck_c[0], buck_c[1], z_floor + buck_boss_h + 7]) cube([buck_board[0], buck_board[1], 14], center = true);
%rotate(motor_a) translate([motor_C - nema[0] / 2, -nema[0] / 2, z_motor_bottom]) cube([nema[0], nema[0], nema[1]]);
