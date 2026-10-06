// Camera bracket for eye_test_stand.scad: a shallow U-channel that straps the C920 board to the
// back of the stand at its middle, with two M3 screws into heat-set inserts (one above the board,
// one below). Replaces the snap tabs. Dimensions: eye_cam_bracket_dims.scad.
//
// PRINT as modelled: feet on the bed; the bridge (~24 mm) bridges, no supports.
include <../params.scad>
include <eye_cam_bracket_dims.scad>

cam_bracket();
