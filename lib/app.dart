import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/services/settings_service.dart';
import 'data/services/presence_service.dart';

class FortAlKalimApp extends ConsumerWidget {
  const FortAlKalimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize settings on app start so audio preferences are enforced globally
    ref.watch(settingsProvider);
    // Eagerly initialize the presence service so online tracking starts in the background
    ref.watch(presenceServiceProvider);
    
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Fort Al-Kalim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
