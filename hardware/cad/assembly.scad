// Piper-Watch assembly preview - bought parts placed where they'll go.
// Grows as printed parts are designed. Use F5 (preview) to look around.
include <params.scad>
use <vitamins/lazy_susan.scad>
use <vitamins/sts3215.scad>

pan_angle  = 0;     // try changing these to check clearances
tilt_angle = 0;

lazy_susan();

// Pan servo: placeholder position, under the bearing centre (direct-drive layout)
translate([0, 0, -2]) sts3215();
