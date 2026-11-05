import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../oclean_protocol.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  static const String _keyAutoBackupDays = 'auto_backup_days';
  static const String _keyLastAutoBackup = 'last_auto_backup';

  /// Gibt das eingestellte Intervall zurück (0 = deaktiviert, z.B. 3, 7, 14, 30 Tage)
  Future<int> getAutoBackupIntervalDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoBackupDays) ?? 7; // Default: alle 7 Tage
  }

  /// Speichert das Intervall
  Future<void> setAutoBackupIntervalDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoBackupDays, days);
  }

  /// Prüft, ob ein automatisches Backup fällig ist (beim Start oder nach dem Putzen)
  Future<bool> checkAndTriggerAutoBackupIfNeeded() async {
    final interval = await getAutoBackupIntervalDays();
    if (interval <= 0) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_keyLastAutoBackup);
    final now = DateTime.now();

    if (lastStr != null) {
      final lastDate = DateTime.tryParse(lastStr);
      if (lastDate != null && now.difference(lastDate).inDays < interval) {
        return false; // Noch nicht fällig
      }
    }

    // Exportieren und Zeitstempel festhalten
    final ok = await exportBackup();
    if (ok) {
      await prefs.setString(_keyLastAutoBackup, now.toIso8601String());
    }
    return ok;
  }

  /// Exportiert alle Sitzungen als JSON-Datei und öffnet den Teilen-/Speichern-Dialog
  /// (Erlaubt direktes Sichern auf Google Drive, Cloud, lokalen Speicher oder per Share)
  Future<bool> exportBackup() async {
    try {
      final sessions = await DatabaseHelper.instance.getAllSessions();
      final data = {
        'version': 1,
        'app': 'XClean',
        'exported_at': DateTime.now().toIso8601String(),
        'session_count': sessions.length,
        'sessions': sessions.map((s) => {
          'timestamp': s.timestamp.toIso8601String(),
          'schemeId': s.schemeId,
          'durationSeconds': s.durationSeconds,
          'validDurationSeconds': s.validDurationSeconds,
          'score': s.score,
          'toothZonePressures': s.toothZonePressures,
          'pressureRatio': s.pressureRatio,
          'gestureCode': s.gestureCode,
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final tempDir = await getTemporaryDirectory();
      final dateTag = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${tempDir.path}/xclean_backup_$dateTag.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      final xFile = XFile(filePath, mimeType: 'application/json');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'XClean Backup ($dateTag) - Zahnbürsten-Verlauf',
          subject: 'XClean Backup $dateTag',
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastAutoBackup, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Importiert Sitzungen aus einer ausgewählten JSON-Backup-Datei
  Future<int?> importBackup() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isEmpty || files.first.path == null) {
        return null; // Abbruch durch User
      }

      final file = File(files.first.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      if (!data.containsKey('sessions') || data['sessions'] is! List) {
        throw const FormatException('Ungültiges Backup-Format');
      }

      final list = data['sessions'] as List;
      int importedCount = 0;

      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final session = BrushingSession(
            timestamp: DateTime.parse(item['timestamp'] as String),
            schemeId: item['schemeId'] as int? ?? 1,
            durationSeconds: item['durationSeconds'] as int? ?? 120,
            validDurationSeconds: item['validDurationSeconds'] as int? ?? 120,
            score: item['score'] as int? ?? 80,
            toothZonePressures: (item['toothZonePressures'] as List<dynamic>?)
                    ?.map((e) => (e as num).toInt())
                    .toList() ??
                List<int>.filled(8, 0),
            pressureRatio: (item['pressureRatio'] as List<dynamic>?)
                    ?.map((e) => (e as num).toInt())
                    .toList() ??
                [],
            gestureCode: item['gestureCode'] as int? ?? 0,
          );

          final id = await DatabaseHelper.instance.insertSession(session);
          if (id > 0) {
            importedCount++;
          }
        }
      }

      return importedCount;
    } catch (e) {
      rethrow;
    }
  }
}
