// Motor bracket - hangs the NEMA17 (shaft up) under the drive deck so its 20 T pulley
// lines up with the turntable pulley's teeth. Two M3 screws from above the deck, through its
// radial slots, into heat-set inserts in the bracket's far wall: slide it outward to tension the
// belt. The motor screws to the plate from above (4 x M3) before the bracket goes in; its pulley
// then goes on, pushed fully down through the plate's centre hole onto the motor.
//
// Also carries the HOMING SENSOR: an A3144-type Hall sensor lying face-up in a pocket on the
// plate, under the turntable pulley's bottom edge. A small magnet glued under the pulley (on the
// flat ring of its bottom face, ~28 mm from the centre, on the motor side when the head looks
// straight ahead) passes ~4 mm above it at home. Its leads run along a groove to the side.
//
// Modelled in place (deck frame, see level2.scad) with the plate at the bottom.
// PRINT as modelled: plate on the bed, walls up, no supports. PETG.
include <../level2.scad>

m3_clear  = 3.6;
plate_u   = [-nema[0] / 2 - 0.5, 35];     // plate extent along the radial line (motor frame)
half_v    = 27;                           // half-width across it
side_wall = 5.5;                          // side walls, |v| = half_v - side_wall .. half_v
side_u0   = -10;                          // side walls start here: clear of the pulley's clamp
                                          //   block even with the bracket slid 4 mm inward
far_wall  = [27, 35];                     // far wall (u range): takes the two deck screws
slot_u    = 31; slot_v = 12;              // must match drive_deck.scad
hall      = [3.4 + 0.4, 4.0 + 0.4, 1.6];  // A3144 TO-92 lying flat: [u, v, depth]
hall_u    = -17;                          // ~28 mm from the turntable's centre

module bracket() {
    z0 = z_motor_face;                    // plate underside = motor face
    z1 = -deck_t;                         // wall tops = deck underside
    difference() {
        union() {
            // motor plate
            translate([plate_u[0], -half_v, z0]) cube([plate_u[1] - plate_u[0], 2 * half_v, bracket_t]);
            // side walls
            for (s = [-1, 1]) translate([side_u0, s > 0 ? half_v - side_wall : -half_v, z0])
                cube([plate_u[1] - side_u0, side_wall, z1 - z0]);
            // far wall
            translate([far_wall[0], -half_v, z0]) cube([far_wall[1] - far_wall[0], 2 * half_v, z1 - z0]);
        }
        // motor centring boss and its four screws
        translate([0, 0, z0 - 1]) cylinder(d = nema_boss + 1, h = bracket_t + 2, $fn = 64);
        for (su = [-1, 1], sv = [-1, 1]) translate([su * nema_holes / 2, sv * nema_holes / 2, z0 - 1])
            cylinder(d = m3_clear, h = bracket_t + 2, $fn = 24);
        // heat-set inserts for the deck screws
        for (v = [-slot_v, slot_v]) translate([slot_u, v, z1 - insert_m3[1]]) cylinder(d = insert_m3[0], h = insert_m3[1] + 1, $fn = 24);
        // Hall sensor pocket + lead groove to the side
        translate([hall_u - hall[0] / 2, -hall[1] / 2, z0 + bracket_t - hall[2]]) cube([hall[0], hall[1], hall[2] + 1]);
        translate([hall_u - 1.6, 0, z0 + bracket_t - 1.2]) cube([3.2, half_v + 1, 2]);
    }
}

rotate(motor_a) translate([motor_C, 0, 0]) bracket();

// ghosts (not printed): motor and its pulley
%rotate(motor_a) translate([motor_C, 0, 0]) {
    translate([-nema[0] / 2, -nema[0] / 2, z_motor_bottom]) cube([nema[0], nema[0], nema[1]]);
    translate([0, 0, z_motor_face]) cylinder(d = 16, h = z_mp_top - z_motor_face);
}
