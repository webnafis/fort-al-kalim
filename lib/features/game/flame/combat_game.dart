import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import 'components/missile.dart';
import '../../../data/services/settings_service.dart';

class CombatGame extends FlameGame {
  late SpriteComponent _bg;
  late SpriteComponent _playerFort;
  late SpriteComponent _enemyFort;
  
  // Expose these so Flutter UI can show HP
  double playerHp = 250;
  double enemyHp = 250;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load background
    final bgSprite = await loadSprite('bg_main.png');
    _bg = SpriteComponent(
      sprite: bgSprite,
      size: size,
    );
    add(_bg);

    // Load Forts
    final playerFortSprite = await loadSprite('fort_player.png');
    final enemyFortSprite = await loadSprite('fort_enemy.png');

    final fortSize = Vector2(150, 150);

    // Player Fort: Bottom Leftish
    _playerFort = SpriteComponent(
      sprite: playerFortSprite,
      size: fortSize,
      position: Vector2(20, size.y - 200),
    );
    add(_playerFort);

    // Enemy Fort: Top Rightish
    _enemyFort = SpriteComponent(
      sprite: enemyFortSprite,
      size: fortSize,
      position: Vector2(size.x - 170, 50),
    );
    add(_enemyFort);
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
