// CONCEPT v3 (rough proportions, not parts): direct-drive tilt, narrow camera-only head (no LCD), drum turret,
// bare Orin in a small box on 12 V (no brick, no buck - external 12 V supply into a barrel jack).
//   variant = "hung"   the pan servo hangs INTO the base (as v2), Orin sits beside the servo column
//   variant = "drum"   the pan servo stands in the drum above a low base (legs of the stand's base() on the lid)
include <parts/servo_test_stand.scad>
part = "view";
variant = "hung";
tilt = 0;
pan = 0;
show_lid = true;

// ---- the narrow head: camera board 80 x 22 behind a window, 7 LEDs ("mouth") below it ----------------------------
hw = 96;  hh = 50;  hy = [-20, 22];          // width, height, back .. front from the axle
// ---- drum / yoke ------------------------------------------------------------------------------------------------
drum_r = 55;  dd_h = hh / 2 + 8;  x_in = hw / 2 + 1.5;
// ---- base boxes -------------------------------------------------------------------------------------------------
fl = 4;  wt = 3;  lid_t = 6;
orin = [100, 80];  orin_top = 31.6;           // PCB, and height of the fan above the floor (6 standoff + 1.6 + 20, to confirm)
bw = variant == "hung" ? 118 : 110;
bd = variant == "hung" ? 146 : 134;
lid_z = variant == "hung" ? 72 : 40;          // lid underside
lid_top = lid_z + lid_t;
yin = bd / 2 - wt;
pan_y = variant == "hung" ? yin - 38 : 0;     // hung: the servo column (sleeve +35.9 front) in front of the Orin
z_desk = variant == "hung" ? z_desk : z_case_bot - 14;       // drum: legs stand on the lid, plugs drop through a lid slot
z_p = variant == "hung" ? lid_top + plate_t : lid_top - z_desk;      // world z of the pan plate's top face
echo(str(variant, ": base ", bw, " x ", bd, " x ", lid_top, "; plate top z ", z_p, "; head top z ", z_p + z_ft + dd_h + hh / 2));

module rb(w, d, h, r = 6) linear_extrude(h) offset(r = r) square([w - 2 * r, d - 2 * r], center = true);
module box_shell() difference() { rb(bw, bd, lid_z); translate([0, 0, fl]) rb(bw - 2 * wt, bd - 2 * wt, lid_z, 3); }

module ghosts() {
    color("#2e7d32") translate([-orin[0] / 2, -yin + 3, fl + 6]) cube([orin[0], orin[1], 1.6]);
    color("#9aa0a6") translate([-35, -yin + 3 + 12, fl + 7.6]) cube([70, 50, orin_top - fl - 7.6]);        // heatsink + fan
    color("#2a6a3a") translate(variant == "hung" ? [-bw / 2 + wt + 2, pan_y - 5, fl + 6] : [-bw / 2 + wt + 4, yin - 33 - 3, fl + 6]) cube(variant == "hung" ? [33, 42, 1.6] : [42, 33, 1.6]);   // Waveshare adapter
    color("#00897b") translate([bw / 2 - wt - 34, variant == "hung" ? pan_y - 5 : yin - 33 - 3, fl + 6]) cube([30, 33, 14]);                 // fuse + terminals
}

module stack() {                               // the stand's frame, pan axis at the origin
    color("#2b2b2b") if (variant == "hung") base(); else { base_legs_on(); }
    color("#2b2b2b") translate([0, 0, z_case_bot - strap_t]) pan_strap();
    color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);
    translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();
    rotate([0, 0, pan]) {
        color("#e8a33d") hub();
        color("#d9dde2") difference() {        // drum: hangs from the turret floor, down to 3 mm over the lid
            h0 = variant == "hung" ? -plate_t + 3 : z_desk + 3;
            translate([0, 0, h0]) cylinder(r = drum_r, h = z_ft - h0, $fn = 120);
            translate([0, 0, h0 - 1]) cylinder(r = drum_r - 2, h = z_ft - h0 - 1, $fn = 120);
        }
        za = z_ft + dd_h;
        color("#6b8fb5") translate([-x_in - 8, -16, z_ft - 0.01]) cube([8, 32, dd_h]);                          // left upright (608)
        color("#6b8fb5") translate([x_in, -16, z_ft - 0.01]) cube([8, 32, dd_h - 14]);                           // right mount
        translate([x_in + 3, 0, za]) rotate([0, -90, 0]) rotate([0, 0, 90]) servo_model();                      // tilt servo
        translate([0, 0, za]) rotate([tilt, 0, 0]) head_box();
    }
}
module base_legs_on() base();
module head_box() {
    color("#8a8d91") translate([-hw / 2, hy[0], -hh / 2]) cube([hw, hy[1] - hy[0], hh]);
    color("#111") translate([0, hy[1] + 0.2, 8]) rotate([-90, 0, 0]) cylinder(d = 16, h = 1, $fn = 40);       // lens
    for (i = [-3 : 3]) color("#fff4e0") translate([i * 7, hy[1] + 0.2, -12]) rotate([-90, 0, 0]) cylinder(d = 4.5, h = 1, $fn = 20);   // mouth LEDs
}

if (part == "view") {
    color("#6b8fb5") box_shell();
    if (show_lid) color("#b5c4d6", 0.35) translate([0, 0, lid_z]) rb(bw, bd, lid_t);
    ghosts();
    translate([0, pan_y, z_p]) stack();
}
