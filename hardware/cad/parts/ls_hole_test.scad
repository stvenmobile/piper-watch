// Lazy Susan hole-position test - a thin ring with M5 clearance holes on both bolt
// circles. Lay the bearing on it, line up the holes, and push M5 screws through the
// bearing into all eight holes. If they all drop straight in, ls_outer_bc and
// ls_inner_bc in params.scad are right and the box top / top plate will line up.
include <../params.scad>

t = 2.0;                               // thickness
hole_d = m5 + clr_hole;                // M5 clearance (5.3), same rule the real parts use

difference() {
    cylinder(d = ls_od, h = t);                              // matches the bearing's rim
    translate([0, 0, -1]) cylinder(d = ls_id, h = t + 2);    // and its centre opening
    for (i = [0 : ls_holes - 1]) {
        rotate([0, 0, i * 360 / ls_holes])                   // outer ring holes
            translate([ls_outer_bc / 2, 0, -1]) cylinder(d = hole_d, h = t + 2);
        rotate([0, 0, ls_inner_rot + i * 360 / ls_holes])    // inner ring holes
            translate([ls_inner_bc / 2, 0, -1]) cylinder(d = hole_d, h = t + 2);
    }
    // engraved marks: "O" beside an outer hole, "I" beside an inner hole
    translate([ls_outer_bc / 2, -6, t - 0.6]) linear_extrude(1)
        text("O", size = 4, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    rotate([0, 0, ls_inner_rot]) translate([ls_inner_bc / 2, -6, t - 0.6]) linear_extrude(1)
        text("I", size = 4, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
}
