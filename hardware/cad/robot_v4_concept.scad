// CONCEPT v4 (first look, estimated sizes - not parts):
//   - the base box holds only the electronics (Orin, servo adapter, fuse + 12 V jack); its lid carries everything above
//   - the pan servo STANDS on the lid inside a STATIONARY cylinder (bolted to the lid) that runs up to a few mm below the rotating
//     tilt plate; the plate carries a short rotating SKIRT that hangs down over the top of the cylinder and hides the gap
//   - narrow camera-only head, tilted by a servo + connecting rod (no LEDs, no LCD)
// Frame: pan axis = (0,0) on the lid; +Y = front; Z = 0 at the underside of the base floor.
// part = "view"   cut = true slices the box / wall / skirt open on the robot's right (x > 0) so the insides show
part = "view";
cut = false;
tilt = 0;

// ---- base box (electronics only) ---------------------------------------------------------------------------------
bw = 118;  bd = 140;  fl = 4;  wt = 3;
lid_z = 34;  lid_t = 8;  lid_top = lid_z + lid_t;               // heatsink top ~31.6 -> lid underside 34
box_y = 4;                                                       // box centre, behind the pan axis a little (Orin at the back)

// ---- pan stack ---------------------------------------------------------------------------------------------------
gap_t  = 3;                                                      // fixed cylinder top -> underside of the rotating plate
z_f    = lid_top + 32 + 12;                                      // turret floor top (servo 32 + horn/hub ~10)
fl_t   = 4;
wall_r = 54.5;  wall_t = 4;  wall_h = z_f - fl_t - gap_t - lid_top;   // fixed cylinder: ~37 tall, around the pan servo
sk_in  = 56;  sk_out = 57.5;                                     // rotating skirt: 1.5 over the cylinder, 1.5 thick, flush with it
sk_h   = 14;  sk_z0 = z_f - fl_t - sk_h;                         // hangs 14 below the plate = overlaps the cylinder top by 11
// ---- head: camera board behind a window, ~84 wide ----------------------------------------------------------------
hw = 84;  hh = 40;  hy = [-14, 22];                              // width, height, back..front from the axle
ax_y = 10;  ax_z = z_f + 40;                                     // tilt axle (x), in the turret frame
ch_in = hw / 2 + 1.5;  ch_t = 8;                                 // cheeks (608 bearing in one)

module rb(w, d, h, r = 6) linear_extrude(h) offset(r = r) square([w - 2 * r, d - 2 * r], center = true);
module servo(sz = [24.72, 45.22, 32]) color("#b0b6bd") translate([-sz[0] / 2, -sz[1] / 2, 0]) cube(sz);
module cutaway() difference() { union() children(); if (cut) translate([0, -300, -1]) cube([300, 600, 400]); }

module base_box() {
    cutaway() {
        color("#6b8fb5") translate([0, box_y, 0]) difference() { rb(bw, bd, lid_z); translate([0, 0, fl]) rb(bw - 2 * wt, bd - 2 * wt, lid_z, 3); }
        color("#8fa9c4") translate([0, box_y, lid_z]) rb(bw, bd, lid_t);                                   // lid
        color("#8fa9c4") difference() { translate([0, 0, lid_top - 0.01]) cylinder(r = wall_r, h = wall_h, $fn = 120);      // fixed wall
                                        translate([0, 0, lid_top - 1]) cylinder(r = wall_r - wall_t, h = wall_h + 2, $fn = 120); }
    }
    color("#2e7d32") translate([-50, box_y - 70 + 3 + 0, fl + 6]) cube([100, 80, 1.6]);                       // Orin
    color("#9aa0a6") translate([-35, box_y - 70 + 3 + 12, fl + 7.6]) cube([70, 50, 22]);                      // heatsink + fan
    color("#2a6a3a") translate([-bw / 2 + wt + 2, box_y + 14, fl + 6]) cube([33, 42, 1.6]);                   // servo adapter
    color("#00897b") translate([bw / 2 - wt - 36, box_y + 16, fl + 6]) cube([30, 20, 14]);                    // fuse + terminals
}

module turret() {
    cutaway() color("#d9dde2") {
        difference() { translate([0, 0, sk_z0]) cylinder(r = sk_out, h = z_f - sk_z0, $fn = 120);              // skirt + floor
                       translate([0, 0, sk_z0 - 1]) cylinder(r = sk_in, h = z_f - sk_z0 - fl_t + 1, $fn = 120); }
    }
    // cheeks
    for (s = [-1, 1]) color("#6b8fb5") hull() {
        translate([s * (ch_in + ch_t / 2) - ch_t / 2, ax_y - 16, z_f - 0.01]) cube([ch_t, 32, 4]);
        translate([s * (ch_in + ch_t / 2) - ch_t / 2, ax_y, ax_z]) rotate([0, 90, 0]) cylinder(d = 36, h = ch_t, $fn = 60);
    }
    // tilt servo behind the head, shaft along X; crank + connecting rod to a lug on the head's back
    sx = 12;  sy = -26.5;
    translate([sx, sy, z_f]) rotate([0, 0, 0]) color("#b0b6bd") translate([-16, -22.6, 0]) cube([32, 45.22, 24.72]);
    pin_s = [sx + 18, sy + 22.6 - 10, z_f + 12.4 + 12];
    pin_h = [sx + 18, ax_y - 24, ax_z + 10];
    color("#e8a33d") hull() { translate([sx + 18, sy + 22.6 - 10, z_f + 12.4]) rotate([0, 90, 0]) cylinder(d = 9, h = 3, center = true, $fn = 24);
                              translate(pin_s) rotate([0, 90, 0]) cylinder(d = 5, h = 3, center = true, $fn = 24); }
    color("#c0392b") hull() { translate(pin_s) rotate([0, 90, 0]) cylinder(d = 4, h = 4, center = true, $fn = 20);
                              translate(pin_h) rotate([0, 90, 0]) cylinder(d = 4, h = 4, center = true, $fn = 20); }
    // head
    translate([0, ax_y, ax_z]) rotate([tilt, 0, 0]) {
        color("#8a8d91") translate([-hw / 2, hy[0], -hh / 2]) cube([hw, hy[1] - hy[0], hh]);
        color("#111") translate([0, hy[1] + 0.2, 5]) rotate([-90, 0, 0]) cylinder(d = 16, h = 1, $fn = 40);        // lens
        color("#6b8fb5") translate([sx + 18 - 3, -24, 6]) cube([6, 24, 8]);                                        // lug to the rod pin
    }
}

if (part == "view") {
    base_box();
    // pan servo, standing, hidden inside the wall; horn hub up through the turret floor
    translate([0, 0, lid_top]) servo();
    color("#e8a33d") translate([0, 0, lid_top + 32]) cylinder(d = 28, h = z_f - fl_t - (lid_top + 32), $fn = 60);
    turret();
    echo(str("base ", bw, " x ", bd, " x ", lid_top, "; skirt dia ", 2 * sk_out, "; turret floor z ", z_f, "; head top z ", ax_z + hh / 2, "; overall ~", ax_z + 20));
}
