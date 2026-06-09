import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lockTimerServiceProvider = Provider((ref) => LockTimerService());

/// Manages the 30-second lock cooldown for words that the player answers incorrectly.
class LockTimerService {
  // Map of Word ID -> Timer
  final Map<String, Timer> _activeLocks = {};
  
  // Map of Word ID -> Seconds remaining (useful if UI wants to bind to it)
  final Map<String, int> _lockDurations = {};

  // Streams for UI to listen to specific word lock updates
  final Map<String, StreamController<int>> _streamControllers = {};

  /// Lock a word for 30 seconds after a failure
  void lockWord(String wordId) {
    // If it's already locked, reset the timer
    _activeLocks[wordId]?.cancel();
    
    _lockDurations[wordId] = 30;
    _getOrCreateController(wordId).add(30);

    _activeLocks[wordId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = (_lockDurations[wordId] ?? 30) - 1;
      
      if (remaining <= 0) {
        unlockWord(wordId);
      } else {
        _lockDurations[wordId] = remaining;
        _getOrCreateController(wordId).add(remaining);
      }
    });
  }

  /// Manually unlock a word early, or called internally when timer hits 0
  void unlockWord(String wordId) {
    _activeLocks[wordId]?.cancel();
    _activeLocks.remove(wordId);
    _lockDurations.remove(wordId);
    
    _getOrCreateController(wordId).add(0);
  }

  /// Check if a word is currently locked
  bool isLocked(String wordId) {
    return _activeLocks.containsKey(wordId);
  }

  /// Watch a word's remaining lock time in seconds
  Stream<int> watchLockTime(String wordId) {
    return _getOrCreateController(wordId).stream;
  }

  StreamController<int> _getOrCreateController(String wordId) {
    if (!_streamControllers.containsKey(wordId)) {
      // Create broadcast stream so multiple widgets can listen (e.g. word card + HUD)
      _streamControllers[wordId] = StreamController<int>.broadcast();
    }
    return _streamControllers[wordId]!;
  }

  /// Clean up all timers when the game ends
  void dispose() {
    for (var timer in _activeLocks.values) {
      timer.cancel();
    }
    _activeLocks.clear();
    _lockDurations.clear();
    
    for (var controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}
