// Head floor - screws down onto the turntable plate (4 x M3 x 8 into the plate's inserts) and
// carries the head's ESP32-S3. The shell + face hook onto it: the face's two tongues go into the
// slots in the front tabs, then two M3 x 8 through the shell's back wall into the back tabs.
//   * 40 mm hole in the middle: the camera's and the ESP32's USB cables go down it into the
//     turntable's hollow tube
//   * pockets underneath clear the lazy Susan's two M5 nuts that sit under the head
//   * the XIAO ESP32-S3 sits in a shallow pocket (hot glue or a dab of foam tape), USB-C toward
//     the hole
//
// PRINT upside down? No - as modelled (bottom on the bed): the nut pockets underneath are
// bridged (12 mm), the tabs stand up. PETG.
include <../head.scad>

tab_w = 14;
tab_d = 8;              // along Y

module floor_plate() {
    difference() {
        union() {
            translate([-floor_x, floor_y[0], 0]) cube([2 * floor_x, floor_y[1] - floor_y[0], floor_t]);
            // front tabs, slotted for the face's tongues
            for (x = tongue_x) translate([x - tab_w / 2, floor_y[1] - tab_d, 0]) cube([tab_w, tab_d, tongue_z + tongue[1] / 2 + 1.5]);   // under the mouth
            // back tabs, with inserts for the shell's screws
            for (x = back_screws) translate([x - tab_w / 2, floor_y[0], 0]) cube([tab_w, tab_d, back_screw_z + 6]);
        }
        // cable hole
        translate([0, 0, -1]) cylinder(d = floor_hole_d, h = floor_t + 2, $fn = 96);
        // M3 screws down into the turntable plate: clearance + head counterbore from the top
        for (m = floor_mounts) translate([m[0], m[1], -1]) {
            cylinder(d = 3.4 + cal_hole, h = floor_t + 2, $fn = 32);
            translate([0, 0, 1 + floor_t - 3]) cylinder(d = 6.4 + cal_hole, h = 4, $fn = 40);
        }
        // the lazy Susan's M5 nuts + bolt tips, underneath
        for (n = floor_nuts) translate([n[0], n[1], -0.01]) cylinder(d = 12, h = 3, $fn = 48);
        // tongue slots (open to the front), a little larger than the tongues
        for (x = tongue_x) translate([x - (tongue[0] + 0.6) / 2, floor_y[1] - tongue[2] - 0.5, tongue_z - (tongue[1] + 0.5) / 2])
            cube([tongue[0] + 0.6, tongue[2] + 1, tongue[1] + 0.5]);
        // back-screw inserts (bore along +Y from the back face)
        for (x = back_screws) translate([x, floor_y[0] - 0.01, back_screw_z]) rotate([-90, 0, 0])
            cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 32);
        // ESP32 pocket, 1.2 deep
        translate([mcu_c[0], mcu_c[1], floor_t - 1.2]) linear_extrude(2) square(mcu + [0.6, 0.6], center = true);
        // ... and a channel from it to the cable hole for the USB-C plug
        translate([0, -6, floor_t - 1.2]) cube([mcu_c[0], 12, 2]);
    }
}

floor_plate();

// ghost: the XIAO and its USB-C plug
%translate([mcu_c[0], mcu_c[1], floor_t - 1.2]) {
    translate([-mcu[0] / 2, -mcu[1] / 2, 0]) cube([mcu[0], mcu[1], 3.5]);
    translate([-mcu[0] / 2 - 14, -4.5, 0.4]) cube([14, 9, 3.5]);
}
