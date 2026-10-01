// Lazy Susan hole gauge - print this first (about 10 minutes, a few grams of PETG).
//
// A flat 2 mm ring with four radial slots for each bolt circle. Lay it on the real
// lazy Susan, line up one slot with a hole, and read where each hole appears in its
// slot against the tick marks. Ticks are every 1 mm of radius = 2 mm of circle
// diameter; every 4th tick is labelled with the bolt-circle diameter it stands for.
// Then put the real values into params.scad (ls_outer_bc, ls_inner_bc, ls_hole_d).
include <../params.scad>

t      = 2.0;      // gauge thickness
span   = 6;        // slot reaches +/- this many mm of radius around the estimate
engr   = 0.6;      // engraving depth for ticks/labels
slot_w = ls_hole_d + 0.5;

module slot(bc) {
    hull() for (r = [bc / 2 - span, bc / 2 + span])
        translate([r, 0, -1]) cylinder(d = slot_w, h = t + 2);
}

module ticks(bc) {
    // A tick per mm of radius (= 2 mm of bolt-circle diameter), long ticks every 2 mm,
    // and the bolt-circle diameter printed beside every 4th tick (every 8 mm).
    for (dr = [-span : span]) {
        r = bc / 2 + dr;
        long = dr % 2 == 0;
        translate([r - 0.3, slot_w / 2 + 0.8, t - engr]) cube([0.6, long ? 4 : 2, 1]);
        if (dr % 4 == 0)
            translate([r, slot_w / 2 + 5.6, t - engr]) rotate([0, 0, 90])
                linear_extrude(1) text(str(2 * r), size = 2.6, halign = "left", valign = "center",
                                       font = "Liberation Sans:style=Bold");
    }
}

difference() {
    // ring wide enough to hold both sets of slots
    difference() {
        cylinder(d = ls_od + 16, h = t);   // wider than the bearing so the outer slots stay closed
        translate([0, 0, -1]) cylinder(d = ls_inner_bc - 2 * span - 14, h = t + 2);
    }
    for (i = [0 : ls_holes - 1]) {
        rotate([0, 0, i * 90]) { slot(ls_outer_bc); ticks(ls_outer_bc); }
        rotate([0, 0, ls_inner_rot + i * 90]) { slot(ls_inner_bc); ticks(ls_inner_bc); }
    }
    // engraved circle showing the expected centre opening, for comparison
    translate([0, 0, t - engr]) difference() {
        cylinder(d = ls_id + 0.8, h = 1);
        cylinder(d = ls_id - 0.8, h = 1);
    }
    // orientation mark at 0 degrees
    translate([ls_od / 2 + 5, 0, t - engr]) cylinder(d = 3, h = 1, $fn = 3);
}
