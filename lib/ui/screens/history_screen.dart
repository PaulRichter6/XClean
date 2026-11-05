import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/toothbrush_state.dart';
import '../../oclean_protocol.dart';
import '../theme/xclean_theme.dart';
import '../widgets/tooth_3d_viewer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // 0 = Alle gültigen (>= minValid), 1 = Top (>= 80), 2 = Optimierungsbedarf (< 80), 3 = Kurze Spülungen (< minValid)
  int _selectedFilter = 0;
  BrushingSession? _inspectedSession;

  String _formatDuration(int seconds) {
    if (seconds < 60) return "${seconds}s";
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? "$m Min." : "$m:${s.toString().padLeft(2, '0')} Min.";
  }

  String _getDayTitle(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessionDate = DateTime(dt.year, dt.month, dt.day);

    if (sessionDate == today) return "HEUTE";
    if (sessionDate == yesterday) return "GESTERN";

    const germanWeekdays = [
      "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"
    ];
    const germanMonths = [
      "Januar", "Februar", "März", "April", "Mai", "Juni",
      "Juli", "August", "September", "Oktober", "November", "Dezember"
    ];

    final weekday = germanWeekdays[dt.weekday - 1];
    final month = germanMonths[dt.month - 1];
    return "$weekday, ${dt.day}. $month ${dt.year}";
  }

  String _getTimePeriod(int hour) {
    if (hour >= 5 && hour < 11) return "Morgens";
    if (hour >= 11 && hour < 14) return "Mittags";
    if (hour >= 14 && hour < 18) return "Nachmittags";
    return "Abends";
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ToothbrushState>();
    final minSeconds = state.minValidDurationSeconds;
    final rawList = state.allHistoryRaw;

    // Filter Listen aufteilen
    final validSessions = rawList.where((s) => s.durationSeconds >= minSeconds).toList();
    final rinseSessions = rawList.where((s) => s.durationSeconds < minSeconds).toList();

    // Deterministisch nach Zeit sortieren (Neueste zuerst)
    validSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    rinseSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    List<BrushingSession> displayedList;
    if (_selectedFilter == 1) {
      displayedList = validSessions.where((s) => s.score >= 80).toList();
    } else if (_selectedFilter == 2) {
      displayedList = validSessions.where((s) => s.score < 80).toList();
    } else if (_selectedFilter == 3) {
      displayedList = rinseSessions;
    } else {
      displayedList = validSessions;
    }

    // Gruppierung nach Kalendertagen
    final Map<String, List<BrushingSession>> grouped = {};
    for (final s in displayedList) {
      final key = _getDayTitle(s.timestamp);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return Scaffold(
      backgroundColor: XCleanTheme.background,
      appBar: AppBar(
        title: const Text(
          "PUTZ-HISTORIE",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: XCleanTheme.textLight,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: XCleanTheme.textMuted),
            color: XCleanTheme.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) async {
              if (val == 'clean_rinses') {
                HapticFeedback.mediumImpact();
                final count = await state.cleanupRinseSessions();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$count kurze Spülvorgänge (< ${minSeconds}s) gelöscht."),
                      backgroundColor: XCleanTheme.cardBg,
                    ),
                  );
                }
              } else if (val == 'clear_all') {
                _showClearAllDialog(context, state);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'clean_rinses',
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services_rounded, color: XCleanTheme.cyan, size: 18),
                    const SizedBox(width: 10),
                    Text("Spülvorgänge (< ${minSeconds}s) bereinigen", style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                    SizedBox(width: 10),
                    Text("Gesamten Verlauf leeren", style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          // Filter Tabs (Revolut Style)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(0, "Gültig (${validSessions.length})"),
                const SizedBox(width: 8),
                _buildFilterChip(1, "Top (≥ 80)"),
                const SizedBox(width: 8),
                _buildFilterChip(2, "Optimierungsbedarf (< 80)"),
                if (rinseSessions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildFilterChip(3, "Spülungen (${rinseSessions.length})"),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Wenn eine Session ausgewählt wurde: Detail-3D-Ansicht
          if (_inspectedSession != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: XCleanTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: XCleanTheme.cyan.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: XCleanTheme.cyan, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat("dd.MM.yyyy • HH:mm").format(_inspectedSession!.timestamp),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: XCleanTheme.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _inspectedSession = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Tooth3DViewer(zones: _inspectedSession!.toothZonePressures),
                ],
              ),
            ),
          ],

          if (displayedList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: XCleanTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: XCleanTheme.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.history_toggle_off, size: 40, color: XCleanTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFilter == 3
                        ? "Keine Spülvorgänge vorhanden."
                        : "Keine Sitzungen für diesen Filter gefunden.",
                    style: const TextStyle(fontSize: 13, color: XCleanTheme.textMuted),
                  ),
                ],
              ),
            )
          else
            ...grouped.entries.expand((entry) {
              final dayTitle = entry.key;
              final daySessions = entry.value;

              return [
                // Datums-Header
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: XCleanTheme.textMuted,
                        ),
                      ),
                      Text(
                        "${daySessions.length} ${daySessions.length == 1 ? 'Sitzung' : 'Sitzungen'}",
                        style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                // Sessions für diesen Tag
                ...daySessions.map((s) => _buildSessionCard(context, state, s)),
              ];
            }),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, ToothbrushState state, BrushingSession s) {
    final timeStr = DateFormat("HH:mm").format(s.timestamp);
    final period = _getTimePeriod(s.timestamp.hour);
    final scoreColor = XCleanTheme.getScoreColor(s.score);
    final isInspected = _inspectedSession == s;
    final isRinse = s.durationSeconds < state.minValidDurationSeconds;

    return Dismissible(
      key: ValueKey(s.timestamp.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) async {
        HapticFeedback.mediumImpact();
        await state.deleteSession(s);
        if (_inspectedSession == s) {
          setState(() => _inspectedSession = null);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Putzsitzung gelöscht"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _inspectedSession = isInspected ? null : s;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isInspected ? XCleanTheme.cardSubtle : XCleanTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isInspected
                  ? XCleanTheme.cyan
                  : (isRinse ? Colors.white10 : XCleanTheme.border),
              width: isInspected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Score Badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isRinse ? Colors.white10 : scoreColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: isRinse ? Colors.white24 : scoreColor, width: 1.8),
                ),
                alignment: Alignment.center,
                child: Text(
                  isRinse ? "—" : "${s.score}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isRinse ? XCleanTheme.textMuted : scoreColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Dauer, Uhrzeit & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDuration(s.durationSeconds),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isRinse ? XCleanTheme.textMuted : XCleanTheme.textLight,
                          ),
                        ),
                        if (isRinse) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Spülen",
                              style: TextStyle(fontSize: 10, color: XCleanTheme.textMuted, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "$timeStr Uhr • $period • Effektiv: ${_formatDuration(s.validDurationSeconds)}",
                      style: const TextStyle(fontSize: 12, color: XCleanTheme.textMuted),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 18,
                ),
                tooltip: "Löschen",
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await state.deleteSession(s);
                  if (_inspectedSession == s) {
                    setState(() => _inspectedSession = null);
                  }
                },
              ),
              Icon(
                isInspected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: isInspected ? XCleanTheme.cyan : XCleanTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, ToothbrushState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: XCleanTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Gesamten Verlauf leeren?"),
        content: const Text(
          "Möchtest du wirklich alle gespeicherten Putzsitzungen aus der lokalen Datenbank löschen?",
          style: TextStyle(fontSize: 13, color: XCleanTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen", style: TextStyle(color: XCleanTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await state.clearDatabase();
              setState(() => _inspectedSession = null);
            },
            child: const Text("Alles löschen"),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? XCleanTheme.cyan : XCleanTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? XCleanTheme.cyan : XCleanTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.black : XCleanTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
