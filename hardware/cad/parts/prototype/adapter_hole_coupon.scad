// Servo adapter hole coupon: checks the board's 4 mounting holes (believed 2.5 mm on a 30 x 37 rectangle).
// Lay the board on the plate: the holes should line up with the board's and take an M2.5 screw. The board's 33 x 43
// outline is a shallow groove, centred on the hole pattern, to show whether the holes are centred on the board.
include <../../params.scad>

hole_sp = [30, 37];  hole_d = 2.5;           // as measured (to verify)
board = [33, 43];                            // the PCB
plate = [41, 51, 2];  groove = [0.8, 0.4];   // outline groove width, depth

difference() {
    translate([-plate[0] / 2, -plate[1] / 2, 0]) cube(plate);
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * hole_sp[0] / 2, sy * hole_sp[1] / 2, -1]) cylinder(d = hole_d + cal_hole, h = plate[2] + 2, $fn = 32);
    translate([0, 0, plate[2] - groove[1]]) linear_extrude(1) difference() {
        square([board[0] + groove[0], board[1] + groove[0]], center = true);
        square([board[0] - groove[0], board[1] - groove[0]], center = true);
    }
    translate([-10, -14, -1]) cube([20, 28, plate[2] + 2]);                                   // window: see the board's underside
    translate([0, 18.5, plate[2] - 0.4]) linear_extrude(1) text("30 x 37", size = 3, halign = "center", valign = "center");
}
