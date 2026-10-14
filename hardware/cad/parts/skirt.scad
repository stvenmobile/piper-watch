// Skirt - the bottom of Piper-Watch: a sleeve that stands on the desk round the reComputer J4012
// and carries Level 2 on top. The Jetson sits loose inside it on the desk; the skirt takes the weight.
//
//   SIZE    the body's 160 x 160 rounded square and 2.5 mm walls, skirt_h (71.1) tall: the
//           Jetson's 58.1 plus a 13 mm air gap over its lid, where its fan draws in
//   TOP     four pads with M3 heat-set inserts: the body's floor screws (skirt_pts) come down
//           into them from inside Level 2
//   BACK    open from the desk up to just over the Jetson's height: its ports, and the 19 V and
//           USB cables (Level 2's cable exit is just above, on the same side)
//   VENTS   tall slots on the front and both sides, below the pads
//   STOPS   low tabs on the inside walls keep the Jetson centred, ports to the back (0.75 mm
//           clearance each side, so it lifts out freely)
//
// PRINT upside down - out/skirt.3mf is exported that way (print_flipped), top face on the bed - no
// supports: the back opening then has no bridge, the pads sit on the bed, and the stops have
// 45-degree undersides. PETG, 3-4 walls. Then four M3 heat-set inserts into the pads, from the top.
include <../level2.scad>

print_flipped = true;           // export it upside down, ready to print (assembly.scad uses skirt() the right way up)

half      = l2_size[0] / 2;     // 80
inner     = half - l2_wall;     // 77.5
stop_gap  = 0.75;               // Jetson <-> stops, each side
stop_h    = 10;                 // stops: full depth up to here, then a 45-degree taper
back_open = [124, jetson[2] + 4];   // back opening: width, height (from the desk)
back_r    = 8;                  // its top corners
pad_d     = 10;                 // the screw pads
pad_h     = 12;                 // below the top face
vent_w    = 3.2;                // slots like Level 2's
vent_pitch = 9;
vent_z    = [10, skirt_h - pad_h - 3];   // slots run between these heights

module rrect(sz, r) { offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true); }

// a stop on a wall: depth d inward from the inside face, w wide; full depth to stop_h, then 45 deg
module stop(w, d) {
    hull() {
        translate([-w / 2, 0, 0]) cube([w, d, stop_h]);
        translate([-w / 2, 0, stop_h + d - 0.01]) cube([w, 0.01, 0.01]);
    }
}

module skirt() {
    difference() {
        union() {
            linear_extrude(skirt_h) difference() {                      // the sleeve
                rrect(l2_size, l2_r);
                rrect(l2_size - [2, 2] * l2_wall, l2_r - l2_wall);
            }
            for (p = skirt_pts) translate([0, 0, skirt_h - pad_h])      // screw pads, joined to the wall
                linear_extrude(pad_h) hull() {
                    translate(p) circle(d = pad_d, $fn = 40);
                    translate([sign(p[0]) * (inner + 1), p[1]]) square([2, pad_d], center = true);
                }
            dx = inner - (jetson[0] / 2 + stop_gap);                    // side stops: 11.7 deep
            dy = inner - (jetson[1] / 2 + stop_gap);                    // front/back stops: 16.2 deep
            for (sx = [-1, 1], y = [-40, 40])                           // left and right walls
                translate([sx * inner, y, 0]) rotate([0, 0, sx > 0 ? 90 : -90]) stop(12, dx);
            for (x = [-40, 40])                                         // front wall
                translate([x, inner, 0]) rotate([0, 0, 180]) stop(12, dy);
            for (sx = [-1, 1])                                          // back corners, beside the opening
                translate([sx * (back_open[0] / 2 + 4.5), -inner, 0]) stop(7, dy);
        }
        for (p = skirt_pts) translate([p[0], p[1], skirt_h - insert_m3[1]])    // inserts, from the top
            cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
        // the back opening: from the desk up, rounded top corners
        translate([0, -inner + 1, 0]) rotate([90, 0, 0])                // 2D (x, z) -> through the back wall
            linear_extrude(l2_wall + 3) hull() {
                translate([-back_open[0] / 2, -1]) square([back_open[0], 1]);
                for (sx = [-1, 1]) translate([sx * (back_open[0] / 2 - back_r), back_open[1] - back_r]) circle(r = back_r, $fn = 32);
            }
        // vents: front and both sides
        h = vent_z[1] - vent_z[0];
        for (sx = [-1, 1], y = [-54 : vent_pitch : 54])
            translate([sx * (half - l2_wall / 2), y, vent_z[0] + h / 2]) rotate([0, 90, 0]) hull()
                for (s = [-1, 1]) translate([s * (h / 2 - vent_w / 2), 0, 0]) cylinder(d = vent_w, h = l2_wall + 2, center = true, $fn = 16);
        for (x = [-54 : vent_pitch : 54])
            translate([x, half - l2_wall / 2, vent_z[0] + h / 2]) rotate([90, 0, 0]) hull()
                for (s = [-1, 1]) translate([0, s * (h / 2 - vent_w / 2), 0]) cylinder(d = vent_w, h = l2_wall + 2, center = true, $fn = 16);
    }
}

if (print_flipped) translate([0, 0, skirt_h]) rotate([180, 0, 0]) skirt();
else skirt();

// ghost (not printed): the reComputer J4012
%translate([0, 0, jetson[2] / 2]) cube(jetson, center = true);
