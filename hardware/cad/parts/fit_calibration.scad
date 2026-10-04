// Fit calibration plate (~35 min): measures what actually decides fits on this printer -
// overall scaling, how much holes shrink and edges grow, first-layer spread, and narrow slots.
// Print with the REAL settings (15% gyroid, 4 walls, 5 top/bottom), flat as modelled, no
// supports. Once in PLA now; again in PETG HF later (set each filament's profile separately).
//
// MEASURE (calipers), and send the numbers:
//   A  the plate's length along X (edge marked "X 80", nominal 80.00) and along Y ("Y 80")
//   B  tower height (30.00), and tower width at mid-height (12.00) in X and in Y
//   C  the plate's X length again, but right at the bed edge (first layer) vs. at its top
//      edge - the difference is the first layer's spread ("elephant's foot")
//   D  vertical holes, labelled 3 4 5 6 8 10 15 - inside diameter of each
//   E  horizontal holes through the tower: 3 (lower) and 5 (upper)
//   F  pins, labelled 3 4 5 6 8 10 - outside diameter of each, at mid-height
//   G  slots 1.0 1.2 1.4 1.6 1.8 2.0 - which ones a 1.5 mm GT2 belt / a 1.6 mm PCB slides into
include <../params.scad>

base_t = 4;
bar    = [80, 10];                 // the L's two bars
tower  = [12, 12, 30];
holes  = [3, 4, 5, 6, 8, 10, 15];
pins   = [3, 4, 5, 6, 8, 10];
slots  = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0];
slot_names = ["1.0", "1.2", "1.4", "1.6", "1.8", "2.0"];
lbl    = 3.2;                      // label text size
engrave = 0.6;

module label(s, size = lbl) {
    linear_extrude(engrave + 0.01) text(s, size = size, halign = "center", valign = "center",
                                         font = "Liberation Sans:style=Bold");
}

// --- A, C: the L (80 mm bars along X and Y) + B: the Z tower in its corner ------------------
module frame() {
    difference() {
        union() {
            cube([bar[0], bar[1], base_t]);                          // X bar
            cube([bar[1], bar[0], base_t]);                          // Y bar
            cube(tower);                                             // tower
        }
        // E: horizontal holes through the tower (along X)
        translate([-1, tower[1] / 2, 10]) rotate([0, 90, 0]) cylinder(d = 3, h = tower[0] + 2, $fn = 48);
        translate([-1, tower[1] / 2, 21]) rotate([0, 90, 0]) cylinder(d = 5, h = tower[0] + 2, $fn = 48);
        // labels on the bars
        translate([46, bar[1] / 2, base_t - engrave]) label("X 80");
        translate([bar[1] / 2, 46, base_t - engrave]) rotate(90) label("Y 80");
        translate([tower[0] / 2, tower[1] / 2, tower[2] - engrave]) label("Z", 4);
    }
}

// --- D: vertical holes ------------------------------------------------------------------------
module hole_plate() {
    p0 = [10, 10]; size = [70, 34];          // touches the L, so it's all one piece
    xs1 = [10, 19, 29, 40, 53];                // centres for 3 4 5 6 8
    xs2 = [14, 36];                            // 10, 15
    difference() {
        translate(p0) cube([size[0], size[1], base_t]);
        for (i = [0 : 4]) translate([p0[0] + xs1[i], p0[1] + 8, -1]) {
            cylinder(d = holes[i], h = base_t + 2, $fn = 64);
        }
        for (i = [0 : 1]) translate([p0[0] + xs2[i], p0[1] + 21, -1]) cylinder(d = holes[5 + i], h = base_t + 2, $fn = 96);
        // labels
        for (i = [0 : 4]) translate([p0[0] + xs1[i], p0[1] + 2.4, base_t - engrave]) label(str(holes[i]), 2.6);
        for (i = [0 : 1]) translate([p0[0] + xs2[i] + holes[5 + i] / 2 + 6, p0[1] + 21, base_t - engrave]) label(str(holes[5 + i]));
    }
}

// --- F: pins -----------------------------------------------------------------------------------
module pin_plate() {
    p0 = [10, 44]; size = [70, 16];
    xs = [9, 17, 26, 36, 47, 60];
    difference() {
        translate(p0) cube([size[0], size[1], base_t]);
        for (i = [0 : 5]) translate([p0[0] + xs[i], p0[1] + 2.6, base_t - engrave]) label(str(pins[i]), 2.4);
    }
    for (i = [0 : 5]) translate([p0[0] + xs[i], p0[1] + 9, base_t - 0.01]) cylinder(d = pins[i], h = 8, $fn = 64);
}

// --- G: slots (through a raised bar, open at the top so things slide in from above) -----------
module slot_plate() {
    p0 = [10, 60]; size = [70, 20];
    pitch = 9;
    difference() {
        union() {
            translate(p0) cube([size[0], size[1], base_t]);
            translate([p0[0], p0[1] + 9, 0]) cube([size[0], 9, base_t + 6]);
        }
        for (i = [0 : 5]) translate([p0[0] + 10 + i * pitch + 2, p0[1] + 8, base_t])
            translate([-slots[i] / 2, 0, 0]) cube([slots[i], 11, 7]);
        for (i = [0 : 5]) translate([p0[0] + 12 + i * pitch, p0[1] + 4, base_t - engrave]) label(slot_names[i], 2.2);
    }
}

frame();
hole_plate();
pin_plate();
slot_plate();
