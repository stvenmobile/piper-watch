// M5 coupon - the lazy Susan's holes take M5, so its screws go into M5 heat-set inserts.
// Top row: insert bores (blind) at 6.2 / 6.4 / 6.6 mm - pick the one that melts in straight
// and holds firmly. Bottom row: clearance holes M5 + 0.3 / + 0.4 (through).
// Put the winners into params.scad (insert_m5).
include <../params.scad>

bores = [6.2, 6.4, 6.6];
holes = [m5 + clr_hole, m5 + clr_hole + 0.1];
pitch = 13;
size  = [len(bores) * pitch + 4, 34, insert_m5[1] + 2.5];   // keeps the bores blind
engr  = 0.6;

module label(s) {
    linear_extrude(1) text(s, size = 2.4, halign = "center", font = "Liberation Sans:style=Bold");
}

difference() {
    cube(size);
    for (i = [0 : len(bores) - 1]) {
        x = 2 + pitch / 2 + i * pitch;
        translate([x, 24, size[2] - insert_m5[1]]) cylinder(d = bores[i], h = insert_m5[1] + 1);
        translate([x, 30.5, size[2] - engr]) label(str(bores[i]));
    }
    for (i = [0 : len(holes) - 1]) {
        x = 2 + pitch + i * pitch;
        translate([x, 9, -1]) cylinder(d = holes[i], h = size[2] + 2);
        translate([x, 1.5, size[2] - engr]) label(str("+", holes[i] - m5));
    }
}
