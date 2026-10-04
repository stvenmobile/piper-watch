// Display fit test: just the front wall of the Level 2 body round the 4.3" display - the window
// (raised 2.8 mm above the board's centre, chamfered) and the four posts with M3 inserts - cut
// straight from l2_body.scad, so it is exactly what the body will have. (~30 min)
// The notch marks the TOP edge. Check: screw the JC4827W543 on (image upright) (M3 x 6-8 into heat-set inserts); the image should fill the
// window evenly with only black border showing, and the glass should sit flat on the wall.
// PRINT as modelled: face down on the bed, posts up, no supports.
use <l2_body.scad>
include <../level2.scad>

disp_zc = -l2_h / 2;                           // must match l2_body.scad
half    = l2_size[0] / 2;

translate([0, 0, half]) rotate([-90, 0, 0])    // wall's outside face -> the bed, posts up
    difference() {
        intersection() {
            l2_body();
            translate([-64, half - 14, disp_zc - 39]) cube([128, 14.2, 78]);
        }
        // notch in the middle of the TOP edge (the window is offset toward it)
        translate([0, half - 7, disp_zc + 39]) rotate([0, 45, 0]) cube([4, 20, 4], center = true);
    }
