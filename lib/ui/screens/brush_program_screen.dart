import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/toothbrush_state.dart';
import '../theme/xclean_theme.dart';
import '../../oclean_protocol.dart';

class BrushProgramScreen extends StatefulWidget {
  const BrushProgramScreen({super.key});

  @override
  State<BrushProgramScreen> createState() => _BrushProgramScreenState();
}

class _BrushProgramScreenState extends State<BrushProgramScreen> {
  int _selectedMode = 1; // 1: Clean, 2: White, 3: Massage, 4: Custom
  int _intensity = 20; // 1..32
  final int _duration = 120; // seconds

  final List<Map<String, dynamic>> _modes = [
    {
      "id": 1,
      "name": "Standard Clean",
      "icon": Icons.cleaning_services_rounded,
      "tag": "ALLTAG",
      "desc": "Tägliche gründliche Plaque-Entfernung mit optimaler Balance.",
      "defaultIntensity": 20,
      "accent": XCleanTheme.cyan,
    },
    {
      "id": 2,
      "name": "White & Polish",
      "icon": Icons.auto_awesome_rounded,
      "tag": "EFFEKT",
      "desc": "Intensive Politur zur Beseitigung oberflächlicher Verfärbungen.",
      "defaultIntensity": 28,
      "accent": XCleanTheme.emerald,
    },
    {
      "id": 3,
      "name": "Sensitiv & Pflege",
      "icon": Icons.spa_rounded,
      "tag": "SANFT",
      "desc": "Zahnfleischschonende Schwingungen für empfindliche Zähne.",
      "defaultIntensity": 14,
      "accent": XCleanTheme.amber,
    },
    {
      "id": 4,
      "name": "Custom / Pro",
      "icon": Icons.tune_rounded,
      "tag": "INDIVIDUELL",
      "desc": "Frei einstellbare Motor-Intensität und Putzdauer für Experten.",
      "defaultIntensity": 24,
      "accent": Colors.purpleAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ToothbrushState>();

    return Scaffold(
      backgroundColor: XCleanTheme.background,
      appBar: AppBar(
        title: const Text(
          "PUTZPROGRAMME",
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
          // Header Infokarte
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: XCleanTheme.cyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: XCleanTheme.cyan.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.brush_rounded, color: XCleanTheme.cyan, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "MAGLEV-SCHALLMOTOR",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: XCleanTheme.textMuted,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Bis zu 42.000 Vpm Vibrationen",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: XCleanTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Modus-Karten (Revolut Grid/Cards)
          const Text(
            "MODUS AUSWÄHLEN",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: XCleanTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),

          ..._modes.map((m) {
            final isSelected = m["id"] == _selectedMode;
            final accent = m["accent"] as Color;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedMode = m["id"] as int;
                  _intensity = m["defaultIntensity"] as int;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.12) : XCleanTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accent : XCleanTheme.border,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? accent.withValues(alpha: 0.2) : XCleanTheme.cardSubtle,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        m["icon"] as IconData,
                        color: isSelected ? accent : XCleanTheme.textMuted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                m["name"] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: XCleanTheme.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m["tag"] as String,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m["desc"] as String,
                            style: const TextStyle(fontSize: 12, color: XCleanTheme.textMuted, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: accent, size: 22)
                    else
                      const Icon(Icons.circle_outlined, color: XCleanTheme.cardSubtle, size: 22),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Intensitäts- & Dauer-Panel
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "MOTOR-INTENSITÄT",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: XCleanTheme.textMuted,
                      ),
                    ),
                    Text(
                      "Stufe $_intensity / 32",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: XCleanTheme.cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: XCleanTheme.cyan,
                    inactiveTrackColor: XCleanTheme.cardSubtle,
                    thumbColor: XCleanTheme.cyan,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _intensity.toDouble(),
                    min: 1,
                    max: 32,
                    divisions: 31,
                    onChanged: (v) {
                      setState(() => _intensity = v.toInt());
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "EMPFOHLENE DAUER",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: XCleanTheme.textMuted,
                      ),
                    ),
                    Text(
                      "$_duration Sekunden (2 Min)",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: XCleanTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Anwenden Button (Revolut Hero Button)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final steps = [
                  SchemeStep(
                    mode: _selectedMode,
                    gear: _intensity, // Stufe 1..32 direkt ohne Drosselung
                    durationSeconds: _duration,
                  ),
                ];
                await state.setBrushScheme(_selectedMode, steps);

                if (context.mounted) {
                  final modeName = _modes.firstWhere((m) => m["id"] == _selectedMode)["name"];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: XCleanTheme.cardBg,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: XCleanTheme.emerald),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "$modeName mit Stufe $_intensity an Bürste gesendet!",
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
              style: ElevatedButton.styleFrom(
                backgroundColor: XCleanTheme.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text(
                "Programm auf Bürste übertragen",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
