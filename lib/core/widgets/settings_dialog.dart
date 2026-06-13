import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../../data/services/settings_service.dart';
import '../../data/services/auth_service.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final userAsync = ref.watch(currentUserModelProvider);

    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: const Text('SETTINGS', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 16),
            userAsync.when(
              data: (user) {
                if (user == null) return const SizedBox.shrink();
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share Online Status', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Show a green dot to friends when online.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  activeColor: AppTheme.gold,
                  value: user.shareOnlineStatus,
                  onChanged: (v) {
                    FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'shareOnlineStatus': v,
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(color: AppTheme.gold),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
