// Fit test for the face's LED ring: just the band of the face around the ring, cut with the
// face's own cut-outs (diffuser seat, light chamber with its spokes, ring pocket), so it
// tests exactly what the face will print. Print it face-down like the face (no supports),
// together with ring_diffuser.scad.
// Check: the diffuser presses in flush from the front; the ring drops in from the back and
// sits flat on its PCB edges (not rocking on the LEDs); then light it to judge the glow.
use <head_front.scad>

r_in  = 23;      // band inner radius (inside the diffuser seat)
r_out = 37;      // band outer radius (outside the ring pocket wall)
h     = 10;      // a little deeper than the ring's back (8.7)

difference() {
    linear_extrude(h) difference() { circle(r = r_out, $fn = 180); circle(r = r_in, $fn = 180); }
    cutouts();
}
