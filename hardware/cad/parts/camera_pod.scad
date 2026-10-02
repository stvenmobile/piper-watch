// Camera pod - holds the stripped C920X and tilts between the two cheeks.
//
// Built the "Fusion way": draw the camera's outline seen from above (2D), then
// extrude it upward. The same outline, grown with offset(), gives the cavity
// (camera + clearance) and the outer shell (cavity + wall).
//
// Coordinates: the camera looks toward -Y. Its flat front face lies on y = 0,
// its back reaches y = cam_d, it sits on z = 0, and it is centred on x = 0.
// The tilt axis runs along X through the middle of the camera (see `axis`).
//
// This file makes the BODY (floor + walls + pivots). The lid is
// parts/camera_pod_lid.scad, which reuses the modules below.
include <../params.scad>

fit     = 0.4;            // clearance between camera and cavity, all round
lip_h   = 3;              // height of the lid's locating lip inside the cavity
end_r   = 8;              // EST: radius of the camera's rounded ends (mic grilles)
end_y   = 15;             // EST: depth position of those end circles' centres
back_a  = 33;             // EST: half-length of the back curve (smaller = rounder back)

axis    = [0, cam_d / 2, cam_h / 2];   // tilt axis passes through this point, along X

// Pivots: 's' = servo side (-X), 'o' = idler side (+X)
horn_d     = sts_horn_d;  // boss the servo horn screws onto
horn_hole  = 3.2;         // EST centre hole; horn screw pattern to be added when measured
axle_od    = 12;          // idler axle, rides in a bearing/bushing in the cheek
axle_id    = 5;           // bore for the cable
axle_slot  = cam_cable_d + 0.4;   // slot so the cable slides in sideways (the USB plug can't pass)
pivot_len  = 6;           // how far each pivot sticks out of the end wall

// ---- 2D: the camera's outline seen from above -------------------------------------
// hull() wraps a rubber band around its children - like sketching tangent arcs:
//   * a thin strip for the flat front face
//   * a circle at each rounded end
//   * the back half of an ellipse for the curved back
// (The small notches where the grilles meet the face are inside the hull, so the
//  pod just has a little extra room there.)
module cam_outline() {
    hull() {
        translate([-cam_face_l / 2, 0]) square([cam_face_l, 0.01]);
        for (sx = [-1, 1])
            translate([sx * (cam_w / 2 - end_r), end_y]) circle(r = end_r);
        intersection() {                                  // back half of an ellipse
            scale([back_a / cam_d, 1]) circle(r = cam_d, $fn = 180);
            translate([-cam_w, 0]) square([2 * cam_w, cam_d]);
        }
    }
}

// The same outline grown outward: + fit = cavity, + fit + wall = outer shell
module cavity_outline() { offset(r = fit) cam_outline(); }
module shell_outline()  { offset(r = fit + wall) cam_outline(); }

// Cavity height: the rim ends about flush with the camera's top (fit test: the first
// print was 4 mm taller than needed). The lid is a cap that fits OUTSIDE the rim.
cavity_h = cam_h + 2 * fit + lip_h - 4;

// ---- 3D: body = shell extruded, minus cavity, minus windows ----------------------
module pod_body() {
    difference() {
        union() {
            // floor + walls: extrude the shell outline from below the floor to the top
            translate([0, 0, -fit - wall])
                linear_extrude(height = wall + cavity_h) shell_outline();
            pivots();
        }
        // the cavity, open at the top (the lid closes it)
        translate([0, 0, -fit]) linear_extrude(height = cavity_h + 1) cavity_outline();

        // front window: shows the glossy face and lens, keeps a rim all round
        // (top edge kept ~3.4 mm below the lowered rim so the strip above it stays sturdy)
        translate([-cam_face_l / 2 + 3, -10, 2]) cube([cam_face_l - 6, 20, cam_h - 6]);

        // cable exit in the back wall, 30 mm from the idler-side (+X) end: a slot open
        // to the top, so the cable (plug still attached) drops in from above
        translate([cam_w / 2 - cam_cable_x, cam_d - 2, 0])
            hull() for (z = [cam_h / 2 - 4, cavity_h + 1])   // 4 mm deeper after the fit test
                translate([0, 0, z]) rotate([-90, 0, 0]) cylinder(d = cam_cable_d + 0.6, h = 10);

        // bores through the pivots
        // servo-side centre hole, through the horn boss and its end wall
        translate(axis) rotate([0, -90, 0])
            translate([0, 0, cam_w / 2 - 1]) cylinder(d = horn_hole, h = fit + wall + pivot_len + 2);
        translate(axis) rotate([0, 90, 0]) idler_bore();
    }
}

// Pivots sit on the tilt axis, sticking out of each end wall
module pivots() {
    end_x = cam_w / 2 + fit + wall;          // outside face of the end walls
    translate(axis) rotate([0, 90, 0]) {
        // 's' servo side: a disc the horn screws onto
        translate([0, 0, -end_x - pivot_len]) cylinder(d = horn_d, h = pivot_len + wall);
        // 'o' idler side: an axle
        translate([0, 0, end_x - wall]) cylinder(d = axle_od, h = pivot_len + wall);
    }
}

// Idler axle bore + slot (in the axle's own frame: axle along +Z). Only the
// protruding axle is hollowed: the slot lets the cable be laid in sideways later,
// when the cheek's cable route is designed. The end wall itself stays solid.
module idler_bore() {
    end_x = cam_w / 2 + fit + wall;
    translate([0, 0, end_x]) {
        cylinder(d = axle_id, h = pivot_len + 1);
        translate([0, -axle_slot / 2, 0]) cube([axle_od, axle_slot, pivot_len + 1]);
    }
}

// ---- Lid: a cap - flat plate plus a short skirt that fits around the OUTSIDE of the
// rim (the rim is flush with the camera's top, so there is no room for an inside lip).
lid_t     = wall;               // plate thickness
skirt_h   = 3;                  // how far the skirt reaches down the outside of the pod
skirt_w   = 1.2;                // skirt wall thickness
skirt_clr = 0.2;                // gap between skirt and pod wall (friction fit)

module pod_lid() {              // modelled upside down, i.e. as printed: plate on the bed
    linear_extrude(height = lid_t)
        offset(delta = skirt_clr + skirt_w) shell_outline();
    translate([0, 0, lid_t]) linear_extrude(height = skirt_h)
        difference() {
            offset(delta = skirt_clr + skirt_w) shell_outline();
            offset(delta = skirt_clr) shell_outline();
        }
}

pod_body();

// Ghost of the camera block for reference (not part of the model) - remove the % to hide
%linear_extrude(height = cam_h) cam_outline();
