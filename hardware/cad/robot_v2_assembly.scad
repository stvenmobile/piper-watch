// Piper robot v2 - the whole assembly (base + pan stack + turret + head), for pictures and clash checks. Not a part.
// The head is imported from an STL of `head_v2.scad -D part="all"` (it shares names with the stand's modules):
//   openscad -D 'part="all"' -o out/head_all.stl parts/head_v2.scad
// -D tilt=.. (head angle, deg), pan=.. (deg), show_lid=false, head_stl="path"
include <parts/archive/base_v2.scad>
include <parts/archive/turret_v2.scad>
part = "none";
tilt = 0;
pan  = 0;
head_stl = "out/head_all.stl";
show_skirt = false;              // the rotating skirt (rough concept): a thin drum from the turret floor down to just above the lid
skirt_r    = 55;                 // the pan axis is 24 off-centre, so the front wall is 56 away: no more room
skirt_gap  = 3;                  // above the lid

module stack() {                         // the stand's frame: pan axis at X = Y = 0, Z = 0 at the plate's top face
    color("#2b2b2b") translate([0, 0, z_case_bot - strap_t]) pan_strap();
    color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);                             // pillow block
    translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();                           // pan servo
    rotate([0, 0, pan]) {
        if (show_skirt) color("#d9dde2") difference() {
            translate([0, 0, -plate_t + skirt_gap]) cylinder(r = skirt_r, h = z_floor + plate_t - skirt_gap, $fn = 120);
            translate([0, 0, -plate_t + skirt_gap - 1]) cylinder(r = skirt_r - 2, h = z_floor + plate_t - skirt_gap + 2, $fn = 120);
        }
        color("#e8a33d") hub();
        color("#2b2b2b") turret_v2();
        color("#6b8fb5") cheek_r();
        color("#6b8fb5") mirror([1, 0, 0]) cheek_r();
        color("#2b2b2b") translate([0, 0, z_srv + srv[1] / 2]) tilt_strap();
        translate([x_horn, y_srv, z_srv]) rotate([0, 90, 0]) rotate([0, 0, 90]) servo_model();    // tilt servo
        a = servo_ang(tilt);
        translate([x_horn + disc_h, y_srv, z_srv]) rotate([a, 0, 0]) rotate([0, 90, 0]) rotate([0, 0, 90]) color("#c55") disc();
        A = [y_srv + arm_s * cos(a), z_srv + arm_s * sin(a)];
        B = [y_axle + arm_h * cos(tilt + crank_off), z_axle + arm_h * sin(tilt + crank_off)];
        color("#d4a017") hull() for (p = [A, B]) translate([x_link, p[0], p[1]]) sphere(d = 4, $fn = 16);
        color("#d4a017") for (p = [A, B]) translate([x_link, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = rod_eye_d, h = rod_ball_w, center = true, $fn = 24);
        translate([0, y_axle, z_axle]) rotate([tilt, 0, 0]) color("#8a8d91") import(head_stl);
    }
}

if (part == "robot_view") {
    color("#6b8fb5") tub();
    if (show_lid) color("#b5c4d6", 0.35) lid();
    if (show_lid) color("#2b2b2b") translate([0, pan_y, z_plate_top]) pan_plate();
    translate([0, pan_y, z_plate_top]) stack();
    ghosts_no_servo();
}
module ghosts_no_servo() difference() { ghosts(); translate([-srv[1] / 2 - 1, pan_y - srv_sh - 1, z_plate_top + z_case_bot - 1]) cube([srv[1] + 2, srv[0] + 2, srv[2] + 2]); }
