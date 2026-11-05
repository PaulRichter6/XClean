import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../oclean_protocol.dart';
import '../../oclean_reassembler.dart';
import '../../database/database_helper.dart';
import 'widget_service.dart';

class ToothbrushState with ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _charWrite;
  BluetoothCharacteristic? _charReadNotify;
  BluetoothCharacteristic? _charSendBrushCmd;
  BluetoothCharacteristic? _charReceiveBrush;
  BluetoothCharacteristic? _charBattery;

  late final OcleanReassembler _reassembler;

  bool _isConnected = false;
  bool _isLoading = false;
  bool _isDemoMode = false;
  int _batteryLevel = 0;
  bool _liftToWake = true;
  bool _overPressure = true;
  int _brushHeadUsedDays = 14;
  int _brushHeadTimes = 28;
  int _brushHeadMaxDays = 90;
  int _minValidDurationSeconds = 15; // Putzvorgänge unter 15s gelten als Spülen
  String _deviceModelName = "";
  String _firmwareVersion = "";

  // Favoriten-Zahnbürste für automatischen Verbindungsaufbau
  String? _favoriteDeviceId;
  String? _favoriteDeviceName;
  bool _autoConnectFavorite = true;

  // Gefundene Geräte während des Scans
  final List<ScanResult> _discoveredDevices = [];

  BrushingSession? _latestSession;
  List<BrushingSession> _history = [];

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isDemoMode => _isDemoMode;
  int get batteryLevel => _batteryLevel;
  bool get liftToWake => _liftToWake;
  bool get overPressure => _overPressure;
  int get brushHeadUsedDays => _brushHeadUsedDays;
  int get brushHeadTimes => _brushHeadTimes;
  int get brushHeadMaxDays => _brushHeadMaxDays;
  int get minValidDurationSeconds => _minValidDurationSeconds;
  String get deviceModelName => _deviceModelName;
  String get firmwareVersion => _firmwareVersion;
  String? get favoriteDeviceId => _favoriteDeviceId;
  String? get favoriteDeviceName => _favoriteDeviceName;
  bool get autoConnectFavorite => _autoConnectFavorite;
  bool get hasFavorite => _favoriteDeviceId != null && _favoriteDeviceId!.isNotEmpty;
  List<ScanResult> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  BrushingSession? get latestSession =>
      _latestSession ??
      _history.where((s) => s.durationSeconds >= _minValidDurationSeconds).firstOrNull;

  /// Liefert nur gültige Putzvorgänge (ohne kurze Spülvorgänge < minValidDurationSeconds), absteigend sortiert
  List<BrushingSession> get history =>
      _history.where((s) => s.durationSeconds >= _minValidDurationSeconds).toList();

  /// Alle Einträge inkl. Spülvorgänge für erweiterte Ansichten
  List<BrushingSession> get allHistoryRaw => _history;

  int get streakDays {
    if (_history.isEmpty) return 0;
    final dates = _history
        .map((s) => DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    if (!dates.contains(todayDate) && !dates.contains(yesterdayDate)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(todayDate) ? todayDate : yesterdayDate;

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  ToothbrushState() {
    _reassembler = OcleanReassembler(onSessionParsed: _handleSessionParsed);
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    _brushHeadMaxDays = prefs.getInt('brush_head_max_days') ?? 90;
    _minValidDurationSeconds = prefs.getInt('min_valid_duration_seconds') ?? 15;
    _favoriteDeviceId = prefs.getString('favorite_device_id');
    _favoriteDeviceName = prefs.getString('favorite_device_name');
    _autoConnectFavorite = prefs.getBool('auto_connect_favorite') ?? true;

    // Automatische Bereinigung von alten Spülvorgängen unterhalb des Schwellenwerts
    if (_minValidDurationSeconds > 0) {
      await DatabaseHelper.instance.deleteSessionsShorterThan(_minValidDurationSeconds);
    }

    await reloadHistory();

    // Automatischer Verbindungsversuch mit Favorit bei App-Start
    if (hasFavorite && _autoConnectFavorite) {
      Future.delayed(const Duration(milliseconds: 500), () => autoConnectToFavorite());
    }
  }

  Future<void> setFavoriteDevice(String id, String name) async {
    _favoriteDeviceId = id;
    _favoriteDeviceName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_device_id', id);
    await prefs.setString('favorite_device_name', name);
    notifyListeners();
  }

  Future<void> removeFavoriteDevice() async {
    _favoriteDeviceId = null;
    _favoriteDeviceName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorite_device_id');
    await prefs.remove('favorite_device_name');
    notifyListeners();
  }

  Future<void> setAutoConnectFavorite(bool val) async {
    _autoConnectFavorite = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_connect_favorite', val);
    notifyListeners();
  }

  /// Verbindet sich gezielt mit der Favoriten-Zahnbürste
  Future<void> autoConnectToFavorite() async {
    if (!hasFavorite || _isConnected || _isLoading) return;
    debugPrint("Auto-Connect zu Favorit $_favoriteDeviceName ($_favoriteDeviceId)...");

    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        debugPrint("Bluetooth ist aus, Auto-Connect abgebrochen.");
        return;
      }
    } catch (_) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final targetId = _favoriteDeviceId!;
      final device = BluetoothDevice.fromId(targetId);

      // 1. Schneller Direktverbindungsversuch
      bool directConnected = false;
      try {
        await device.connect(autoConnect: false, timeout: const Duration(seconds: 4));
        directConnected = true;
      } catch (_) {}

      if (directConnected) {
        await _connectToDevice(device);
        return;
      }

      // 2. Schneller gezielter Scan nach der Ziel-MAC
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        androidUsesFineLocation: true,
      );

      final subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (final r in results) {
          if (r.device.remoteId.str.toUpperCase() == targetId.toUpperCase()) {
            await FlutterBluePlus.stopScan();
            await _connectToDevice(r.device);
            return;
          }
        }
      });

      await Future.delayed(const Duration(seconds: 8));
      await subscription.cancel();
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Auto-connect Fehler: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadHistory() async {
    _history = await DatabaseHelper.instance.getAllSessions(minDurationSeconds: _minValidDurationSeconds);
    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _latestSession = _history.isNotEmpty ? _history.first : null;
    _syncHomescreenWidget();
    notifyListeners();
  }

  Future<void> clearDatabase() async {
    await DatabaseHelper.instance.clearAllSessions();
    _history.clear();
    _latestSession = null;
    _syncHomescreenWidget();
    notifyListeners();
  }

  Future<void> deleteSession(BrushingSession session) async {
    await DatabaseHelper.instance.deleteSessionByTimestamp(session.timestamp.toIso8601String());
    await reloadHistory();
  }

  Future<void> setBrushHeadMaxDays(int days) async {
    _brushHeadMaxDays = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('brush_head_max_days', days);
    notifyListeners();
  }

  Future<void> setMinValidDurationSeconds(int seconds) async {
    _minValidDurationSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('min_valid_duration_seconds', seconds);
    if (seconds > 0) {
      await DatabaseHelper.instance.deleteSessionsShorterThan(seconds);
    }
    await reloadHistory();
  }

  /// Bereinigt alle historischen kurzen Einträge (< minValidDurationSeconds) aus der Datenbank
  Future<int> cleanupRinseSessions() async {
    final threshold = _minValidDurationSeconds > 0 ? _minValidDurationSeconds : 15;
    final count = await DatabaseHelper.instance.deleteSessionsShorterThan(threshold);
    await reloadHistory();
    return count;
  }

  void _handleSessionParsed(BrushingSession session) async {
    // Kurze Spülvorgänge unterhalb des Schwellenwerts ignorieren (verhindert 0%-Verfälschung)
    if (_minValidDurationSeconds > 0 && session.durationSeconds < _minValidDurationSeconds) {
      debugPrint("Spülvorgang ignoriert: ${session.durationSeconds}s < ${_minValidDurationSeconds}s");
      return;
    }
    await DatabaseHelper.instance.insertSession(session);
    await reloadHistory();
  }

  void _syncHomescreenWidget() {
    final streak = streakDays;
    final score = _latestSession?.score ?? 0;
    final timeStr = _latestSession != null
        ? "${_latestSession!.timestamp.day}.${_latestSession!.timestamp.month}. ${_latestSession!.timestamp.hour.toString().padLeft(2, '0')}:${_latestSession!.timestamp.minute.toString().padLeft(2, '0')}"
        : "";
    WidgetService.update(
      streak: streak,
      score: score,
      battery: _batteryLevel,
      lastTime: timeStr,
    );
  }

  void toggleDemoMode() {
    setDemoMode(!_isDemoMode);
  }

  void setDemoMode(bool enable) {
    _isDemoMode = enable;
    if (_isDemoMode) {
      _isConnected = false;
      _batteryLevel = 88;
      _brushHeadUsedDays = 14;
      _brushHeadTimes = 28;
    }
    notifyListeners();
  }

  /// Generiert eine realistische 42-Byte Mock-Session wie von einer echten Oclean X Pro Elite
  void simulateIncomingSession() {
    final rand = math.Random();
    final mockRecord = List<int>.filled(42, 0);

    final now = DateTime.now();
    mockRecord[0] = (now.year - 2000) & 0xFF;
    mockRecord[1] = now.month & 0xFF;
    mockRecord[2] = now.day & 0xFF;
    mockRecord[3] = now.hour & 0xFF;
    mockRecord[4] = now.minute & 0xFF;
    mockRecord[5] = now.second & 0xFF;

    final durationSec = 120 + rand.nextInt(30);
    final validSec = durationSec - rand.nextInt(10);

    mockRecord[6] = 0x01; // Clean Mode
    mockRecord[7] = (durationSec >> 8) & 0xFF;
    mockRecord[8] = durationSec & 0xFF;
    mockRecord[9] = (validSec >> 8) & 0xFF;
    mockRecord[10] = validSec & 0xFF;

    int score = 70 + rand.nextInt(30);
    for (int i = 0; i < 8; i++) {
      int zoneSec = 10 + rand.nextInt(15);
      mockRecord[23 + i] = zoneSec;
    }

    mockRecord[33] = score;

    final session = BrushingSession.fromRecordBytes(mockRecord);
    _handleSessionParsed(session);
  }

  /// Prüft, ob ein Scan-Result zu einer Oclean-Zahnbürste gehört
  bool isOcleanDevice(ScanResult r) {
    final advName = (r.advertisementData.advName).toUpperCase();
    final devName = (r.device.platformName).toUpperCase();

    // 1. Namen-Match (offizielle Oclean Präfixe & Modellnummern)
    final prefixes = [
      "OCLEAN", "Y2088", "Y3P", "Y3", "Y2", "Y5", "V20", "X20", "V1", "A1", "Z1", "ELITE"
    ];
    for (var p in prefixes) {
      if (advName.contains(p) || devName.contains(p)) return true;
    }

    // 2. Service UUID Match (falls beworben)
    for (var u in r.advertisementData.serviceUuids) {
      final s = u.str128.toLowerCase();
      if (s == OcleanGattUuids.service.toLowerCase() ||
          s.startsWith("8082caa8") ||
          s.startsWith("00007000") ||
          s.startsWith("0000aaaa") ||
          s.startsWith("0000ffff")) {
        return true;
      }
    }

    // 3. Manufacturer Data Match (Oclean Vendor IDs)
    if (r.advertisementData.manufacturerData.isNotEmpty) {
      return advName.isNotEmpty || devName.isNotEmpty;
    }

    return false;
  }

  /// Startet den Scan nach Oclean-Bürsten (ohne blockierenden Service-Filter)
  Future<void> scanAndConnect({BluetoothDevice? targetDevice}) async {
    if (targetDevice != null) {
      await _connectToDevice(targetDevice);
      return;
    }

    _isLoading = true;
    _discoveredDevices.clear();
    notifyListeners();

    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        debugPrint("Bluetooth ist ausgeschaltet!");
        _isLoading = false;
        notifyListeners();
        return;
      }

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 12),
        androidUsesFineLocation: true,
      );

      final subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (final r in results) {
          if (!_discoveredDevices.any((d) => d.device.remoteId == r.device.remoteId)) {
            _discoveredDevices.add(r);
            notifyListeners();
          }

          // Auto-Connect beim ersten eindeutigen Oclean-Treffer
          if (isOcleanDevice(r) && !_isConnected) {
            await FlutterBluePlus.stopScan();
            await _connectToDevice(r.device);
            return;
          }
        }
      });

      await Future.delayed(const Duration(seconds: 12));
      await subscription.cancel();
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Scan error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _isLoading = true;
    notifyListeners();
    try {
      await FlutterBluePlus.stopScan();
      await _connectToDevice(device);
    } catch (e) {
      debugPrint("Connection error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _device = device;
    debugPrint("Verbinde mit ${device.platformName} (${device.remoteId})...");
    await device.connect(autoConnect: false, timeout: const Duration(seconds: 15));
    _isConnected = true;
    _isDemoMode = false;
    notifyListeners();

    // Listener für automatische Erkennung von Verbindungsabbruch
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint("Gerät getrennt: ${device.remoteId}");
        _isConnected = false;
        _device = null;
        _charWrite = null;
        _charReadNotify = null;
        _charSendBrushCmd = null;
        _charReceiveBrush = null;
        _charBattery = null;
        notifyListeners();
      }
    });

    await Future.delayed(const Duration(milliseconds: 800));
    final services = await device.discoverServices();
    debugPrint("GATT Services gefunden: ${services.length}");

    for (var s in services) {
      final sUuid = s.uuid.str128.toLowerCase();
      debugPrint("Service: $sUuid");

      if (sUuid == OcleanGattUuids.service.toLowerCase() || sUuid.startsWith("8082caa8")) {
        for (var c in s.characteristics) {
          final cUuid = c.uuid.str128.toLowerCase();
          if (cUuid == OcleanGattUuids.writeChar.toLowerCase()) _charWrite = c;
          if (cUuid == OcleanGattUuids.readNotifyChar.toLowerCase()) _charReadNotify = c;
          if (cUuid == OcleanGattUuids.sendBrushCmd.toLowerCase()) _charSendBrushCmd = c;
          if (cUuid == OcleanGattUuids.receiveBrush.toLowerCase()) _charReceiveBrush = c;
        }
      } else if (sUuid == OcleanGattUuids.batteryService.toLowerCase() || sUuid.contains("180f")) {
        for (var c in s.characteristics) {
          if (c.uuid.str128.toLowerCase().contains("2a19")) _charBattery = c;
        }
      } else if (sUuid == OcleanGattUuids.disService.toLowerCase() || sUuid.contains("180a")) {
        for (var c in s.characteristics) {
          final cUuid = c.uuid.str128.toLowerCase();
          if (cUuid.contains("2a24")) {
            try {
              final val = await c.read();
              _deviceModelName = String.fromCharCodes(val).trim();
              debugPrint("Oclean Modell: $_deviceModelName");
            } catch (_) {}
          } else if (cUuid.contains("2a26")) {
            try {
              final val = await c.read();
              _firmwareVersion = String.fromCharCodes(val).trim();
              debugPrint("Oclean Firmware: $_firmwareVersion");
            } catch (_) {}
          }
        }
      }
    }

    if (_charReadNotify != null) {
      await _charReadNotify!.setNotifyValue(true);
      _charReadNotify!.onValueReceived.listen(_onReadNotifyData);
    }

    if (_charReceiveBrush != null) {
      await _charReceiveBrush!.setNotifyValue(true);
      _charReceiveBrush!.onValueReceived.listen((data) => _reassembler.handlePacket(data));
    }

    // Auto-Poll
    await fetchBatteryLevel();
    await syncTime();
    await requestSessions();
  }

  void _onReadNotifyData(List<int> data) {
    if (data.length >= 2 && data[0] == 0x03 && data[1] == 0x02) {
      final s = OcleanSettings.fromNotifyBytes(data);
      _brushHeadUsedDays = s.headUsedDays;
      _brushHeadTimes = s.headUsedTimes;
      notifyListeners();
    }
  }

  Future<void> fetchBatteryLevel() async {
    if (_isDemoMode) {
      _batteryLevel = 88;
      notifyListeners();
      return;
    }
    if (_charBattery != null) {
      try {
        final val = await _charBattery!.read();
        if (val.isNotEmpty) {
          _batteryLevel = val[0];
          _syncHomescreenWidget();
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Batterie-Fehler: $e");
      }
    }
  }

  Future<void> syncTime() async {
    if (_isDemoMode) return;
    if (_charWrite != null) {
      final cmd = OcleanCommands.buildSetClockCommand(DateTime.now());
      await _charWrite!.write(cmd, withoutResponse: false);
    }
  }

  Future<void> requestSessions() async {
    if (_isDemoMode) {
      simulateIncomingSession();
      return;
    }
    if (_charSendBrushCmd != null) {
      _reassembler.reset();
      await _charSendBrushCmd!.write(OcleanCommands.buildQuerySessionsCommand(), withoutResponse: false);
      Future.delayed(const Duration(seconds: 5), () => _reassembler.flush());
    }
  }

  Future<void> resetBrushHead() async {
    if (_isDemoMode) {
      _brushHeadTimes = 0;
      _brushHeadUsedDays = 0;
      notifyListeners();
      return;
    }
    if (_charWrite != null) {
      await _charWrite!.write(OcleanCommands.buildClearBrushHeadCommand(), withoutResponse: false);
      _brushHeadTimes = 0;
      _brushHeadUsedDays = 0;
      notifyListeners();
    }
  }

  Future<void> toggleLiftToWake(bool val) async {
    _liftToWake = val;
    notifyListeners();
    if (_isDemoMode) return;
    if (_charWrite != null) {
      await _charWrite!.write(OcleanCommands.buildLiftToWakeCommand(val), withoutResponse: false);
    }
  }

  Future<void> toggleOverPressure(bool val) async {
    _overPressure = val;
    notifyListeners();
    if (_isDemoMode) return;
    if (_charWrite != null) {
      await _charWrite!.write(OcleanCommands.buildOverPressureAlertCommand(val), withoutResponse: false);
    }
  }

  Future<void> setBrushScheme(int modeId, List<SchemeStep> steps) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    if (_charWrite != null) {
      final packets = OcleanCommands.buildSchemePackets(modeId, steps);
      for (var pkt in packets) {
        await _charWrite!.write(pkt, withoutResponse: false);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  Future<void> disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
      _device = null;
    }
    _isConnected = false;
    _charWrite = null;
    _charReadNotify = null;
    _charSendBrushCmd = null;
    _charReceiveBrush = null;
    _charBattery = null;
    notifyListeners();
  }
}
