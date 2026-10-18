// Neck concepts - two ways to carry the camera pod on the turntable plate, side by side to compare
// (not print-ready yet: choose one, then it gets proper parts in parts/).
//
//   A  STACKING NECK   a 30 mm neck; extra 30 mm rings of the same diameter stack on it; the pod
//                      plugs into the top. Every joint is the same: a SOCKET (recess) on top, a
//                      SPIGOT underneath, a key so nothing twists, two M3 screws through the socket
//                      wall into inserts in the spigot. Height in 30 mm steps; no tilt.
//   B  TILT YOKE       a fixed 30 mm neck ending in a fork; the pod pivots between the cheeks on
//                      an M4 bolt. One cheek has an arc of holes at 0 / 10 / 20 / 30 deg up; a second
//                      bolt through the chosen hole into the pod's side locks the angle.
//
// Both bolt to the turntable plate with the four M3 inserts already in it (the old head floor's),
// and keep a bore down the middle for the camera's USB cable (its USB-A plug passes through).
// The pod: the bare C920 board (80 x 22) upright behind the front, lens through a window, held by
// the U-channel bracket used on the eye test stand; LED pinholes TBD once the LEDs are located.
//
// F5 to preview. show = "both" | "A" | "B"; rings = extra rings on A; tilt = B's angle.
include <../level2.scad>
include <../head.scad>

show  = "both";
rings = 1;
tilt  = 20;

// ---- shared ------------------------------------------------------------------------------------
neck_d   = 40;          // neck and rings, outside
neck_h   = 30;          // the neck above its flange top; each ring adds the same
flange_d = 74;          // reaches the plate's M3 inserts (radius 31.1) with room for the screw heads
flange_t = 4;
bore_d   = 18;          // the camera's USB cable, plug and all
sock     = [30.4, 8];   // socket: diameter, depth (the spigot is 30)
key_w    = 4;

// the pod (board upright, lens toward +Y)
pod      = [90, 28, 30];        // width, depth, height
pod_r    = 7;                   // rounded ends, seen from the front: an oblong
pod_wall = 2.5;
lens_win = 15;                  // window round the 11 mm lens barrel
board    = [80, 22];

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

// ---- the turntable plate and Level 2's deck, for context -----------------------------------------
module context() {
    color("#c7cbd0") translate([0, 0, -deck_t]) linear_extrude(deck_t) rrect(l2_size, l2_r);
    color("#9aa3ad") translate([0, 0, z_ls]) cylinder(d = 140, h = z_plate - z_ls, $fn = 96);    // lazy Susan
    color("#e8a33d") translate([0, 0, z_plate]) cylinder(d = top_plate_d, h = 8, $fn = 96);      // turntable plate
}
plate_top = z_plate + 8;

// ---- the pod -------------------------------------------------------------------------------------
module pod() {
    difference() {
        rotate([90, 0, 0]) translate([0, 0, -pod[1] / 2]) linear_extrude(pod[1]) rrect([pod[0], pod[2]], pod_r);
        rotate([90, 0, 0]) translate([0, 0, -pod[1] / 2 + pod_wall]) linear_extrude(pod[1] - pod_wall)
            rrect([pod[0], pod[2]] - [2, 2] * pod_wall, pod_r - pod_wall);                  // open at the back (a lid closes it)
        translate([0, pod[1] / 2 + 1, 0]) rotate([90, 0, 0]) cylinder(d = lens_win, h = pod_wall + 2, $fn = 48);
    }
    // the board inside (ghost-ish) and its lens
    color("#2e6b3a") translate([0, pod[1] / 2 - pod_wall - 0.5 - 14, 0]) cube([board[0], 1.3, board[1]], center = true);
    color("#111") translate([0, pod[1] / 2 - 0.5 - 7, 0]) rotate([-90, 0, 0]) cylinder(d = 11, h = 7, center = true, $fn = 32);
}

// ---- A: neck, rings, pod with spigot ----------------------------------------------------------------
module spigot() {
    difference() {
        union() {
            translate([0, 0, -sock[1]]) cylinder(d = sock[0] - 0.4, h = sock[1], $fn = 64);
            translate([-key_w / 2, sock[0] / 2 - 1.5, -sock[1]]) cube([key_w, 1.5, sock[1]]);    // key
        }
        translate([0, 0, -sock[1] - 1]) cylinder(d = bore_d, h = sock[1] + 2, $fn = 48);
    }
}
module socket_cut(top) {
    translate([0, 0, top - sock[1]]) cylinder(d = sock[0], h = sock[1] + 1, $fn = 64);
    translate([-key_w / 2 - 0.2, sock[0] / 2 - 2, top - sock[1]]) cube([key_w + 0.4, 2.4, sock[1] + 1]);   // key slot
    for (a = [90, 270]) translate([0, 0, top - sock[1] / 2]) rotate([0, 90, a]) cylinder(d = 3.4, h = neck_d, $fn = 24);   // lock screws
}
module neck_A() {
    difference() {
        union() {
            cylinder(d = flange_d, h = flange_t, $fn = 96);
            cylinder(d = neck_d, h = flange_t + neck_h, $fn = 96);
        }
        translate([0, 0, -1]) cylinder(d = bore_d, h = 100, $fn = 48);
        socket_cut(flange_t + neck_h);
        for (m = floor_mounts) translate([m[0], m[1], -1]) cylinder(d = 3.4, h = flange_t + 2, $fn = 24);
    }
}
module ring_A() {
    difference() {
        cylinder(d = neck_d, h = neck_h, $fn = 96);
        translate([0, 0, -1]) cylinder(d = bore_d, h = 100, $fn = 48);
        socket_cut(neck_h);
    }
    spigot();
}
module option_A() {
    translate([0, 0, plate_top]) {
        color("#2b2b2b") neck_A();
        for (i = [0 : rings - 1]) if (rings > 0) translate([0, 0, flange_t + neck_h + i * neck_h]) color(i % 2 ? "#2b2b2b" : "#3a3a3a") ring_A();
        translate([0, 0, flange_t + neck_h * (1 + rings) + pod[2] / 2]) {
            color("#2b2b2b") pod();
            color("#2b2b2b") translate([0, 0, -pod[2] / 2 + 0.01]) spigot();
        }
    }
}

// ---- B: fixed neck with a fork, pod pivoting, index holes on one cheek ----------------------------
cheek_t   = 5;
pivot_z   = 22;         // pivot above the neck's top (room for the pod to tilt)
index_r   = 17;         // index holes: radius round the pivot
angles    = [0, 10, 20, 30];
module yoke_B() {
    gap = pod[0] + 1;                                   // between the cheeks
    difference() {
        union() {
            cylinder(d = flange_d, h = flange_t, $fn = 96);
            cylinder(d = neck_d, h = flange_t + neck_h, $fn = 96);
            translate([0, 0, flange_t + neck_h]) hull() {                         // cross bar
                for (s = [-1, 1]) translate([s * (gap / 2 + cheek_t / 2), 0, 3]) cube([cheek_t, 26, 6], center = true);
                cylinder(d = neck_d, h = 0.1, $fn = 96);
            }
            for (s = [-1, 1]) translate([s * (gap / 2 + cheek_t / 2), 0, flange_t + neck_h]) hull() {   // cheeks
                translate([0, 0, 3]) cube([cheek_t, 26, 6], center = true);
                translate([0, 0, pivot_z]) rotate([0, 90, 0]) cylinder(d = 2 * index_r + 12, h = cheek_t, center = true, $fn = 64);
            }
        }
        translate([0, 0, -1]) cylinder(d = bore_d, h = 100, $fn = 48);
        for (m = floor_mounts) translate([m[0], m[1], -1]) cylinder(d = 3.4, h = flange_t + 2, $fn = 24);
        translate([0, 0, flange_t + neck_h + pivot_z]) rotate([0, 90, 0]) cylinder(d = 4.4, h = 200, center = true, $fn = 24);   // pivot
        for (a = angles) translate([gap / 2 + cheek_t / 2, 0, flange_t + neck_h + pivot_z])                           // index holes
            rotate([a, 0, 0]) translate([0, 0, -index_r]) rotate([0, 90, 0]) cylinder(d = 4.4, h = cheek_t + 2, center = true, $fn = 24);
    }
    // the angle marks, engraved beside the holes (shown as small dots here)
    for (a = angles) translate([gap / 2 + cheek_t + 0.3, 0, flange_t + neck_h + pivot_z])
        rotate([a, 0, 0]) translate([0, 0, -index_r - 5]) color("#e8e8e8") cube([0.6, 1.2, 1.2], center = true);
}
module option_B() {
    translate([0, 0, plate_top]) {
        color("#2b2b2b") yoke_B();
        translate([0, 0, flange_t + neck_h + pivot_z]) rotate([tilt, 0, 0]) color("#2b2b2b") pod();
        // bolts: pivot through both cheeks, the lock through the chosen index hole
        color("#b8b8b8") translate([0, 0, flange_t + neck_h + pivot_z]) rotate([0, 90, 0]) cylinder(d = 4, h = pod[0] + 2 * cheek_t + 8, center = true, $fn = 16);
        color("#b8b8b8") translate([(pod[0] + 1) / 2 + cheek_t / 2, 0, flange_t + neck_h + pivot_z]) rotate([tilt, 0, 0])
            translate([0, 0, -index_r]) rotate([0, 90, 0]) cylinder(d = 4, h = cheek_t + 8, center = true, $fn = 16);
    }
}

// ---- layout --------------------------------------------------------------------------------------
if (show == "A" || show == "both") translate([show == "both" ? -95 : 0, 0, 0]) { context(); option_A(); }
if (show == "B" || show == "both") translate([show == "both" ? 95 : 0, 0, 0]) { context(); option_B(); }
