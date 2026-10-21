#!/usr/bin/env python3
"""Find servos on the bus and print their settings. Reads only - sends no movement commands."""
import sys

from sts import (ADDR_ID, ADDR_MAX_ANGLE, ADDR_MIN_ANGLE, ADDR_MODE, ADDR_TORQUE, Bus, pos_to_deg)

ids = [int(a) for a in sys.argv[1:]] or range(0, 21)

bus = Bus()
try:
    found = []
    for sid in ids:
        model = bus.ping(sid)
        if model is not None:
            found.append(sid)
            s = bus.status(sid)
            lo, hi = bus.r2(sid, ADDR_MIN_ANGLE), bus.r2(sid, ADDR_MAX_ANGLE)
            print(f"ID {bus.r1(sid, ADDR_ID)}: model {model}, mode {bus.r1(sid, ADDR_MODE)}, "
                  f"torque {'on' if bus.r1(sid, ADDR_TORQUE) else 'off'}")
            print(f"  position {s['pos']} ({pos_to_deg(sid, s['pos']):+.1f} deg), "
                  f"{s['volts']:.1f} V, {s['temp']} C, load {s['load%']:.1f} %")
            print(f"  angle limits {lo}..{hi}")
    if not found:
        print(f"no servo answered on IDs {ids[0]}..{ids[-1]}")
finally:
    bus.close()
