// Lazy Susan turntable bearing - simple visual model for assembly checks (not printed).
include <../params.scad>

module ls_holes(bc, rot = 0) {
    for (i = [0 : ls_holes - 1])
        rotate([0, 0, rot + i * 360 / ls_holes])
            translate([bc / 2, 0, -1]) cylinder(d = ls_hole_d, h = ls_h + 2);
}

module lazy_susan() {
    color("silver") {
        difference() {                                   // outer ring
            cylinder(d = ls_od, h = ls_h);
            translate([0, 0, -1]) cylinder(d = ls_split_d, h = ls_h + 2);
            ls_holes(ls_outer_bc);
        }
        difference() {                                   // inner ring
            cylinder(d = ls_split_d - 1, h = ls_h);
            translate([0, 0, -1]) cylinder(d = ls_id, h = ls_h + 2);
            ls_holes(ls_inner_bc, ls_inner_rot);
        }
    }
}

lazy_susan();
