import 'package:flutter/material.dart';

class ScoreDisplayWidget extends StatelessWidget {
  final int score;
  final int durationSeconds;
  final int validDurationSeconds;

  const ScoreDisplayWidget({
    super.key,
    required this.score,
    required this.durationSeconds,
    required this.validDurationSeconds,
  });

  Color _getScoreColor(int s) {
    if (s >= 85) return Colors.green;
    if (s >= 65) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    final timeStr = "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Score Kreis
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$score",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Text("Score", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            // Metriken
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 20, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      "Putzzeit: $timeStr",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      "Effektiv: ${validDurationSeconds}s",
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
