// Feetech STS3215 serial bus servo - simple visual model (not printed).
// Origin = centre of the output shaft at the top face of the body; shaft points +Z.
// Dimensions are estimates - check against the real servo before designing brackets.
include <../params.scad>

module sts3215(horn = true) {
    color("dimgray")
        translate([-sts_shaft_x, -sts_body[1] / 2, -sts_body[2]])
            cube(sts_body);
    if (horn)
        color("lightgray") cylinder(d = sts_horn_d, h = sts_horn_h);
}

sts3215();
