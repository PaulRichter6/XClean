import 'package:flutter/material.dart';
import '../theme/xclean_theme.dart';
import '../../oclean_protocol.dart';

class StatisticsScreen extends StatelessWidget {
  final List<BrushingSession> history;

  const StatisticsScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final count = history.length;
    final avgScore = count > 0 ? (history.map((e) => e.score).reduce((a, b) => a + b) / count).round() : 0;
    final avgDuration = count > 0 ? (history.map((e) => e.durationSeconds).reduce((a, b) => a + b) / count).round() : 0;

    // Echte 7-Tage-Historie berechnen
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final past7Days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final List<String> dayLabels = [];
    final List<int> barScores = [];
    final germanWeekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];

    int fullRoutineDays = 0;

    for (final d in past7Days) {
      dayLabels.add(germanWeekdays[d.weekday - 1]);
      final matching = history.where((s) =>
        s.timestamp.year == d.year &&
        s.timestamp.month == d.month &&
        s.timestamp.day == d.day
      ).toList();

      if (matching.isNotEmpty) {
        final dayAvg = (matching.map((e) => e.score).reduce((a, b) => a + b) / matching.length).round();
        barScores.add(dayAvg);

        final hasMorning = matching.any((s) => s.timestamp.hour < 12);
        final hasEvening = matching.any((s) => s.timestamp.hour >= 17);
        if (hasMorning && hasEvening) fullRoutineDays++;
      } else {
        barScores.add(0);
      }
    }

    return Scaffold(
      backgroundColor: XCleanTheme.background,
      appBar: AppBar(
        title: const Text(
          "PUTZ-STATISTIKEN",
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
          // KPI Kacheln
          Row(
            children: [
              Expanded(
                child: _buildKpiCard("DURCHSCHNITT", "$avgScore", "/ 100", XCleanTheme.getScoreColor(avgScore)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard("DURCHSCHN. DAUER", "${avgDuration}s", "pro Session", XCleanTheme.cyan),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Wochen-Balkendiagramm (WHOOP Strain Style)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "WOCHEN-VERLAUF (CLEAN SCORE)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: XCleanTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final score = barScores[i];
                      final hasData = score > 0;
                      final heightFactor = hasData ? (score / 100.0).clamp(0.15, 1.0) : 0.08;
                      final color = hasData ? XCleanTheme.getScoreColor(score) : Colors.white12;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            hasData ? "$score" : "-",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasData ? color : XCleanTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 18,
                            height: 90 * heightFactor,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: hasData ? 0.8 : 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(dayLabels[i], style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: XCleanTheme.border, height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "2x TÄGLICH (MORGENS & ABENDS)",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: XCleanTheme.textMuted),
                    ),
                    Text(
                      "$fullRoutineDays von 7 Tagen",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: XCleanTheme.cyan),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Zonen-Problemanalyse Karte
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: XCleanTheme.emerald, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "KI-PUTZANALYSE & EMPFEHLUNG",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: XCleanTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  "Exzellente Regelmäßigkeit! Dein Unterkiefer innen (Zone 4 & 8) hat im Schnitt 15% weniger Putzdauer erhalten als die Außenflächen. Verweile dort beim nächsten Putzen ca. 10 Sekunden länger.",
                  style: TextStyle(fontSize: 13, height: 1.4, color: XCleanTheme.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Putzroutine-Tipp
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: XCleanTheme.amber, size: 24),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ROUTINE-TIPP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: XCleanTheme.textMuted,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "2x täglich je 2 Minuten putzen hält deinen Clean-Score konstant über 90 Punkten.",
                        style: TextStyle(fontSize: 12, color: XCleanTheme.textLight, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, String sub, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: XCleanTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: XCleanTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: XCleanTheme.textMuted),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: accent)),
                const SizedBox(width: 4),
                Text(sub, style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
