// Level 2 body: floor + four walls, open at the top (the drive deck screws on as the lid).
//
//   FRONT  the JC4827W543 4.3" display: window over its active area; the board's four corner
//          ears screw (M3, straight into tapped posts - no inserts) to posts behind the wall,
//          holding the glass against it.
//   BACK   (left)  a column: 6 x 30 mm panel FUSE holder (double-D hole: 15 dia, flats 12.2 apart)
//                  above the 5.5 x 2.1 IP68 panel jack (11.2 mm thread, flange 14.1, nut 13.6 AF,
//                  21 mm behind the flange: flange + gasket outside, nut inside); right of them the
//                  snap-in ROCKER switch, upright (ON at the top) in a plain cut-out.
//                  Split block -> fuse -> switch -> perfboard J1 (the head side only; the Jetson is unswitched)
//          (right) cable exit, low under the motor: Jetson 19 V, ESP32 USB, camera USB
//          (big enough for a USB-A plug and the barrel plug to pass), two zip-tie anchors
//   LEFT   ESP32-S3 breakout (70 x 80, holes 32 x 72.5) standing 5 mm off the wall on tapped M3
//          bosses (no inserts), USB to the back
//   FLOOR  19 V split block (2-way barrier strip, 36 x 21.5, M3.5 spade screws) back-left near the
//          jack and switch: a low pad at each end with two M3 inserts; its − side is the common ground.
//          Bosses (M2.5 inserts) for a 50 x 70 perfboard (stepper driver + 100 uF,
//          terminal blocks) in the
//          front-right; bosses for the 19 -> 5 V buck (Seloky LM2596S, 66 x 36, holes 54 x 31) in
//          the front-left, input end to the back; four screws down into the skirt
//   CORNERS solid rounded-square columns, floor to deck, filleted into both walls, each with an M3
//          insert at the top for the drive deck's screws
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
corner_col = 14;                 // the corner columns: this square (rounded), filleted into the walls
corner_fillet = 3;
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
switch_cut  = [12.3 + 0.3, 17.1 + 1.3];   // MEASURED body 12.3 wide x 17.1 tall (length +1.0 after the test print) (upright; flange 14.8 x 21.7)
switch_xz   = [-10, -42];        // centre (x, z) on the back wall - where the fuse was, 10 mm further in
jack_d      = 11.2 + 0.3 + cal_hole;  // MEASURED thread 11.2 OD (sold as M12) + 0.3: no wobble before the nut is on
jack_xz     = [-40, -58];        // 10 mm further in from the corner than before
fuse_d      = 15.0 + cal_hole;   // panel fuse holder: round hole ...
fuse_flats  = 12.2 + 0.3;        // ... with two flats this far apart (stops it turning)
fuse_xz     = [-40, -36];        // above the jack: its ring nut (~20) clears the jack's nut (13.6 AF)        // its ring nut (~20 across) clears the switch's recess and the
                                 //   motor; the holder reaches ~34 mm inside, over the split block
exit_slot   = [32, 16];          // cable exit (w x h), rounded
exit_xz     = [22, z_floor + 3 + 8];

// ---- left wall: ESP32-S3 breakout (ESP32-S3-TA-44P: 70 x 80, holes 32 x 72.5) --------------------
brk_holes   = [72.5, 32];        // along y, along z
brk_zc      = z_floor + 3 + 35;  // board 70 tall, 3 above the floor
brk_standoff = 5;

// ---- floor: 50 x 70 perfboard, front-right ----------------------------------------------------
pb_holes    = [66, 46];          // x, y hole spacing MEASURED (M2.5 holes): the 70 side runs left-right
pb_c        = [40, 36];          // centre (x, y): clear of the display's back (y < 66) and the motor (y > -2)
pb_boss_h   = 6;

// ---- floor: 19 -> 5 V buck (Seloky LM2596S with voltmeter: 66 x 36 x 14, holes 54 x 31 MEASURED) ----
buck_board  = [36, 66];          // x, y: long side runs front-back
buck_holes  = [31, 54];          // x, y hole spacing
buck_c      = [-35, 28];         // centre: clear of the breakout (x > -60), the perfboard (x < 5) and
                                 //   the display's back (y < 66); input terminals face the back
buck_boss_h = 6;                 // its underside has pin stubs (~3 mm)

// ---- floor: 19 V split block (2-way barrier terminal strip), back-left by the jack and switch ---
tb_size     = [36, 21.5, 13];    // length (x), base width (y), height (spec sheet)
tb_holes    = [28.7, 8.8];       // MEASURED: four 4 mm holes, two at each end - along x, across y
tb_c        = [-38, -46];        // centre: ~21 mm to the back wall for the spades + wire bends (jack and
                                 //   switch leads on its back side); the Jetson
                                 //   and perfboard leads leave from its front side; clear of the corner
                                 //   post, the skirt screw at (-71, -45), the buck (y > -5) and the breakout (x < -60)
tb_boss_h   = 3;                 // floor 3 + boss 3 = room for a 5 mm M3 insert

// ---- body <-> skirt screws: along the sides, outside the reComputer (x +/-65) -------------------
skirt_pts   = [[-71, -45], [-71, 45], [71, -45], [71, 5]];   // clear of the breakout (left, |y| < 40),
                                 //   the perfboard (right front) and the motor (right back)

// the four corner columns (2D): a square filling each corner of the inside, its exposed corner
// rounded, joined to both walls by fillets. Built from plain shapes (not offset closing, which
// $fn = 96 from params.scad breaks).
module corner_columns_2d() {
    a = inner - corner_col;                 // the column's inner faces (x and y)
    f = corner_fillet;
    for (sx = [-1, 1], sy = [-1, 1]) scale([sx, sy]) {
        intersection() {
            rrect(l2_size - [2, 2] * l2_wall, l2_r - l2_wall);                              // inside the walls
            translate([a, a]) offset(r = 2) offset(delta = -2) square(corner_col + 5);     // exposed corner rounded
        }
        for (m = [0, 1]) multmatrix(m ? [[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0]] : [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0]])   // both walls (swap x/y)
            translate([a - f, inner - f]) difference() { square(f + 0.01); circle(r = f); }
    }
}

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

module shell() {
    difference() {
        translate([0, 0, z_bot]) linear_extrude(z_top - z_bot) rrect(l2_size, l2_r);
        translate([0, 0, z_floor]) linear_extrude(z_top - z_floor + 1) rrect(l2_size - [2, 2] * l2_wall, l2_r - l2_wall);
    }
}

module adds() {
    // corner columns for the deck screws: solid, floor to deck, filleted into both walls
    translate([0, 0, z_floor - 0.01]) linear_extrude(z_top - z_floor + 0.01) corner_columns_2d();
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
    // split-block bosses
    for (sx = [-1, 1]) translate([tb_c[0] + sx * tb_holes[0] / 2, tb_c[1], z_floor - 0.01])
        hull() for (sy = [-1, 1]) translate([0, sy * tb_holes[1] / 2, 0]) cylinder(d = 8, h = tb_boss_h + 0.01, $fn = 32);
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
    // display post screws (tapped M3 - an M3 screw cuts its own thread; screws <= 8 mm long)
    for (sx = [-1, 1], sz = [-1, 1]) translate([sx * disp_holes[0] / 2, inner - disp_glass_t - 0.01, disp_zc + sz * disp_holes[1] / 2])
        rotate([-90, 0, 0]) cylinder(d = tap_m3[0], h = min(tap_m3[1], disp_glass_t + 1), $fn = 24);   // 1.5 mm skin left in front
    // switch: a plain cut-out, upright - it snaps in from outside
    translate([switch_xz[0], -half, switch_xz[1]]) {
        translate([-switch_cut[0] / 2, -1, -switch_cut[1] / 2]) cube([switch_cut[0], l2_wall + 2, switch_cut[1]]);
    }
    // barrel jack: plain hole in the full wall - flange + gasket outside, nut inside
    translate([jack_xz[0], -half, jack_xz[1]]) rotate([-90, 0, 0])
        translate([0, 0, -1]) cylinder(d = jack_d, h = l2_wall + 2, $fn = 48);
    // fuse holder: double-D hole
    translate([fuse_xz[0], -half - 1, fuse_xz[1]]) rotate([-90, 0, 0]) linear_extrude(l2_wall + 2)
        intersection() { circle(d = fuse_d, $fn = 64); square([fuse_flats, fuse_d + 1], center = true); }
    // cable exit
    translate([exit_xz[0], -half - 1, exit_xz[1]]) rotate([-90, 0, 0]) linear_extrude(l2_wall + 2)
        offset(r = 6) square(exit_slot - [12, 12], center = true);
    // breakout boss holes (tapped M3)
    for (sy = [-1, 1], sz = [-1, 1]) translate([-inner + brk_standoff - tap_m3[1] + 0.01, sy * brk_holes[0] / 2, brk_zc + sz * brk_holes[1] / 2])
        rotate([0, 90, 0]) cylinder(d = tap_m3[0], h = tap_m3[1], $fn = 24);
    // perfboard boss holes (M2.5 inserts)
    for (sx = [-1, 1], sy = [-1, 1]) translate([pb_c[0] + sx * pb_holes[0] / 2, pb_c[1] + sy * pb_holes[1] / 2, z_floor + pb_boss_h - insert_m25[1]])
        cylinder(d = insert_m25[0], h = insert_m25[1] + 1, $fn = 24);
    // buck boss holes (M3 inserts)
    for (sx = [-1, 1], sy = [-1, 1]) translate([buck_c[0] + sx * buck_holes[0] / 2, buck_c[1] + sy * buck_holes[1] / 2, z_floor + buck_boss_h - insert_m3[1]])
        cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
    // split-block boss holes (M3 inserts; the strip's 4 mm holes take M3 screws + washers)
    for (sx = [-1, 1], sy = [-1, 1]) translate([tb_c[0] + sx * tb_holes[0] / 2, tb_c[1] + sy * tb_holes[1] / 2, z_floor + tb_boss_h - insert_m3[1]])
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
%translate([tb_c[0], tb_c[1], z_floor + tb_boss_h + tb_size[2] / 2]) cube(tb_size, center = true);
%rotate(motor_a) translate([motor_C - nema[0] / 2, -nema[0] / 2, z_motor_bottom]) cube([nema[0], nema[0], nema[1]]);
