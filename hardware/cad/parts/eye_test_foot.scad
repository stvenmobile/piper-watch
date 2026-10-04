// Desk foot for eye_test_stand.scad: a weighted base with a socket the stand's stem plugs into,
// tilted back so the eye looks up 10 deg (a seated person at a desk). Print flat, no supports.
include <../params.scad>

stem     = [16, 16];            // the stand's stem cross-section
fit      = 0.3;                 // each side: snug push fit
tilt     = 10;                  // eye looks up this much
base     = [80, 70, 5];
sock_h   = 22;                  // socket depth along the stem
block    = [stem[0] + 2 * fit + 6, stem[1] + 2 * fit + 6];

difference() {
    union() {
        translate([-base[0] / 2, -base[1] / 2, 0]) cube(base);
        // socket block, leaning back by `tilt`
        hull() {
            translate([-block[0] / 2, -block[1] / 2, 0]) cube([block[0], block[1], 1]);
            rotate([-tilt, 0, 0]) translate([-block[0] / 2, -block[1] / 2, sock_h]) cube([block[0], block[1], 1]);
        }
    }
    // the socket (open at the top, along the tilted axis)
    rotate([-tilt, 0, 0]) translate([-(stem[0] / 2 + fit), -(stem[1] / 2 + fit), 3])
        cube([stem[0] + 2 * fit, stem[1] + 2 * fit, sock_h + 10]);
}
