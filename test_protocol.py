"""
Python-basierte Referenz-Implementierung und Test-Suite für das
Oclean X Pro Elite (OCLEANY3P) Type-1 BLE Protokoll.
"""

import datetime
from typing import List, Dict, Any, Optional

OCLEAN_SERVICE_UUID = "8082caa8-41a6-4021-91c6-56f9b954cc18"
WRITE_CHAR_UUID = "9d84b9a3-000c-49d8-9183-855b673fbb85"
READ_NOTIFY_CHAR_UUID = "5f78df94-798c-46f5-990a-855b673fbb86"
SEND_BRUSH_CMD_UUID = "5f78df94-798c-46f5-990a-855b673fbb89"
RECEIVE_BRUSH_UUID = "5f78df94-798c-46f5-990a-855b673fbb90"

BATTERY_CHAR_UUID = "00002a19-0000-1000-8000-00805f9b34fb"

TOOTH_ZONE_NAMES = [
    "upper_left_out",
    "upper_left_in",
    "lower_left_out",
    "lower_left_in",
    "upper_right_out",
    "upper_right_in",
    "lower_right_out",
    "lower_right_in",
]


def build_set_clock_command(dt: datetime.datetime, tz_index: int = 0) -> bytes:
    year_byte = (dt.year - 2000) if dt.year >= 2000 else 0
    # Python weekday(): 0=Mo..6=So. Oclean weekday: 0=So, 1=Mo..6=Sa
    weekday = (dt.weekday() + 1) % 7
    return bytes([0x02, 0x01, year_byte, dt.month, dt.day, dt.hour, dt.minute, dt.second, weekday, tz_index])


def build_clear_brush_head_command() -> bytes:
    return bytes([0x02, 0x0F])


def build_over_pressure_alert_command(enable: bool) -> bytes:
    return bytes([0x02, 0x12, 0x01 if enable else 0x00])


def build_lift_to_wake_command(enable: bool) -> bytes:
    return bytes([0x02, 0x09, 0x01 if enable else 0xEC])


def parse_session_record(record: bytes) -> Dict[str, Any]:
    if len(record) < 42:
        raise ValueError(f"Record length {len(record)} < 42")

    year_byte = record[0]
    year = datetime.datetime.now().year if year_byte == 0 else (2000 + year_byte)
    month = 1 if record[1] == 0 else record[1]
    day = 1 if record[2] == 0 else record[2]
    dt = datetime.datetime(year, month, day, record[3], record[4], record[5])

    scheme = record[6]
    duration = (record[7] << 8) | record[8]
    valid_duration = (record[9] << 8) | record[10]
    pressure_ratio = list(record[11:16])
    zones = list(record[23:31])
    gesture_code = (record[30] >> 2) & 0x03
    score = 0 if record[33] == 0xFF else record[33]

    zone_dict = {name: zones[i] for i, name in enumerate(TOOTH_ZONE_NAMES)}

    return {
        "timestamp": dt.isoformat(),
        "scheme": scheme,
        "duration_seconds": duration,
        "valid_duration_seconds": valid_duration,
        "score": score,
        "pressure_ratio": pressure_ratio,
        "zones": zone_dict,
        "gesture_code": gesture_code,
    }


class OcleanReassembler:
    def __init__(self):
        self.buffer = bytearray()
        self.expected_bytes = 0
        self.in_progress = False
        self.completed_sessions: List[Dict[str, Any]] = []

    def handle_packet(self, packet: bytes):
        if len(packet) >= 7 and packet[0:2] == b"\x03\x07" and packet[2:5] == b"\x2a\x42\x23":
            count = (packet[5] << 8) | packet[6]
            if count > 0:
                self.expected_bytes = count * 42
                self.buffer.clear()
                self.in_progress = True
                if len(packet) > 7:
                    self.buffer.extend(packet[7:])
                self._check()
            return

        if self.in_progress:
            self.buffer.extend(packet)
            self._check()

    def _check(self):
        if len(self.buffer) >= self.expected_bytes and self.expected_bytes > 0:
            self.flush()

    def flush(self):
        count = len(self.buffer) // 42
        for i in range(count):
            rec = bytes(self.buffer[i * 42 : (i + 1) * 42])
            self.completed_sessions.append(parse_session_record(rec))
        self.buffer = self.buffer[count * 42 :]
        self.in_progress = False


def run_tests():
    print("[*] Running Oclean X Pro Elite Protocol Tests...")

    # 1. Test Time Sync Command
    test_dt = datetime.datetime(2026, 10, 31, 18, 30, 0)  # Samstag
    cmd_time = build_set_clock_command(test_dt, 0)
    expected_time = bytes([0x02, 0x01, 26, 10, 31, 18, 30, 0, 6, 0])
    assert cmd_time == expected_time, f"Time sync mismatch: {cmd_time.hex()} != {expected_time.hex()}"
    print("[+] build_set_clock_command verified:", cmd_time.hex())

    # 2. Test Feature Switches
    cmd_reset = build_clear_brush_head_command()
    assert cmd_reset == bytes([0x02, 0x0F])
    print("[+] build_clear_brush_head_command verified:", cmd_reset.hex())

    cmd_wake_on = build_lift_to_wake_command(True)
    cmd_wake_off = build_lift_to_wake_command(False)
    assert cmd_wake_on == bytes([0x02, 0x09, 0x01])
    assert cmd_wake_off == bytes([0x02, 0x09, 0xEC])
    print("[+] build_lift_to_wake_command verified: on=", cmd_wake_on.hex(), "off=", cmd_wake_off.hex())

    # 3. Test 42-Byte Record Parsing
    raw_rec = bytearray(42)
    raw_rec[0] = 26     # Year 2026
    raw_rec[1] = 10     # Month 10
    raw_rec[2] = 31     # Day 31
    raw_rec[3] = 18     # Hour
    raw_rec[4] = 45     # Min
    raw_rec[5] = 12     # Sec
    raw_rec[6] = 1      # Scheme
    raw_rec[7] = 0x00
    raw_rec[8] = 120    # 120 seconds duration
    raw_rec[9] = 0x00
    raw_rec[10] = 115   # 115 seconds valid duration
    raw_rec[11:16] = bytes([10, 20, 5, 2, 0]) # Pressure ratios
    raw_rec[23:31] = bytes([15, 12, 14, 18, 11, 13, 16, 17]) # 8 Zones
    raw_rec[33] = 94    # Score 94

    parsed = parse_session_record(bytes(raw_rec))
    assert parsed["duration_seconds"] == 120
    assert parsed["valid_duration_seconds"] == 115
    assert parsed["score"] == 94
    assert parsed["zones"]["upper_left_out"] == 15
    assert parsed["zones"]["lower_right_in"] == 17
    print("[+] parse_session_record verified:", parsed)

    # 4. Test Multi-Packet Reassembly
    reassembler = OcleanReassembler()
    # Packet 1: Header + first 13 bytes of raw_rec
    pkt1 = bytes([0x03, 0x07, 0x2A, 0x42, 0x23, 0x00, 0x01]) + raw_rec[:13]
    # Packet 2: Continuation 20 bytes
    pkt2 = raw_rec[13:33]
    # Packet 3: Continuation remaining 9 bytes
    pkt3 = raw_rec[33:42]

    reassembler.handle_packet(pkt1)
    assert reassembler.in_progress is True
    reassembler.handle_packet(pkt2)
    reassembler.handle_packet(pkt3)

    assert len(reassembler.completed_sessions) == 1
    assert reassembler.completed_sessions[0]["score"] == 94
    print("[+] *B# Multi-Packet Reassembly verified successfully across 3 packets!")
    print("[*] All tests PASSED!")

if __name__ == "__main__":
    run_tests()
