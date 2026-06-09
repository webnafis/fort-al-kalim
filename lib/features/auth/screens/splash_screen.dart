import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Show splash for at least 2.5s
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Story screen handles whether to go to Home or Login next
    context.go(Routes.story);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Color(0xFF1A1A2E),
                  AppTheme.backgroundDark,
                ],
              ),
            ),
          ),
          // Animated logo + title
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fort icon placeholder (will be replaced with Lottie/asset)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.gold.withOpacity(0.4),
                          width: 2,
                        ),
                        gradient: const RadialGradient(
                          colors: [Color(0xFF2D1B00), AppTheme.backgroundDark],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🏰',
                          style: TextStyle(fontSize: 56),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Arabic title
                    Text(
                      'قلعة الكليم',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gold,
                        shadows: [
                          Shadow(
                            color: AppTheme.gold.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // English title
                    const Text(
                      'FORT AL-KALIM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tagline
                    Text(
                      'Words are your only weapons.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 56),
                    // Loading indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.gold.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
