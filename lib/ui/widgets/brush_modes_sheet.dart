import 'package:flutter/material.dart';
import '../theme/xclean_theme.dart';
import '../../oclean_protocol.dart';

class BrushModesSheet extends StatefulWidget {
  final Function(int pNum, List<SchemeStep> steps) onApplyScheme;

  const BrushModesSheet({super.key, required this.onApplyScheme});

  @override
  State<BrushModesSheet> createState() => _BrushModesSheetState();
}

class _BrushModesSheetState extends State<BrushModesSheet> {
  int _selectedMode = 1; // 1: Clean, 2: White, 3: Massage, 4: Custom
  int _intensity = 20; // 1..32
  final int _duration = 120; // seconds

  final List<Map<String, dynamic>> _modes = [
    {"id": 1, "name": "Standard Clean", "icon": Icons.cleaning_services, "desc": "Tägliche gründliche Reinigung (Stufe 20)"},
    {"id": 2, "name": "White & Polish", "icon": Icons.auto_awesome, "desc": "Aufhellung & Plaque-Entfernung (Stufe 26)"},
    {"id": 3, "name": "Sensitiv & Massage", "icon": Icons.spa, "desc": "Zahnfleischschonend (Stufe 14)"},
    {"id": 4, "name": "Benutzerdefiniert", "icon": Icons.tune, "desc": "Frei einstellbare Intensität (1–32)"},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: XCleanTheme.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: XCleanTheme.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text(
            "PUTZMODUS & INTENSITÄT",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: XCleanTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ..._modes.map((m) {
            final isSelected = m["id"] == _selectedMode;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? XCleanTheme.cardSubtle : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? XCleanTheme.cyan : XCleanTheme.border),
              ),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _selectedMode = m["id"];
                    if (_selectedMode == 1) _intensity = 20;
                    if (_selectedMode == 2) _intensity = 26;
                    if (_selectedMode == 3) _intensity = 14;
                  });
                },
                leading: Icon(m["icon"] as IconData, color: isSelected ? XCleanTheme.cyan : XCleanTheme.textMuted),
                title: Text(m["name"] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(m["desc"] as String, style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted)),
                trailing: isSelected ? const Icon(Icons.check, color: XCleanTheme.cyan) : null,
              ),
            );
          }),
          const SizedBox(height: 16),
          // Intensitäts-Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Motor-Intensität", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text("Stufe $_intensity / 32", style: const TextStyle(color: XCleanTheme.cyan, fontWeight: FontWeight.w900)),
            ],
          ),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 32,
            divisions: 31,
            activeColor: XCleanTheme.cyan,
            inactiveColor: XCleanTheme.cardSubtle,
            onChanged: (v) => setState(() => _intensity = v.toInt()),
          ),
          const SizedBox(height: 16),
          // Anwenden Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final steps = [
                  SchemeStep(gear: (_intensity / 4).clamp(1, 7).toInt(), durationSeconds: _duration),
                ];
                widget.onApplyScheme(_selectedMode, steps);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: XCleanTheme.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Modus auf Bürste aktivieren (CMD 0206)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
