import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../services/matchmaking_service.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  final int level;
  const MatchmakingScreen({super.key, required this.level});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  int _secondsLeft = 15;
  Timer? _timer;
  StreamSubscription<String>? _matchSub;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _startMatchmaking();
  }

  void _startMatchmaking() async {
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) {
      if (mounted) context.go(Routes.login);
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        }
      });
    });

    final service = ref.read(matchmakingServiceProvider);
    
    // Pass selected level, and lifetime score for rank
    final stream = service.findMatch(
      uid: user.uid,
      displayName: user.displayName,
      level: widget.level,
      lifetimeScore: user.lifetimeScore,
    );

    _matchSub = stream.listen((gameId) {
      if (_navigating) return;
      _navigating = true;
      _timer?.cancel();
      // Navigate to the reading phase for this game!
      if (mounted) {
        context.go('${Routes.readingPhase}?gameId=$gameId');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _matchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Searching for Opponent...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(height: 40),
              
              // Radar / Searching Animation Placeholder
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 2),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.gold,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Countdown text
              Text(
                '0:${_secondsLeft.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Expanding search radius...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 60),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: AppTheme.redFort),
                label: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.redFort, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
