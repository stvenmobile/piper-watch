// Run book step 3 render: the pan stack, the turret with its tilt linkage, and the lot onto the lid, exploded
// bottom to top in assembly order with numbered callouts (numbers = the steps in README.md "Step 3").
//   openscad -o 34_render_turret_to_lid_exploded.png --imgsize=1400,2000 --colorscheme=Tomorrow \
//            --camera=0,0,360,64,0,205,1700 --projection=p 34_turret_to_lid_exploded.scad
include <../../parts/base_v4.scad>
part = "none";  show_cowl = false;
VPR = [64, 0, 205];                                   // keep in step with --camera (callouts face the camera)

// explode offsets above each part's assembled height (base frame, mm)
d_strap = 25;  d_pan = 50;  d_skirt = 120;  d_pb = 155;  d_hub = 235;  d_tur = 310;  d_cowl = 420;
lx = -52;                                             // the linkage pulled out to the left (-X): crank, then rod
module at(dz) translate([0, 0, z_pt + dz]) children();

// ---- the base, as built (step 1-2) ----------------------------------------------------------------------------------
color("#6b8fb5", 0.35) tub4();
color("#b5c4d6") lid4();
translate([ad_c[0], ad_c[1], wall_top + ad_so[1]]) color("#222") translate([-21.5, -16.5, 0]) cube([43, 33, 1.6]);   // servo adapter

// ---- pan stack --------------------------------------------------------------------------------------------------------
at(d_strap) color("#2b2b2b") translate([0, 0, z_case_bot - strap_t]) pan_strap4();
at(d_pan) translate([0, 0, z_horn - disc_h]) rotate([0, 0, 90]) servo_model();
at(d_skirt) color("#8fa9c4") skirt4s();
at(d_pb) color("#b0b6bd") translate([-pb[0] / 2, -pb[1] / 2, 0]) cube(pb);
at(d_hub) rotate([0, 0, 90]) color("#e8a33d") hub4();             // window turned to face FRONT (+Y)

// ---- turret + tilt servo + linkage + head ---------------------------------------------------------------------------
at(d_tur) {
    color("#6b8fb5") turret4();
    color("#b0b6bd") translate([tsv[0], tsv_y[0], tsv_z[0]]) cube([tsv[1] - tsv[0], tsv_y[1] - tsv_y[0], tsv_z[1] - tsv_z[0]]);   // tilt servo
    color("#c0c0c0") translate([tsh[0] - 3, tsh[1], tsh[2]]) rotate([0, 90, 0]) cylinder(d = sts_horn_d, h = 3, $fn = 40);        // its horn
    translate([0, 0, 14]) strap4();
    translate([lx, 0, 0]) crank4();
    translate([2 * lx, 0, 0]) tilt_rod4();
    head4();
    for (sx = [-1, 1]) translate([sx * 12, 0, 0]) covers4();
}
at(d_cowl) cowl4();

// ---- the cables' way: down the turret floor hole, the hub, out of its window toward the front ---------------------
color("#d62728") for (seg = [[[4, 4, z_pt + d_tur + z_ft + 20], [4, 4, z_pt + d_hub + z_horn + hub_end + 10]],
                             [[4, 4, z_pt + d_hub + z_horn + hub_end + 10], [4, 40, z_pt + d_hub + z_horn + hub_end + 10]]])
    hull() for (p = seg) translate(p) sphere(d = 3, $fn = 12);

// ---- callouts ---------------------------------------------------------------------------------------------------------
module callout(n, a, l) {
    color("#444") hull() { translate(a) sphere(d = 1.2, $fn = 8); translate(l) sphere(d = 1.2, $fn = 8); }
    color("#444") translate(a) sphere(d = 3, $fn = 12);
    translate(l) rotate(VPR) {
        color("#c0392b") cylinder(d = 17, h = 0.6, center = true, $fn = 48);
        color("white") translate([0, 0, 0.4]) linear_extrude(0.6)
            text(str(n), size = n < 10 ? 9 : 7.5, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}
L = 100;                                              // callouts out to the sides: +X shows on the LEFT (camera in front)
zs = z_pt;
callout(1, [-pb[0] / 2, pb[1] / 2, zs + d_pb + pb[2]],                [-L, 20, zs + d_pb + 20]);       // pillow block
callout(2, [-srv[1] / 2, 20, zs + d_pan - 45],                        [-L, 20, zs + d_pan - 40]);      // pan servo into the sleeve
callout(3, [-12, 0, zs + d_strap + z_case_bot - strap_t],             [-L, 10, zs + d_strap - 85]);    // pan strap
callout(4, [0, -hub_od / 2, zs + d_hub + z_flange - 15],              [L, -20, zs + d_hub - 20]);      // hub onto the horn
callout(5, [tsv[1], -38, zs + d_tur + sb_top + 14],                   [L, -60, zs + d_tur + 60]);      // tilt servo + strap
callout(6, [tsh[0] + lx - 6, tsh[1], zs + d_tur + tsh[2] + 8],        [-L - 40, -60, zs + d_tur + 30]);    // crank
callout(7, [pin_s[0] + 2 * lx, pin_s[1] + 6, zs + d_tur + pin_s[2]],  [-L - 40, -20, zs + d_tur + 75]);    // rod
callout(8, [-ch_x[1] - 12 - cv_t, ax_y, zs + d_tur + ax_z + 10],           [-L - 30, 40, zs + d_tur + 120]);    // head + cheek covers
callout(9, [4, 40, zs + d_hub + z_horn + hub_end + 10],               [L, 60, zs + d_hub - 60]);       // cables out of the window
callout(10, [flange_r * cos(hub_a), flange_r * sin(hub_a), zs + d_tur + z_floor], [L, 30, zs + d_tur - 20]);   // turret on the flange
callout(11, [-sk_ro, 0, zs + d_skirt + bolt_z - z_pt],                [-L, -20, zs + d_skirt - 70]);   // skirt over the wall
callout(12, [-cw_r * 0.7, -cw_r * 0.7, zs + d_cowl + z_ft + 25],      [-L, -40, zs + d_cowl + 50]);    // cowl

// a FRONT marker on the lid
translate([0, bd / 2 + 14, wall_top]) rotate(VPR) color("#2e7d32") linear_extrude(0.6)
    text("FRONT", size = 9, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
