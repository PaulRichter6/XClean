import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/xclean_theme.dart';

/// Echte originale Oclean 3D-Gebiss-Visualisierung:
/// Verwendet das originale `yaya.dae` Collada-3D-Modell (Ober- und Unterkiefer)
/// mit Three.js WebGL, 360° OrbitControls und dem offiziellen Färbealgorithmus.
class Tooth3DViewer extends StatefulWidget {
  final List<int> zones; // 8 Oclean-Zonen: [0..7] in Sekunden

  const Tooth3DViewer({super.key, required this.zones});

  @override
  State<Tooth3DViewer> createState() => _Tooth3DViewerState();
}

class _Tooth3DViewerState extends State<Tooth3DViewer> {
  late final WebViewController _controller;
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0C0E14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isWebViewReady = true);
              _updateZonesInWebView();
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/3d_teeth_bundle.html');
  }

  @override
  void didUpdateWidget(covariant Tooth3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.zones, widget.zones) && _isWebViewReady) {
      _updateZonesInWebView();
    }
  }

  void _updateZonesInWebView() {
    final z = widget.zones.length >= 8 ? widget.zones : List<int>.filled(8, 0);
    final jsonStr = jsonEncode(z);
    _controller.runJavaScript('if (window.updateFromSeconds) window.updateFromSeconds($jsonStr);');
  }

  void _resetCamera() {
    HapticFeedback.lightImpact();
    _controller.runJavaScript('if (window.resetCamera) window.resetCamera();');
  }

  @override
  Widget build(BuildContext context) {
    final z = widget.zones.length >= 8 ? widget.zones : List<int>.filled(8, 0);
    final upperSec = z[0] + z[1] + z[4] + z[5];
    final lowerSec = z[2] + z[3] + z[6] + z[7];
    final coveredZones = z.where((sec) => sec > 0).length;
    final coveragePercent = ((coveredZones / 8.0) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: XCleanTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: XCleanTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Titel und Reset-Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "3D-GEBISS & PUTZANALYSE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: XCleanTheme.textMuted,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Ober- & Unterkiefer",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: XCleanTheme.textLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: "Zentrieren",
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.refresh_rounded, color: XCleanTheme.cyan, size: 22),
                onPressed: _resetCamera,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Farb-Legende (sauber in eigener Zeile, kein Overflow)
          Row(
            children: [
              _buildLegendDot(const Color(0xFFE54D2E), "Fehlt (< 10s)"),
              const SizedBox(width: 12),
              _buildLegendDot(const Color(0xFFFFB224), "Mäßig (10-25s)"),
              const SizedBox(width: 12),
              _buildLegendDot(const Color(0xFF30A46C), "Gut (> 25s)"),
            ],
          ),
          const SizedBox(height: 12),

          // Interaktiver 3D WebGL Container (Three.js OrbitControls)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Stack(
                children: [
                  WebViewWidget(
                    controller: _controller,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                  if (!_isWebViewReady)
                    const Center(
                      child: CircularProgressIndicator(color: XCleanTheme.cyan, strokeWidth: 2.5),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3 Zonen-Statistiken
          Row(
            children: [
              Expanded(
                child: _buildMetricPill("Oberkiefer", "${upperSec}s"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill("Unterkiefer", "${lowerSec}s"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill("Abdeckung", "$coveragePercent%"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 10, color: XCleanTheme.textMuted)),
      ],
    );
  }

  Widget _buildMetricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: XCleanTheme.cardSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: XCleanTheme.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: XCleanTheme.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: XCleanTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
