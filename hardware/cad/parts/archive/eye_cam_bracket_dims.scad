// Camera bracket - shared by eye_cam_bracket.scad (the part) and eye_test_stand.scad (its insert
// holes), so the two can't drift apart. Coordinates: the stand's (x along the board, y up, as
// seen from the back), but z = 0 at the stand's BACK face, positive away from it.
//
// A shallow U-channel strapped across the back of the camera board at its middle (x = 0):
//
//            leg ____________________ leg
//     foot      |        bridge      |      foot        bridge underside 3.0 above the
//     =(o)======|                    |======(o)=        back face (clears the board's back
//     ----------+--------board-------+----------        parts); M3 screws into inserts
//
// The legs sit just outside the board's top and bottom edges, so they also locate it up/down.

br_pcb_top = 11.0;             // board's top edge (22 tall, centred)
br_pcb_h   = 18.4;             // MEASURED: board height at the middle (bottom edge cut back here)
br_pcb_bot = br_pcb_top - br_pcb_h;          // -7.4
br_ext     = 10;               // bracket runs this far beyond each board edge
br_rise    = 3.0;              // bridge underside above the stand's back face
br_t       = 2.5;              // material thickness (feet, legs, bridge)
br_w       = 10;               // width along the board (x)
br_clr     = 0.5;              // legs' clearance from the board's edges
// holes: centred on the flat foot (an M3 head, 5.5 across, would overlap the leg at 5 mm out)
br_leg_out = br_clr + br_t;                   // leg's outer face, measured from the board edge
br_hole_out = br_leg_out + (br_ext - br_leg_out) / 2;     // 6.5 from the board edge
br_holes_y = [br_pcb_top + br_hole_out, br_pcb_bot - br_hole_out];   // [17.5, -13.9]

module cam_bracket() {
    y0  = br_pcb_bot - br_ext;                // bottom end
    y1  = br_pcb_top + br_ext;                // top end
    yi0 = br_pcb_bot - br_clr;                // legs' inner faces
    yi1 = br_pcb_top + br_clr;
    h   = br_rise + br_t;                     // overall height
    module blk(ya, yb, za, zb) translate([-br_w / 2, ya, za]) cube([br_w, yb - ya, zb - za]);
    difference() {
        union() {
            blk(y0, yi0 - br_t, 0, br_t);                 // bottom foot
            blk(yi1 + br_t, y1, 0, br_t);                 // top foot
            blk(yi0 - br_t, yi0, 0, h);                   // legs
            blk(yi1, yi1 + br_t, 0, h);
            blk(yi0 - br_t, yi1 + br_t, br_rise, h);      // bridge
        }
        // M3 clearance holes (3.4, drawn with the hole calibration)
        for (y = br_holes_y) translate([0, y, -1]) cylinder(d = 3.4 + cal_hole, h = br_t + 2, $fn = 32);
    }
}
