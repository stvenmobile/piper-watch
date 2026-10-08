// Head assembly - every head part in place (head frame), plus simple models of the bought parts,
// for previews and the clash check (tools: pick `only` = one body, or `clash = [a, b]` to get the
// intersection of two - empty = no clash).
include <head.scad>
include <head_cam.scad>
use <parts/head_face.scad>
use <parts/head_shell.scad>
use <parts/head_cam_plate.scad>
use <parts/head_cam_strap.scad>
use <parts/head_floor.scad>

only  = "";             // "" = everything
clash = [];             // e.g. ["shell", "cam_plate"]

BODIES = ["face", "shell", "floor", "cam_plate", "strap", "eyes", "mouth", "camera", "mcu"];

module body(n) {
    if (n == "face") head_face();
    else if (n == "shell") head_shell();
    else if (n == "floor") floor_plate();
    else if (n == "cam_plate") at_lens() cam_plate();
    else if (n == "strap") at_lens() translate([0, cam_y_board - cam_boss_h, 0]) rotate([90, 0, 0]) cam_strap();
    else if (n == "eyes") for (sx = [-1, 1])               // board + glass, upside down (tab up)
        translate([sx * eye_dx, face_y - eye_skin, eye_z]) rotate([90, 0, 0]) linear_extrude(eye_t) {
            circle(d = eye_board_d, $fn = 96);
            translate([-eye_tab[0] / 2, 0]) square([eye_tab[0], eye_board_d / 2 + eye_tab[1]]);
        }
    else if (n == "mouth") translate([0, face_y - m_skin, mouth_z]) {   // glass, board, parts behind
        translate([m_glass_dx - oled_glass[0] / 2, -oled_glass[2], -oled_glass[1] / 2]) cube([oled_glass[0], oled_glass[2], oled_glass[1]]);
        translate([m_pcb_dx - oled_pcb[0] / 2, -oled_t, -oled_pcb[1] / 2]) cube([oled_pcb[0], oled_t - oled_glass[2] - 0.2, oled_pcb[1]]);
    }
    else if (n == "camera") at_lens() {                     // board, its back parts, lens holder + barrel
        translate([-cam_board[0] / 2, cam_y_board - cam_board_t, -cam_board[1] / 2]) cube([cam_board[0], cam_board_t, cam_board[1]]);
        translate([-35, cam_y_board - cam_board_t - 3.0, -8]) cube([70, 3.0, 16]);
        translate([-7, cam_y_board, -7]) cube([14, 10.6, 14]);
        translate([0, cam_y_board, 0]) rotate([-90, 0, 0]) cylinder(d = cam_lens_d, h = cam_lens_h - 0.01, $fn = 40);
    }
    else if (n == "mcu") translate([mcu_c[0], mcu_c[1], floor_t - 1.2]) {
        translate([-mcu[0] / 2, -mcu[1] / 2, 0]) cube([mcu[0], mcu[1], 3.5]);
        translate([-mcu[0] / 2 - 14, -4.5, 0.4]) cube([14, 9, 3.5]);
    }
}

COLORS = ["#eef0f2", "#d9dcdf", "#9aa3ad", "#6d7a88", "#55606b", "#1a4fa0", "#141414", "#202020", "#1b6b3a"];

if (len(clash) == 2) intersection() { body(clash[0]); body(clash[1]); }
else for (i = [0 : len(BODIES) - 1]) if (only == "" || only == BODIES[i]) color(COLORS[i]) body(BODIES[i]);
