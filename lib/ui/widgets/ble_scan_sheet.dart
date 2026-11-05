import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/toothbrush_state.dart';
import '../theme/xclean_theme.dart';

/// Interaktiver Bluetooth-Such- und Verbindungsdialog
class BleScanSheet extends StatelessWidget {
  const BleScanSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ToothbrushState>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: XCleanTheme.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "BLUETOOTH GERÄTE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: XCleanTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.isLoading ? "Suche nach Oclean..." : "Gefundene Geräte",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: XCleanTheme.textLight,
                    ),
                  ),
                ],
              ),
              if (state.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: XCleanTheme.cyan),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: XCleanTheme.cyan),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    state.scanAndConnect();
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Device List
          if (state.discoveredDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      state.isLoading ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                      size: 40,
                      color: state.isLoading ? XCleanTheme.cyan : XCleanTheme.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.isLoading
                          ? "Bürste einschalten (Display antippen)\nund nah ans Smartphone halten..."
                          : "Keine Geräte gefunden.\nTippe auf Aktualisieren.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: XCleanTheme.textMuted, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.discoveredDevices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final result = state.discoveredDevices[index];
                  final isOclean = state.isOcleanDevice(result);
                  final isFavorite = state.favoriteDeviceId == result.device.remoteId.str;
                  final name = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : (result.advertisementData.advName.isNotEmpty
                          ? result.advertisementData.advName
                          : "Unbekanntes BLE-Gerät");

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFavorite
                          ? Colors.amber.withValues(alpha: 0.12)
                          : (isOclean ? XCleanTheme.cyan.withValues(alpha: 0.1) : XCleanTheme.cardSubtle),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFavorite
                            ? Colors.amber.withValues(alpha: 0.6)
                            : (isOclean ? XCleanTheme.cyan.withValues(alpha: 0.5) : XCleanTheme.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFavorite
                                ? Colors.amber
                                : (isOclean ? XCleanTheme.cyan : Colors.white12),
                          ),
                          child: Icon(
                            isFavorite ? Icons.star_rounded : Icons.bluetooth,
                            color: isFavorite ? Colors.black : (isOclean ? Colors.black : Colors.white70),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isFavorite
                                            ? Colors.amber
                                            : (isOclean ? XCleanTheme.cyan : XCleanTheme.textLight),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isFavorite) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "FAVORIT",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ] else if (isOclean) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: XCleanTheme.cyan,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "OCLEAN",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${result.device.remoteId} • RSSI: ${result.rssi} dBm",
                                style: const TextStyle(fontSize: 11, color: XCleanTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        // Stern Favorit Button
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isFavorite ? Colors.amber : XCleanTheme.textMuted,
                            size: 22,
                          ),
                          tooltip: isFavorite ? "Favorit entfernen" : "Als Favorit speichern",
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (isFavorite) {
                              state.removeFavoriteDevice();
                            } else {
                              state.setFavoriteDevice(result.device.remoteId.str, name);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            await state.connectToDevice(result.device);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFavorite
                                ? Colors.amber
                                : (isOclean ? XCleanTheme.cyan : Colors.white24),
                            foregroundColor: isFavorite ? Colors.black : (isOclean ? Colors.black : Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Verbinden", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
