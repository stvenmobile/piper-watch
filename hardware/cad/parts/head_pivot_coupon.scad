// Head pivot coupon: one working pivot of the v2 head (concepts/real_head_v2_concept.scad), to tune the fits
// before printing the head and the yoke.
//
//   BAR    a piece of yoke cheek (8 thick) with three 608 pockets, drawn 21.6 / 21.7 / 21.8 (+ the printer's
//          hole shrink): a light press, and the bearing stays in when the bar is turned over. Round 1 (22.2 /
//          22.4 / 22.6) and round 2 (21.9 / 22.0 / 22.1) were all loose: the bearing fell out.
//          The bearing goes in from the face marked with the groove; a 1 mm lip on the other face stops it.
//   EARS   round 2: all with the 8.1 stub (round 1's winner in the bearing), and a SOLID square key drawn
//          5.1 / 5.25 / 5.4 (numbered 1 2 3 on the back of the cap) for the wall's socket (drawn 5.5): keep the
//          one that pushes in with no wobble. Round 1 (stubs 7.9 / 8.0 / 8.1, 5 mm key slotted through) fitted
//          the bearing best at 8.1 but the slotted key flexed in the socket. The slots now stop at the key.
//          The stub should slide into the bearing's bore by hand (snug, not forced) - the M3 then spreads it.
//   WALL   a piece of the head's side wall with its boss (touches only the bearing's inner race), the ear's
//          square key socket, and an M3 heat-set insert inside.
//
// Assemble: insert in the wall's boss (from the inside face); bearing into a pocket; the ear's stub through the
// bearing into the wall's socket; M3 x 20 through the ear into the insert. Tightening clamps the bearing's INNER
// race between the ear's shoulder (it reaches through the lip) and the wall's boss, and spreads the stub: the
// ear and the wall should then turn together, freely, with the bearing - nothing rubbing on the bar.
// PRINT: everything as laid out (bar flat, ears cap-down, wall inside-face up), no supports.
include <../params.scad>

part = "all";                    // "all" | "bar" | "ears" | "wall"   ("ears" alone for round 2)

brg      = [22, 8, 7];           // 608-2RS: OD, bore, width
cheek    = 8;
lip      = cheek - brg[2];       // 1 mm lip on the outer face
pockets  = [21.6, 21.7, 21.8];   // drawn (before the hole shrink); round 1 22.2-22.6 and round 2 21.9-22.1: all loose
stubs    = [8.1, 8.1, 8.1];      // drawn (round 1 tried 7.9 / 8.0 / 8.1: 8.1 won)
keys     = [5.1, 5.25, 5.4];     // drawn: the solid key, against the 5.5 socket
ear_d    = 32;                   // octagonal cap, across the flats
ear_t    = 4;
ear_gap  = 1;                    // cap to the cheek's outer face
yoke_gap = 1.5;                  // head wall to the cheek: the wall's boss fills it
key      = 5;                    // square key on the stub's inner end
key_fit  = 0.25;                 // socket clearance each side
t        = 2.5;                  // head wall
boss_in  = 6;                    // the insert boss inside the head wall

module octagon2d(w) rotate([0, 0, 22.5]) circle(r = w / 2 / cos(22.5), $fn = 8);

// ---- the bar: three pockets ---------------------------------------------------------------------------------
module bar() {
    pitch = 34;
    difference() {
        translate([-pitch * 1.5, -17, 0]) cube([pitch * 3, 34, cheek]);
        for (i = [0 : 2]) translate([(i - 1) * pitch, 0, 0]) {
            translate([0, 0, lip]) cylinder(d = pockets[i] + cal_hole, h = cheek, $fn = 96);        // pocket (bearing side up)
            translate([0, 0, -1]) cylinder(d = 12 + cal_hole, h = cheek, $fn = 48);                 // the lip's hole
            translate([0, -14, cheek - 0.6]) linear_extrude(1) text(str(i + 1), size = 4, halign = "center", valign = "center");
        }
        translate([-pitch * 1.5 - 1, 16, cheek - 0.6]) cube([pitch * 3 + 2, 2, 1]);                 // groove: the bearing side
    }
}

// ---- an ear (printed cap-down: z = 0 is the cap's outer face) -------------------------------------------------
module ear(stub, n, k = key) {
    stub_l = brg[2] - 0.2;                          // a hair shorter than the bearing: the clamp is on the inner race
    z_stub = ear_t + ear_gap + lip;                 // the shoulder reaches through the lip to the inner race
    difference() {
        union() {
            linear_extrude(ear_t) octagon2d(ear_d);                                                  // cap
            translate([0, 0, ear_t]) cylinder(d = 11, h = ear_gap + lip, $fn = 48);                 // shoulder (inner race only)
            translate([0, 0, z_stub]) cylinder(d = stub, h = stub_l, $fn = 64);                     // stub
            translate([-k / 2, -k / 2, z_stub + stub_l - 0.01]) cube([k, k, key]);                  // key (solid)
        }
        translate([0, 0, -1]) cylinder(d = 6.2 + cal_hole, h = 2.5 + 1, $fn = 32);                  // bolt head recess
        translate([0, 0, 1.5]) cylinder(d = 3.4 + cal_hole, h = z_stub, $fn = 24);                   // M3 clearance
        translate([0, 0, z_stub]) cylinder(d1 = 3.4 + cal_hole, d2 = 2.6, h = stub_l + key + 0.01, $fn = 24);   // narrowing: spreads the stub
        for (a = [0, 90]) rotate([0, 0, a]) translate([-stub, -0.4, z_stub + 1]) cube([2 * stub, 0.8, stub_l - 1]);   // slots: the stub only
        translate([0, 0, ear_t - 0.6]) rotate([0, 0, 0]) for (k = [0 : n - 1])                        // number = dots on the cap's back
            translate([9 + 2.5 * k, 0, 0]) cylinder(d = 1.6, h = 1, $fn = 12);
    }
}

// ---- the wall piece (printed inside-face up: z = 0 is the boss's outer face) ------------------------------------
module wall() {
    difference() {
        union() {
            cylinder(d = 12, h = yoke_gap, $fn = 48);                                                // boss: inner race only
            translate([-15, -15, yoke_gap]) cube([30, 30, t]);                                       // the head wall
            translate([0, 0, yoke_gap + t]) cylinder(d = 11, h = boss_in, $fn = 48);                // insert boss inside
        }
        translate([-key / 2 - key_fit, -key / 2 - key_fit, -1]) cube([key + 2 * key_fit, key + 2 * key_fit, key + 1 + 0.5]);   // key socket
        translate([0, 0, yoke_gap + t + boss_in - insert_m3[1]]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 32);    // M3 insert
        translate([0, 0, -1]) cylinder(d = 3.4 + cal_hole, h = 30, $fn = 24);                        // bolt through
    }
}

if (part == "all" || part == "bar") bar();
if (part == "all" || part == "ears") for (i = [0 : 2]) translate([(i - 1) * 38, 45, 0]) ear(stubs[i], i + 1, keys[i]);
if (part == "all" || part == "wall") translate([0, -45, 0]) wall();
