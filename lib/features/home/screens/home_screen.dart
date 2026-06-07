// Placeholder screens — will be fully implemented in Phase 2 & 3

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════
Widget _placeholder(String title, IconData icon) {
  return Scaffold(
    backgroundColor: AppTheme.backgroundDark,
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppTheme.gold.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Coming in Phase 2 & 3',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context) =>
      _placeholder('Home', Icons.home_outlined);
}
