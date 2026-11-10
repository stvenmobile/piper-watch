// HEAD v6: two printed pieces + three small straps, replacing base_head_v4 / base_camframe_v4 / base_head_v5.
//
//   FRONT   the whole front of the head (18 mm deep): front wall with 4 openings (camera square hole, OLED window, 2 eye holes), flared side
//           walls, visor, 2 joint bosses (M2.5 insert) and 3 pilot bosses for the straps. Open at the back and at the bottom. Prints front face down, no supports.
//   BACK    rear plate, the two pivot arms with axle stubs and the crank bracket. Bolted to the front with 2 x M2.5 through its two ears.
//   STRAPS  1 long camera strap (one M2 at each end) and 1 OLED half strap (one M2, on the top edge; now optional). The OLED itself is held
//           by four M2 screws through its mounting holes into the front wall.
// The OLED sits in the front wall (glass in a pocket behind a 2.2 lip); 9.8 mm are free behind its board for the Dupont plugs.
// part = "v6_front" | "v6_back" | "v6_straps" | "v6_view"
include <base_v4.scad>
cam_dx = ox;                                   // lens, eyes, camera board centre on the OLED window's middle (the window is 3.9 off the PCB centre)
oz = -5.3;                                     // OLED centre height (was -7.5): 2.2 higher so the front plate clears the turret floor at -22 deg tilt

// ---- parameters (all y values relative to the axle, z relative to the axle) -----------------------------------------------------
hd_t = 18;                                     // head depth, front face to rear face
yf = 28;                                       // front face
yr = yf - hd_t;                                // rear face of the back piece (10)
yj = yr + 3;                                   // front face of the back piece = rear edge of the front piece's walls (13)
yc = yf - 3;                                   // front wall's rear face over the camera (25); the camera bosses (5.1) rest on it
yo = yf - 4;                                   // front wall's rear face over the OLED (24): the PCB lies on it
zs = 5.4;                                      // the front wall steps from 4 to 3 thick at this height (the OLED board's top is at oz + 10.3 = 5.0)
zb = pl_z[0];                                  // bottom of the front plate / back plate (-20)
z0 = lens_z - 11.5;  zt = 32.5;  hwt = 58;  wt6 = 2.5;     // the flare: starts where the camera board starts, top height, half width at the top
zrw = 22.5;                                    // wings behind y = 18 and the back piece's ears only above this (keeps clear of the cheek covers, r 17)
oy_pcb = [yo - 1.2, yo];                       // OLED PCB, resting on the wall's rear face
by_cam = pl_y[1];                              // camera board's rear face (18); it is 1.6 thick, its bosses are 5.1 tall
st_t = 2.5;                                    // strap thickness

module ey(y0, y1) translate([0, ax_y + y1, ax_z]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();      // 2D (x, z rel. the axle) -> y0..y1
module zclip(a, b) intersection() { children(); translate([-200, a]) square([400, b - a]); }
hwl = 46;                                      // face half width up to where the flare starts: the face is symmetric about the lens/window centre (cam_dx)
module out2d() offset(r = 3) offset(delta = -3) polygon([[cam_dx - hwl, zb], [cam_dx + hwl, zb], [cam_dx + hwl, z0], [cam_dx + hwt, zt], [cam_dx - hwt, zt], [cam_dx - hwl, z0]]);
module ring2d() difference() { out2d(); offset(delta = -wt6) out2d(); }

// bolt/boss positions
xb3 = 24;  zb3 = -13.5;                       // third joint bolt, bottom right (clear of the cable slot, x -34 .. 16): boss on the bottom wall, M2.5 x 8
xj = 47.5;  zj = 27;                           // joint bosses (x = cam_dx +- xj)
xcs = 44.5;                                    // camera strap bosses (x = cam_dx +- xcs, at lens height)
zos = 7.7;  xos = 14;                          // OLED strap boss: height and x (clear of the lens cube, which spans x -10.9 .. 3.1)
yb_cam = by_cam + 0.2;                         // camera strap bosses' free end (the strap clamps the board 0.2 below it)
yb_ol = oy_pcb[0] + 0.2;                       // OLED strap boss' free end
module fwd(x, y, z, d, h) translate([x, ax_y + y, ax_z + z]) rotate([-90, 0, 0]) cylinder(d = d, h = h, $fn = 40);      // cylinder from y forward

// ---- indexing lip: stands inboard of the front piece's walls, runs rearward past the joint face and sits in a shallow pocket in the back plate ---------
lip_t = 2;  lip_h = 1.6;  lip_c = 0.2;                         // thickness (inward from the wall's inner face), how far it goes behind the joint face (y 13), pocket clearance
module lip_band(t, o = 0) difference() { offset(delta = -wt6 + o) out2d(); offset(delta = -wt6 - t) out2d(); }
module lip_sel() union() {                                      // where it runs: about 40 mm along the visor, and the flared sides between the arm blocks and the joint bosses
    translate([cam_dx - 20, 26]) square([40, 10]);
    for (sx = [-1, 1]) translate([cam_dx + (sx > 0 ? 20 : -75), 13.5]) square([55, 9]);
}
module lip_prof(t) intersection() { lip_band(t); lip_sel(); }
module lip3d() difference() {
    union() {
        ey(yj - lip_h, yj + 0.01) lip_prof(lip_t);
        n = 8;  for (i = [0 : n - 1]) ey(yj + i * lip_t / n, yj + (i + 1) * lip_t / n + 0.01) lip_prof(lip_t * (1 - (i + 0.5) / n));   // 45 deg ramp: no supports
    }
    sweep_k();
}
fr_b = 2;                                                       // fillet radius where a joint boss meets its wall
module jboss2d(cx, cz, zw) {                                    // boss section (x, z): circle d7 + the two tangent lines run perpendicular to the wall (inner face at zw) + concave fillets
    d = zw > cz ? 1 : -1;  r = 3.5;
    translate([cx, cz]) circle(r = r, $fn = 48);
    translate([cx - r, d > 0 ? cz : zw - 0.5]) square([2 * r, abs(zw - cz) + 0.5]);
    for (sx = [-1, 1]) difference() {
        translate([sx > 0 ? cx + r - 0.01 : cx - r - fr_b + 0.01, d > 0 ? zw - fr_b : zw - 0.01]) square([fr_b, fr_b]);
        translate([cx + sx * (r + fr_b), zw - d * fr_b]) circle(r = fr_b, $fn = 32);
    }
}
module camboss(sx) difference() {                                                            // camera strap boss: runs through the mic pocket down to its floor
    fwd(cam_dx + sx * xcs, yb_cam, lens_z, 6, yc + 1.5 - yb_cam);
    fwd(cam_dx + sx * xcs, yb_cam - 1, lens_z, 1.6, 7.5);                                    // M2 pilot (self-tapping)
}
// everything the cheeks and their covers can occupy at any tilt, in the head's frame: nothing of the shell may be there
module cheek_k() for (s = [-1, 1]) {
    translate([s > 0 ? ch_x[0] - 2.6 : -ch_x[1] - 2.6, ax_y - 12.6, z_ft - 0.5]) cube([ch_t4 + 5.2, 25.2, 3.1]);      // the fillets round the cheeks' feet (2 high)
    hull() {
    translate([s > 0 ? ch_x[0] - 0.5 : -ch_x[1] - 0.5, ax_y - 10.5, z_ft - 0.5]) cube([ch_t4 + 1, 21, 7]);
    translate([s > 0 ? ch_x[0] - 0.5 : -ch_x[1] - 4, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 35, h = ch_t4 + 4.5, $fn = 60);      // cheek + cover (3.5)
    }
}
module sweep_k() for (t = [-26 : 2 : 48]) translate([0, ax_y, ax_z]) rotate([-t, 0, 0]) translate([0, -ax_y, -ax_z]) cheek_k();
module front6() { difference() { front6a(); sweep_k(); } for (sx = [-1, 1]) camboss(sx); lip3d(); }
module front6a() color("#8a8d91") difference() {
    union() {
        ey(yo, yf) zclip(zb - 1, zs) out2d();                      // OLED zone: 4 thick
        ey(yc, yf) zclip(zs - 0.01, zt + 1) out2d();               // camera zone: 3 thick
        ey(yj, yf) ring2d();                                       // side walls, visor and bottom: the closed shell, from the front wall to the back piece
        ey(yj, yf) zclip(zb - 1, zb + 3.5) out2d();               // bottom wall 3.5 thick (the chamfer below slices its front part)
        for (sx = [-1, 1]) ey(yj, yc + 0.5) jboss2d(cam_dx + sx * xj, zj, zt - wt6);               // joint bosses (top corners): tangent lines up to the visor, filleted
        ey(yj, 21) jboss2d(xb3, zb3, zb + 3.5);                                                     // bottom joint boss: down to the floor
        fwd(xos, yb_ol, zos, 4.6, yc - yb_ol + 0.5);                                                // OLED strap boss
        for (sx = [-1, 1]) translate([cam_dx + sx * eye_x, ax_y + yc + 0.01, ax_z + eye_z]) rotate([90, 0, 0]) cylinder(d = 5, h = spg, $fn = 32);   // eye spigots
    }
    translate([cam_dx - cube_w / 2 - 0.2, ax_y + yc - 1, ax_z + lens_z - cube_w / 2 - 0.2]) cube([cube_w + 0.4, 5, cube_w + 0.4]);   // camera: square hole for the lens cube
    for (sx = [-1, 1]) {
        translate([cam_dx + sx * eye_x, ax_y + yc - spg - 1, ax_z + eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_d, h = spg + 5, $fn = 24);         // eye holes
        translate([cam_dx + sx * eye_x, ax_y + yf - eye_seat, ax_z + eye_z]) rotate([-90, 0, 0]) cylinder(d = eye_seat_d, h = eye_seat + 1, $fn = 48);   // glass seats
        translate([cam_dx + sx * 40.5, ax_y + yc - 1, ax_z + lens_z - 2.1]) rotate([-90, 0, 0]) cylinder(d = 11, h = 2.4, $fn = 40);                  // mic cans
    }
    translate([cam_dx + 12, ax_y + yc - 1, ax_z + lens_z - 0.8]) cube([5.9, 2.5, 9.5]);                  // tall white camera-cable connector
    translate([0, ax_y, ax_z + oz]) {                                                                        // OLED: window + glass pocket
        translate([ox - 26.6, yo - 1, -7.39]) cube([53.2, 6, 14.78]);                                        // window (viewing area 53.18 x 14.78)
        translate([-33.95, yo - 1, -10.6]) cube([67.9, 2.8, 21.2]);                                         // pocket: glass 62.5, connector and solder joints; 2.2 lip left (0.2 more clearance all round)
        for (sx = [-36, 36], sz = [-7.75, 7.75]) translate([sx, yo - 1, sz]) rotate([-90, 0, 0]) cylinder(d = 1.6, h = 4, $fn = 20);   // the board's four mounting holes: M2 pilots, 3 deep (self-tapping)
    }
    for (sx = [-1, 1]) fwd(cam_dx + sx * xj, yj - 1, zj, insert_m25[0], insert_m25[1] + 2.5);               // M2.5 insert bores from the rear end
    for (sx = [-1, 1]) fwd(cam_dx + sx * xj, yj, zj, 2.6, 9);                                                // and the screw's path on
    fwd(xos, yb_ol - 1, zos, 1.6, 4.8);
    fwd(xb3, yj - 1, zb3, insert_m25[0], insert_m25[1] + 2.5);  fwd(xb3, yj, zb3, 2.6, 7);        // bottom joint: insert bore + screw path
    translate([-100, 0, 0]) rotate([90, 0, 90]) linear_extrude(200)                                           // bottom chamfer: at -22 deg the front must stay 0.5 above the turret floor (z -26)
        polygon([[ax_y + 10, ax_z - 27.51 + 4.045], [ax_y + 30, ax_z - 27.51 + 12.135], [ax_y + 30, ax_z - 60], [ax_y + 10, ax_z - 60]]);
}

// ---- back piece --------------------------------------------------------------------------------------------------------------------
module back6() color("#6b8fb5") difference() {
    union() {
        difference() { ey(yr, yj) out2d(); sweep_k(); ey(yj - lip_h - lip_c, yj + 0.01) intersection() { lip_band(lip_t + 2 * lip_c, lip_c); lip_sel(); } }                                                      // plate: the whole face outline, so the head is closed (clear of the cheeks)
        for (s = [-1, 1]) hull() {                                                                                    // arms
            translate([s > 0 ? arm_x[0] : -arm_x[1], ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 16, h = 3, $fn = 40);
            translate([s > 0 ? arm_x[0] : -arm_x[1], ax_y + yr, ax_z - 12]) cube([3, 3, 24]);
        }
        for (s = [-1, 1]) translate([s > 0 ? arm_x[1] : -ch_x[1] - 0.5, ax_y, ax_z]) rotate([0, 90, 0])                // axle stubs (into the 608s)
            cylinder(d = stub_d, h = (s > 0 ? ch_x[1] - arm_x[1] : ch_x[1] - arm_x[1] + 0.5 + (ch_x[1] - ch_x[1])) + 0.01, $fn = 24);
        difference() { hull() {                                                                                      // crank bracket on the left arm
            translate([-arm_x[1] - 0.01, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 12, h = 3.01, $fn = 32);
            translate([pin_h[0] - 2.5 - 6, ax_y + cr_h * cos(hb0), ax_z + cr_h * sin(hb0)]) rotate([0, 90, 0]) cylinder(d = 9, h = 6.01, $fn = 32);
        }
        translate([pin_h[0] - 2.5 + 0.01, ax_y + cr_h * cos(hb0), ax_z + cr_h * sin(hb0)]) rotate([0, -90, 0]) cylinder(d = insert_m3[0], h = insert_m3[1] + 0.2, $fn = 24);
        }
    }
    translate([-34, ax_y + yr - 1, ax_z + zb - 1]) cube([50, yj - yr + 2, 10]);                                      // cable exit: 50 x 9 slot at the bottom of the plate
    fwd(xb3, yr - 1, zb3, 2.8 + cal_hole, 6);  fwd(xb3, yr - 1, zb3, 5.4 + cal_hole, 2.5);                          // the bottom joint bolt
    for (sx = [-1, 1]) {                                                                                             // the two joint bolts, heads sunk in the rear face
        fwd(cam_dx + sx * xj, yr - 1, zj, 2.8 + cal_hole, 6);
        fwd(cam_dx + sx * xj, yr - 1, zj, 5.4 + cal_hole, 2.5);
    }
}

// ---- straps --------------------------------------------------------------------------------------------------------------------------
module strap_cam(sx) color("#d9dde2") difference() {          // sx = +1 / -1: right / left end of the camera board
    xb = cam_dx + sx * xcs;
    ey(by_cam - st_t, by_cam) offset(r = 1.2) offset(delta = -1.2)
        translate([min(xb - sx * 6, xb + sx * 2.7), lens_z - 3]) square([8.7, 6]);
    fwd(xb, by_cam - st_t - 1, lens_z, 2.4 + cal_hole, st_t + 2);
    fwd(xb, by_cam - st_t - 1, lens_z, 4.4 + cal_hole, 1 + 1.2);
}
module strap_cam_long() color("#d9dde2") difference() {         // one strap across the whole board: a hole at each boss (cam_dx +- xcs), same width and thickness as the short ones
    ey(by_cam - st_t, by_cam) offset(r = 1.2) offset(delta = -1.2) translate([cam_dx - xcs - 2.7, lens_z - 3]) square([2 * xcs + 5.4, 6]);
    for (sx = [-1, 1]) {
        fwd(cam_dx + sx * xcs, by_cam - st_t - 1, lens_z, 2.4 + cal_hole, st_t + 2);
        fwd(cam_dx + sx * xcs, by_cam - st_t - 1, lens_z, 4.4 + cal_hole, 1 + 1.2);
    }
}
module strap_oled() color("#d9dde2") difference() {
    ey(oy_pcb[0] - st_t, oy_pcb[0]) offset(r = 1.5) offset(delta = -1.5) translate([xos - 12, oz + 10.3 - 2.4]) square([24, zos + 2.3 - (oz + 10.3 - 2.4)]);
    fwd(xos, oy_pcb[0] - st_t - 1, zos, 2.4 + cal_hole, st_t + 2);
    fwd(xos, oy_pcb[0] - st_t - 1, zos, 4.4 + cal_hole, 1 + 1.2);
}
module flat(yfront, xc, zc, px, py) translate([px - xc, py - (ax_z + zc), ax_y + yfront]) rotate([-90, 0, 0]) children();    // lay a strap on the bed, rear face up
module straps_all() { straps_asm(); }
module straps_asm() { strap_cam_long(); strap_oled(); }

// ---- ghosts + views --------------------------------------------------------------------------------------------------------------------
module tilted() translate([0, ax_y, ax_z]) rotate([tilt4, 0, 0]) translate([0, -ax_y, -ax_z]) children();
show_b = true;  show_s = true;
xp_f = 0;  xp_b = 0;  xp_s = 0;  xp_c = 0;  xp_o = 0;           // explode: distances toward the rear (y)
module ghosts6() {
    translate([0, -xp_c, 0]) {
        color("#1b5e20") difference() {                                                           // camera board with its edge slot's neighbour cut-outs left out
            translate([cam_dx - 41, ax_y + by_cam, ax_z + lens_z - 11.5]) cube([82, cb_t, 23]);
        }
        color("#222") translate([cam_dx - cube_w / 2, ax_y + by_cam + cb_t, ax_z + lens_z - cube_w / 2]) cube([cube_w, cube_h, cube_w]);
        color("#222") for (s = [-1, 1]) translate([cam_dx + s * 8.5, ax_y + by_cam + cb_t, ax_z + lens_z]) rotate([-90, 0, 0]) cylinder(d = 6.5, h = boss_h, $fn = 24);
        color("#111") translate([cam_dx, ax_y + by_cam + cb_t + cube_h, ax_z + lens_z]) rotate([-90, 0, 0]) cylinder(d = 11, h = 3, $fn = 40);
    }
    translate([0, ax_y - xp_o, ax_z + oz]) {
        color("#1b5e20") translate([-37.75, oy_pcb[0], -10.3]) cube([75.5, 1.2, 20.6]);
        color("#050505") translate([-31.25, yo, -10.3]) cube([62.5, 1.63, 20.6]);
        color("#9fd6ff") translate([ox - 25.59, yo + 1.64, -6.39]) cube([51.18, 0.15, 12.78]);
    }
    color("#f4f4f4") for (sx = [-1, 1]) translate([cam_dx + sx * eye_x, ax_y + yf - eye_seat, ax_z + eye_z]) rotate([-90, 0, 0]) cylinder(d = 4.66, h = 3.3, $fn = 32);
}
module head6() tilted() {
    translate([0, xp_f, 0]) front6();
    if (show_b) translate([0, -xp_b, 0]) back6();
    if (show_s) translate([0, -xp_s, 0]) straps_asm();
    ghosts6();
}
ctx = false;                                                    // true: draw the turret, cheek covers and cowl round the head
if (part == "v6_front") translate([0, 0, ax_y + yf]) rotate([-90, 0, 0]) front6();                  // front face on the bed
if (part == "v6_back") translate([0, 0, ax_y + yj]) rotate([-90, 0, 0]) back6();                    // plate's front face on the bed, arms and stubs up
if (part == "v6_straps") {
    flat(by_cam, cam_dx, lens_z, 0, 0) strap_cam_long();
    flat(oy_pcb[0], xos, zos, 0, 20) strap_oled();
}
if (part == "v6_view") { head6(); if (ctx) { color("#6b8fb5") turret4(); covers4(); if (show_cowl) cowl4(); } }
