import 'oclean_protocol.dart';

/// Reassembly handler for *B# multi-packet session stream
class OcleanReassembler {
  final List<int> _buffer = [];
  int _expectedBytes = 0;
  bool _inProgress = false;

  final void Function(BrushingSession session) onSessionParsed;

  OcleanReassembler({required this.onSessionParsed});

  bool get isInProgress => _inProgress;
  int get bufferedBytes => _buffer.length;
  int get expectedBytes => _expectedBytes;

  void reset() {
    _buffer.clear();
    _expectedBytes = 0;
    _inProgress = false;
  }

  /// Process an incoming BLE notification chunk from fbb90
  void handlePacket(List<int> packet) {
    if (packet.isEmpty) return;

    // Detect *B# header:
    // Packet layout: [03 07] [2A 42 23] [count_hi count_lo] [record byte 0 ...]
    if (packet.length >= 7 &&
        packet[0] == 0x03 &&
        packet[1] == 0x07 &&
        packet[2] == 0x2A &&
        packet[3] == 0x42 &&
        packet[4] == 0x23) {
      final recordCount = (packet[5] << 8) | packet[6];
      if (recordCount > 0) {
        _expectedBytes = recordCount * BrushingSession.recordSize;
        _buffer.clear();
        _inProgress = true;

        if (packet.length > 7) {
          _buffer.addAll(packet.sublist(7));
        }
        _checkCompletion();
      } else {
        // RecordCount == 0 (no unread sessions in stream mode)
        reset();
      }
      return;
    }

    // Continuation packet
    if (_inProgress) {
      _buffer.addAll(packet);
      _checkCompletion();
    }
  }

  void _checkCompletion() {
    if (_buffer.length >= _expectedBytes && _expectedBytes > 0) {
      flush();
    }
  }

  /// Flush complete records from buffer
  void flush() {
    final available = _buffer.length;
    final completeRecordsCount = available ~/ BrushingSession.recordSize;

    for (int i = 0; i < completeRecordsCount; i++) {
      final start = i * BrushingSession.recordSize;
      final end = start + BrushingSession.recordSize;
      final recordBytes = _buffer.sublist(start, end);
      try {
        final session = BrushingSession.fromRecordBytes(recordBytes);
        onSessionParsed(session);
      } catch (e) {
        // Log/skip corrupt record
      }
    }

    // Retain any partial leftover or reset
    final remainingStart = completeRecordsCount * BrushingSession.recordSize;
    if (remainingStart < _buffer.length) {
      final remaining = _buffer.sublist(remainingStart);
      _buffer.clear();
      _buffer.addAll(remaining);
      _expectedBytes = (_expectedBytes > remainingStart) ? (_expectedBytes - remainingStart) : 0;
    } else {
      reset();
    }
  }
}
