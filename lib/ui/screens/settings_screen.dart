import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/toothbrush_state.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../theme/xclean_theme.dart';
import '../widgets/ble_scan_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _autoBackupDays = 7;
  bool _reminderEnabled = false;
  int _morningHour = 8;
  int _morningMinute = 0;
  int _eveningHour = 21;
  int _eveningMinute = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final days = await BackupService.instance.getAutoBackupIntervalDays();
    final notif = await NotificationService.instance.loadSettings();
    if (mounted) {
      setState(() {
        _autoBackupDays = days;
        _reminderEnabled = notif['enabled'] as bool;
        _morningHour = notif['morning_hour'] as int;
        _morningMinute = notif['morning_minute'] as int;
        _eveningHour = notif['evening_hour'] as int;
        _eveningMinute = notif['evening_minute'] as int;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    await NotificationService.instance.saveSettings(
      enabled: _reminderEnabled,
      morningHour: _morningHour,
      morningMinute: _morningMinute,
      eveningHour: _eveningHour,
      eveningMinute: _eveningMinute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ToothbrushState>();

    return Scaffold(
      backgroundColor: XCleanTheme.background,
      appBar: AppBar(
        title: const Text(
          "EINSTELLUNGEN",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: XCleanTheme.textLight,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          // 0. FAVORIT & AUTO-CONNECT
          _buildSectionHeader("FAVORITEN-ZAHNBÜRSTE & AUTO-CONNECT"),
          Container(
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: state.hasFavorite ? Colors.amber.withValues(alpha: 0.4) : XCleanTheme.border,
              ),
            ),
            child: Column(
              children: [
                if (state.hasFavorite) ...[
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.black, size: 22),
                    ),
                    title: Text(
                      state.favoriteDeviceName ?? "Oclean X Elite",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber),
                    ),
                    subtitle: Text(
                      "${state.favoriteDeviceId} • Favorit aktiv",
                      style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: XCleanTheme.coral),
                      tooltip: "Favorit entfernen",
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        state.removeFavoriteDevice();
                      },
                    ),
                  ),
                  const Divider(color: XCleanTheme.border, height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected) ? Colors.amber : null,
                    ),
                    secondary: const Icon(Icons.bolt_rounded, color: Colors.amber),
                    title: const Text("Auto-Connect beim Start", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("Verbindet sich beim Öffnen sofort mit dieser Bürste", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                    value: state.autoConnectFavorite,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      state.setAutoConnectFavorite(v);
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_border_rounded, color: XCleanTheme.textMuted, size: 20),
                    ),
                    title: const Text("Keine Favoriten-Bürste gewählt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("Tippe hier zum Scannen & tippe auf das ⭐-Symbol", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: XCleanTheme.cyan),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const BleScanSheet(),
                      );
                      state.scanAndConnect();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. ZAHNBÜRSTEN-HARDWARE & FUNKTIONEN
          _buildSectionHeader("HARDWARE & STEUERUNG"),
          Container(
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeTrackColor: XCleanTheme.cyan.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected) ? XCleanTheme.cyan : null,
                  ),
                  secondary: const Icon(Icons.screen_lock_portrait, color: XCleanTheme.cyan),
                  title: const Text("Heben zum Aufwecken", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Display aktiviert sich automatisch bei Bewegung", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  value: state.liftToWake,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    state.toggleLiftToWake(v);
                  },
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeTrackColor: XCleanTheme.coral.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected) ? XCleanTheme.coral : null,
                  ),
                  secondary: const Icon(Icons.warning_amber_rounded, color: XCleanTheme.coral),
                  title: const Text("Überdruck-Warnung", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Reduziert Motorfrequenz bei zu festem Andrücken", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  value: state.overPressure,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    state.toggleOverPressure(v);
                  },
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.timer_outlined, color: XCleanTheme.cyan),
                  title: const Text("Bürstenkopf-Lebensdauer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Empfohlener Wechsel nach ${state.brushHeadMaxDays} Tagen", style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  trailing: DropdownButton<int>(
                    value: state.brushHeadMaxDays,
                    dropdownColor: XCleanTheme.cardBg,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text("30 Tage")),
                      DropdownMenuItem(value: 60, child: Text("60 Tage")),
                      DropdownMenuItem(value: 90, child: Text("90 Tage (Standard)")),
                      DropdownMenuItem(value: 120, child: Text("120 Tage")),
                      DropdownMenuItem(value: 180, child: Text("180 Tage")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        state.setBrushHeadMaxDays(val);
                      }
                    },
                  ),
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded, color: XCleanTheme.amber),
                  title: const Text("Bürstenkopf zurücksetzen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${state.brushHeadUsedDays} Tage / ${state.brushHeadTimes} Zyklen seit Wechsel", style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  trailing: const Icon(Icons.chevron_right, color: XCleanTheme.textMuted),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _showResetHeadDialog(context, state);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. PUTZFILTER & SPÜL-ERKENNUNG
          _buildSectionHeader("PUTZFILTER & SPÜL-ERKENNUNG"),
          Container(
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.filter_alt_outlined, color: XCleanTheme.cyan),
                  title: const Text("Mindest-Putzdauer (Filter)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text(
                    "Kurze Motorläufe (z.B. Bürstenkopf-Abspülen) nicht als unvollständige Putzung werten",
                    style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted),
                  ),
                  trailing: DropdownButton<int>(
                    value: state.minValidDurationSeconds,
                    dropdownColor: XCleanTheme.cardBg,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("Aus")),
                      DropdownMenuItem(value: 10, child: Text("10 Sek.")),
                      DropdownMenuItem(value: 15, child: Text("15 Sek. (Standard)")),
                      DropdownMenuItem(value: 20, child: Text("20 Sek.")),
                      DropdownMenuItem(value: 30, child: Text("30 Sek.")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        state.setMinValidDurationSeconds(val);
                      }
                    },
                  ),
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: XCleanTheme.amber),
                  title: const Text("Alte Spülvorgänge bereinigen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    "Löscht bestehende Einträge unter ${state.minValidDurationSeconds}s aus dem Verlauf",
                    style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: XCleanTheme.textMuted),
                  onTap: () => _showCleanupRinseDialog(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. DISPLAY & TIMEOUT INFO
          _buildSectionHeader("DISPLAY & TIMEOUT"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: XCleanTheme.cyan, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Display-Standby-Timeout (~15s)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: XCleanTheme.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Die Oclean X Elite schaltet ihr Touch-Display nach ca. 15 Sekunden Inaktivität automatisch ab, um den Akku zu schonen. Dieses Verhalten ist fest in der Firmware des Microcontrollers programmiert. "
                  "Tipp: Aktiviere oben 'Heben zum Aufwecken', damit sich das Display beim Hochheben der Zahnbürste sofort einschaltet.",
                  style: TextStyle(fontSize: 12, color: XCleanTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: XCleanTheme.cardSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.deviceModelName.isNotEmpty ? state.deviceModelName : "Modell: Y2088 (X Elite)",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: XCleanTheme.cyan),
                      ),
                      Text(
                        state.firmwareVersion.isNotEmpty ? "FW: ${state.firmwareVersion}" : "FW: 1.0.0.32",
                        style: const TextStyle(fontSize: 12, color: XCleanTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. PUTZ-ERINNERUNGEN (LOKAL)
          _buildSectionHeader("PUTZ-ERINNERUNGEN (100% LOKAL)"),
          Container(
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeTrackColor: XCleanTheme.emerald.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected) ? XCleanTheme.emerald : null,
                  ),
                  secondary: const Icon(Icons.notifications_active_rounded, color: XCleanTheme.emerald),
                  title: const Text("Tägliche Putz-Erinnerungen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Erinnert morgens & abends an deine Zahnhygiene", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  value: _reminderEnabled,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    if (v) {
                      await NotificationService.instance.requestPermission();
                    }
                    setState(() => _reminderEnabled = v);
                    await _saveNotificationSettings();
                  },
                ),
                if (_reminderEnabled) ...[
                  const Divider(color: XCleanTheme.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent),
                    title: const Text("Morgen-Routine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      "${_morningHour.toString().padLeft(2, '0')}:${_morningMinute.toString().padLeft(2, '0')} Uhr",
                      style: const TextStyle(fontSize: 12, color: XCleanTheme.cyan, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: XCleanTheme.textMuted),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: _morningHour, minute: _morningMinute),
                      );
                      if (time != null) {
                        setState(() {
                          _morningHour = time.hour;
                          _morningMinute = time.minute;
                        });
                        await _saveNotificationSettings();
                      }
                    },
                  ),
                  const Divider(color: XCleanTheme.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.nightlight_round, color: Colors.indigoAccent),
                    title: const Text("Abend-Routine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      "${_eveningHour.toString().padLeft(2, '0')}:${_eveningMinute.toString().padLeft(2, '0')} Uhr",
                      style: const TextStyle(fontSize: 12, color: XCleanTheme.cyan, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: XCleanTheme.textMuted),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: _eveningHour, minute: _eveningMinute),
                      );
                      if (time != null) {
                        setState(() {
                          _eveningHour = time.hour;
                          _eveningMinute = time.minute;
                        });
                        await _saveNotificationSettings();
                      }
                    },
                  ),
                  const Divider(color: XCleanTheme.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.send_rounded, color: XCleanTheme.cyan),
                    title: const Text("Test-Benachrichtigung senden", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: XCleanTheme.cyan)),
                    subtitle: const Text("Prüft die Benachrichtigungsausgabe auf deinem Smartphone", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: XCleanTheme.cyan),
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      await NotificationService.instance.showTestNotification(streak: state.streakDays);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Test-Benachrichtigung gesendet!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. BACKUP, EXPORT & GOOGLE DRIVE
          _buildSectionHeader("AUTOMATISCHES BACKUP & GOOGLE DRIVE"),
          Container(
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule_rounded, color: XCleanTheme.cyan),
                  title: const Text("Automatischer Backup-Rhythmus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    _autoBackupDays == 0 ? "Deaktiviert" : "Alle $_autoBackupDays Tage nach Putzsitzung anfragen",
                    style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted),
                  ),
                  trailing: DropdownButton<int>(
                    value: _autoBackupDays,
                    dropdownColor: XCleanTheme.cardBg,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("Aus")),
                      DropdownMenuItem(value: 3, child: Text("Alle 3 Tage")),
                      DropdownMenuItem(value: 7, child: Text("Alle 7 Tage")),
                      DropdownMenuItem(value: 14, child: Text("Alle 14 Tage")),
                      DropdownMenuItem(value: 30, child: Text("Alle 30 Tage")),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        await BackupService.instance.setAutoBackupIntervalDays(val);
                        setState(() => _autoBackupDays = val);
                      }
                    },
                  ),
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: XCleanTheme.cyan),
                  title: const Text("Jetzt sichern (Google Drive / Export)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Als JSON in Google Drive oder Dateisystem sichern", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  trailing: const Icon(Icons.chevron_right, color: XCleanTheme.textMuted),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final ok = await BackupService.instance.exportBackup();
                    if (context.mounted && !ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Export fehlgeschlagen oder abgebrochen.")),
                      );
                    }
                  },
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: XCleanTheme.emerald),
                  title: const Text("Backup wiederherstellen (Import)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("JSON-Backup aus Drive oder Gerätespeicher laden", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  trailing: const Icon(Icons.chevron_right, color: XCleanTheme.textMuted),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    try {
                      final count = await BackupService.instance.importBackup();
                      if (!context.mounted) return;
                      if (count != null) {
                        await state.reloadHistory();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("$count Putzsitzungen erfolgreich importiert!")),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Fehler beim Import: $e")),
                      );
                    }
                  },
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: XCleanTheme.coral),
                  title: const Text("Lokalen Verlauf löschen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: XCleanTheme.coral)),
                  subtitle: const Text("Setzt die lokale SQLite-Datenbank zurück", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  onTap: () => _showClearDbDialog(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. ENTWICKLUNG & SYSTEM
          _buildSectionHeader("SYSTEM & LABOR"),
          Container(
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeTrackColor: Colors.purpleAccent.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected) ? Colors.purpleAccent : null,
                  ),
                  secondary: const Icon(Icons.science_rounded, color: Colors.purpleAccent),
                  title: const Text("Demo- & Simulationsmodus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Ermöglicht Testen aller Screens ohne Bürste", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  value: state.isDemoMode,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    state.toggleDemoMode();
                  },
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.terminal_rounded, color: XCleanTheme.cyan),
                  title: const Text("Custom Firmware (Forschung)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Dialog DA1469x ARM Cortex-M33 Status", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                  trailing: const Icon(Icons.chevron_right, color: XCleanTheme.textMuted),
                  onTap: () => _showFirmwareInfoDialog(context),
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                const ListTile(
                  leading: Icon(Icons.shield_outlined, color: XCleanTheme.emerald),
                  title: Text("100% Privacy & Open-Source", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Keine Oclean-Cloud, keine Werbung, keine Tracker", style: TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: XCleanTheme.textMuted,
        ),
      ),
    );
  }

  void _showCleanupRinseDialog(BuildContext context, ToothbrushState state) {
    final threshold = state.minValidDurationSeconds > 0 ? state.minValidDurationSeconds : 15;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: XCleanTheme.cardBg,
        title: const Text("Spülvorgänge bereinigen?"),
        content: Text(
          "Alle historischen Einträge mit weniger als $threshold Sekunden Dauer werden aus der Datenbank gelöscht. "
          "Deine echten Putzsitzungen bleiben vollständig erhalten.",
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: XCleanTheme.amber, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              final deleted = await state.cleanupRinseSessions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: XCleanTheme.cardBg,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: XCleanTheme.emerald),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "$deleted kurze Spülvorgänge erfolgreich bereinigt!",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                );
              }
            },
            child: const Text("Jetzt bereinigen", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetHeadDialog(BuildContext context, ToothbrushState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: XCleanTheme.cardBg,
        title: const Text("Bürstenkopf zurücksetzen?"),
        content: const Text(
          "Setzt den Zähler für Putzzyklen und Nutzungstage auf 0 zurück (Befehl 020F an die Bürste).",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: XCleanTheme.amber, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              state.resetBrushHead();
            },
            child: const Text("Zurücksetzen", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showClearDbDialog(BuildContext context, ToothbrushState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: XCleanTheme.cardBg,
        title: const Text("Datenbank leeren?"),
        content: const Text(
          "Möchtest du wirklich alle lokalen Putzsitzungen unwiderruflich löschen? Erstelle vorher am besten ein Backup.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: XCleanTheme.coral, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              state.clearDatabase();
            },
            child: const Text("Löschen", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFirmwareInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: XCleanTheme.cardBg,
        title: const Text("Eigene Firmware flashen?"),
        content: const Text(
          "Die Oclean X Pro Elite nutzt einen Dialog Semiconductor DA1469x BLE SoC (ARM Cortex-M33). "
          "Firmware-Binaries erfordern kryptografische Signaturen oder direkten SWD-Hardware-Zugriff via JLink an den internen Testpads. "
          "Software-OTA ohne offizielle Oclean Private-Keys würde die Bürste bricken. BLE-Befehle und Display-Wallpapers sind der sicherste Weg!",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Verstanden")),
        ],
      ),
    );
  }
}
