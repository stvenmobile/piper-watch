// TURRET v2 - the test stand's turret (cradle, floor, cable tunnel) for the real head v2, with the head's YOKE as two
// separate cheek plates. Level 2 of the case, above the pan stack (base + hub from servo_test_stand.scad stay as proven).
//
//   TURRET  the stand's turret without its cheeks, floor widened to carry the plates (floor_t 4)
//   CHEEK   2 x identical plate, 8 thick, bolted to the floor edge by 3 x M3 from underneath into inserts in a
//           thickened foot. The 608-2RS pocket is the coupon's (pivot_pocket 21.8, 1 mm lip on the OUTER face), printed
//           OUTER FACE DOWN, flat, exactly as the fitted coupon bar was - not as a sideways hole in the turret.
//
// Head v2 (parts/head_v2.scad): 106 wide, wall -> cheek gap 1.5 (the wall's boss fills it) -> cheeks' inner faces at
// +/-54.5. Link 85 (rod_c) so the axle is 85 above the tilt servo's shaft.
// Assembly: plates on the floor (screws from below) -> bearings into the pockets from the inside -> head between the
// cheeks, its boss on the inner race -> ears from outside (see head_v2.scad).
//
// part = "v2_turret" (default) | "v2_cheek" | "v2_assembly"      (laid out for the bed; names differ from the stand's)
include <../servo_test_stand.scad>

part = "v2_turret";
turret_cheeks = false;

// ---- overrides of the stand's numbers --------------------------------------------------------------------------
rod_c    = 85;                  // link, centre to centre (head v2)
cheek_t  = 8;                   // = the coupon bar
x_cheek  = 106 / 2 + 1.5;       // head width / 2 + yoke_gap: the cheeks' inner faces
floor_t  = 4;

// ---- the cheek plate -------------------------------------------------------------------------------------------
c_boss   = 36;                  // round the axle: 7 mm of wall round the 22.2 pocket
c_foot_h = 12;                  // the thickened foot (inserts), height above the floor
c_foot_w = 12;                  // its thickness (inner face moves 4 mm toward the servo: head wall is far above)
c_y      = [-30, 30];           // the foot's extent in Y (the floor is -34 .. 34)
c_scr_y  = [-26, -6, 14];       // the 3 screws
lip      = cheek_t - 7;         // 608 is 7 thick: 1 mm lip on the outer face

// the plate in the TURRET frame, right-hand cheek (x from x_cheek to x_cheek + cheek_t)
module cheek_r() {
    x0 = x_cheek;
    difference() {
        union() {
            hull() {
                box([x0, x0 + cheek_t], c_y, [z_ft - 0.01, z_ft + 4]);                              // base along the floor
                translate([x0, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = c_boss, h = cheek_t, $fn = 96);
            }
            box([x0 - (c_foot_w - cheek_t), x0 + cheek_t], c_y, [z_ft - 0.01, z_ft + c_foot_h]);     // foot
        }
        translate([x0 + lip, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = pivot_pocket + cal_hole, h = cheek_t, $fn = 120);   // pocket, from the inside face
        translate([x0 - 1, y_axle, z_axle]) rotate([0, 90, 0]) cylinder(d = 12 + cal_hole, h = cheek_t + 2, $fn = 64);   // the lip's hole
        for (y = c_scr_y) translate([x0 + cheek_t / 2 - (c_foot_w - cheek_t) / 2, y, z_ft - 0.01]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
    }
}

// the plate on the bed: outer face down (z = 0), pocket opening up
module cheek_print() {
    rotate([0, 90, 0]) translate([-(x_cheek + cheek_t), -y_axle, -z_axle]) cheek_r();
    // after rotate([0,90,0]) (x,y,z) -> (z,y,-x): the outer face (x_cheek + cheek_t) lands at z = 0
}

module floor_screws() for (s = [-1, 1], y = c_scr_y)          // M3 clearance in the floor, under the foot
    translate([s * (x_cheek + cheek_t / 2 - (c_foot_w - cheek_t) / 2), y, z_floor - 1]) cylinder(d = 3.4 + cal_hole, h = floor_t + 2, $fn = 24);

module turret_v2() difference() { turret(); floor_screws(); }

if (part == "v2_assembly") {
    color("#2b2b2b") turret_v2();
    color("#6b8fb5") cheek_r();
    color("#6b8fb5") mirror([1, 0, 0]) cheek_r();
}
if (part == "v2_turret") translate([0, 0, -z_floor]) turret_v2();
if (part == "v2_cheek")  cheek_print();
