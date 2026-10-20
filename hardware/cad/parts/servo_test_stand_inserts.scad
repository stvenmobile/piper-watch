// Assembly diagrams for the servo test stand: each part with its heat-set inserts (brass) and a red arrow
// showing which face each insert is pressed in FROM. Not a printable part.
//   show = "base" | "hub" | "turret" | "disc" | "head"
include <servo_test_stand.scad>
part = "none";                       // (after the include: stops servo_test_stand.scad drawing its own part)
show = "base";

// an insert: `p` = the hole's mouth, `dir` = the direction it's pressed in, d/len = insert size
module ins(p, dir, d, len) {
    a = [0, acos(dir[2] / norm(dir)), atan2(dir[1], dir[0])];       // +Z -> dir
    translate(p) rotate(a) {
        color("#d4a017") cylinder(d = d, h = len, $fn = 24);                                  // the insert, in its hole
        color("#e01b24") {
            translate([0, 0, -11]) cylinder(d = 1.6, h = 7, $fn = 12);                       // arrow shaft (outside)
            translate([0, 0, -4]) cylinder(d1 = 4.5, d2 = 0, h = 4, $fn = 16);                // ... and head
        }
    }
}
M3 = [insert_m3[0], insert_m3[1]];
M4 = [insert_m4[0], insert_m4[1]];

if (show == "base") {
    color("#9aa3ad", 0.55) base();
    for (x = [-1, 1], y = [-1, 1]) ins([x * pb_holes[0] / 2, y * pb_holes[1] / 2, 0], [0, 0, -1], M4[0], M4[1]);   // top face
    for (x = [-1, 1], y = pan_ins_y) ins([x * pan_ins_x, y, z_case_bot], [0, 0, 1], M3[0], M3[1]);                   // sleeve's bottom
}
if (show == "hub") {
    color("#e8a33d", 0.55) hub();
    for (a = [0 : 90 : 270]) ins([flange_r * cos(a), flange_r * sin(a), z_flange + flange_t], [0, 0, -1], M3[0], M3[1]);
}
if (show == "turret") {
    yb = [y_srv - srv_sh - clr, y_srv - srv_sh + srv[0] + clr];
    zb1 = z_srv + srv[1] / 2;
    color("#555", 0.45) turret();
    ins([idl_ins[0], idl_ins[1], zb1], [0, 0, -1], M3[0], M3[1]);
    ins([post_ins[0], post_ins[1], zb1], [0, 0, -1], M3[0], M3[1]);
}
if (show == "disc") {
    color("#c55", 0.55) disc();
    ins([arm_s, 0, disc_t + boss_h], [0, 0, -1], M3[0], M3[1]);
}
if (show == "head") {
    color("#555", 0.45) head();
    for (s = [-1, 1]) ins([s * x_ear, 0, 0], [-s, 0, 0], M4[0], M4[1]);                                               // ears, from outside
    ins([x_link + rod_ball_w / 2 + 0.2, arm_h * cos(crank_off), arm_h * sin(crank_off)], [1, 0, 0], M3[0], M3[1]);   // crank, from inside
}
