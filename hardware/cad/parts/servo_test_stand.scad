// Servo pan/tilt TEST STAND - the prototype of the new head (concepts/servo_turret.scad), stand-alone
// on four legs so both STS3215s can be powered and exercised before the base box exists.
//
//   BASE    top plate on four legs; the ServoCity 1" pillow block bolts on top (4 x M4 into heat-set
//           inserts); the PAN servo hangs underneath in a sleeve, shaft up on the bearing's axis,
//           pushed up against stop tabs and held by a strap
//   HUB     a tube through the pillow block's 25.4 bearing; its closed lower end screws to the pan
//           servo's horn (4 x M3 on the 14 mm circle, driven down the open tube before the turret goes
//           on); a window lets the tilt servo's cable out below the plate; a flange on top carries
//   TURRET  floor (4 x M3 into the hub flange), the TILT servo lying on its side in a cradle (shaft
//           along +X; idler disc located in the end wall; strap on top), two cheeks for the head's axle;
//           a tunnel under the servo takes its cable from its connector end down into the hub
//   DISC    32 mm, on the tilt servo's horn (4 x M3); its boss carries the link's rod end 12 mm out
//   HEAD    a stand-in: two ears on the axle (M4 screws through the cheeks into inserts in the ears),
//           a bridge plate for a camera later, and the 15 mm CRANK (an M3 insert) on the right ear
//   LINK    two M3 rod ends (rose joints) on M3 threaded rod, 40 mm centre to centre, jam nuts
//
// Geometry (concept): servo arm 12 and head crank 15, both pointing forward (parallel) at 20 deg of
// head tilt; the head's axle 15.5 mm behind the pan axis -> head -20 .. +60 deg for servo -/+54 deg.
//
// MEASURE AND CHECK before the long prints: hub_od against the bearing's bore (print the hub first),
// rod end ball width (rod_ball_w), the bearing flange's height above the block (brg_flange).
//
// Frame: pan axis at X = Y = 0, Z = 0 at the top plate's top face (the pillow block's underside);
// +Y = front, +X = right (seen from behind the robot... and from the front, X is to the LEFT).
// part = "assembly" | "base" | "hub" | "turret" | "disc" | "head" | "straps"
include <../params.scad>

part = "assembly";
pan  = 0;
tilt = 20;

// ---- bought parts ---------------------------------------------------------------------------------
pb       = [43, 40, 7];         // ServoCity 1" bore 2-post pillow block (drawing): X, Y, thickness
pb_holes = [32, 32];            //   its 4 x 4 mm through-holes (M4): a 32 mm square, MEASURED (the drawing
                                //   showed 32 x 24) - 22.6 mm from the centre
brg_bore = 25.4;                //   the bearing's bore
brg_flange = 1.52;              //   the bearing's flange stands this far above the block (8.52 - 7) - CHECK
srv      = sts_body;            // STS3215 [45.22, 24.72, 32]
srv_sh   = sts_shaft_x;         // 10.11: shaft from the near end
disc_h   = sts_horn_h;          // 2.6: each of the servo's two discs
pcd      = sts_horn_pcd;        // 14
rod_c    = 40;                  // link, centre to centre
rod_ball_w = 5;                 // rod end ball width (EST - check)
rod_eye_d  = 10;                // rod end eye outside (EST)

// ---- base -----------------------------------------------------------------------------------------
plate_t  = 6;
plate    = [[-35, 35], [-34, 42]];   // X and Y extents: the servo body runs to Y = +35
sleeve_t = 3;
clr      = 0.3;
z_horn   = -24;                 // pan servo's horn top (leaves room for the hub's cable window)
z_case_top = z_horn - disc_h;   // -26.6
z_case_bot = z_case_top - srv[2];   // -58.6
strap_t  = 3;
ins_wall = 0.8;                 // plastic left between an insert's hole and the servo it sits beside
ins_boss = insert_m3[0] + 4;    // round bosses round the strap inserts (2 mm of wall all round)
pan_ins_x = srv[1] / 2 + clr + ins_wall + insert_m3[0] / 2;   // pan strap inserts: X (the sleeve's sides)
z_desk   = z_case_bot - disc_h - strap_t - 2;   // legs' feet
leg      = 9;

// ---- hub ------------------------------------------------------------------------------------------
hub_od   = brg_bore - 0.15;     // slip fit in the bearing (CHECK: print the hub first)
hub_id   = 19;
hub_end  = 3;                   // closed lower end (onto the horn)
z_flange = pb[2] + brg_flange + 1.0;   // flange's underside: 1 mm over the bearing's flange
flange_t = 6;
flange_d = 66;
flange_r = 29;                  // turret screws (4 x M3, at 0/90/180/270 - clear of the tilt servo)
win      = [12, 11];            // cable window, below the plate

// ---- turret ---------------------------------------------------------------------------------------
z_floor  = z_flange + flange_t;     // turret floor's underside
floor_t  = 3;
z_ft     = z_floor + floor_t;       // floor top
z_srv    = z_ft + 16 + 2;           // tilt servo shaft: the 32 mm disc clears the floor by 2
y_srv    = -(srv[0] / 2 - srv_sh);  // -12.5: the servo body centred front-back
x_idler  = -srv[2] / 2;             // -16: the servo's idler face (body from -16 to +16 in X)
x_horn   = srv[2] / 2;              // +16: horn face
disc_d   = 32;
disc_t   = 4;
boss_h   = 2;                       // boss on the disc under the rod end
arm_s    = 12;
x_link   = x_horn + disc_h + disc_t + boss_h + rod_ball_w / 2;   // the link's plane
arm_h    = 15;
crank_off = -20;                    // crank angle (from forward) = tilt + this
y_axle   = (y_srv + arm_s) - arm_h; // -15.5
z_axle   = z_srv + rod_c;
cheek_t  = 5;
x_cheek  = 36;                      // cheeks' inner faces at +/- this
floor_xy = [[-x_cheek - cheek_t, x_cheek + cheek_t], [-34, 34]];

// ---- head stand-in --------------------------------------------------------------------------------
ear_t    = 4;
x_ear    = x_cheek - 1;             // ears' outer faces (a washer between ear and cheek)
bridge   = [2 * x_ear, 34, 4];      // camera bridge: X, Y, thickness
bridge_dz = 10;                     // above the axle
head_dy  = -y_axle;                 // the bridge sits forward, centred over the pan axis

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }
module box(xr, yr, zr) translate([xr[0], yr[0], zr[0]]) cube([xr[1] - xr[0], yr[1] - yr[0], zr[1] - zr[0]]);
module insert3(h = insert_m3[1] + 1) cylinder(d = insert_m3[0], h = h, $fn = 24);
module hole3(h) cylinder(d = 3.4 + cal_hole, h = h, $fn = 24);

// ==== BASE ===========================================================================================
pan_ins_y = [-srv_sh - clr - sleeve_t / 2 + 6, srv[0] - srv_sh + clr - 6];   // pan strap inserts: Y (front, back)

module base() {
    sx = [-srv[1] / 2 - clr, srv[1] / 2 + clr];            // sleeve inside, X
    sy = [-srv_sh - clr, srv[0] - srv_sh + clr];            // sleeve inside, Y (shaft at Y = 0)
    difference() {
        union() {
            translate([0, 0, -plate_t]) linear_extrude(plate_t)                                  // top plate
                translate([(plate[0][0] + plate[0][1]) / 2, (plate[1][0] + plate[1][1]) / 2])
                    rrect([plate[0][1] - plate[0][0], plate[1][1] - plate[1][0]], 6);
            for (x = plate[0], y = plate[1])                                                     // legs
                translate([x - (x > 0 ? leg : 0), y - (y > 0 ? leg : 0), z_desk]) cube([leg, leg, -z_desk - 0.01]);
            box([sx[0] - sleeve_t, sx[1] + sleeve_t], [sy[0] - sleeve_t, sy[1]], [z_case_bot, -plate_t + 0.01]);  // sleeve
            for (x = [-1, 1], y = pan_ins_y) translate([x * pan_ins_x, y, z_case_bot])         // bosses for the strap inserts
                cylinder(d = ins_boss, h = insert_m3[1] + 3, $fn = 32);
        }
        box(sx, [sy[0], sy[1] + 5], [z_case_bot - 1, -plate_t + 0.02]);                         // the servo's pocket (open at +Y)
        translate([0, 0, -plate_t - 1]) cylinder(d = hub_od + 2, h = plate_t + 2, $fn = 64);   // hub passes through
        translate([0, 0, z_horn - 1]) cylinder(d = hub_od + 1, h = -z_horn, $fn = 64);           // room for the hub down
                                                                                                 //   to the horn (cuts the
                                                                                                 //   sleeve's walls above
                                                                                                 //   the servo's case only)
        for (x = [-1, 1], y = [-1, 1])                                                           // pillow block: M4 inserts
            translate([x * pb_holes[0] / 2, y * pb_holes[1] / 2, -insert_m4[1]]) cylinder(d = insert_m4[0], h = insert_m4[1] + 1, $fn = 24);
        for (x = [-1, 1], y = pan_ins_y) translate([x * pan_ins_x, y, z_case_bot - 0.01]) insert3();   // strap inserts
    }
    // stop tabs: the servo's case top bears on these (far from the horn)
    for (x = [-1, 1]) translate([x > 0 ? srv[1] / 2 + clr - 3 : -srv[1] / 2 - clr, sy[1] - 14, z_case_top]) cube([3, 12, 3]);
}

module pan_strap() {          // under the pan servo: 2 x M3 into the sleeve's ends
    sy = [-srv_sh - clr, srv[0] - srv_sh + clr];
    difference() {
        hull() for (x = [-1, 1], y = pan_ins_y) translate([x * pan_ins_x, y, 0]) cylinder(d = ins_boss, h = strap_t, $fn = 32);
        translate([0, 0, -1]) cylinder(d = sts_horn_d + 1.5, h = strap_t + 2, $fn = 48);       // idler disc
        for (x = [-1, 1], y = pan_ins_y) translate([x * pan_ins_x, y, -1]) hole3(strap_t + 2);
    }
}

// ==== HUB ============================================================================================
module hub() {
    difference() {
        union() {
            translate([0, 0, z_horn]) cylinder(d = hub_od, h = z_flange - z_horn + 0.01, $fn = 96);
            translate([0, 0, z_flange]) cylinder(d = flange_d, h = flange_t, $fn = 128);
        }
        translate([0, 0, z_horn + hub_end]) cylinder(d = hub_id, h = 200, $fn = 64);             // bore
        translate([0, 0, z_horn - 1]) cylinder(d = 6.5, h = hub_end + 2, $fn = 32);              // horn's centre screw
        for (a = [45 : 90 : 360]) rotate(a) translate([pcd / 2, 0, z_horn - 1]) {               // 4 x M3 into the horn
            hole3(hub_end + 2);
            translate([0, 0, hub_end + 1]) cylinder(d = 6.2, h = 10, $fn = 24);                   // heads, inside
        }
        translate([0, 0, z_horn + hub_end + win[1] / 2 + 1]) rotate([0, 90, 0])                  // cable window (+X)
            linear_extrude(hub_od) square([win[1], win[0]], center = true);
        for (a = [0 : 90 : 270]) rotate(a) translate([flange_r, 0, z_flange + flange_t - insert_m3[1]]) insert3();
    }
}

// ==== TURRET =========================================================================================
tun_x    = [-11, -3.5];          // cable tunnel, X (clear of the floor screw at X = 0) ...
tun_y1   = 31.5;                 // ... runs from the hub's hole back to here

// tilt strap inserts: one in the idler end wall (moved outward, into a boss), one in the post by the horn
post_x   = [x_horn + clr, x_horn + clr + 6];                 // the post starts clear of the servo's case
idl_ins  = [x_idler - clr - ins_wall - insert_m3[0] / 2, 8];
post_ins = [(post_x[0] + post_x[1]) / 2, (8 + (y_srv - srv_sh + srv[0] + clr) + 3) / 2];

module turret() {
    yb = [y_srv - srv_sh - clr, y_srv - srv_sh + srv[0] + clr];     // tilt servo body, Y (-22.9 .. 22.9)
    zb = [z_srv - srv[1] / 2, z_srv + srv[1] / 2];                  // ... Z
    difference() {
        union() {
            translate([0, 0, z_floor]) linear_extrude(floor_t)                                   // floor
                translate([0, (floor_xy[1][0] + floor_xy[1][1]) / 2]) rrect([floor_xy[0][1] - floor_xy[0][0], floor_xy[1][1] - floor_xy[1][0]], 6);
            box([x_idler - clr, x_horn], yb, [z_ft - 0.01, zb[0]]);                              // pedestal
            box([x_idler - clr - 3, x_idler - clr], [yb[0] - 3, yb[1] + 3], [z_ft - 0.01, zb[1]]);   // idler-end wall
            box([x_idler - clr, x_horn - 4], [yb[0] - 3, yb[0]], [z_ft - 0.01, zb[1]]);            // front end wall
            box([x_idler - clr, x_horn - 4], [yb[1], yb[1] + 3], [z_ft - 0.01, zb[0] + 6]);        // back end (low: the connectors)
            box([post_x[0], post_x[1]], [8, yb[1] + 3], [z_ft - 0.01, zb[1]]);                     // strap post, beside the horn
            translate([idl_ins[0], idl_ins[1], zb[1] - insert_m3[1] - 3])                            // boss on the end wall
                cylinder(d = ins_boss, h = insert_m3[1] + 3, $fn = 32);
            for (s = [-1, 1]) {                                                                  // cheeks
                x0 = s > 0 ? x_cheek : -x_cheek - cheek_t;
                hull() {
                    box([x0, x0 + cheek_t], [y_axle - 12, y_axle + 12], [z_ft - 0.01, z_ft + 6]);
                    translate([x0, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = 16, h = cheek_t, $fn = 48);
                }
            }
        }
        translate([0, 0, z_floor - 1]) cylinder(d = 18, h = floor_t + 2, $fn = 48);              // cables down the hub
        // cable tunnel: from behind the tilt servo (its connector end, +Y), under it through the floor and the
        // pedestal, to the hole down the hub - big enough for the servo's 3-pin plug; offset in X to miss the
        // turret screw at (0, flange_r); 1 mm of pedestal left over it, under the servo
        box(tun_x, [0, tun_y1], [z_floor - 1, zb[0] - 1]);
        box(tun_x, [yb[1] + 3 + 0.5, tun_y1], [z_floor - 1, zb[1] + 10]);                         // ... and open upward there
        for (a = [0 : 90 : 270]) rotate(a) translate([flange_r, 0, z_floor - 1]) {               // 4 x M3 into the hub flange
            hole3(floor_t + 2);
        }
        translate([x_idler - clr - 4, y_srv, z_srv]) rotate([0, 90, 0]) cylinder(d = sts_horn_d + 1, h = 6, $fn = 48);   // idler disc
        for (s = [-1, 1]) translate([s > 0 ? x_cheek - 1 : -x_cheek - cheek_t - 1, y_axle, z_axle]) rotate([0, 90, 0])
            cylinder(d = 4.4 + cal_hole, h = cheek_t + 2, $fn = 32);                            // axle screws (M4)
        // strap inserts: on the idler wall's top and the post's top
        translate([idl_ins[0], idl_ins[1], zb[1] - insert_m3[1]]) insert3();
        translate([post_ins[0], post_ins[1], zb[1] - insert_m3[1]]) insert3();
    }
}

module tilt_strap() {         // across the tilt servo's top: from the idler wall to the post
    yb = [y_srv - srv_sh - clr, y_srv - srv_sh + srv[0] + clr];
    a = idl_ins;
    b = post_ins;
    difference() {
        hull() for (p = [a, b]) translate(p) cylinder(d = 8, h = 3, $fn = 32);
        for (p = [a, b]) translate([p[0], p[1], -1]) hole3(5);
    }
}

// ==== DISC (in its own frame: horn face at Z = 0, boss up) ====================================================
module disc() {
    difference() {
        union() {
            cylinder(d = disc_d, h = disc_t, $fn = 96);
            translate([arm_s, 0, 0]) cylinder(d = 8, h = disc_t + boss_h, $fn = 32);            // rod end boss
        }
        translate([0, 0, -1]) cylinder(d = 6.5, h = disc_t + 2, $fn = 32);                      // horn's centre screw
        for (a = [45 : 90 : 360]) rotate(a) translate([pcd / 2, 0, -1]) {                       // 4 x M3 into the horn
            hole3(disc_t + 2);
            translate([0, 0, disc_t + 1 - 2]) cylinder(d = 6.2, h = 3, $fn = 24);                // counterbores (heads flush)
        }
        translate([arm_s, 0, disc_t + boss_h - insert_m3[1]]) insert3(insert_m3[1] + 1);        // rod end screw
    }
}

// ==== HEAD stand-in (in the turret frame, at tilt 0, about the axle) ===================================
module head() {
    difference() {
        union() {
            for (s = [-1, 1]) {                                                                   // ears
                x0 = s > 0 ? x_ear - ear_t : -x_ear;
                hull() {
                    translate([x0, 0, 0]) rotate([0, 90, 0]) cylinder(d = 14, h = ear_t, $fn = 48);
                    translate([x0, -5 + head_dy, bridge_dz]) cube([ear_t, 10, 1]);
                }
            }
            translate([-bridge[0] / 2, head_dy - bridge[1] / 2, bridge_dz]) cube(bridge);        // bridge
            // the crank: a boss on the right ear's inner face, 15 mm from the axle, pointing forward-down
            hull() {                                                              // from inside the ear inward
                translate([x_ear - 1, 0, 0]) rotate([0, -90, 0]) cylinder(d = 10, h = ear_t + 1, $fn = 32);
                translate([x_ear - 1, arm_h * cos(crank_off), arm_h * sin(crank_off)]) rotate([0, -90, 0])
                    cylinder(d = 9, h = (x_ear - 1) - (x_link + rod_ball_w / 2) - 0.2, $fn = 32);
            }
        }
        for (s = [-1, 1]) translate([s > 0 ? x_ear - insert_m4[1] : -x_ear - 1, 0, 0]) rotate([0, 90, 0])
            cylinder(d = insert_m4[0], h = insert_m4[1] + 1, $fn = 32);                          // axle inserts (M4)
        translate([x_link + rod_ball_w / 2 + 0.2 - 1, arm_h * cos(crank_off), arm_h * sin(crank_off)]) rotate([0, 90, 0])
            cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);                          // crank: M3 insert
        for (x = [-20, 20], y = [-8, 8]) translate([x, head_dy + y, bridge_dz - 1]) hole3(bridge[2] + 2);   // camera holes
    }
}

// ==== the rest, for the assembly view ===================================================================
module servo_model() {                       // shaft along +Z at the origin, body below, length along +X
    color("#1d3557") translate([-srv_sh, -srv[1] / 2, -srv[2]]) cube(srv);
    color("#c0c0c0") cylinder(d = sts_horn_d, h = disc_h, $fn = 40);
    color("#c0c0c0") translate([0, 0, -srv[2] - disc_h]) cylinder(d = sts_horn_d, h = disc_h, $fn = 40);
}
function servo_ang(t, lo = -85, hi = 85, n = 40) = n == 0 ? (lo + hi) / 2 :
    (lerr((lo + hi) / 2, t) > 0) == (lerr(lo, t) > 0) ? servo_ang(t, (lo + hi) / 2, hi, n - 1) : servo_ang(t, lo, (lo + hi) / 2, n - 1);
function lerr(a, t) = norm([y_srv + arm_s * cos(a) - (y_axle + arm_h * cos(t + crank_off)),
                            (z_srv + arm_s * sin(a)) - (z_axle + arm_h * sin(t + crank_off))]) - rod_c;

module assembly() {
    color("#9aa3ad") base();
    color("#9aa3ad") translate([0, 0, z_case_bot - strap_t]) pan_strap();
    color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);                            // pillow block
    translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();                          // pan servo (horn top at z_horn)
    rotate([0, 0, pan]) {
        color("#e8a33d") hub();
        color("#2b2b2b") turret();
        color("#2b2b2b") translate([0, 0, z_srv + srv[1] / 2]) tilt_strap();
        translate([x_horn, y_srv, z_srv]) rotate([0, 90, 0]) rotate([0, 0, 90]) servo_model();   // tilt servo, horn +X, body toward +Y
        a = servo_ang(tilt);
        translate([x_horn + disc_h, y_srv, z_srv]) rotate([a, 0, 0]) rotate([0, 90, 0]) rotate([0, 0, 90]) color("#c55") disc();
        A = [y_srv + arm_s * cos(a), z_srv + arm_s * sin(a)];
        B = [y_axle + arm_h * cos(tilt + crank_off), z_axle + arm_h * sin(tilt + crank_off)];
        color("#d4a017") hull() for (p = [A, B]) translate([x_link, p[0], p[1]]) sphere(d = 4, $fn = 16);
        color("#d4a017") for (p = [A, B]) translate([x_link, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = rod_eye_d, h = rod_ball_w, center = true, $fn = 24);
        translate([0, y_axle, z_axle]) rotate([tilt, 0, 0]) color("#555") head();
    }
}

// ==== output =========================================================================================
if (part == "assembly") assembly();
if (part == "base")   rotate([180, 0, 0]) base();                                   // top plate on the bed
if (part == "hub")    translate([0, 0, z_flange + flange_t]) rotate([180, 0, 0]) hub();   // flange on the bed
if (part == "turret") translate([0, 0, -z_floor]) turret();
if (part == "disc")   disc();
if (part == "head")   translate([0, 0, bridge_dz + bridge[2]]) rotate([180, 0, 0]) translate([0, -head_dy, 0]) head();   // bridge on the bed
if (part == "straps") { pan_strap(); translate([60, 0, 0]) tilt_strap(); }
echo(str("tilt servo angle at head -20/20/60: ", servo_ang(-20), " / ", servo_ang(20), " / ", servo_ang(60)));
echo(str("heights: desk ", z_desk, "  axle ", z_axle, "  -> axle ", z_axle - z_desk, " above the desk"));
