"""Minimal STS3215 bus-servo access over the Waveshare bus servo adapter (USB mode).

Register map: Feetech STS series (little-endian, protocol_end = 0).
"""
from scservo_sdk import COMM_SUCCESS, PacketHandler, PortHandler

PORT = "COM21"
BAUD = 1_000_000

# EEPROM
ADDR_MODEL = 3          # 2 bytes
ADDR_ID = 5
ADDR_MIN_ANGLE = 9      # 2 bytes
ADDR_MAX_ANGLE = 11     # 2 bytes
ADDR_MODE = 33          # 0 = position
# RAM
ADDR_TORQUE = 40
ADDR_ACC = 41
ADDR_GOAL = 42          # 6 bytes: position, time, speed
ADDR_POS = 56           # 2 bytes
ADDR_SPEED = 58         # 2 bytes, sign bit 15
ADDR_LOAD = 60          # 2 bytes, sign bit 10, 0.1 %
ADDR_VOLT = 62          # 0.1 V
ADDR_TEMP = 63          # deg C
ADDR_MOVING = 66

STEPS_PER_DEG = 4096 / 360
CENTRE = 2048
# +1 or -1 per servo ID so positive angles follow the robot convention: pan + = LEFT (counter-clockwise
# seen from above). Pan's raw positive direction turns RIGHT (checked 2026-10-21).
DIRECTION = {1: -1}


def deg_to_pos(sid, deg):
    return round(CENTRE + DIRECTION.get(sid, 1) * deg * STEPS_PER_DEG)


def pos_to_deg(sid, pos):
    return DIRECTION.get(sid, 1) * (pos - CENTRE) / STEPS_PER_DEG


def _signed(v, bit):
    return -(v & ~(1 << bit)) if v & (1 << bit) else v


class Bus:
    def __init__(self, port=PORT, baud=BAUD):
        self.port = PortHandler(port)
        self.pk = PacketHandler(0)
        if not self.port.openPort():
            raise RuntimeError(f"can't open {port}")
        if not self.port.setBaudRate(baud):
            raise RuntimeError(f"can't set {baud} baud")

    def close(self):
        self.port.closePort()

    def _check(self, res, err, what):
        if res != COMM_SUCCESS:
            raise IOError(f"{what}: {self.pk.getTxRxResult(res)}")
        if err:
            print(f"  ! {what}: {self.pk.getRxPacketError(err)}")

    def ping(self, sid):
        model, res, err = self.pk.ping(self.port, sid)
        return model if res == COMM_SUCCESS else None

    def r1(self, sid, addr):
        v, res, err = self.pk.read1ByteTxRx(self.port, sid, addr)
        self._check(res, err, f"read {addr}")
        return v

    def r2(self, sid, addr):
        v, res, err = self.pk.read2ByteTxRx(self.port, sid, addr)
        self._check(res, err, f"read {addr}")
        return v

    def w1(self, sid, addr, v):
        res, err = self.pk.write1ByteTxRx(self.port, sid, addr, v)
        self._check(res, err, f"write {addr}")

    def status(self, sid):
        return {
            "pos": self.r2(sid, ADDR_POS),
            "speed": _signed(self.r2(sid, ADDR_SPEED), 15),
            "load%": _signed(self.r2(sid, ADDR_LOAD), 10) / 10,
            "volts": self.r1(sid, ADDR_VOLT) / 10,
            "temp": self.r1(sid, ADDR_TEMP),
            "moving": self.r1(sid, ADDR_MOVING),
        }

    def torque(self, sid, on):
        self.w1(sid, ADDR_TORQUE, 1 if on else 0)

    def goto(self, sid, pos, speed, acc):
        """Position (0..4095), speed (steps/s), acceleration (x 100 steps/s^2)."""
        pos = max(0, min(4095, int(pos)))
        self.w1(sid, ADDR_ACC, acc)
        data = [pos & 0xFF, pos >> 8, 0, 0, speed & 0xFF, speed >> 8]
        res, err = self.pk.writeTxRx(self.port, sid, ADDR_GOAL, 6, data)
        self._check(res, err, "goal")
