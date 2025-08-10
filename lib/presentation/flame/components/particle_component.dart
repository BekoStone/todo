import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/performance_utils.dart' hide Vector2;

/// A Flame component for managing particle effects.
/// Handles various game particle effects like explosions, sparkles, and celebrations.
/// Follows Clean Architecture by being a pure presentation component.
class ParticleComponent extends PositionComponent with HasGameRef {
  // Configuration
  final ParticleType particleType;
  final Color primaryColor;
  final int particleCount;
  final double intensity;
  final Duration duration;
  
  // Internal components
  late ParticleSystemComponent _particleSystem;
  
  // Performance monitoring
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  ParticleComponent._({
    required this.particleType,
    required this.primaryColor,
    required this.particleCount,
    required this.intensity,
    required this.duration,
    required Vector2 position,
  }) {
    this.position = position;
  }

  /// Factory constructor for block placement effect
  factory ParticleComponent.blockPlacement({
    required Vector2 position,
    required Color color,
  }) {
    return ParticleComponent._(
      particleType: ParticleType.blockPlacement,
      primaryColor: color,
      particleCount: 15,
      intensity: 0.7,
      duration: const Duration(milliseconds: 800),
      position: position,
    );
  }

  /// Factory constructor for line clear effect
  factory ParticleComponent.lineClear({
    required Vector2 position,
    required double cellSize,
  }) {
    return ParticleComponent._(
      particleType: ParticleType.lineClear,
      primaryColor: AppColors.accent,
      particleCount: 25,
      intensity: 1.0,
      duration: const Duration(milliseconds: 1200),
      position: position,
    );
  }

  /// Factory constructor for combo effect
  factory ParticleComponent.combo({
    required Vector2 position,
    required int comboLevel,
  }) {
    return ParticleComponent._(
      particleType: ParticleType.combo,
      primaryColor: AppColors.warning,
      particleCount: 10 + (comboLevel * 5),
      intensity: 0.5 + (comboLevel * 0.2),
      duration: Duration(milliseconds: 600 + (comboLevel * 200)),
      position: position,
    );
  }

  /// Factory constructor for power-up activation effect
  factory ParticleComponent.powerUpActivation({
    required Vector2 position,
    required Color powerUpColor,
  }) {
    return ParticleComponent._(
      particleType: ParticleType.powerUpActivation,
      primaryColor: powerUpColor,
      particleCount: 30,
      intensity: 1.2,
      duration: const Duration(milliseconds: 1500),
      position: position,
    );
  }

  /// Factory constructor for achievement unlock effect
  factory ParticleComponent.achievementUnlock({
    required Vector2 position,
  }) {
    return ParticleComponent._(
      particleType: ParticleType.achievementUnlock,
      primaryColor: AppColors.success,
      particleCount: 50,
      intensity: 1.5,
      duration: const Duration(milliseconds: 2000),
      position: position,
    );
  }

  /// Factory constructor for game over effect
  factory ParticleComponent.gameOver({
    required Vector2 position,
  }) {
    return ParticleComponent._(
      particleType: ParticleType.gameOver,
      primaryColor: AppColors.error,
      particleCount: 100,
      intensity: 2.0,
      duration: const Duration(milliseconds: 3000),
      position: position,
    );
  }

  /// Factory constructor for celebration effect
  factory ParticleComponent.celebration({
    required Vector2 position,
  }) {
    return ParticleComponent._(
      particleType: ParticleType.celebration,
      primaryColor: AppColors.success,
      particleCount: 80,
      intensity: 1.8,
      duration: const Duration(milliseconds: 2500),
      position: position,
    );
  }

  /// Factory constructor for score popup effect
  factory ParticleComponent.scorePopup({
    required Vector2 position,
    required int score,
  }) {
    return ParticleComponent._(
      particleType: ParticleType.scorePopup,
      primaryColor: AppColors.accent,
      particleCount: 8,
      intensity: 0.6,
      duration: const Duration(milliseconds: 1000),
      position: position,
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    _performanceMonitor.startTracking('particle_creation');
    
    await _createParticleSystem();
    
    _performanceMonitor.stopTracking('particle_creation');
    
    debugPrint('✨ ParticleComponent loaded - Type: $particleType');
  }

  /// Create the appropriate particle system based on type
  Future<void> _createParticleSystem() async {
    Particle particle;
    
    switch (particleType) {
      case ParticleType.blockPlacement:
        particle = _createBlockPlacementParticle();
        break;
      case ParticleType.lineClear:
        particle = _createLineClearParticle();
        break;
      case ParticleType.combo:
        particle = _createComboParticle();
        break;
      case ParticleType.powerUpActivation:
        particle = _createPowerUpActivationParticle();
        break;
      case ParticleType.achievementUnlock:
        particle = _createAchievementUnlockParticle();
        break;
      case ParticleType.gameOver:
        particle = _createGameOverParticle();
        break;
      case ParticleType.celebration:
        particle = _createCelebrationParticle();
        break;
      case ParticleType.scorePopup:
        particle = _createScorePopupParticle();
        break;
    }
    
    _particleSystem = ParticleSystemComponent(
      particle: particle,
    );
    
    add(_particleSystem);
    
    // Auto-remove after duration
    Future.delayed(duration, () {
      removeFromParent();
    });
  }

  /// Create particle effect for block placement
  Particle _createBlockPlacementParticle() {
    return Particle.generate(
      count: particleCount,
      lifespan: duration.inMilliseconds / 1000,
      generator: (i) {
        final random = math.Random();
        final angle = random.nextDouble() * 2 * math.pi;
        final speed = random.nextDouble() * 100 * intensity;
        
        return AcceleratedParticle(
          acceleration: Vector2(0, 98), // Gravity
          speed: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed - 50,
          ),
          child: CircleParticle(
            radius: 2 + random.nextDouble() * 3,
            paint: Paint()
              ..color = _getParticleColor(random)
              ..blendMode = BlendMode.plus,
          ),
        );
      },
    );
  }

  /// Create particle effect for line clearing
  Particle _createLineClearParticle() {
    return Particle.generate(
      count: particleCount,
      lifespan: duration.inMilliseconds / 1000,
      generator: (i) {
        final random = math.Random();
        final angle = random.nextDouble() * 2 * math.pi;
        final speed = random.nextDouble() * 150 * intensity;
        
        return ComputedParticle(
          lifespan: duration.inMilliseconds / 1000,
          renderer: (canvas, particle) {
            final progress = particle.progress;
            final size = (5 * (1 - progress)).clamp(0.0, 5.0);
            
            canvas.drawCircle(
              Offset.zero,
              size,
              Paint()
                ..color = _getParticleColor(random).withValues(alpha:1 - progress)
                ..blendMode = BlendMode.plus,
            );
          },
        ).moving(
          by: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed,
          ),
        );
      },
    );
  }

  /// Create particle effect for combo
  Particle _createComboParticle() {
    return Particle.generate(
      count: particleCount,
      lifespan: duration.inMilliseconds / 1000,
      generator: (i) {
        final random = math.Random();
        final angle = (i / particleCount) * 2 * math.pi;
        final speed = 80 + random.nextDouble() * 40;
        
        return AcceleratedParticle(
          acceleration: Vector2(0, -50), // Upward acceleration
          speed: Vector2(
            math.cos(angle) * speed * intensity,
            math.sin(angle) * speed * intensity,
          ),
          child: ScalingParticle(
            from: 1.0,
            to: 0.0,
            child: RotatingParticle(
              from: 0,
              to: math.pi * 4,
              child: RectangleParticle(
                size: Vector2.all(4 + random.nextDouble() * 4),
                paint: Paint()
                  ..color = _getComboColor(random)
                  ..blendMode = BlendMode.plus,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Create particle effect for power-up activation
  Particle _createPowerUpActivationParticle() {
    return ComposedParticle(
      children: [
        // Inner burst
        Particle.generate(
          count: particleCount ~/ 2,
          lifespan: duration.inMilliseconds / 1000 * 0.6,
          generator: (i) {
            final random = math.Random();
            final angle = random.nextDouble() * 2 * math.pi;
            final speed = random.nextDouble() * 200 * intensity;
            
            return MovingParticle(
              from: Vector2.zero(),
              to: Vector2(
                math.cos(angle) * speed,
                math.sin(angle) * speed,
              ),
              child: ScalingParticle(
                from: 1.5,
                to: 0.0,
                child: CircleParticle(
                  radius: 6 + random.nextDouble() * 4,
                  paint: Paint()
                    ..color = primaryColor.withValues(alpha:0.8)
                    ..blendMode = BlendMode.plus,
                ),
              ),
            );
          },
        ),
        
        // Outer ring
        Particle.generate(
          count: particleCount ~/ 2,
          lifespan: duration.inMilliseconds / 1000,
          generator: (i) {
            final angle = (i / (particleCount ~/ 2)) * 2 * math.pi;
            final radius = 50 + math.Random().nextDouble() * 30;
            
            return MovingParticle(
              from: Vector2.zero(),
              to: Vector2(
                math.cos(angle) * radius,
                math.sin(angle) * radius,
              ),
              child: ScalingParticle(
                from: 0.5,
                to: 1.2,
                curve: Curves.easeOut,
                child: RotatingParticle(
                  from: 0,
                  to: math.pi * 2,
                  child: RectangleParticle(
                    size: Vector2.all(3),
                    paint: Paint()
                      ..color = primaryColor.withValues(alpha:0.6),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Create particle effect for achievement unlock
  Particle _createAchievementUnlockParticle() {
    return ComposedParticle(
      children: [
        // Fireworks effect
        Particle.generate(
          count: particleCount,
          lifespan: duration.inMilliseconds / 1000,
          generator: (i) {
            final random = math.Random();
            final delay = random.nextDouble() * 0.5;
            
            return TimerParticle(
              lifespan: delay,
              child: Particle.generate(
                count: 8,
                lifespan: 1.5,
                generator: (j) {
                  final angle = (j / 8) * 2 * math.pi;
                  final speed = 100 + random.nextDouble() * 100;
                  
                  return AcceleratedParticle(
                    acceleration: Vector2(0, 98),
                    speed: Vector2(
                      math.cos(angle) * speed,
                      math.sin(angle) * speed - 100,
                    ),
                    child: ScalingParticle(
                      from: 1.0,
                      to: 0.0,
                      child: CircleParticle(
                        radius: 4,
                        paint: Paint()
                          ..color = _getAchievementColor(random)
                          ..blendMode = BlendMode.plus,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Create particle effect for game over
  Particle _createGameOverParticle() {
    return Particle.generate(
      count: particleCount,
      lifespan: duration.inMilliseconds / 1000,
      generator: (i) {
        final random = math.Random();
        final startAngle = random.nextDouble() * 2 * math.pi;
        final speed = random.nextDouble() * 50 + 25;
        
        return AcceleratedParticle(
          acceleration: Vector2(0, 98),
          speed: Vector2(
            math.cos(startAngle) * speed,
            math.sin(startAngle) * speed - 50,
          ),
          child: ScalingParticle(
            from: 1.0,
            to: 0.3,
            child: RotatingParticle(
              from: 0,
              to: math.pi * 4,
              child: RectangleParticle(
                size: Vector2.all(8 + random.nextDouble() * 4),
                paint: Paint()
                  ..color = _getGameOverColor(random)
                  ..blendMode = BlendMode.multiply,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Create particle effect for celebration
  Particle _createCelebrationParticle() {
    return ComposedParticle(
      children: [
        // Confetti
        Particle.generate(
          count: particleCount * 2 ~/ 3,
          lifespan: duration.inMilliseconds / 1000,
          generator: (i) {
            final random = math.Random();
            final angle = random.nextDouble() * 2 * math.pi;
            final speed = random.nextDouble() * 200 + 100;
            
            return AcceleratedParticle(
              acceleration: Vector2(0, 98),
              speed: Vector2(
                math.cos(angle) * speed,
                math.sin(angle) * speed - 200,
              ),
              child: RotatingParticle(
                from: 0,
                to: math.pi * 8,
                child: RectangleParticle(
                  size: Vector2(
                    6 + random.nextDouble() * 4,
                    2 + random.nextDouble() * 2,
                  ),
                  paint: Paint()
                    ..color = _getCelebrationColor(random),
                ),
              ),
            );
          },
        ),
        
        // Sparkles
        Particle.generate(
          count: particleCount ~/ 3,
          lifespan: duration.inMilliseconds / 1000 * 0.7,
          generator: (i) {
            final random = math.Random();
            final angle = random.nextDouble() * 2 * math.pi;
            final distance = random.nextDouble() * 150;
            
            return MovingParticle(
              from: Vector2.zero(),
              to: Vector2(
                math.cos(angle) * distance,
                math.sin(angle) * distance,
              ),
              child: ScalingParticle(
                from: 0.0,
                to: 1.0,
                curve: Curves.elasticOut,
                child: RotatingParticle(
                  from: 0,
                  to: math.pi * 2,
                  child: SpriteParticle(
                    sprite: null, // Would be a star sprite
                    size: Vector2.all(8),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Create particle effect for score popup
  Particle _createScorePopupParticle() {
    return Particle.generate(
      count: particleCount,
      lifespan: duration.inMilliseconds / 1000,
      generator: (i) {
        final random = math.Random();
        final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi / 2;
        final speed = 50 + random.nextDouble() * 30;
        
        return MovingParticle(
          from: Vector2.zero(),
          to: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed,
          ),
          child: ScalingParticle(
            from: 1.0,
            to: 0.0,
            child: CircleParticle(
              radius: 3 + random.nextDouble() * 2,
              paint: Paint()
                ..color = primaryColor.withValues(alpha:0.7)
                ..blendMode = BlendMode.plus,
            ),
          ),
        );
      },
    );
  }

  /// Get varied particle color based on primary color
  Color _getParticleColor(math.Random random) {
    final hsl = HSLColor.fromColor(primaryColor);
    final hueVariation = (random.nextDouble() - 0.5) * 0.1;
    final saturationVariation = (random.nextDouble() - 0.5) * 0.2;
    final lightnessVariation = (random.nextDouble() - 0.5) * 0.2;
    
    return hsl.withHue((hsl.hue + hueVariation * 360) % 360)
        .withSaturation((hsl.saturation + saturationVariation).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + lightnessVariation).clamp(0.0, 1.0))
        .toColor();
  }

  /// Get combo-specific colors
  Color _getComboColor(math.Random random) {
    final colors = [
      AppColors.warning,
      AppColors.accent,
      AppColors.success,
      Colors.purple,
      Colors.orange,
    ];
    
    return colors[random.nextInt(colors.length)];
  }

  /// Get achievement-specific colors
  Color _getAchievementColor(math.Random random) {
    final colors = [
      AppColors.success,
      Colors.gold,
      Colors.orange,
      AppColors.accent,
    ];
    
    return colors[random.nextInt(colors.length)];
  }

  /// Get game over colors
  Color _getGameOverColor(math.Random random) {
    final colors = [
      AppColors.error,
      Colors.grey,
      Colors.black54,
    ];
    
    return colors[random.nextInt(colors.length)];
  }

  /// Get celebration colors
  Color _getCelebrationColor(math.Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    
    return colors[random.nextInt(colors.length)];
  }

  @override
  void onRemove() {
    _performanceMonitor.dispose();
    super.onRemove();
  }
}

/// Enum defining different types of particle effects
enum ParticleType {
  blockPlacement,
  lineClear,
  combo,
  powerUpActivation,
  achievementUnlock,
  gameOver,
  celebration,
  scorePopup,
}