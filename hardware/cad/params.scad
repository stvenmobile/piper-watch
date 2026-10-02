// Piper-Watch - all dimensions in one place (millimetres).
// Values marked EST are estimates; correct them after measuring the real part.

$fn = 96;                        // circle smoothness for previews/exports

// --- Printing: Bambu Lab A1, 0.4 mm nozzle, PETG -------------------------------
line_w      = 0.45;              // extrusion width
wall        = 4 * line_w;        // 1.8 mm: minimum for load-bearing walls
bed         = [225, 225, 225];   // build volume
clr_hole    = 0.30;              // added to bolt hole diameters - measured: +0.3 is the smallest free fit (coupon, 2026-10-01)
clr_fit     = 0.35;              // gap for parts that slide/rotate against each other (a little looser than clr_hole)

// --- Fasteners ------------------------------------------------------------------
m3          = 3.0;
m4          = 4.0;
insert_m3   = [4.1, 5.0];        // heat-set insert bore [diameter, depth] - coupon "M3a" confirmed
insert_m4   = [5.6, 6.0];        // coupon "M4a" confirmed

// --- Lazy Susan: 140 mm round aluminium turntable bearing (Amazon B08CSMCRC6) ----
ls_od        = 140;              // outer diameter (given)
ls_id        = 89;               // centre opening - measured on the real part (listing said 85)
ls_h         = 10.5;             // total thickness, both rings (measured on listing photo)
ls_split_d   = 113;              // EST: diameter where outer and inner ring meet
ls_hole_d    = 4.5;              // EST: through holes, countersunk (M4 / #8)
ls_outer_bc  = 128;              // EST: outer ring bolt circle diameter, 4 holes
ls_inner_bc  = 100;              // EST: inner ring bolt circle diameter, 4 holes
ls_holes     = 4;
ls_inner_rot = 45;               // inner holes sit between the outer ones

// --- Feetech STS3215 (12 V / 30 kg.cm) - EST from datasheet, verify on arrival --
sts_body     = [45.2, 24.7, 35]; // length x width x height (without horn)
sts_shaft_x  = 11.5;             // EST: output shaft centre from the near end
sts_horn_d   = 20;               // EST: horn diameter
sts_horn_h   = 3;

// --- Logitech C920X core module - EST ----------------------------------------------
cam_core     = [90, 30, 25];

// --- E32R40T 4" display board - TODO: measure outline, holes, connector positions --
lcd_board    = [110, 70, 12];    // EST placeholder
