// Piper-Watch - all dimensions in one place (millimetres).
// Values marked EST are estimates; correct them after measuring the real part.

$fn = 96;                        // circle smoothness for previews/exports

// --- Printing: Bambu Lab A1, 0.4 mm nozzle, PETG -------------------------------
line_w      = 0.45;              // extrusion width
wall        = 4 * line_w;        // 1.8 mm: minimum for load-bearing walls
bed         = [225, 225, 225];   // build volume
clr_hole    = 0.30;              // added to bolt hole diameters - measured: +0.3 is the smallest free fit (coupon, 2026-10-01)
// FIT CALIBRATION (fit_calibration.scad; 15% gyroid, 4 walls, 5 top/bottom; Bambu profiles with
// NO slicer compensation - the CAD compensates). Pick the material the part is printed in:
material   = "PETG";             // "PETG" = Bambu PETG Basic (base parts), "PLA" = Bambu PLA Basic
//   PLA  (2026-10-04): holes ~0.4 small on the diameter (4..15 mm); pins/outer edges ~0.1 small;
//                      X/Y -0.45% (80 -> 79.6 / 79.7); Z true.
//   PETG (2026-10-07): holes 0.29..0.48 small (mean 0.39; 4..6 mm ~0.46, 8..15 mm ~0.32);
//                      pins 0.19..0.22 small; X/Y -0.30% (79.74 / 79.78); Z true (30.02);
//                      first layer slightly squashed (4.00 plate -> 4.11).
cal_hole   = 0.4;                                    // add to a hole's diameter to get it as drawn
cal_edge   = material == "PLA" ? 0.1 : 0.2;          // add to an outside dimension
cal_xy     = material == "PLA" ? 1.0045 : 1.0030;    // scale long X/Y distances (bolt circles, spans)
hole_shrink = 0.6;               // MEASURED on the turntable pulley (PLA, 15% gyroid, 4 walls): a 6.0 hole printed 5.4.
                                 //   Larger PLA parts: draw a hole this much bigger than the size you want.
clr_fit     = 0.35;              // gap for parts that slide/rotate against each other (a little looser than clr_hole)

// --- Fasteners ------------------------------------------------------------------
m3          = 3.0;
m4          = 4.0;
insert_m3   = [4.1, 5.0];        // heat-set insert bore [diameter, depth] - coupon "M3a" confirmed
insert_m4   = [5.6, 6.0];        // coupon "M4a" confirmed
m5          = 5.0;
insert_m5   = [6.4, 7.0];        // EST - confirm with parts/m5_coupon.scad

// --- Lazy Susan: 140 mm round aluminium turntable bearing (Amazon B08CSMCRC6) ----
// Two COPLANAR rings, both 10.5 mm thick and flush top and bottom, with a 0.8 mm gap.
// The outer ring screws down into the box (countersinks on top); the inner ring
// screws up into the turntable top plate (countersinks underneath). No access hole.
ls_od        = 140;              // outer ring, outside (measured)
ls_ring_w    = 12.4;             // radial width of each ring (measured)
ls_gap       = 0.8;              // radial gap between the rings (measured)
ls_outer_id  = ls_od - 2 * ls_ring_w;            // 115.2  outer ring, inside
ls_inner_od  = ls_outer_id - 2 * ls_gap;         // 113.6  inner ring, outside
ls_id        = ls_inner_od - 2 * ls_ring_w;      // 88.8   centre opening (measured ~89)
ls_h         = 10.5;             // thickness of both rings (measured)
ls_hole_d    = 5.05;             // through holes, countersunk (measured 5.05; M5 passes) -> M5 flat-head screws
ls_outer_bc  = 128.0;            // measured: 133 edge-to-edge across opposite holes - hole dia (ring-centre estimate 127.6)
ls_inner_bc  = 101.0;            // measured: 106 edge-to-edge across opposite holes - hole dia (ring-centre estimate 101.2)
ls_holes     = 4;                // per ring, 90 degrees apart
ls_inner_rot = 45;               // inner holes sit between the outer ones

// Mounting rules that follow from the flush rings
ls_clear     = 1.0;              // keep printed parts this far (diameter) from the other ring
top_plate_d  = ls_inner_od - ls_clear;           // 112.6  turntable plate touches the inner ring only
plinth_id    = ls_outer_id + ls_clear;           // 116.2  box-top plinth touches the outer ring only
plinth_h     = 2.0;              // raised plinth height = clear gap under the inner ring

// --- Feetech STS3215 (12 V / 30 kg.cm) - EST from datasheet, verify on arrival --
sts_body     = [45.2, 24.7, 35]; // length x width x height (without horn)
sts_shaft_x  = 11.5;             // EST: output shaft centre from the near end
sts_horn_d   = 20;               // EST: horn diameter
sts_horn_h   = 3;

// --- Pan-only head on a neck (no tilt motor) ----------------------------------------
head_size    = [105, 45, 105];   // round face: diameter, depth (final ~45), diameter
head_tilt    = 15;               // fixed upward tilt, set by the swappable wedge
neck_out     = 40;               // EST: chamfered square neck, outside
neck_in      = 28;               // inside opening: camera USB plug + ~10 x 2 mm silicone wires

// --- GT2 timing belt (6 mm) and printed pulley teeth -----------------------------------
// Tooth-space shape is tunable: print parts/pulley_test_arc.scad and adjust until the belt
// seats fully with no rocking.
gt2_pitch    = 2.0;              // tooth pitch
gt2_pld      = 0.254;            // pitch line sits this far outside the pulley's tooth tips
gt2_belt_w   = 6.0;              // belt width
gt2_belt_t   = 1.5;              // belt total thickness, teeth included (measured)
gt2_tooth_h  = 0.75;             // belt tooth height
gt2_depth    = gt2_tooth_h + 0.05;   // tooth-space depth (belt tooth + clearance) - fits (test arc 1)
gt2_tip_r    = 0.555 + 0.05;     // rounded bottom of the tooth space
gt2_mouth    = 1.35;             // tooth-space width at the tips

// --- Face LED ring: 24-LED WS2812-type ring (measured / vendor) ------------------------
// Through-hole pads (2x 5 V, 2x GND, DIN, DOUT); wires can leave from either side.
ring_od      = 65.6;             // outer diameter
ring_id      = 52.3;             // inner diameter
ring_t       = 3.2;              // PCB (1.6) + 5050 LEDs
ring_n       = 24;               // LEDs, 15 deg apart (~7.7 mm)

// Diffuser in front of the LEDs (ring_diffuser.scad), pressed into the face flush
diff_t       = 2.0;              // thickness
diff_w       = 6.5;              // radial width
diff_clr     = [0.25, 0.45];     // [inner, outer] clearance each side. Fit test 3: diffuser 0.15/0.15 bound
                                 //   at both edges. Then 0.25/0.25 printed 53.2 / 64.5 but the stand's seat
                                 //   printed 52.2 / 64.2 (outer wall at the bed shrinks) -> outer 0.45: CONFIRMED, drops in smoothly

// --- Mouth: 2.08" white OLED, 256 x 64, SH1122, 4-wire SPI (GME25664-65; vendor drawing:
// 2_08-white_OLED_2.jpg). X along the board's length, from the pin end; Y across.
oled_pcb     = [75.5, 20.6];     // board
oled_t       = 5.6;              // max, board + glass (board 1.2)
oled_holes   = [72.0, 15.5];     // 4 x d2.5 mounting holes, centred on the board
oled_hole_d  = 2.5;
oled_glass   = [62.5, 20.6, 1.63];   // glass starts 7.25 from the pin end
oled_glass_x = 7.25;
oled_va      = [53.18, 14.78];   // visible area: starts 7.25 + 2.10 from the pin end, centred across
oled_va_x    = 7.25 + 2.10;
oled_aa      = [51.18, 12.78];   // active (pixel) area, 1 mm inside the visible area
oled_va_dx   = oled_va_x + oled_va[0] / 2 - oled_pcb[0] / 2;   // -1.82: visible area's centre, off the board's

// --- Logitech C920X, housing partly stripped (photos: cam_front.jpg, cam_top.jpg) ---
// Seen from above it is a lozenge: flat glossy front face, rounded back, rounded ends
// (the mic grilles) with a small notch where each grille meets the face.
cam_w        = 94;               // width, along the tilt axis (measured)
cam_h        = 29;               // height (measured)
cam_d        = 24.1;             // depth front-to-back at the middle (measured)
cam_face_l   = 63.5;             // flat front face length between the notches (measured)
cam_cable_x  = 31.6;             // cable centre from the nearest end: measured 30, moved 1.6 mm inward over two fit tests
cam_cable_d  = 3.0;              // cable diameter (measured); USB-A plug on the end, so it can't thread through holes
cam_core     = [cam_w, cam_d, cam_h];

// --- E32R40T 4" display board - TODO: measure outline, holes, connector positions --
lcd_board    = [110, 70, 12];    // EST placeholder
