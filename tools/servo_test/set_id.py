#!/usr/bin/env python3
"""Change a servo's ID (stored in the servo). Connect ONLY that servo to the bus. Does not move it.

usage: py set_id.py OLD NEW          e.g.  py set_id.py 1 2
"""
import sys
import time

from sts import ADDR_ID, ADDR_LOCK, Bus

old, new = int(sys.argv[1]), int(sys.argv[2])
bus = Bus()
try:
    if bus.ping(old) is None:
        sys.exit(f"no servo answers as ID {old}")
    if bus.ping(new) is not None:
        sys.exit(f"ID {new} is already on the bus")
    bus.w1(old, ADDR_LOCK, 0)
    bus.w1(old, ADDR_ID, new)          # from here it answers as `new`
    time.sleep(0.1)
    bus.w1(new, ADDR_LOCK, 1)
    print(f"ID {old} -> {new}:", "OK" if bus.ping(new) is not None else "FAILED - no answer on the new ID")
finally:
    bus.close()
