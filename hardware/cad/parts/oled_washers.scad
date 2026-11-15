// Washers for the four M2 (2 mm thread, 6 mm long) screws that hold the OLED board to the head front.
// Stack at each screw: board 1.2 + washer 1.8 + 3.0 mm into the pilot = 6.0 thread, leaving 1 mm of the 4 mm wall.
$fn = 64;
w_id = 2.4;   // screw 2.0 + clearance
w_od = 5.0;   // fits the board's 2.5 mm corner hole margin
w_t  = 1.8;
module washer() difference() {
    cylinder(d = w_od, h = w_t);
    translate([0, 0, -1]) cylinder(d = w_id, h = w_t + 2);
}
for (i = [0:3]) translate([(i % 2) * 8, floor(i / 2) * 8, 0]) washer();
