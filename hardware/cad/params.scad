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

// --- Tilt bearings: one in each cheek, carrying the camera pod -----------------------
// Servo side: 608ZZ (the servo only supplies torque through a misalignment-tolerant coupling).
// Cable side: 6803-2RS thin-section - its 17 mm bore takes a hollow axle the USB-A plug
// (about 12 x 4.5 mm, 12.8 mm diagonal) can pass through, so the cable needs no slot.
brg_608      = [8, 22, 7];       // [bore, outside, width]
brg_6803     = [17, 26, 5];
usb_plug     = [12.0, 4.5];      // EST: USB-A plug cross-section the hollow axle must pass

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
