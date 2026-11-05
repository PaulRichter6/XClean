library oclean_protocol;

/// Oclean X Pro Elite (OCLEANY3P) Protocol Encoders & Decoders
import 'dart:typed_data';

/// GATT UUIDs
class OcleanGattUuids {
  static const String service = "8082caa8-41a6-4021-91c6-56f9b954cc18";
  static const String writeChar = "9d84b9a3-000c-49d8-9183-855b673fbb85";
  static const String readNotifyChar = "5f78df94-798c-46f5-990a-855b673fbb86";
  static const String sendBrushCmd = "5f78df94-798c-46f5-990a-855b673fbb89";
  static const String receiveBrush = "5f78df94-798c-46f5-990a-855b673fbb90";

  static const String batteryService = "0000180f-0000-1000-8000-00805f9b34fb";
  static const String batteryChar = "00002a19-0000-1000-8000-00805f9b34fb";
  static const String disService = "0000180a-0000-1000-8000-00805f9b34fb";
  static const String disModelChar = "00002a24-0000-1000-8000-00805f9b34fb";
}

/// Commands Builder
class OcleanCommands {
  /// Build 0201 Time Calibration command (10 bytes total)
  static Uint8List buildSetClockCommand(DateTime dt, {int tzIndex = 0}) {
    final yearOffset = (dt.year >= 2000) ? (dt.year - 2000) : 0;
    // Weekday: Dart 1=Mo..7=So. Bürste: 0=So, 1=Mo..6=Sa
    final weekday = dt.weekday == 7 ? 0 : dt.weekday;

    return Uint8List.fromList([
      0x02,
      0x01,
      yearOffset,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      weekday,
      tzIndex & 0xFF,
    ]);
  }

  /// Build 020F Clear Brush Head counter command (2 bytes)
  static Uint8List buildClearBrushHeadCommand() {
    return Uint8List.fromList([0x02, 0x0F]);
  }

  /// Build 0212 Over Pressure switch command (3 bytes)
  static Uint8List buildOverPressureAlertCommand(bool enable) {
    return Uint8List.fromList([0x02, 0x12, enable ? 0x01 : 0x00]);
  }

  /// Build 0209 Lift to Wake switch command (3 bytes)
  static Uint8List buildLiftToWakeCommand(bool enable) {
    return Uint8List.fromList([0x02, 0x09, enable ? 0x01 : 0xEC]);
  }

  /// Build 020D Area Reminder switch command (3 bytes)
  static Uint8List buildAreaRemindCommand(bool enable) {
    return Uint8List.fromList([0x02, 0x0D, enable ? 0x01 : 0x00]);
  }

  /// Build 0240 Running Switch command (3 bytes)
  static Uint8List buildRunningSwitchCommand(bool enable) {
    return Uint8List.fromList([0x02, 0x40, enable ? 0x01 : 0x00]);
  }

  /// Build 0303 Query Status command (2 bytes)
  static Uint8List buildQueryStatusCommand() {
    return Uint8List.fromList([0x03, 0x03]);
  }

  /// Build 030201 Query Settings command (3 bytes)
  static Uint8List buildQuerySettingsCommand() {
    return Uint8List.fromList([0x03, 0x02, 0x01]);
  }

  /// Build 0307 Request Sessions command (2 bytes)
  static Uint8List buildQuerySessionsCommand() {
    return Uint8List.fromList([0x03, 0x07]);
  }

  /// Build 0206 Set Brush Scheme packets (handles split if > 20 bytes)
  static List<Uint8List> buildSchemePackets(int pNum, List<SchemeStep> steps) {
    if (steps.isEmpty || steps.length > 8) {
      throw ArgumentError("Scheme must have between 1 and 8 steps");
    }

    final payload = <int>[
      0x02,
      0x06,
      pNum & 0xFF,
      steps.length & 0xFF,
    ];

    for (var s in steps) {
      payload.add(s.mode & 0xFF);
      payload.add(s.gear.clamp(1, 32) & 0xFF);
      payload.add(s.durationSeconds & 0xFF);
    }

    payload.add(0x00);
    payload.add(0x05);

    if (payload.length > 20) {
      final pkt1 = List<int>.from(payload.sublist(0, 16))..addAll([0x2A, 0x2B]);
      final pkt2 = <int>[0x02, 0x0B, ...payload.sublist(16)];
      return [Uint8List.fromList(pkt1), Uint8List.fromList(pkt2)];
    } else {
      return [Uint8List.fromList(payload)];
    }
  }
}

class SchemeStep {
  final int mode;
  final int gear;
  final int durationSeconds;

  SchemeStep({
    this.mode = 1,
    required this.gear,
    required this.durationSeconds,
  });
}

/// Parsed Brushing Session from 42-Byte Record
class BrushingSession {
  final DateTime timestamp;
  final int schemeId;
  final int durationSeconds;
  final int validDurationSeconds;
  final int score;
  final List<int> toothZonePressures; // 8 regions
  final List<int> pressureRatio; // 5 classes
  final int gestureCode;

  BrushingSession({
    required this.timestamp,
    required this.schemeId,
    required this.durationSeconds,
    required this.validDurationSeconds,
    required this.score,
    required this.toothZonePressures,
    required this.pressureRatio,
    required this.gestureCode,
  });

  static const int recordSize = 42;

  factory BrushingSession.fromRecordBytes(List<int> rec) {
    if (rec.length < recordSize) {
      throw ArgumentError("Record size must be at least $recordSize bytes");
    }

    final yearBase = rec[0];
    int year = (yearBase > 0 && yearBase <= 50) ? (2000 + yearBase) : DateTime.now().year;
    int month = (rec[1] >= 1 && rec[1] <= 12) ? rec[1] : 1;
    int day = (rec[2] >= 1 && rec[2] <= 31) ? rec[2] : 1;
    int hour = (rec[3] >= 0 && rec[3] <= 23) ? rec[3] : 0;
    int minute = (rec[4] >= 0 && rec[4] <= 59) ? rec[4] : 0;
    int second = (rec[5] >= 0 && rec[5] <= 59) ? rec[5] : 0;

    DateTime dt = DateTime(year, month, day, hour, minute, second);
    // Plausibilitäts-Check: Wenn Zeitstempel unrealistisch in der Zukunft liegt, begrenzen
    if (dt.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      dt = DateTime.now();
    }

    final scheme = rec[6];
    final duration = (rec[7] << 8) | rec[8];
    final validDuration = (rec[9] << 8) | rec[10];
    final pressureRatio = rec.sublist(11, 16);
    final zones = rec.sublist(23, 31);
    final gesture = (rec[30] >> 2) & 0x03;
    final score = rec[33] == 0xFF ? 0 : rec[33];

    return BrushingSession(
      timestamp: dt,
      schemeId: scheme,
      durationSeconds: duration,
      validDurationSeconds: validDuration,
      score: score,
      toothZonePressures: zones,
      pressureRatio: pressureRatio,
      gestureCode: gesture,
    );
  }
}

/// Settings & Wear Information
class OcleanSettings {
  final int mode;
  final int headMaxDays;
  final int headUsedSeconds;
  final int headUsedDays;
  final int headUsedTimes; // blunt_teeth

  OcleanSettings({
    required this.mode,
    required this.headMaxDays,
    required this.headUsedSeconds,
    required this.headUsedDays,
    required this.headUsedTimes,
  });

  factory OcleanSettings.fromNotifyBytes(List<int> payload) {
    final mode = payload.length > 5 ? payload[5] : 0;
    int headMax = 0;
    int headUsed = 0;
    int headDays = 0;
    int headTimes = 0;

    if (payload.length >= 32) {
      headMax = (payload[25] << 8) | payload[26];
      headUsed = (payload[27] << 8) | payload[28];
      headDays = (payload[29] << 8) | payload[30];
      headTimes = payload[31];
    }

    return OcleanSettings(
      mode: mode,
      headMaxDays: headMax,
      headUsedSeconds: headUsed,
      headUsedDays: headDays,
      headUsedTimes: headTimes,
    );
  }
}
