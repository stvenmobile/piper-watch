// Decorative lens flange: 20 mm ring around the camera lens, 11.2 mm hole (clears the lugs on the lens), 1.8 mm thick.
// Plain ring, no notches. Print flat, blue or white; fix with thin double-sided tape to the head's FRONT FACE ONLY.
// It must not touch or be glued to the lens: the C920's lens barrel moves to focus, and a glued ring held it (soft picture).
$fn = 96;
fl_od = 20; fl_id = 11.2; fl_t = 1.8;
difference() {
    cylinder(d = fl_od, h = fl_t);
    translate([0, 0, -1]) cylinder(d = fl_id, h = fl_t + 2);
}
