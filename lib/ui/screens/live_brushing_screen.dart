import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/toothbrush_state.dart';
import '../theme/xclean_theme.dart';

class LiveBrushingScreen extends StatefulWidget {
  const LiveBrushingScreen({super.key});

  @override
  State<LiveBrushingScreen> createState() => _LiveBrushingScreenState();
}

class _LiveBrushingScreenState extends State<LiveBrushingScreen> with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 120; // 2 Minuten
  int _secondsRemaining = _totalSeconds;
  bool _isRunning = false;
  Timer? _timer;

  // 4 Quadranten je 30 Sekunden
  final List<Map<String, dynamic>> _quadrants = [
    {
      "index": 1,
      "name": "Oberkiefer Rechts",
      "instruction": "Außen-, Kau- & Innenflächen sanft im 45°-Winkel reinigen",
      "jaw": "OBERKIEFER",
      "side": "RECHTS",
      "icon": Icons.arrow_upward_rounded,
    },
    {
      "index": 2,
      "name": "Oberkiefer Links",
      "instruction": "Gleichmäßige kreisende Bewegungen von Rot nach Weiß",
      "jaw": "OBERKIEFER",
      "side": "LINKS",
      "icon": Icons.arrow_upward_rounded,
    },
    {
      "index": 3,
      "name": "Unterkiefer Links",
      "instruction": "Besonders die Innenflächen der Backenzähne beachten",
      "jaw": "UNTERKIEFER",
      "side": "LINKS",
      "icon": Icons.arrow_downward_rounded,
    },
    {
      "index": 4,
      "name": "Unterkiefer Rechts",
      "instruction": "Schneidezähne und Kauflächen gründlich vollenden",
      "jaw": "UNTERKIEFER",
      "side": "RECHTS",
      "icon": Icons.arrow_downward_rounded,
    },
  ];

  int get _currentQuadrantIndex {
    final elapsed = _totalSeconds - _secondsRemaining;
    final q = (elapsed ~/ 30);
    return q.clamp(0, 3);
  }

  int get _quadrantSecondsRemaining {
    final elapsed = _totalSeconds - _secondsRemaining;
    final inQuarter = elapsed % 30;
    return 30 - inQuarter;
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });

        // Haptisches Feedback bei Quadrantenwechsel (alle 30s)
        if (_secondsRemaining % 30 == 0) {
          HapticFeedback.heavyImpact();
        }
      } else {
        _timer?.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isRunning = false;
        });
        HapticFeedback.vibrate();
        _showFinishedDialog();
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _totalSeconds;
      _isRunning = false;
    });
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: XCleanTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: XCleanTheme.emerald, size: 28),
            SizedBox(width: 10),
            Text("Perfekt geputzt!", style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "2 Minuten vollständige Abdeckung aller 4 Quadranten abgeschlossen.",
              style: TextStyle(fontSize: 14, color: XCleanTheme.textLight, height: 1.4),
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Text("Clean Score: ", style: TextStyle(color: XCleanTheme.textMuted)),
                Text("100 / 100", style: TextStyle(fontWeight: FontWeight.bold, color: XCleanTheme.emerald)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: XCleanTheme.cyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Fertig", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ToothbrushState>();
    final q = _quadrants[_currentQuadrantIndex];
    final progress = (_totalSeconds - _secondsRemaining) / _totalSeconds;
    final quadrantProgress = (30 - _quadrantSecondsRemaining) / 30.0;

    return Scaffold(
      backgroundColor: XCleanTheme.background,
      appBar: AppBar(
        title: const Text(
          "LIVE-PUTZBEGLEITER",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: XCleanTheme.textMuted),
            tooltip: "Zurücksetzen",
            onPressed: _resetTimer,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // 1. Zahnbürsten-Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: state.isConnected
                      ? XCleanTheme.cyan.withValues(alpha: 0.1)
                      : XCleanTheme.cardSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: state.isConnected
                        ? XCleanTheme.cyan.withValues(alpha: 0.3)
                        : XCleanTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      size: 16,
                      color: state.isConnected ? XCleanTheme.cyan : XCleanTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isConnected
                          ? "${state.deviceModelName.isNotEmpty ? state.deviceModelName : 'Oclean X Elite'} verbunden"
                          : "Offline-Timer (Bürste nicht verbunden)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: state.isConnected ? XCleanTheme.cyan : XCleanTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // 2. Großer kreisförmiger WHOOP-Style Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  // Äußerer Gesamt-Fortschrittsring
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: XCleanTheme.cardSubtle,
                      valueColor: const AlwaysStoppedAnimation<Color>(XCleanTheme.cyan),
                    ),
                  ),
                  // Innerer Quadranten-Countdown Ring (30s)
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: quadrantProgress,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(XCleanTheme.emerald),
                    ),
                  ),
                  // Zentrierte Zeitanzeige
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: XCleanTheme.textLight,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: XCleanTheme.emerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Noch ${_quadrantSecondsRemaining}s in Zone",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: XCleanTheme.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // 3. Quadranten-Visualisierung & Anweisung
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: XCleanTheme.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: XCleanTheme.cyan.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: XCleanTheme.cyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(q["icon"] as IconData, color: XCleanTheme.cyan, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "QUADRANT ${q["index"]} VON 4",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: XCleanTheme.cyan,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  q["name"] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: XCleanTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // 4 Quadranten Mini-Dots
                        Row(
                          children: List.generate(4, (i) {
                            final isActive = i == _currentQuadrantIndex;
                            final isDone = i < _currentQuadrantIndex;
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? XCleanTheme.cyan
                                    : (isDone ? XCleanTheme.emerald : Colors.white24),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      q["instruction"] as String,
                      style: const TextStyle(fontSize: 12, color: XCleanTheme.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Steuerungsknöpfe
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? XCleanTheme.amber : XCleanTheme.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ).elevatedButton(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            _isRunning ? "PAUSIEREN" : (_secondsRemaining < _totalSeconds ? "FORTSETZEN" : "STARTEN"),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ButtonStyle {
  Widget elevatedButton({required VoidCallback onPressed, required Widget child}) {
    return ElevatedButton(
      style: this,
      onPressed: onPressed,
      child: child,
    );
  }
}
