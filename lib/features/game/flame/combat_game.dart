import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import 'components/missile.dart';
import '../../../data/services/settings_service.dart';

class CombatGame extends FlameGame {
  late SpriteComponent _bg;
  late PositionComponent _playerFort;
  late PositionComponent _enemyFort;
  
  // Expose these so Flutter UI can show HP
  double playerHp = 250;
  double enemyHp = 250;

  late Sprite _bgDesktop;
  late Sprite _bgMobile;
  bool _isInitialized = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load both backgrounds
    _bgDesktop = await loadSprite('bg_combat_v3.png');
    _bgMobile = await loadSprite('bg_combat_mobile.png');

    final isWide = size.x / size.y > 1.2;

    _bg = SpriteComponent(
      sprite: isWide ? _bgDesktop : _bgMobile,
      size: size,
    );
    add(_bg);

    // The forts are now baked into the background image!
    // We just need invisible anchor points for the missiles to fly to/from.
    // They are positioned roughly on the left and right edges.
    
    final fortHeight = size.y * 0.75;
    final fortWidth = fortHeight; // Rough approximation of baked fort size
    final groundY = size.y - fortHeight;

    // Player Fort Anchor: Left side
    _playerFort = PositionComponent(
      size: Vector2(fortWidth, fortHeight),
      position: Vector2(size.x * 0.05, groundY),
    );
    add(_playerFort);

    // Enemy Fort Anchor: Right side
    _enemyFort = PositionComponent(
      size: Vector2(fortWidth, fortHeight),
      position: Vector2(size.x * 0.95 - fortWidth, groundY),
    );
    add(_enemyFort);

    _isInitialized = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_isInitialized) {
      _bg.size = size;
      final isWide = size.x / size.y > 1.2;
      _bg.sprite = isWide ? _bgDesktop : _bgMobile;

      final fortHeight = size.y * 0.75;
      final fortWidth = fortHeight;
      final groundY = size.y - fortHeight;
      _playerFort.size = Vector2(fortWidth, fortHeight);
      _playerFort.position = Vector2(size.x * 0.05, groundY);
      _enemyFort.size = Vector2(fortWidth, fortHeight);
      _enemyFort.position = Vector2(size.x * 0.95 - fortWidth, groundY);
    }
  }

  /// Fire a missile from Player -> Enemy
  void fireMissileAtEnemy(String type, double damage, VoidCallback onHit) {
    final start = _playerFort.position + Vector2(75, 0); // Top of player fort
    final end = _enemyFort.position + Vector2(75, 75); // Center of enemy fort

    final missile = MissileComponent(
      startPos: start,
      targetPos: end,
      type: type, // 'listen', 'read', 'write', 'speak'
      onHit: () {
        enemyHp -= damage;
        if (enemyHp < 0) enemyHp = 0;
        onHit();
      },
    );
    add(missile);
    SettingsNotifier.playSfx('launchmissile.mp3');
  }

  /// Enemy fires at Player
  void fireMissileAtPlayer(String type, double damage, VoidCallback onHit) {
    final start = _enemyFort.position + Vector2(75, 75); 
    final end = _playerFort.position + Vector2(75, 75);

    final missile = MissileComponent(
      startPos: start,
      targetPos: end,
      type: type,
      onHit: () {
        playerHp -= damage;
        if (playerHp < 0) playerHp = 0;
        onHit();
      },
    );
    add(missile);
    SettingsNotifier.playSfx('launchmissile.mp3');
  }
}
