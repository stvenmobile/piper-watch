// Lazy Susan hole gauge - a self-centring template (about 10 minutes, a few grams of PETG).
//
// Same outer diameter (140 mm) and centre opening (89 mm) as the real bearing, so it
// sits exactly concentric when its edges line up with the bearing's. Four radial slots
// per bolt circle show where the real holes are; read their position against the tick
// marks. Ticks are every 1 mm of radius = 2 mm of bolt-circle diameter; every 4th tick
// is labelled with the bolt-circle diameter it stands for.
// Then put the real values into params.scad (ls_outer_bc, ls_inner_bc, ls_hole_d).
include <../params.scad>

t      = 2.0;      // gauge thickness
span   = 6;        // slot reaches up to +/- this many mm of radius around the estimate
margin = 1.0;      // material kept between a slot end and the gauge's edges
engr   = 0.6;      // engraving depth for ticks/labels
slot_w = ls_hole_d + 0.5;

// Slot radius range, kept inside the ring so the gauge's edges stay intact
function r_lo(bc) = max(bc / 2 - span, ls_id / 2 + slot_w / 2 + margin);
function r_hi(bc) = min(bc / 2 + span, ls_od / 2 - slot_w / 2 - margin);

module slot(bc) {
    hull() for (r = [r_lo(bc), r_hi(bc)])
        translate([r, 0, -1]) cylinder(d = slot_w, h = t + 2);
}

module ticks(bc) {
    // A tick per mm of radius (= 2 mm of bolt-circle diameter), long ticks every 2 mm,
    // and the bolt-circle diameter printed beside every 4th tick (every 8 mm).
    for (dr = [-span : span]) {
        r = bc / 2 + dr;
        if (r >= r_lo(bc) && r <= r_hi(bc)) {
            long = dr % 2 == 0;
            translate([r - 0.3, slot_w / 2 + 0.8, t - engr]) cube([0.6, long ? 4 : 2, 1]);
            if (dr % 4 == 0)
                translate([r, slot_w / 2 + 5.6, t - engr]) rotate([0, 0, 90])
                    linear_extrude(1) text(str(2 * r), size = 2.6, halign = "left",
                                           valign = "center", font = "Liberation Sans:style=Bold");
        }
    }
}

difference() {
    difference() {
        cylinder(d = ls_od, h = t);                              // matches the bearing's rim
        translate([0, 0, -1]) cylinder(d = ls_id, h = t + 2);    // matches its centre opening
    }
    for (i = [0 : ls_holes - 1]) {
        rotate([0, 0, i * 90]) { slot(ls_outer_bc); ticks(ls_outer_bc); }
        rotate([0, 0, ls_inner_rot + i * 90]) { slot(ls_inner_bc); ticks(ls_inner_bc); }
    }
    // orientation mark, between the 0 deg outer slot and the 45 deg inner slot
    rotate([0, 0, -22.5]) translate([(ls_id + ls_od) / 4, 0, t - engr])
        cylinder(d = 3.5, h = 1, $fn = 3);
}
