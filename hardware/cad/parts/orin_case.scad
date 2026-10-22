// Orin NX case: Seeed's printable case for the J401 carrier (shell + bottom plate, the heat-set insert
// version), modified to carry the pan/tilt base on its top. The Seeed meshes are NOT in git (third-party):
// vitamins/models/seeed_orin_case_shell.stl and seeed_orin_case_plate.stl, from Seeed's
// "jetson_Orin_NX外壳.3mf" (plate 1, "needs heat-set nuts").
//
//   SHELL  + four M3 inserts in the top, at the corners of the base section's footprint (the case's main
//          part, 100 wide - not the stepped ledge over the 40-pin header). They land on the shell's solid
//          corner posts (~25 mm deep), so the top stays flat and prints top-down as Seeed's does
//          + two RP-SMA antenna holes in the solid block beside the vent slats (robot's left, toward the
//          back), counterbored from inside so the bulkhead nuts reach (optional - Wi-Fi works without)
//   PLATE  Seeed's, unchanged
//
// Frame: the Seeed mesh's own - centred, top skin at z 13.9..17.9 with the fan opening.
// +Y = the robot's FRONT (the fan side), -Y = BACK (all the ports), +X = the robot's right (40-pin header).
// part = "shell" | "plate" | "view"
include <../params.scad>

part = "view";

shell_stl = "../vitamins/models/seeed_orin_case_shell.stl";
plate_stl = "../vitamins/models/seeed_orin_case_plate.stl";

// ---- the Seeed shell (MEASURED from the mesh) -----------------------------------------------------------
case_xy   = [114.9, 105.5];
case_top  = 17.88;               // top surface; the top skin is 4 thick
main_x    = [-57.45, 42.8];      // the main part (east of 42.8 the top steps down over the header)
fan_open  = [[-32.6, 27.6], [-5.5, 34.5]];   // the module's fan shows through here - keep it clear

// ---- inserts for the base section ------------------------------------------------------------------------
pad_in    = 7;                   // insert centres this far in from the footprint's edges (over the corner posts)
pad_xy    = [for (x = [main_x[0] + pad_in, main_x[1] - pad_in], y = [-1, 1]) [x, y * (case_xy[1] / 2 - pad_in)]];
pan_xy    = [(main_x[0] + main_x[1]) / 2, 0];      // the footprint's centre: where the pan axis will be

// ---- antenna holes ----------------------------------------------------------------------------------------
ant_y     = [-42, -28];          // in the solid block (y -45..-25, z -8..12)
ant_z     = 4;
ant_d     = 6.6;                 // RP-SMA bulkhead (1/4"-36 thread)
ant_wall  = 3;                   // wall left for the bulkhead's thread
ant_cb    = 12;                  // counterbore from inside (the nut + a little)
x_outer   = -case_xy[0] / 2;

module shell() {
    difference() {
        import(shell_stl, convexity = 10);
        for (p = pad_xy) translate([p[0], p[1], case_top - insert_m3[1] - 1]) cylinder(d = insert_m3[0], h = insert_m3[1] + 2, $fn = 24);
        for (y = ant_y) translate([x_outer - 1, y, ant_z]) rotate([0, 90, 0]) {
            cylinder(d = ant_d + cal_hole, h = 20, $fn = 32);
            translate([0, 0, 1 + ant_wall]) cylinder(d = ant_cb, h = 20, $fn = 40);
        }
    }
}

if (part == "shell") rotate([180, 0, 0]) translate([0, 0, -case_top]) shell();          // top down on the bed (as Seeed)
if (part == "plate") import(plate_stl, convexity = 10);
if (part == "view") {
    shell();
    color("#333") translate([0, 0, -case_xy[1]]) import(plate_stl, convexity = 10);
    echo(str("pan axis over the case at ", pan_xy, "; pad inserts at ", pad_xy));
}
