// Tolerance coupon - print once to tune clearances for this printer + filament.
//
// Row 1: M3 holes, nominal + 0.0 ... 0.4 mm   (pick the tightest an M3 screw passes freely)
// Row 2: M4 holes, nominal + 0.0 ... 0.4 mm
// Row 3: heat-set insert bores for M3 and M4 at two sizes each (pick the one that melts in straight)
// Put the winners into params.scad (clr_hole, insert_m3, insert_m4).
include <../params.scad>

steps = [0, 0.1, 0.2, 0.3, 0.4];
pitch = 12;
size  = [len(steps) * pitch + 4, 46, 8];   // 8 mm thick so the 6 mm insert bores stay blind
engr  = 0.6;

module label(s) {
    linear_extrude(1) text(s, size = 2.4, halign = "center", font = "Liberation Sans:style=Bold");
}

difference() {
    cube(size);
    for (i = [0 : len(steps) - 1]) {
        x = 2 + pitch / 2 + i * pitch;
        // M3 row
        translate([x, 38, -1]) cylinder(d = m3 + steps[i], h = size[2] + 2);
        translate([x, 42.5, size[2] - engr]) label(str("+", steps[i]));
        // M4 row
        translate([x, 24, -1]) cylinder(d = m4 + steps[i], h = size[2] + 2);
        translate([x, 29, size[2] - engr]) label(str("+", steps[i]));
    }
    // insert bores (blind, from the top)
    bores = [[insert_m3[0], insert_m3[1], "M3a"], [insert_m3[0] + 0.2, insert_m3[1], "M3b"],
             [insert_m4[0], insert_m4[1], "M4a"], [insert_m4[0] + 0.2, insert_m4[1], "M4b"]];
    for (i = [0 : len(bores) - 1]) {
        x = 2 + pitch / 2 + i * pitch + pitch / 2;
        translate([x, 9, size[2] - bores[i][1]]) cylinder(d = bores[i][0], h = bores[i][1] + 1);
        translate([x, 1.5, size[2] - engr]) label(bores[i][2]);
    }
}
