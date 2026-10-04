// Level 2 - shared dimensions for the drive deck, motor bracket, body and skirt.
// Frame: origin at the centre of the deck's TOP surface; +Z up, +Y = front (display), +X = right.
// The lazy Susan sits on the deck's plinth; the turntable pulley hangs through the deck's hole.
include <params.scad>

// ---- outline -------------------------------------------------------------------------------
l2_size   = [160, 160];     // footprint (rounded square), same for body and skirt
l2_r      = 14;             // corner radius
l2_h      = 90;             // body height (floor to the deck's underside... see body)
l2_wall   = 2.5;            // body walls

// ---- deck ----------------------------------------------------------------------------------
deck_t    = 4;              // deck plate: z = -deck_t .. 0
deck_hole = 112;            // reach the inner ring's bolts from below during assembly

// ---- lazy Susan + turntable pulley (turntable_pulley.scad) --------------------------------
z_ls      = plinth_h;                    // lazy Susan's underside (on the plinth): 2
z_plate   = z_ls + ls_h;                 // turntable plate's underside = inner ring top: 12.5
belt_drop = 24.5;                        // plate underside -> belt centre (turntable_pulley)
z_belt    = z_plate - belt_drop;         // -12: belt centre, below the deck top
pulley_R  = 100 * 2 / PI / 2;            // 31.83: ring pulley pitch radius (100 T)
pulley_bottom = z_belt - 3.2 - 1.6 - 2.2;  // -19: lowest point of the hanging pulley
clamp_r   = 35.5;                        // pulley's belt clamp block (its widest part)

// ---- motor ----------------------------------------------------------------------------------
motor_a   = -45;            // direction of the motor from the centre: back-right corner
motor_C   = 46;             // nominal centre distance; the bracket slides +/- tension_travel (42..50:
                            //   at 41 the motor pulley would touch the ring pulley's flange)
tension_travel = 4;
nema      = [42.3, 33.4];   // NEMA17 (MEASURED body length; not a pancake): square, body length
nema_shaft = 17.5;          // MEASURED shaft length above the face
nema_holes = 31;            // M3 screw spacing on its face
nema_boss = 22;             // centring boss on its face (dia), ~2 tall
mp_T      = 20;             // motor pulley teeth
mp_belt_c = 13 + 6.5 / 2;   // MEASURED: pulley pushed fully down on the motor, the belt (6.5 wide) runs
                            //   13..19.5 above the motor face -> centre 16.25 above it
bracket_t = 3;              // motor plate thickness; the pulley passes down through its centre hole
z_motor_face  = z_belt - mp_belt_c;          // -28.25
z_bracket_top = z_motor_face + bracket_t;    // -25.25
z_motor_bottom = z_motor_face - nema[1];     // -61.65
z_mp_top  = z_motor_face + 13 + 6.5 + 1;     // ~-7.75 (EST: top flange 1 mm above the belt)
