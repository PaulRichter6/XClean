import 'package:flutter/material.dart';
import '../theme/xclean_theme.dart';

class ProfileScreen extends StatelessWidget {
  final int streakDays;

  const ProfileScreen({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XCleanTheme.background,
      appBar: AppBar(
        title: const Text(
          "BENUTZERPROFIL",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [XCleanTheme.cyan, XCleanTheme.emerald]),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Icon(Icons.person, size: 40, color: Colors.black),
                ),
                const SizedBox(height: 12),
                const Text("XClean User", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("Local & Offline Mode • Keine Cloud", style: TextStyle(fontSize: 12, color: XCleanTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Streak Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$streakDays Tage Putz-Streak!", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.orange)),
                      const Text("Jeden Tag morgens & abends geputzt", style: TextStyle(fontSize: 12, color: XCleanTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("ENTWICKLER & FORSCHUNG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: XCleanTheme.textMuted)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: XCleanTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: XCleanTheme.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.terminal, color: XCleanTheme.cyan),
                  title: const Text("Custom Firmware (Forschung)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Status & Machbarkeitsanalyse für eigene FW", style: TextStyle(fontSize: 12, color: XCleanTheme.textMuted)),
                  trailing: const Icon(Icons.chevron_right, color: XCleanTheme.textMuted),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: XCleanTheme.cardBg,
                        title: const Text("Eigene Firmware flashen?"),
                        content: const Text(
                          "Die Oclean X Pro Elite nutzt einen Dialog Semiconductor DA1469x BLE SoC (ARM Cortex-M33). "
                          "Firmware-Binaries erfordern cryptografische Signaturen oder direkten SWD-Hardware-Zugriff via JLink an den internen Testpads. "
                          "Software-OTA ohne offizielle Oclean Private-Keys würde die Bürste bricken. BLE-Befehle und Display-Wallpapers sind der sicherste Weg!",
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Verstanden")),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(color: XCleanTheme.border, height: 1),
                const ListTile(
                  leading: Icon(Icons.shield_outlined, color: XCleanTheme.emerald),
                  title: Text("100% Werbefrei & Open-Source", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Keine Telemetrie an Oclean-Cloud / Drittanbieter", style: TextStyle(fontSize: 12, color: XCleanTheme.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
