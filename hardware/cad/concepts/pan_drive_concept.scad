// Pan drive concept - ROUGH DRAFT for discussion, not a printable part.
// Stack, bottom to top: reComputer J4012 case -> saddle (air gap over its ribbed top) -> base
// (NEMA17 + belt + electronics) -> lazy Susan -> turntable plate with the hanging ring pulley
// -> neck. Origin: centre of the lazy Susan's bottom face. F5 to look around.
include <../params.scad>
use <../vitamins/lazy_susan.scad>

show_base_shell = true;      // set false to see inside
cutaway         = true;      // cut the base shell in half
show_top        = true;      // lazy Susan, turntable plate, neck and the base's top deck

// ---- sizes (draft) ---------------------------------------------------------------
case_sz   = [121, 130, 61];  // reComputer J4012
saddle_h  = 13;              // air gap over the ribbed top
base_h    = 52;              // base: from saddle deck to the plinth top
plinth_h2 = 2;

ring_T    = 100;             // ring pulley teeth (GT2, 2 mm pitch)
motor_T   = 20;              // motor pulley teeth
R  = ring_T * 2 / PI / 2;    // 31.8  pitch radius
r  = motor_T * 2 / PI / 2;   //  6.4
C  = 45;                     // centre distance (slotted mount: tension by sliding the motor out)
motor_dir = 45;              // motor sits on the diagonal, inside the case footprint
belt_w  = 6;
belt_z  = -14;               // belt plane (below the lazy Susan, inside the base)
nema    = [42.3, 42.3, 23];  // pancake NEMA17
hollow_d = 48;               // cable passage through the ring pulley

// belt length for this centre distance (closed loop)
belt_L = 2 * sqrt(C^2 - (R - r)^2) + PI * (R + r) + 2 * (R - r) * asin((R - r) / C) * PI / 180;
echo(ratio = ring_T / motor_T, belt_length_mm = belt_L, belt_teeth = belt_L / 2,
     open_belt_travel_deg = 180 - acos((R - r) / C) - 18);

z_case_top = -base_h - saddle_h;

module rbox(sz, r = 6) {     // rounded box, centred in XY, from z = 0
    linear_extrude(sz[2]) offset(r = r) square([sz[0] - 2 * r, sz[1] - 2 * r], center = true);
}

// ---- Jetson case --------------------------------------------------------------------
color("#2a2a2a") translate([0, 0, z_case_top - case_sz[2]]) rbox(case_sz, 5);
color("#3a3a3a") for (x = [-56 : 4 : 56])                       // ribs on its top
    translate([x, 0, z_case_top - 0.5]) cube([2, case_sz[1] - 8, 1], center = true);

// ---- saddle: rim that grips the case top, posts at the corners, open sides for air -----
color("#9aa0a6") translate([0, 0, z_case_top - 6]) difference() {
    rbox([case_sz[0] + 4, case_sz[1] + 4, saddle_h + 6], 7);
    translate([0, 0, -1]) rbox([case_sz[0], case_sz[1], 7], 5);              // grips the case
    translate([0, 0, -1]) rbox([case_sz[0] - 6, case_sz[1] - 6, saddle_h + 10], 4);
    for (a = [0, 90]) rotate(a) translate([0, 0, 6 + saddle_h / 2])        // airflow windows
        cube([200, 90, saddle_h - 4], center = true);
}

// ---- base shell -----------------------------------------------------------------------
if (show_base_shell) color("#b8bcc0", 0.55) difference() {
    translate([0, 0, -base_h]) difference() {
        rbox([case_sz[0] + 4, case_sz[1] + 4, base_h], 7);
        translate([0, 0, 2.5]) rbox([case_sz[0] - 1, case_sz[1] - 1, base_h], 5);
    }
    translate([0, 0, -10]) cylinder(d = ls_id - 4, h = 20);             // centre opening
    if (cutaway) translate([-100, -200, -100]) cube([200, 200, 200]);
}
// top deck with the plinth the lazy Susan's OUTER ring screws to
if (show_top) color("#b8bcc0") difference() {
    translate([0, 0, -plinth_h2 - 3]) rbox([case_sz[0] + 4, case_sz[1] + 4, 3], 7);
    translate([0, 0, -10]) cylinder(d = ls_id - 4, h = 20);
    if (cutaway) translate([-100, -200, -100]) cube([200, 200, 200]);
}
if (show_top) color("#b8bcc0") translate([0, 0, -plinth_h2]) difference() {
    cylinder(d = ls_od, h = plinth_h2);
    translate([0, 0, -1]) cylinder(d = plinth_id, h = 5);
    if (cutaway) translate([-100, -200, -100]) cube([200, 200, 200]);
}

// ---- lazy Susan + turntable plate + neck ------------------------------------------------
if (show_top) lazy_susan();
if (show_top) color("#d0d4d8") translate([0, 0, ls_h]) difference() {                 // turntable plate
    cylinder(d = top_plate_d, h = 4);
    translate([0, 0, -1]) cylinder(d = hollow_d, h = 6);
}
if (show_top) color("#d0d4d8") translate([0, 0, ls_h + 4]) difference() {             // neck stub
    linear_extrude(35) offset(r = 3) square(34, center = true);
    translate([0, 0, -1]) cube([28, 28, 40], center = true);
}

// ---- ring pulley: a tube hanging from the plate through the bearing, teeth at the bottom --
color("#e8a33d") difference() {
    union() {
        translate([0, 0, belt_z + belt_w / 2 + 1]) cylinder(d = 2 * R + 6, h = ls_h - belt_z - belt_w / 2 - 1);  // tube
        translate([0, 0, belt_z - belt_w / 2 - 1.5]) cylinder(d = 2 * R + 5, h = 1.5);   // lower flange
        translate([0, 0, belt_z + belt_w / 2]) cylinder(d = 2 * R + 5, h = 1);            // upper flange
        translate([0, 0, belt_z - belt_w / 2]) difference() {                            // teeth (simplified)
            cylinder(d = 2 * R - 0.5, h = belt_w, $fn = ring_T * 2);
            for (i = [0 : ring_T - 1]) rotate(i * 360 / ring_T) translate([R, 0, -1]) cylinder(d = 1.1, h = belt_w + 2, $fn = 8);
        }
    }
    translate([0, 0, -50]) cylinder(d = hollow_d, h = 100);
}
color("white") rotate(motor_dir + 180) translate([R - 4, 0, belt_z - belt_w / 2 - 1.5]) cylinder(d = 4, h = 1.6);   // homing magnet

// ---- belt ------------------------------------------------------------------------------
color("#222") translate([0, 0, belt_z - belt_w / 2]) linear_extrude(belt_w) difference() {
    hull() { circle(r = R + 1.2); rotate(motor_dir) translate([C, 0]) circle(r = r + 1.2); }
    hull() { circle(r = R); rotate(motor_dir) translate([C, 0]) circle(r = r); }
}

// ---- motor, pulley and slotted mount -----------------------------------------------------
rotate(motor_dir) translate([C, 0, 0]) {
    pulley_bottom = belt_z - belt_w / 2 - 8;                             // hub below the teeth
    color("#555") translate([0, 0, pulley_bottom - 3 - nema[2]]) rbox(nema, 3);
    color("silver") translate([0, 0, pulley_bottom - 1]) cylinder(d = 5, h = 20);   // shaft
    color("#c0c0c0") translate([0, 0, pulley_bottom]) {
        cylinder(d = 16, h = 7);                                         // hub + set screws
        translate([0, 0, 7]) cylinder(d = 2 * r, h = belt_w + 2, $fn = motor_T * 2);
        translate([0, 0, 7]) cylinder(d = 2 * r + 4, h = 0.8);
        translate([0, 0, 7 + belt_w + 1.2]) cylinder(d = 2 * r + 4, h = 0.8);
    }
}
// motor bracket: a shelf from the base wall that the motor's face screws to (slots: slide out
// to tension the belt); the motor hangs below it
color("#8899aa") rotate(motor_dir) translate([C, 0, belt_z - belt_w / 2 - 8 - 3]) difference() {
    translate([-25, -25, 0]) cube([50 + 22, 50, 3]);
    translate([0, 0, -1]) cylinder(d = 23, h = 5);                       // motor's centring boss
    for (sx = [-1, 1], sy = [-1, 1]) hull()
        for (dx = [-3, 3]) translate([sx * 15.5 + dx, sy * 15.5, -1]) cylinder(d = 3.4, h = 5, $fn = 16);
}

// ---- homing sensor (Hall, A3144 / or a plotter endstop) ------------------------------------
color("#3355cc") rotate(motor_dir + 180) translate([R + 4.5, 0, belt_z - belt_w / 2 - 9]) cube([4, 5, 6], center = true);

// ---- electronics (placeholders) ---------------------------------------------------------
module board(pos, sz, col, rot = 0) { color(col) translate(pos) rotate(rot) translate(-[sz[0], sz[1], 0] / 2) cube(sz); }
board([-38, 20, -base_h + 3], [25.5, 63, 12], "#1f6f3f", 0);     // ESP32-S3 DevKitC-1
board([ 35, -38, -base_h + 3], [20, 15, 12], "#7a1f9a");          // TMC2209 module + heatsink
board([-30, -40, -base_h + 3], [43, 21, 14], "#1f4f9f", 0);       // 12 V -> 5 V buck
board([ 5, -45, -base_h + 3], [30, 25, 6], "#2f2f2f");            // FE1.1s USB hub
