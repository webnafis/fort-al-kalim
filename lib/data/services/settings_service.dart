import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_audio/flame_audio.dart';

class SettingsState {
  final double musicVolume;
  final double sfxVolume;

  const SettingsState({
    this.musicVolume = 1.0,
    this.sfxVolume = 1.0,
  });

  SettingsState copyWith({
    double? musicVolume,
    double? sfxVolume,
  }) {
    return SettingsState(
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  // Global static accessors for non-widget components like Flame
  static double currentMusicVolume = 1.0;
  static double currentSfxVolume = 1.0;

  static String? currentBgmTrack;

  /// Global helper to play sound effects respecting the SFX volume setting
  static void playSfx(String file) {
    if (currentSfxVolume > 0) {
      FlameAudio.play(file, volume: currentSfxVolume);
    }
  }

  /// Global helper to play BGM, remembering the track so it can restore if volume was 0
  static Future<void> playBgm(String file) async {
    currentBgmTrack = file;
    await FlameAudio.bgm.stop();
    if (currentMusicVolume > 0) {
      await FlameAudio.bgm.play(file, volume: currentMusicVolume);
    }
  }

  SettingsNotifier(this._prefs) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final music = _prefs.getDouble('musicVolume') ?? 1.0;
    final sfx = _prefs.getDouble('sfxVolume') ?? 1.0;
    state = SettingsState(musicVolume: music, sfxVolume: sfx);
    currentMusicVolume = music;
    currentSfxVolume = sfx;
    _applyMusicVolume(music);
  }

  Future<void> setMusicVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    await _prefs.setDouble('musicVolume', v);
    state = state.copyWith(musicVolume: v);
    currentMusicVolume = v;
    _applyMusicVolume(v);
  }

  Future<void> setSfxVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    await _prefs.setDouble('sfxVolume', v);
    state = state.copyWith(sfxVolume: v);
    currentSfxVolume = v;
  }

  void _applyMusicVolume(double v) {
    if (v <= 0) {
      if (FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.pause();
      }
    } else {
      if (!FlameAudio.bgm.isPlaying) {
        // If a track is stored but wasn't playing (e.g. because it was blocked by 0 volume), play it now
        if (currentBgmTrack != null && FlameAudio.bgm.audioPlayer?.source == null) {
          FlameAudio.bgm.play(currentBgmTrack!, volume: v);
        } else {
          FlameAudio.bgm.resume();
        }
      }
      FlameAudio.bgm.audioPlayer?.setVolume(v);
    }
  }
}

// Ensure you override this in main.dart:
// ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)])
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
