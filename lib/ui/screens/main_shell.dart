import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/toothbrush_state.dart';
import '../theme/xclean_theme.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'brush_program_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ToothbrushState>();

    final screens = [
      const DashboardScreen(),
      const HistoryScreen(),
      StatisticsScreen(history: state.history),
      const BrushProgramScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: XCleanTheme.background,
      body: Stack(
        children: [
          // Content Tab Stack
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Revolut-Style Floating Navigation Bar (Ultra-Clean Frosted Glass)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171E).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_rounded,
                        label: "Home",
                        activeColor: XCleanTheme.cyan,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.history_rounded,
                        label: "Verlauf",
                        activeColor: XCleanTheme.emerald,
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.insights_rounded,
                        label: "Statistik",
                        activeColor: Colors.purpleAccent,
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.tune_rounded,
                        label: "Modi",
                        activeColor: XCleanTheme.cyan,
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: Icons.settings_rounded,
                        label: "Settings",
                        activeColor: XCleanTheme.amber,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : XCleanTheme.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? activeColor : XCleanTheme.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
