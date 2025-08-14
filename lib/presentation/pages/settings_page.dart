// lib/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final bool muted;
  final ValueChanged<bool> onToggleMute;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final VoidCallback onResume;

  const SettingsPage({
    super.key,
    required this.muted,
    required this.onToggleMute,
    required this.onRestart,
    required this.onMainMenu,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: const Color(0xFF141418),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Mute sounds', style: TextStyle(color: Colors.white)),
                value: muted,
                onChanged: onToggleMute,
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: const Text('Restart', style: TextStyle(color: Colors.white)),
                onTap: onRestart,
              ),
              ListTile(
                title: const Text('Main Menu', style: TextStyle(color: Colors.white)),
                onTap: onMainMenu,
              ),
              ListTile(
                title: const Text('Resume', style: TextStyle(color: Colors.white)),
                onTap: onResume,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
