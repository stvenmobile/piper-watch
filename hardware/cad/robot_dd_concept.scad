// CONCEPT: direct-drive tilt. The tilt servo's shaft sits ON the head's axle (right side), a 608 on the left; no disc, link or crank.
// The turret is a drum (r = skirt_r) with two uprights; the axle only has to clear the head's drop (54 mm) -> ~66 above the floor.
// The head is still the v2 STL (its crank / pivot bosses are not redrawn): rough picture for proportions, not parts.
include <robot_v2_assembly.scad>
part = "none";
tilt = 0;
dd_h = 66;                       // axle above the drum top
drum_r = 55;
x_in = 54.5;                     // the head's side faces (+ yoke gap)

module stack_dd() {
    z_top = z_ft;                                                                    // the drum's top face
    color("#2b2b2b") translate([0, 0, z_case_bot - strap_t]) pan_strap();
    color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);
    translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();
    rotate([0, 0, pan]) {
        color("#e8a33d") hub();
        color("#d9dde2") difference() {                                              // drum: skirt + top
            translate([0, 0, -plate_t + skirt_gap]) cylinder(r = drum_r, h = z_top + plate_t - skirt_gap, $fn = 120);
            translate([0, 0, -plate_t + skirt_gap - 1]) cylinder(r = drum_r - 2, h = z_floor + plate_t - skirt_gap + 1, $fn = 120);
        }
        za = z_top + dd_h;
        color("#6b8fb5") translate([-x_in - 8, -20, z_top - 0.01]) cube([8, 40, dd_h]);               // left upright (608 pocket)
        color("#6b8fb5") translate([x_in, -20, z_top - 0.01]) cube([8, 40, dd_h - 14]);                // right mount under the servo
        translate([x_in + 3, 0, za]) rotate([0, -90, 0]) rotate([0, 0, 90]) servo_model();             // tilt servo: shaft toward the head
        translate([0, 0, za]) rotate([tilt, 0, 0]) color("#8a8d91") import(head_stl);
    }
}
if (part == "dd_view") {
    color("#6b8fb5") tub();
    if (show_lid) color("#b5c4d6", 0.35) lid();
    if (show_lid) color("#2b2b2b") translate([0, pan_y, z_plate_top]) pan_plate();
    translate([0, pan_y, z_plate_top]) stack_dd();
}
