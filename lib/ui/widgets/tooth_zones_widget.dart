import 'package:flutter/material.dart';

class ToothZonesWidget extends StatelessWidget {
  final List<int> zones; // 8 Werte: [0..7]

  const ToothZonesWidget({super.key, required this.zones});

  Color _getColorForPressure(int val) {
    if (val == 0) return Colors.grey.shade300;
    if (val < 10) return Colors.orange.shade300;
    if (val <= 30) return Colors.green.shade400;
    return Colors.red.shade400; // Zu viel Druck
  }

  Widget _buildZoneBox(String label, int val) {
    final color = _getColorForPressure(val);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "$val",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: val == 0 ? Colors.grey : Colors.black87,
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "8-Zonen Kiefer-Analyse",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.brush, color: Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 12),
            // Oberkiefer (Oben)
            const Text("Oberkiefer", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Row(
              children: [
                _buildZoneBox("Links Außen\n(Z1)", z[0]),
                _buildZoneBox("Links Innen\n(Z2)", z[1]),
                _buildZoneBox("Rechts Innen\n(Z6)", z[5]),
                _buildZoneBox("Rechts Außen\n(Z5)", z[4]),
              ],
            ),
            const SizedBox(height: 8),
            // Unterkiefer (Unten)
            Row(
              children: [
                _buildZoneBox("Links Außen\n(Z3)", z[2]),
                _buildZoneBox("Links Innen\n(Z4)", z[3]),
                _buildZoneBox("Rechts Innen\n(Z8)", z[7]),
                _buildZoneBox("Rechts Außen\n(Z7)", z[6]),
              ],
            ),
            const Text("Unterkiefer", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
