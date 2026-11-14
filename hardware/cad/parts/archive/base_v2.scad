// BASE v2 - the robot's base box: Orin NX carrier board (no case), the 65 W brick, the 19 -> 12 V buck and the
// Waveshare bus-servo adapter on the floor; a thick lid carries the pan stack. Replaces the stand's four legs.
//
//   TUB    floor + walls, open at the top. Standoffs (M3 inserts) for the Orin carrier (86 x 58 holes) and the buck,
//          M2.5 standoffs for the Waveshare adapter, brick cradle (rails + stops), lid posts (M3 inserts), port slot and
//          AC opening in the back wall, USB-C hole in the front wall, two antenna holes in the left wall, feet recesses.
//   LID    6 mm plate on the posts (12 x M3 from the top). Slot for the pan servo's sleeve, 6 x M3 nut traps (underside)
//          for the pan plate, vent slots over the Orin's fan.
//   PLATE  the stand's base() without its legs (top plate 70 x 76 + the sleeve hanging below), bolted to the lid by
//          6 x M3 through plate and lid into nuts. The pillow block, hub and turret go on top of it as before.
//
// Why 78 mm tall: the pan servo hangs ~58.6 mm under the plate (sleeve, hub, plugs) so it needs the full height, and
// it can't hang over the Orin, so the pan axis is moved forward to pan_y (the heavy parts sit at the back as counterweight).
//
// Frame: base centre X = Y = 0, Z = 0 at the underside of the floor; +Y = front, +X = the robot's right.
// part = "base_view" (default) | "base_tub" | "base_lid" | "base_plate"
include <../servo_test_stand.scad>

part = "base_view";
base_legs = false;
show_lid = true;               // base_view: false to see inside from above

// ---- the box ----------------------------------------------------------------------------------------------------
bw = 172;  bd = 160;           // outside, X x Y
wt = 3;                        // wall
fl = 4;                        // floor
lid_z = 72;                    // lid's underside, from the floor's underside
lid_t = 6;
rr = 6;                        // outside corner radius
x_in = bw / 2 - wt;  y_in = bd / 2 - wt;     // interior half sizes: 83 x 77

// ---- pan stack --------------------------------------------------------------------------------------------------
pan_y = 24;                    // pan axis: forward of centre so the servo hangs in front of the Orin board
z_plate_top = lid_z + lid_t + plate_t;       // the pan plate's top face (the pillow block's underside)
slot_x = 19.5;  slot_y = [pan_y - 13.9, pan_y + 35.9];      // the sleeve (+ strap bosses) passes through the lid here
plate_bolts = [for (x = [-29, 29], y = [-29, 4, 37]) [x, pan_y + y]];   // plate -> lid, M3 + nut under the lid

// ---- Orin NX on its carrier (Seeed J401; same 86 x 58 holes as the dev kit) ------------------------------------------
orin_pcb = [100, 80, 1.6];
orin_c   = [-31, -34];         // PCB centre: back edge 3 mm off the back wall (ports overhang), 2 mm off the left wall
orin_h   = [86, 58];           // mounting holes
so_h     = 6;                  // standoff height (M3 insert from the top)
orin_pts = [for (sx = [-1, 1], sy = [-1, 1]) [orin_c[0] + sx * orin_h[0] / 2, orin_c[1] + sy * orin_h[1] / 2]];
port_slot = [94, 22];          // back wall: one slot over all the ports, 45 deg corners so it prints without support
port_z0   = 8;
ant_y     = [-60, -45];  ant_z = 22;         // antenna holes, left wall (positions to confirm on the real board)

// ---- 65 W brick (HP PPP009H), flat, AC end against the back wall -----------------------------------------------------
brick    = [45, 78, 28];
brick_x0 = 30;  brick_y0 = -76.5;
ac_w     = 38;  ac_h = 26;     // opening for the C5 plug; centre 9 mm off the brick's centre line (to confirm)
ac_x     = brick_x0 + brick[0] / 2 + 9;

// ---- buck (Seloky 66 x 36, holes 54 x 31 from l2_body.scad), long side front-back, right-front ---------------------
buck_board = [36, 66];  buck_holes = [31, 54];
buck_c   = [43, 41];
buck_h   = 6;
fuse_c   = [73, 30];  fuse_blk = [18, 40];   // fuse + terminal block, to the right of the buck (placeholder)

// ---- Waveshare bus-servo adapter (PCB 42 x 33, M2.5 holes 37 x 28; DC jack + screw terminal on the -x edge,
// USB-C on the -y edge, servo ports on +y). Turned 180 deg so the power side faces the buck and USB-C the front wall.
ad_pcb = [42, 33, 1.6];
ad_o   = [-80, 30];            // PCB corner
ad_pts = [for (x = [2.5, 39.5], y = [2.5, 30.5]) [ad_o[0] + x, ad_o[1] + y]];
ad_usb_x = ad_o[0] + 17;       // USB-C on the front wall (the STEP: 25 from the PCB's -x edge, so 17 after turning)

// ---- lid posts --------------------------------------------------------------------------------------------------
post_d = 10;
pp = 4.5;                      // post centre this far in from the wall's inner face (the post overlaps the wall by 0.5)
corner_pts = [for (sx = [-1, 1], sy = [-1, 1]) [sx * (x_in - pp), sy * (y_in - pp)]];
mid_pts = [[-(x_in - pp), -25], [-(x_in - pp), 30], [x_in - pp, -25], [x_in - pp, 30],
           [-45, y_in - pp], [45, y_in - pp], [-45, -(y_in - pp)], [45, -(y_in - pp)]];
lid_pts = concat(corner_pts, mid_pts);

module slab(w, d, r, h) linear_extrude(h) offset(r = r) square([w - 2 * r, d - 2 * r], center = true);
module xz_cut(pts, y0 = -76, len = 5) translate([0, y0, 0]) rotate([90, 0, 0]) linear_extrude(len) polygon(pts);
module standoff(p, d, h, ins) {
    translate([p[0], p[1], fl - 0.01]) cylinder(d = d, h = h + 0.01, $fn = 40);
}
module standoff_bore(p, h, ins) translate([p[0], p[1], fl + h - ins[1]]) cylinder(d = ins[0], h = ins[1] + 1, $fn = 24);

// ==== TUB ============================================================================================================
module tub() {
    difference() {
        union() {
            difference() {
                slab(bw, bd, rr, lid_z);
                translate([0, 0, fl]) slab(2 * x_in, 2 * y_in, rr - wt, lid_z);
            }
            for (p = corner_pts) translate([p[0], p[1], fl - 0.01]) cylinder(d = post_d, h = lid_z - fl + 0.01, $fn = 40);
            for (p = mid_pts) {                                  // corbels at the top of the walls, 45 deg underneath
                translate([p[0], p[1], lid_z - 18]) cylinder(d = post_d, h = 18, $fn = 40);
                translate([p[0], p[1], lid_z - 23]) cylinder(d1 = 0.01, d2 = post_d, h = 5, $fn = 40);
            }
            for (p = orin_pts) standoff(p, 8, so_h);
            for (p = ad_pts) standoff(p, 6.5, so_h);
            for (sx = [-1, 1], sy = [-1, 1]) standoff([buck_c[0] + sx * buck_holes[0] / 2, buck_c[1] + sy * buck_holes[1] / 2], 7, buck_h);
            for (y = [-14, 14]) standoff([fuse_c[0], fuse_c[1] + y], 7, buck_h);
            for (x = [brick_x0 - 1 - 1.6, brick_x0 + brick[0] + 1])                 // brick: side rails ...
                translate([x, brick_y0 + 2, fl - 0.01]) cube([1.6, brick[1] - 8, 14]);
            for (x = [brick_x0 - 1, brick_x0 + brick[0] - 6])                        // ... and front stops (DC cable between)
                translate([x, brick_y0 + brick[1] + 1, fl - 0.01]) cube([7, 1.6, 14]);
        }
        for (p = orin_pts) standoff_bore(p, so_h, insert_m3);
        for (p = ad_pts) standoff_bore(p, so_h, insert_m25);
        for (sx = [-1, 1], sy = [-1, 1]) standoff_bore([buck_c[0] + sx * buck_holes[0] / 2, buck_c[1] + sy * buck_holes[1] / 2], buck_h, insert_m3);
        for (y = [-14, 14]) standoff_bore([fuse_c[0], fuse_c[1] + y], buck_h, insert_m3);
        for (p = lid_pts) translate([p[0], p[1], lid_z - insert_m3[1]]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
        // back wall: port slot (trapezoid) and the AC opening (chamfered top)
        x0 = orin_c[0] - port_slot[0] / 2;  x1 = orin_c[0] + port_slot[0] / 2;
        xz_cut([[x0, port_z0], [x1, port_z0], [x1 - port_slot[1], port_z0 + port_slot[1]], [x0 + port_slot[1], port_z0 + port_slot[1]]], -y_in + 1);
        xz_cut([[ac_x - ac_w / 2, fl + 1], [ac_x + ac_w / 2, fl + 1], [ac_x + ac_w / 2, fl + ac_h - 6], [ac_x + ac_w / 2 - 6, fl + ac_h],
                [ac_x - ac_w / 2 + 6, fl + ac_h], [ac_x - ac_w / 2, fl + ac_h - 6]], -y_in + 1);
        for (y = ant_y) translate([-bw / 2 - 1, y, ant_z]) rotate([0, 90, 0]) cylinder(d = 6.6 + cal_hole, h = wt + 2, $fn = 32);
        translate([ad_usb_x - 6, y_in - 1, 10]) cube([12, wt + 2, 6]);                      // USB-C
        for (x = [-1, 1] * (bw / 2 - 18), y = [-1, 1] * (bd / 2 - 18)) translate([x, y, -0.01]) cylinder(d = 12, h = 1.5, $fn = 40);   // feet
    }
}

// ==== LID ============================================================================================================
module lid() {
    difference() {
        translate([0, 0, lid_z]) slab(bw, bd, rr, lid_t);
        for (p = lid_pts) translate([p[0], p[1], lid_z - 1]) cylinder(d = 3.4 + cal_hole, h = lid_t + 2, $fn = 24);
        translate([-slot_x, slot_y[0], lid_z - 1]) cube([2 * slot_x, slot_y[1] - slot_y[0], lid_t + 2]);
        for (q = plate_bolts) {
            translate([q[0], q[1], lid_z - 1]) cylinder(d = 3.4 + cal_hole, h = lid_t + 2, $fn = 24);
            translate([q[0], q[1], lid_z - 0.01]) cylinder(d = 6.9 + cal_hole, h = 2.8, $fn = 6);     // M3 nut, from underneath
        }
        for (i = [0 : 6]) translate([orin_c[0] - 24 + i * 6, orin_c[1] - 28, lid_z - 1]) cube([3, 36, lid_t + 2]);   // vents over the fan
    }
}

// ==== PAN PLATE (the stand's base() without legs, hung on the lid) ============================================================
module pan_plate() difference() {
    base();
    for (q = plate_bolts) translate([q[0], q[1] - pan_y, -plate_t - 1]) cylinder(d = 3.4 + cal_hole, h = plate_t + 2, $fn = 24);
}

// ==== ghosts (not printed) ===========================================================================================
module ghosts() {
    color("#2e7d32") translate([orin_c[0] - orin_pcb[0] / 2, orin_c[1] - orin_pcb[1] / 2, fl + so_h]) cube(orin_pcb);
    color("#9aa0a6") translate([orin_c[0] + 10 - 35, orin_c[1] + 6 - 25, fl + so_h + orin_pcb[2]]) cube([70, 50, 20]);
    color("#555") translate([brick_x0, brick_y0, fl]) cube(brick);
    color("#1f4f9f") translate([buck_c[0] - buck_board[0] / 2, buck_c[1] - buck_board[1] / 2, fl + buck_h]) cube([buck_board[0], buck_board[1], 14]);
    color("#00897b") translate([fuse_c[0] - fuse_blk[0] / 2, fuse_c[1] - fuse_blk[1] / 2, fl + buck_h]) cube([fuse_blk[0], fuse_blk[1], 12]);
    color("#2a6a3a") translate([ad_o[0], ad_o[1], fl + so_h]) cube(ad_pcb);
    color("#222") translate([ad_o[0] + ad_pcb[0], ad_o[1] + 8, fl + so_h + ad_pcb[2]]) cube([12.3, 16, 11]);
    color("#b0b0b0") translate([-srv[1] / 2, pan_y - srv_sh, z_plate_top + z_case_bot]) cube([srv[1], srv[0], srv[2]]);     // the pan servo
}

if (part == "base_view") {
    color("#6b8fb5") tub();
    if (show_lid) color("#b5c4d6", 0.35) lid();
    if (show_lid) color("#2b2b2b") translate([0, pan_y, z_plate_top]) pan_plate();
    ghosts();
    echo(str("base ", bw, " x ", bd, " x ", lid_z + lid_t, "; pan axis (0, ", pan_y, "); servo bottom at z ", z_plate_top + z_case_bot,
             " (floor top ", fl, "); plugs room ", z_plate_top + z_case_bot - fl));
}
if (part == "base_tub")   tub();
if (part == "base_lid")   translate([0, 0, lid_z + lid_t]) rotate([180, 0, 0]) lid();
if (part == "base_plate") rotate([180, 0, 0]) pan_plate();
