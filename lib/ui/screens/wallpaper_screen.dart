import 'package:flutter/material.dart';
import '../theme/xclean_theme.dart';

class WallpaperScreen extends StatefulWidget {
  const WallpaperScreen({super.key});

  @override
  State<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  int _selectedPreset = 0;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<Map<String, dynamic>> _presets = [
    {
      "title": "Minimalist Dark",
      "desc": "OLED Schwarz mit Cyan Akzent",
      "colors": [const Color(0xFF0D0F12), const Color(0xFF00E5FF)],
      "id": 1,
    },
    {
      "title": "Emerald Strain",
      "desc": "WHOOP Recovery Grün",
      "colors": [const Color(0xFF10281E), const Color(0xFF00E676)],
      "id": 2,
    },
    {
      "title": "Cyber Sunset",
      "desc": "Neon Violett zu Orange Gradient",
      "colors": [const Color(0xFF2C103F), const Color(0xFFFF5252)],
      "id": 3,
    },
    {
      "title": "Nordic Frost",
      "desc": "Eisblau & kühles Silber",
      "colors": [const Color(0xFF13222F), const Color(0xFF80D8FF)],
      "id": 4,
    },
  ];

  void _uploadWallpaper() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Simuliert das Senden der Display-Pakete
    for (int i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _uploadProgress = i / 20.0;
      });
    }

    if (!mounted) return;
    setState(() {
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: XCleanTheme.emerald,
        content: Text(
          "Wallpaper '${_presets[_selectedPreset]['title']}' erfolgreich auf Bürste übertragen!",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XCleanTheme.background,
      appBar: AppBar(
        title: const Text(
          "DISPLAY WALLPAPERS",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Wähle ein Zifferblatt oder Theme für das LCD-Touchdisplay deiner Oclean X Pro Elite:",
            style: TextStyle(color: XCleanTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Preview Canvas
          Center(
            child: Container(
              width: 140,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey.shade700, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: (_presets[_selectedPreset]["colors"][1] as Color).withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _presets[_selectedPreset]["colors"] as List<Color>,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "08:14",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.brush, size: 12, color: _presets[_selectedPreset]["colors"][1] as Color),
                          const SizedBox(width: 4),
                          const Text("94%", style: TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "VERFÜGBARE DESIGNS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: XCleanTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_presets.length, (index) {
            final p = _presets[index];
            final isSelected = index == _selectedPreset;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: XCleanTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? XCleanTheme.cyan : XCleanTheme.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                onTap: () => setState(() => _selectedPreset = index),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(colors: p["colors"] as List<Color>),
                  ),
                ),
                title: Text(p["title"] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(p["desc"] as String, style: const TextStyle(fontSize: 12, color: XCleanTheme.textMuted)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: XCleanTheme.cyan)
                    : const Icon(Icons.circle_outlined, color: XCleanTheme.textMuted),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (_isUploading)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 6,
                    backgroundColor: XCleanTheme.cardSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(XCleanTheme.cyan),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Übertrage Display-Chunks... ${(_uploadProgress * 100).toInt()}%",
                  style: const TextStyle(fontSize: 12, color: XCleanTheme.cyan),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: _uploadWallpaper,
              style: ElevatedButton.styleFrom(
                backgroundColor: XCleanTheme.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "Wallpaper auf Bürste flashen",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
