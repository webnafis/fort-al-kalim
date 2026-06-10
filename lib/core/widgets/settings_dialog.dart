import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/services/settings_service.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: const Text('SETTINGS', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Music Volume', style: TextStyle(color: Colors.white)),
          Slider(
            value: settings.musicVolume,
            activeColor: AppTheme.gold,
            inactiveColor: Colors.white24,
            onChanged: (v) => notifier.setMusicVolume(v),
          ),
          const SizedBox(height: 16),
          const Text('Sound Effects Volume', style: TextStyle(color: Colors.white)),
          Slider(
            value: settings.sfxVolume,
            activeColor: AppTheme.gold,
            inactiveColor: Colors.white24,
            onChanged: (v) => notifier.setSfxVolume(v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
