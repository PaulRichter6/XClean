import 'package:flutter/material.dart';

class ControlButtonsWidget extends StatelessWidget {
  final bool isConnected;
  final bool isLoading;
  final bool liftToWake;
  final bool overPressure;
  final VoidCallback onSyncTime;
  final VoidCallback onFetchSessions;
  final VoidCallback onResetBrushHead;
  final ValueChanged<bool> onToggleLiftToWake;
  final ValueChanged<bool> onToggleOverPressure;

  const ControlButtonsWidget({
    super.key,
    required this.isConnected,
    required this.isLoading,
    required this.liftToWake,
    required this.overPressure,
    required this.onSyncTime,
    required this.onFetchSessions,
    required this.onResetBrushHead,
    required this.onToggleLiftToWake,
    required this.onToggleOverPressure,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Befehle & Einstellungen",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected && !isLoading ? onFetchSessions : null,
                    icon: const Icon(Icons.download),
                    label: const Text("Daten laden"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isConnected && !isLoading ? onSyncTime : null,
                    icon: const Icon(Icons.access_time),
                    label: const Text("Uhrzeit sync"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Switches
            SwitchListTile(
              title: const Text("Lift-to-Wake (Geste)"),
              subtitle: const Text("Display aktiviert sich beim Anheben"),
              value: liftToWake,
              onChanged: isConnected ? onToggleLiftToWake : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text("Überdruck-Warnung"),
              subtitle: const Text("Vibration & optischer Alarm bei zu viel Druck"),
              value: overPressure,
              onChanged: isConnected ? onToggleOverPressure : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            // Brush Head Reset
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: const Text("Bürstenkopf zurücksetzen"),
              subtitle: const Text("Setzt den Verschleißzähler (CMD 020F) auf 0"),
              dense: true,
              contentPadding: EdgeInsets.zero,
              trailing: TextButton(
                onPressed: isConnected && !isLoading ? onResetBrushHead : null,
                child: const Text("Reset", style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
