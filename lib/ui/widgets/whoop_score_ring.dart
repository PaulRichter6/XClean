import 'package:flutter/material.dart';
import '../theme/xclean_theme.dart';

class WhoopScoreRing extends StatelessWidget {
  final int score;
  final int durationSeconds;
  final int validDurationSeconds;

  const WhoopScoreRing({
    super.key,
    required this.score,
    required this.durationSeconds,
    required this.validDurationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = XCleanTheme.getScoreColor(score);
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: XCleanTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: XCleanTheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "SESSION SCORE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: XCleanTheme.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  score >= 85 ? "OPTIMAL" : (score >= 65 ? "GUT" : "AUSBAUFÄHIG"),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Dual Circular Progress Gauge
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ring: Duration Progress (Target: 120s)
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: (durationSeconds / 120.0).clamp(0.0, 1.0),
                    strokeWidth: 4,
                    backgroundColor: XCleanTheme.cardSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(XCleanTheme.cyan),
                  ),
                ),
                // Inner Ring: Score Gauge
                SizedBox(
                  width: 144,
                  height: 144,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: (score / 100.0).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: XCleanTheme.cardSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      );
                    },
                  ),
                ),
                // Center Metrics
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$score",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      "/ 100",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: XCleanTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Bottom Stats Row (Revolut Style)
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.timer_outlined,
                  label: "GESAMTZEIT",
                  value: timeStr,
                  accentColor: XCleanTheme.cyan,
                ),
              ),
              Container(width: 1, height: 36, color: XCleanTheme.border),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.check_circle_outline,
                  label: "EFFEKTIV GEBÜRSTET",
                  value: "${validDurationSeconds}s",
                  accentColor: XCleanTheme.emerald,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: XCleanTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: XCleanTheme.textLight,
          ),
        ),
      ],
    );
  }
}
