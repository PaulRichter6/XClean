import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/toothbrush_state.dart';
import '../theme/xclean_theme.dart';
import '../widgets/whoop_score_ring.dart';
import '../widgets/tooth_3d_viewer.dart';
import '../widgets/revolut_control_pills.dart';
import '../widgets/ble_scan_sheet.dart';
import 'live_brushing_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ToothbrushState>();
    final session = state.latestSession;

    return Scaffold(
      backgroundColor: XCleanTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 112,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              // Profile Avatar
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(streakDays: state.streakDays),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [XCleanTheme.cyan, XCleanTheme.emerald],
                    ),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: const Icon(Icons.person, size: 20, color: Colors.black),
                ),
              ),
              const SizedBox(width: 6),
              // Streak Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange),
                    const SizedBox(width: 2),
                    Text(
                      "${state.streakDays}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "XCLEAN",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 16,
                color: XCleanTheme.textLight,
              ),
            ),
            if (state.isDemoMode) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purpleAccent, width: 1),
                ),
                child: const Text(
                  "DEMO",
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Battery Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.batteryLevel > 20 ? Icons.battery_full_rounded : Icons.battery_alert_rounded,
                  size: 16,
                  color: state.batteryLevel > 20 ? XCleanTheme.emerald : XCleanTheme.coral,
                ),
                const SizedBox(width: 4),
                Text(
                  "${state.batteryLevel}%",
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: XCleanTheme.textLight),
                ),
              ],
            ),
          ),
          // Bluetooth Status Button
          IconButton(
            padding: const EdgeInsets.only(right: 12),
            icon: Icon(
              state.isConnected
                  ? Icons.bluetooth_connected
                  : (state.isDemoMode ? Icons.science_rounded : Icons.bluetooth),
              color: state.isConnected
                  ? XCleanTheme.cyan
                  : (state.isDemoMode ? Colors.purpleAccent : XCleanTheme.textMuted),
              size: 22,
            ),
            tooltip: state.isDemoMode ? "Demo Modus aktiv" : (state.isConnected ? "Trennen" : "Verbinden"),
            onPressed: () {
              HapticFeedback.selectionClick();
              if (state.isConnected) {
                state.disconnect();
              } else {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const BleScanSheet(),
                );
                state.scanAndConnect();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: XCleanTheme.cyan,
        backgroundColor: XCleanTheme.cardBg,
        onRefresh: () async {
          if (state.isDemoMode) {
            state.simulateIncomingSession();
          } else if (state.isConnected) {
            await state.fetchBatteryLevel();
            await state.requestSessions();
          } else {
            await state.scanAndConnect();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            // Status Banner if Disconnected
            if (!state.isConnected && !state.isDemoMode)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: XCleanTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: XCleanTheme.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.isLoading ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                      color: state.hasFavorite ? Colors.amber : XCleanTheme.amber,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.isLoading
                            ? (state.hasFavorite
                                ? "Verbinde mit Favorit '${state.favoriteDeviceName ?? 'Oclean'}'..."
                                : "Suche nach Oclean Zahnbürsten...")
                            : (state.hasFavorite
                                ? "Favorit '${state.favoriteDeviceName ?? 'Oclean'}' nicht verbunden. Display antippen & tippe auf Verbinden."
                                : "Bürste nicht verbunden. Tippe auf Scan oder aktiviere den Demo-Modus in Settings."),
                        style: const TextStyle(fontSize: 12, color: XCleanTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: XCleanTheme.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const BleScanSheet(),
                        );
                        state.scanAndConnect();
                      },
                      child: state.isLoading
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text("Scan", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Connected Device Status Badge
            if (state.isConnected)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: XCleanTheme.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: XCleanTheme.cyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: XCleanTheme.cyan, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.deviceModelName.isNotEmpty
                            ? "${state.deviceModelName} ${state.firmwareVersion.isNotEmpty ? '• FW ${state.firmwareVersion}' : ''}"
                            : "Oclean X Elite (Y2088) • Verbunden",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: XCleanTheme.cyan),
                      ),
                    ),
                    const Text("100% Offline BLE", style: TextStyle(fontSize: 10, color: XCleanTheme.textMuted)),
                  ],
                ),
              ),

            // Demo Mode Quick Action Bar
            if (state.isDemoMode)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science, color: Colors.purpleAccent, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Demo-Modus aktiv: Testdaten simulieren",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purpleAccent),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        state.simulateIncomingSession();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("+ Session", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Live-Putzbegleiter Quick Card
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveBrushingScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      XCleanTheme.cyan.withValues(alpha: 0.15),
                      XCleanTheme.emerald.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: XCleanTheme.cyan.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: XCleanTheme.cyan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer_rounded, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LIVE-PUTZBEGLEITER",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: XCleanTheme.cyan,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "2-Minuten Quadranten-Guide mit Ruckel-Timer",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: XCleanTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.play_circle_fill_rounded, color: XCleanTheme.cyan, size: 30),
                  ],
                ),
              ),
            ),

            // 1. WHOOP-Style Dual Score Ring
            WhoopScoreRing(
              score: session?.score ?? 0,
              durationSeconds: session?.durationSeconds ?? 0,
              validDurationSeconds: session?.validDurationSeconds ?? 0,
            ),
            const SizedBox(height: 16),

            // 2. Interaktives 3D-Zahnmodell & Kieferabdeckung
            Tooth3DViewer(
              zones: session?.toothZonePressures ?? List.filled(8, 0),
            ),
            const SizedBox(height: 16),

            // 3. Revolut Control Pills & Lifespan Card
            RevolutControlPills(
              isConnected: state.isConnected,
              isDemoMode: state.isDemoMode,
              isLoading: state.isLoading,
              brushHeadDays: state.brushHeadUsedDays,
              brushHeadMaxDays: state.brushHeadMaxDays,
              brushHeadTimes: state.brushHeadTimes,
              onSyncTime: () {
                HapticFeedback.lightImpact();
                state.syncTime();
              },
              onFetchSessions: () {
                HapticFeedback.lightImpact();
                state.requestSessions();
              },
              onResetBrushHead: () {
                HapticFeedback.mediumImpact();
                state.resetBrushHead();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
