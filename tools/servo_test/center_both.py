#!/usr/bin/env python3
"""Put BOTH servos at their centre (raw 2048) and hold them there, before anything is attached.

usage: py centre_both.py              clear both servos' stored angle limits, then move both to centre and hold
       py centre_both.py --keep-limits   move to centre without touching the stored limits
       py centre_both.py --release       torque off on both (they turn freely)

For the first assembly of the pan stack and the tilt linkage (run book, step 3): run it with NOTHING attached
to either horn, leave the servos powered (they keep holding after the script ends), then
  - pan: turn the hub / turret so the head faces front and screw the hub to the pan horn;
  - tilt: fit the crank so it points up, leaning about 15 deg forward (its position with the head level).
    The crank's 4 holes (90 deg apart) and the horn's 25-tooth spline (14.4 deg) together give 3.6 deg steps:
    lift the horn off its spline and refit it a tooth over to get close.
Then fine-tune the centre with centre_here.py (torque off, head held level and facing front) and set new tilt
limits (LIMITS in sts.py, then set_limits.py 2).

Why the limits are cleared: the tilt servo still has the old test stand's limits (servo -70 .. +6.3 deg) stored
in it, which would stop the new linkage from tilting the head up. Until new limits are set, the servo will
go anywhere it's told: keep moves small and watch for contact.
"""
import argparse
import time

from sts import ADDR_LOCK, ADDR_MAX_ANGLE, ADDR_MIN_ANGLE, ADDR_POS, CENTRE, Bus

IDS = {1: "pan", 2: "tilt"}

ap = argparse.ArgumentParser()
ap.add_argument("--keep-limits", action="store_true", help="don't clear the servos' stored angle limits")
ap.add_argument("--release", action="store_true", help="torque off on both servos and exit")
ap.add_argument("--speed", type=int, default=200, help="steps/s (200 = ~18 deg/s)")
ap.add_argument("--acc", type=int, default=10)
args = ap.parse_args()


def eeprom(write, *a):
    """EEPROM writes: the servo can miss a command (or not answer) while it saves the last one."""
    for attempt in range(5):
        try:
            write(*a)
            break
        except (IOError, IndexError):
            pass
        time.sleep(0.2)
    time.sleep(0.2)


bus = Bus()
try:
    found = [sid for sid in IDS if bus.ping(sid) is not None]
    for sid in IDS:
        if sid not in found:
            print(f"ID {sid} ({IDS[sid]}): no answer - check its plug and the 12 V (py ping.py)")
    if args.release:
        for sid in found:
            bus.torque(sid, False)
            print(f"ID {sid} ({IDS[sid]}): torque off")
    else:
        for sid in found:
            if not args.keep_limits:
                eeprom(bus.w1, sid, ADDR_LOCK, 0)
                eeprom(bus.w2, sid, ADDR_MIN_ANGLE, 0)
                eeprom(bus.w2, sid, ADDR_MAX_ANGLE, 4095)
                eeprom(bus.w1, sid, ADDR_LOCK, 1)
            lo, hi = bus.r2(sid, ADDR_MIN_ANGLE), bus.r2(sid, ADDR_MAX_ANGLE)
            print(f"ID {sid} ({IDS[sid]}): at {bus.r2(sid, ADDR_POS)}, limits {lo}..{hi} (raw)")
        for sid in found:
            bus.torque(sid, True)
            bus.goto(sid, CENTRE, args.speed, args.acc)
        t0 = time.time()
        time.sleep(0.3)
        while any(bus.status(sid)["moving"] for sid in found) and time.time() - t0 < 30:
            time.sleep(0.05)
        for sid in found:
            s = bus.status(sid)
            print(f"ID {sid} ({IDS[sid]}): at {s['pos']} (centre {CENTRE}), holding, load {s['load%']:+.1f} %")
        if found:
            print("Both stay at centre while powered. Afterwards: py centre_both.py --release")
finally:
    bus.close()
