import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../oclean_protocol.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('oclean_sessions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE brushing_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL UNIQUE,
        scheme_id INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        valid_duration_seconds INTEGER NOT NULL,
        score INTEGER NOT NULL,
        upper_left_out INTEGER NOT NULL,
        upper_left_in INTEGER NOT NULL,
        lower_left_out INTEGER NOT NULL,
        lower_left_in INTEGER NOT NULL,
        upper_right_out INTEGER NOT NULL,
        upper_right_in INTEGER NOT NULL,
        lower_right_out INTEGER NOT NULL,
        lower_right_in INTEGER NOT NULL,
        pressure_ratio TEXT NOT NULL,
        gesture_code INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE device_metrics (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        battery_level INTEGER NOT NULL,
        brush_head_used_days INTEGER NOT NULL,
        brush_head_used_times INTEGER NOT NULL,
        brush_head_max_days INTEGER NOT NULL,
        last_synced_at TEXT NOT NULL
      )
    ''');
  }

  /// Speichert eine geparste Sitzung ab. Verhindert Duplikate via UNIQUE auf `timestamp`.
  Future<int> insertSession(BrushingSession session) async {
    final db = await instance.database;

    final zones = session.toothZonePressures.length >= 8
        ? session.toothZonePressures
        : List<int>.filled(8, 0);

    final row = {
      'timestamp': session.timestamp.toIso8601String(),
      'scheme_id': session.schemeId,
      'duration_seconds': session.durationSeconds,
      'valid_duration_seconds': session.validDurationSeconds,
      'score': session.score,
      'upper_left_out': zones[0],
      'upper_left_in': zones[1],
      'lower_left_out': zones[2],
      'lower_left_in': zones[3],
      'upper_right_out': zones[4],
      'upper_right_in': zones[5],
      'lower_right_out': zones[6],
      'lower_right_in': zones[7],
      'pressure_ratio': session.pressureRatio.join(','),
      'gesture_code': session.gestureCode,
      'created_at': DateTime.now().toIso8601String(),
    };

    return await db.insert(
      'brushing_sessions',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Holt die letzten Putzsitzungen sortiert nach neuester zuerst (chronologisch absteigend)
  Future<List<BrushingSession>> getRecentSessions({
    int limit = 50,
    int minDurationSeconds = 0,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'brushing_sessions',
      where: minDurationSeconds > 0 ? 'duration_seconds >= ?' : null,
      whereArgs: minDurationSeconds > 0 ? [minDurationSeconds] : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    final list = result.map((row) {
      final zones = [
        row['upper_left_out'] as int,
        row['upper_left_in'] as int,
        row['lower_left_out'] as int,
        row['lower_left_in'] as int,
        row['upper_right_out'] as int,
        row['upper_right_in'] as int,
        row['lower_right_out'] as int,
        row['lower_right_in'] as int,
      ];

      final prString = row['pressure_ratio'] as String;
      final prList = prString.isNotEmpty
          ? prString.split(',').map((e) => int.tryParse(e) ?? 0).toList()
          : <int>[];

      return BrushingSession(
        timestamp: DateTime.parse(row['timestamp'] as String),
        schemeId: row['scheme_id'] as int,
        durationSeconds: row['duration_seconds'] as int,
        validDurationSeconds: row['valid_duration_seconds'] as int,
        score: row['score'] as int,
        toothZonePressures: zones,
        pressureRatio: prList,
        gestureCode: row['gesture_code'] as int,
      );
    }).toList();

    // Deterministische Sortierung in Dart (Neueste zuerst)
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Holt die aktuellste gültige Session
  Future<BrushingSession?> getLatestSession({int minDurationSeconds = 0}) async {
    final list = await getRecentSessions(limit: 1, minDurationSeconds: minDurationSeconds);
    if (list.isNotEmpty) return list.first;
    return null;
  }

  /// Löscht eine einzelne Sitzung anhand des Zeitstempels
  Future<int> deleteSessionByTimestamp(String timestamp) async {
    final db = await instance.database;
    return await db.delete(
      'brushing_sessions',
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }

  /// Löscht alle gespeicherten Sitzungen (Reset)
  Future<void> clearAllSessions() async {
    final db = await instance.database;
    await db.delete('brushing_sessions');
  }

  /// Löscht kurze Spülvorgänge unter einem bestimmten Schwellenwert (z.B. < 15 Sekunden)
  Future<int> deleteSessionsShorterThan(int seconds) async {
    final db = await instance.database;
    return await db.delete(
      'brushing_sessions',
      where: 'duration_seconds < ?',
      whereArgs: [seconds],
    );
  }

  /// Holt alle gespeicherten Sitzungen ohne Limit (für Export & UI)
  Future<List<BrushingSession>> getAllSessions({int minDurationSeconds = 0}) async {
    return getRecentSessions(limit: 100000, minDurationSeconds: minDurationSeconds);
  }

  /// Aktualisiert Device-Status (Batterie, Bürstenkopf-Verschleiß)
  Future<void> updateDeviceMetrics({
    required int batteryLevel,
    required int headDays,
    required int headTimes,
    required int headMaxDays,
  }) async {
    final db = await instance.database;
    await db.insert(
      'device_metrics',
      {
        'id': 1,
        'battery_level': batteryLevel,
        'brush_head_used_days': headDays,
        'brush_head_used_times': headTimes,
        'brush_head_max_days': headMaxDays,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
