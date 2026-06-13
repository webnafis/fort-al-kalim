import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../../../../data/services/settings_service.dart';

class MissileComponent extends SpriteComponent with HasGameRef {
  final Vector2 startPos;
  final Vector2 targetPos;
  final String type; // 'listen', 'read', 'write', 'speak'
  final VoidCallback onHit;
  
  double speed = 400.0; // pixels per second

  MissileComponent({
    required this.startPos,
    required this.targetPos,
    required this.type,
    required this.onHit,
  }) : super(
         position: startPos,
         size: Vector2(40, 40),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    String imageName = 'missile_${type}_v2.png';
    // Fallback if type isn't one of the 4
    if (!['listen', 'read', 'write', 'speak'].contains(type)) {
      imageName = 'missile_read_v2.png'; 
    }
    
    sprite = await gameRef.loadSprite(imageName);
    
    // Rotate to face the target
    final delta = targetPos - startPos;
    angle = delta.screenAngle(); 
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    final direction = (targetPos - position).normalized();
    position += direction * speed * dt;
    
    // Check if we hit the target
    if (position.distanceTo(targetPos) < 10) {
      SettingsNotifier.playSfx('hit.mp3');
      onHit();
      removeFromParent(); // Explode / disappear
    }
  }
}
