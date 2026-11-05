import 'package:flutter/material.dart';
import '../theme/xclean_theme.dart';

class ModernToothHeatmap extends StatelessWidget {
  final List<int> zones; // 8 Zonen: [0..7]

  const ModernToothHeatmap({super.key, required this.zones});

  Color _getZoneColor(int val) {
    if (val == 0) return XCleanTheme.cardSubtle;
    if (val < 10) return XCleanTheme.amber;
    if (val <= 30) return XCleanTheme.emerald;
    return XCleanTheme.coral; // Zu viel Druck
  }

  Widget _buildZoneTile(String label, int val) {
    final color = _getZoneColor(val);
    final isUnbrushed = val == 0;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isUnbrushed ? 0.4 : 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnbrushed ? XCleanTheme.border : color.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: XCleanTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isUnbrushed ? "-" : "$val",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isUnbrushed ? XCleanTheme.textMuted : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final z = zones.length >= 8 ? zones : List<int>.filled(8, 0);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: XCleanTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: XCleanTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  "8-ZONEN ABDECKUNG",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: XCleanTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(XCleanTheme.emerald, "Ideal"),
                  const SizedBox(width: 6),
                  _buildLegendDot(XCleanTheme.amber, "Wenig"),
                  const SizedBox(width: 6),
                  _buildLegendDot(XCleanTheme.coral, "Druck"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Oberkiefer
          const Text(
            "OBERKIEFER",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: XCleanTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildZoneTile("L-Außen", z[0]),
              _buildZoneTile("L-Innen", z[1]),
              _buildZoneTile("R-Innen", z[5]),
              _buildZoneTile("R-Außen", z[4]),
            ],
          ),
          const SizedBox(height: 14),
          // Unterkiefer
          const Text(
            "UNTERKIEFER",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: XCleanTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildZoneTile("L-Außen", z[2]),
              _buildZoneTile("L-Innen", z[3]),
              _buildZoneTile("R-Innen", z[7]),
              _buildZoneTile("R-Außen", z[6]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: XCleanTheme.textMuted)),
      ],
    );
  }
}
