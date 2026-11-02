// BASE v3 - the compact base: bare Orin NX carrier, Waveshare bus-servo adapter, fuse + terminal block and a 12 V barrel jack.
// Everything runs from ONE external 12 V supply (no brick, no buck): the Orin NX takes 5-20 V on its own jack, the servo
// adapter 9-12.6 V. The pan servo hangs through the lid as in v2, beside the Orin, so the base stays low.
//
//   TUB    floor + walls, open at the top. M3 standoffs (inserts) for the Orin (86 x 58), M2.5 for the adapter (turned -90 deg:
//          servo ports toward the pan servo, power toward the front, USB-C to a hole in the left wall), 2 M3 for the fuse /
//          terminal block, 12 corbels (M3 inserts) at the wall tops for the lid, port slot (back), antenna holes + inlet
//          slots (left), inlet slots (right), 12 V jack hole (right), 4 feet recesses.
//   LID    8 mm plate on the 12 corbels. Sleeve slot (also the cable hole for the head's 3 cables), 6 nut traps for the pan
//          plate, vent slots over the Orin's fan.
//   PLATE  the stand's base() without legs, bolted through the lid (as v2).
//
// The drum (r 54) hangs from the turret floor to 3 mm over the lid; no lid screw lies inside its swept circle.
// Frame: base centre X = Y = 0, Z = 0 at the underside of the floor; +Y = front, +X = the robot's right.
// part = "base_view" | "base_tub" | "base_lid" | "base_plate"
include <servo_test_stand.scad>

part = "base_view";
base_legs = false;
show_lid = true;

// ---- the box ----------------------------------------------------------------------------------------------------
bw = 118;  bd = 150;
wt = 3;  fl = 4;
lid_z = 70;  lid_t = 8;
rr = 6;
x_in = bw / 2 - wt;  y_in = bd / 2 - wt;          // interior half sizes: 56 x 72

// ---- pan stack ---------------------------------------------------------------------------------------------------
pan_y = 20;                                       // the drum (r 54) then ends 1 mm inside the lid's front edge
drum_r = 54;
z_plate_top = lid_z + lid_t + plate_t;
slot_x = 19.5;  slot_y = [pan_y - 13.9, pan_y + 35.9];
plate_bolts = [for (x = [-29, 29], y = [-29, 4, 37]) [x, pan_y + y]];

// ---- Orin NX carrier ----------------------------------------------------------------------------------------------
orin_pcb = [100, 80, 1.6];
orin_c   = [0, -y_in + 3 + orin_pcb[1] / 2];      // back edge 3 mm off the back wall (the ports overhang into the slot)
orin_h   = [86, 58];
so_h     = 6;
orin_pts = [for (sx = [-1, 1], sy = [-1, 1]) [orin_c[0] + sx * orin_h[0] / 2, orin_c[1] + sy * orin_h[1] / 2]];
port_slot = [94, 22];  port_z0 = 8;
ant_y = [-60, -45];  ant_z = 22;                  // antenna holes, left wall (to confirm on the real board)
fan_h = 20;                                       // heatsink + fan above the PCB (to confirm)

// ---- Waveshare adapter, turned -90 deg: footprint 33 (X) x 42 (Y) ------------------------------------------------------
ad_o  = [-53, 16];                                    // jack + terminals stick out 12 mm past its front edge: 54 in all, 1.7 mm to the wall
ad_pts = [for (xo = [2.5, 39.5], yo = [2.5, 30.5]) [ad_o[0] + yo, ad_o[1] + 42 - xo]];
ad_usb_y = ad_o[1] + 17;                          // USB-C on the left edge
// ---- fuse + terminal block and the 12 V jack (right wall) ----------------------------------------------------------------
fuse_o   = [20, 44];  fuse_blk = [30, 20, 14];
fuse_pts = [[fuse_o[0] + 5, fuse_o[1] + 10], [fuse_o[0] + 25, fuse_o[1] + 10]];
jack_y = 54;  jack_z = 18;  jack_d = 11.5;

// ---- lid corbels: all clear of the drum's circle (r 54 about the pan axis) ----------------------------------------------------
pp = 4.5;  post_d = 10;
lid_pts = concat([for (sx = [-1, 1], sy = [-1, 1]) [sx * (x_in - pp), sy * (y_in - pp)]],
                 [[-(x_in - pp), -25], [-(x_in - pp), 55], [x_in - pp, -25], [x_in - pp, 55],
                  [-40, y_in - pp], [40, y_in - pp], [-40, -(y_in - pp)], [40, -(y_in - pp)]]);

module slab(w, d, r, h) linear_extrude(h) offset(r = r) square([w - 2 * r, d - 2 * r], center = true);
module xz_cut(pts, y0 = -76, len = 5) translate([0, y0, 0]) rotate([90, 0, 0]) linear_extrude(len) polygon(pts);
module standoff(p, d, h) translate([p[0], p[1], fl - 0.01]) cylinder(d = d, h = h + 0.01, $fn = 40);
module standoff_bore(p, h, ins) translate([p[0], p[1], fl + h - ins[1]]) cylinder(d = ins[0], h = ins[1] + 1, $fn = 24);

// ---- webs: every boss near a wall is tied to it by a solid hull (circle + the wall strip beside it), never a tangent ----------
function wdirs(p, th) = [for (a = [[1, 0], [-1, 0], [0, 1], [0, -1]]) if (a[0] * p[0] + a[1] * p[1] > (a[0] != 0 ? x_in : y_in) - th) a];
module wstrip(p, a, hw)                                                          // the wall's thickness, 2 hw wide, beside p
    translate(a[0] != 0 ? [a[0] * (x_in + 1.5), p[1]] : [p[0], a[1] * (y_in + 1.5)])
        rotate(a[0] != 0 ? 0 : 90) square([3, 2 * hw], center = true);
module web2d(p, d, th, hw) hull() { translate(p) circle(d = d, $fn = 40); for (a = wdirs(p, th)) wstrip(p, a, hw); }

// corbel: the web at the lid seat, tapering to a thin root on the wall 23 mm lower (steep sides, nothing to bridge)
module corbel_web(p) hull() {
    translate([0, 0, lid_z - 0.01]) linear_extrude(0.01) web2d(p, post_d, 10.5, 11);
    translate([0, 0, lid_z - 23]) linear_extrude(0.01) hull() { translate(p) circle(d = 0.01); for (a = wdirs(p, 10.5)) wstrip(p, a, 5.5); }
}
corbel_pairs = [for (i = [0 : len(lid_pts) - 1], j = [0 : len(lid_pts) - 1]) if (j > i && norm(lid_pts[i] - lid_pts[j]) < 16) [i, j]];
module corbels() intersection() {                                              // clipped inside the outer skin (webs reach into the walls)
    union() {
        for (p = lid_pts) {
            corbel_web(p);
            translate([p[0], p[1], lid_z - 18]) cylinder(d = post_d, h = 18, $fn = 40);        // the boss itself, 45 deg cone underneath
            translate([p[0], p[1], lid_z - 23]) cylinder(d1 = 0.01, d2 = post_d, h = 5, $fn = 40);
        }
        for (q = corbel_pairs) hull() { corbel_web(lid_pts[q[0]]); corbel_web(lid_pts[q[1]]); }   // two bosses together: filled between
    }
    translate([0, 0, fl]) slab(bw - 1, bd - 1, rr - 0.5, lid_z);
}
module floor_webs() intersection() {                                           // low webs (1.5 under the standoff tops, so nothing touches the boards)
    translate([0, 0, fl - 0.01]) linear_extrude(so_h - 1.5) union() {
        for (p = orin_pts) web2d(p, 8, 14, 9);
        for (p = ad_pts)   web2d(p, 6.5, 9, 8);
        for (p = fuse_pts) web2d(p, 7, 12, 8);
    }
    translate([0, 0, fl - 1]) slab(bw - 1, bd - 1, rr - 0.5, 20);
}

// ==== TUB ============================================================================================================
module tub() {
    difference() {
        union() {
            difference() {
                slab(bw, bd, rr, lid_z);
                translate([0, 0, fl]) slab(2 * x_in, 2 * y_in, rr - wt, lid_z);
            }
            corbels();
            floor_webs();
            for (p = orin_pts) standoff(p, 8, so_h);
            for (p = ad_pts) standoff(p, 6.5, so_h);
            for (p = fuse_pts) standoff(p, 7, so_h);
        }
        for (p = orin_pts) standoff_bore(p, so_h, insert_m3);
        for (p = ad_pts) standoff_bore(p, so_h, insert_m25);
        for (p = fuse_pts) standoff_bore(p, so_h, insert_m3);
        for (p = lid_pts) translate([p[0], p[1], lid_z - insert_m3[1]]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
        // back wall: one trapezoid over all the ports (45 deg top corners)
        x0 = orin_c[0] - port_slot[0] / 2;  x1 = orin_c[0] + port_slot[0] / 2;
        xz_cut([[x0, port_z0], [x1, port_z0], [x1 - port_slot[1], port_z0 + port_slot[1]], [x0 + port_slot[1], port_z0 + port_slot[1]]], -y_in + 1);
        // left wall: antennas, adapter USB-C, inlet slots; right wall: 12 V jack, inlet slots
        for (y = ant_y) translate([-bw / 2 - 1, y, ant_z]) rotate([0, 90, 0]) cylinder(d = 6.6 + cal_hole, h = wt + 2, $fn = 32);
        translate([-bw / 2 - 1, ad_usb_y - 6, fl + so_h + 1.6 - 1]) cube([wt + 2, 12, 6.5]);
        for (i = [0 : 5]) translate([-bw / 2 - 1, -35 + i * 7, 12]) cube([wt + 2, 2.6, 20]);
        translate([bw / 2 - wt - 1, jack_y, jack_z]) rotate([0, 90, 0]) cylinder(d = jack_d, h = wt + 2, $fn = 40);
        for (i = [0 : 7]) translate([bw / 2 - wt - 1, -62 + i * 7, 12]) cube([wt + 2, 2.6, 20]);
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
            translate([q[0], q[1], lid_z - 0.01]) cylinder(d = 6.9 + cal_hole, h = 2.8, $fn = 6);
        }
        for (i = [0 : 5]) translate([-15 + i * 6, -58, lid_z - 1]) cube([3, 24, lid_t + 2]);       // vents behind the drum's reach
    }
}

module pan_plate() difference() {
    base();
    for (q = plate_bolts) translate([q[0], q[1] - pan_y, -plate_t - 1]) cylinder(d = 3.4 + cal_hole, h = plate_t + 2, $fn = 24);
}

// ==== ghosts (not printed) ===========================================================================================
module ghosts() {
    color("#2e7d32") translate([orin_c[0] - orin_pcb[0] / 2, orin_c[1] - orin_pcb[1] / 2, fl + so_h]) cube(orin_pcb);
    color("#9aa0a6") translate([-35, orin_c[1] - 28, fl + so_h + orin_pcb[2]]) cube([70, 50, fan_h]);
    color("#2a6a3a") translate([ad_o[0], ad_o[1], fl + so_h]) cube([33, 42, 1.6]);
    color("#222") translate([ad_o[0] + 8, ad_o[1] + 42, fl + so_h + 1.6]) cube([16, 12.3, 11]);
    color("#00897b") translate([fuse_o[0], fuse_o[1], fl + so_h]) cube(fuse_blk);
    color("#b0b0b0") translate([-srv[1] / 2, pan_y - srv_sh, z_plate_top + z_case_bot]) cube([srv[1], srv[0], srv[2]]);
}

if (part == "base_view") {
    color("#6b8fb5") tub();
    if (show_lid) color("#b5c4d6", 0.35) lid();
    if (show_lid) color("#2b2b2b") translate([0, pan_y, z_plate_top]) pan_plate();
    ghosts();
    echo(str("base ", bw, " x ", bd, " x ", lid_z + lid_t, "; pan axis (0, ", pan_y, "); servo bottom z ", z_plate_top + z_case_bot,
             "; drum front edge y ", pan_y + drum_r, " (lid edge ", bd / 2, ")"));
}
if (part == "base_tub")   tub();
if (part == "base_lid")   translate([0, 0, lid_z + lid_t]) rotate([180, 0, 0]) lid();
if (part == "base_plate") rotate([180, 0, 0]) pan_plate();
