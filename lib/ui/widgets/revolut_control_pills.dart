import 'package:flutter/material.dart';
import '../theme/xclean_theme.dart';

class RevolutControlPills extends StatelessWidget {
  final bool isConnected;
  final bool isDemoMode;
  final bool isLoading;
  final int brushHeadDays;
  final int brushHeadMaxDays;
  final int brushHeadTimes;
  final VoidCallback onSyncTime;
  final VoidCallback onFetchSessions;
  final VoidCallback onResetBrushHead;

  const RevolutControlPills({
    super.key,
    required this.isConnected,
    required this.isDemoMode,
    required this.isLoading,
    required this.brushHeadDays,
    required this.brushHeadMaxDays,
    required this.brushHeadTimes,
    required this.onSyncTime,
    required this.onFetchSessions,
    required this.onResetBrushHead,
  });

  @override
  Widget build(BuildContext context) {
    final active = isConnected || isDemoMode;
    final maxDays = brushHeadMaxDays > 0 ? brushHeadMaxDays : 90;
    final headLifePercent = (brushHeadDays / maxDays.toDouble()).clamp(0.0, 1.0);

    return Column(
      children: [
        // Quick Action Buttons (Revolut Pills Row)
        Row(
          children: [
            Expanded(
              child: _buildActionPill(
                icon: Icons.sync,
                label: "Uhrzeit",
                onTap: active && !isLoading ? onSyncTime : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionPill(
                icon: Icons.download_rounded,
                label: "Download",
                isPrimary: true,
                onTap: active && !isLoading ? onFetchSessions : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionPill(
                icon: Icons.restart_alt,
                label: "Reset Kopf",
                onTap: active && !isLoading ? onResetBrushHead : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Brush Head Lifespan Card
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: XCleanTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: XCleanTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "BÜRSTENKOPF-GESUNDHEIT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: XCleanTheme.textMuted,
                    ),
                  ),
                  Text(
                    "$brushHeadDays / $maxDays Tage",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: XCleanTheme.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: headLifePercent,
                  minHeight: 6,
                  backgroundColor: XCleanTheme.cardSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    headLifePercent > 0.85
                        ? XCleanTheme.coral
                        : (headLifePercent > 0.6 ? XCleanTheme.amber : XCleanTheme.emerald),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bereits $brushHeadTimes Mal geputzt",
                    style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted),
                  ),
                  Text(
                    "${((1.0 - headLifePercent) * 100).round()}% übrig",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: headLifePercent > 0.85 ? XCleanTheme.coral : XCleanTheme.emerald,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? XCleanTheme.cyan : XCleanTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? XCleanTheme.cyan : XCleanTheme.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? Colors.black : XCleanTheme.textLight,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.black : XCleanTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
