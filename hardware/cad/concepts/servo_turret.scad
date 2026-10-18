// Concept: base box + 6807 bearing + pan servo, a turret that pans, and a head that TILTS on a
// pushrod from a tilt servo low in the turret (proportions only - estimates, not parts).
//
//   BASE    Jetson on the floor, the 4.3" display in the front wall, pan servo hanging from the lid
//   PAN     6807ZZ (35 x 47 x 7) pressed into the lid; the turret's hub turns in its inner race,
//           driven from below by the pan servo's horn - the bearing takes the weight and side loads
//   TURRET  a hollow column that pans; inside it the TILT servo (shaft along X), a ball stud on its
//           horn disc (7 mm out), an M3 turnbuckle (rod) up to a 10 mm crank on the head's axle,
//           set 20 deg down, so the head tilts -20 .. +60 deg for about +/-67 deg of servo
//   HEAD    a closed box with a camera window, on an axle through two ears that straddle the turret
//
// Servos: STS3215 from Feetech's drawing (45.22 x 24.72 x 32 case, discs 19.2 on both faces, no flange). Rod: the 64-74 mm turnbuckle at 69.
// F5 to preview. pan, tilt (head angle, deg up) move it; cutaway opens the turret and base.
include <../params.scad>

pan     = 0;
tilt    = 20;
cutaway = true;

// ---- base (as servo_head.scad) -------------------------------------------------------------------
base    = [135, 112, 92];       // depth: the J401 (80) + port overhang + the display stack + walls
base_r  = 12;
wall    = 2.5;
floor_t = 3;
lid_t   = 8;                    // thicker: the bearing seat
disp_z  = floor_t + (base[2] - floor_t - lid_t) / 2;

// ---- bearing, servos, linkage -------------------------------------------------------------------
brg     = [35, 47, 7];          // 6807ZZ: bore, OD, width
servo   = [45.22, 24.72, 32];   // STS3215 case (Feetech drawing): length, width, height along the shaft
servo_sh = 10.11;               // shaft from the near end (drawing)
disc    = [32, 4];              // a 32 mm disc screwed to the servo's 20 mm horn (4 x M3 on its 14 mm circle)
arm_s   = 12;                   // ball stud on the 32 mm disc: 12 mm out (M3 insert)
arm_h   = 15;                   // crank on the head's axle: the rod stays ~vertical, so the head's
                                //   swing is limited to arm_h*sin(swing) <= arm_s - 10 mm reaches +/-40 deg
crank_off = -20;                // crank angle = tilt + this: the +/-40 swing is centred on 20 deg UP,
                                //   so the head covers -20 .. +60 with the servo within about +/-67 deg
rod     = 40;                   // link: two M3 rod ends (rose joints) on M3 threaded rod, centre to centre -
                                //   the shortest that keeps the head crank clear of the servo disc

// ---- turret + head ------------------------------------------------------------------------------
tur     = [56, 62];             // turret column, outside (X, Y): the servo + its flange fit lengthwise
tur_r   = 10;
head    = [110, 52, 46];        // W, D, H
head_r  = 12;
ear_t   = 5;
win     = [80, 26];

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

module servo_body() {           // shaft along +Z at the origin, body below, length along +X from the shaft
    color("#1d3557") translate([-servo_sh, -servo[1] / 2, -servo[2]]) cube(servo);
    color("#c0c0c0") translate([0, 0, -servo[2] - 2.6]) cylinder(d = 19.2, h = 2.6, $fn = 40);    // idler disc underneath
    color("#c0c0c0") cylinder(d = disc[0], h = disc[1], $fn = 40);
}

// heights
z_lid   = base[2];
z_tfl   = z_lid + 2;                                    // turret floor (on the inner race)
z_srv   = z_tfl + 3 + disc[0] / 2 + 2;                  // tilt servo shaft: the disc clears the turret floor
y_srv   = -(servo[0] / 2 - servo_sh);                   // servo shaft toward the back, body centred in the turret
a0      = 0;                                            // its arm points FORWARD, parallel to the head's crank: the two
                                                        //   ball studs swing together, so the short link stays upright
y_axle  = (y_srv + arm_s) - arm_h;                      // head axle 15 mm behind the pan axis: the rod is then
                                                        //   vertical at mid-swing (20 deg), the best spot for a short link
head_dy = -y_axle;                                      // ... and the head box sits forward on its ears, centred again
z_axle  = z_srv + rod;
x_link  = tur[0] / 2 - wall - 6;                        // plane the linkage moves in (inside the turret's right wall)

// four-bar: the servo angle that gives head angle t (arms both forward at t = 0)
function link_err(a, t) = norm([y_srv + arm_s * cos(a + a0) - (y_axle + arm_h * cos(t + crank_off)), (z_srv + arm_s * sin(a + a0)) - (z_axle + arm_h * sin(t + crank_off))]) - rod;
function servo_ang(t, lo = -85, hi = 85, n = 40) = n == 0 ? (lo + hi) / 2 :
    (link_err((lo + hi) / 2, t) > 0) == (link_err(lo, t) > 0) ? servo_ang(t, (lo + hi) / 2, hi, n - 1) : servo_ang(t, lo, (lo + hi) / 2, n - 1);

module base_box() {
    difference() {
        linear_extrude(base[2]) rrect([base[0], base[1]], base_r);
        translate([0, 0, floor_t]) linear_extrude(base[2] - floor_t - lid_t) rrect([base[0], base[1]] - [2, 2] * wall, base_r - wall);
        translate([0, base[1] / 2 + 1, disp_z + 2.8]) rotate([90, 0, 0]) linear_extrude(wall + 2) square([97, 56], center = true);
        translate([0, 0, z_lid - brg[2]]) cylinder(d = brg[1], h = brg[2] + 1, $fn = 96);      // bearing seat
        translate([0, 0, z_lid - lid_t - 1]) cylinder(d = brg[0] - 4, h = lid_t, $fn = 64);    // hub / horn clearance
        for (sx = [-1, 1], y = [-40 : 8 : 40]) translate([sx * base[0] / 2, y, floor_t + 20]) cube([wall * 3, 3, 26], center = true);
        translate([0, -base[1] / 2, floor_t + 5 + 11]) cube([98, wall * 3, 20], center = true);      // the J401's ports
        if (cutaway) translate([0, -base[1], -1]) cube([base[0], 2 * base[1], base[2] + 2]);
    }
    color("#0d1117") translate([0, base[1] / 2 - wall - 2.2, disp_z]) cube([105.5, 4.4, 67.3], center = true);
    // Orin NX on Seeed's J401 carrier (from Seeed's reComputer J4012 STEP, case removed): PCB 100 x 79,
    // fan top ~28 above the PCB's underside; ports along its -Y edge -> the back wall
    color("#3c6e47") translate([0, -base[1] / 2 + wall + 2 + 41.2, floor_t + 5])
        import("../vitamins/models/j401_orin_nx.stl");
    // the bearing
    color("#b0b6bd") translate([0, 0, z_lid - brg[2]]) difference() {
        cylinder(d = brg[1], h = brg[2], $fn = 96); translate([0, 0, -1]) cylinder(d = brg[0], h = brg[2] + 2, $fn = 96);
    }
    // pan servo under the lid, shaft up into the hub
    translate([0, 0, z_lid - lid_t]) rotate([0, 0, 90]) servo_body();
}

module turret_and_head() {
    rotate([0, 0, pan]) {
        // hub in the bearing + turret column
        color("#2b2b2b", cutaway ? 0.35 : 1) difference() {
            union() {
                translate([0, 0, z_lid - brg[2]]) cylinder(d = brg[0], h = brg[2] + 2.01, $fn = 96);
                translate([0, 0, z_tfl]) linear_extrude(z_axle - z_tfl + 8) rrect(tur, tur_r);
            }
            translate([0, 0, z_tfl + 3]) linear_extrude(z_axle - z_tfl) rrect(tur - [2, 2] * wall, tur_r - wall);
            if (cutaway) translate([x_link + 3, -50, z_tfl - 1]) cube([50, 100, 200]);     // open the linkage side
        }
        // tilt servo lying in the turret: shaft along +X, toward the linkage plane
        translate([x_link - 3 - disc[1], y_srv, z_srv]) multmatrix([[0, 0, 1, 0], [1, 0, 0, 0], [0, 1, 0, 0]]) servo_body();
        a = servo_ang(tilt);
        A = [y_srv + arm_s * cos(a + a0), z_srv + arm_s * sin(a + a0)];   // (y, z) of the servo's ball stud
        color("#c0c0c0") hull() for (p = [[y_srv, z_srv], A]) translate([x_link - 3, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = 5, h = 2, center = true, $fn = 16);
        B = [y_axle + arm_h * cos(tilt + crank_off), z_axle + arm_h * sin(tilt + crank_off)];   // head crank's ball stud
        // rod
        color("#d4a017") hull() for (p = [A, B]) translate([x_link, p[0], p[1]]) sphere(d = 4, $fn = 16);
        color("#d4a017") for (p = [A, B]) translate([x_link, p[0], p[1]]) sphere(d = 6, $fn = 20);
        // head crank on the axle
        color("#888") hull() for (p = [[y_axle, z_axle], B]) translate([x_link, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = 6, h = 3, center = true, $fn = 20);
        // axle
        color("#c0c0c0") translate([0, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = 5, h = tur[0] + 2 * ear_t + 6, center = true, $fn = 20);
        // head: ears straddle the turret top, the box above, tilting about the axle
        translate([0, y_axle, z_axle]) rotate([tilt, 0, 0]) color("#222") {
            for (sx = [-1, 1]) translate([sx * (tur[0] / 2 + 0.5 + ear_t / 2), head_dy / 2, 6]) cube([ear_t, 22 + head_dy, 24], center = true);
            translate([0, head_dy, 0]) difference() {
                translate([0, 0, 14]) rotate([90, 0, 0]) translate([0, head[2] / 2, -head[1] / 2]) linear_extrude(head[1]) rrect([head[0], head[2]], head_r);
                translate([0, head[1] / 2 - 1, 14 + head[2] / 2]) cube([win[0], 4, win[1]], center = true);
            }
            color("#111", 0.7) translate([0, head_dy + head[1] / 2 - 1.5, 14 + head[2] / 2]) cube([win[0], 1.5, win[1]], center = true);
            color("#000") translate([0, head_dy + head[1] / 2 - 0.5, 14 + head[2] / 2]) rotate([-90, 0, 0]) cylinder(d = 11, h = 1, $fn = 32);
        }
    }
}

base_box();
turret_and_head();
echo(str("servo angle for tilt ", tilt, ": ", servo_ang(tilt), "  axle height ", z_axle, "  head top ~", z_axle + 14 + head[2]));
