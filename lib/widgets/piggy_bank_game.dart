import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../services/coin_style_service.dart';

// ---------------------------------------------------------
// Forge2D Game (Physics Piggy Bank)
// ---------------------------------------------------------
class PiggyBankGame extends Forge2DGame {
  final int initialCoinCount;
  final List<Map<String, dynamic>> coinRecords;
  final double bellyWidth;
  final double bellyHeight;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Vector2 _currentGravity = Vector2(0, 98.0);

  PiggyBankGame({
    required this.initialCoinCount,
    required this.coinRecords,
    required this.bellyWidth,
    required this.bellyHeight,
  }) : super(gravity: Vector2(0, 98.0), zoom: 1.0);

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _createBellyBounds();

    final rnd = math.Random();
    // 表示上限を25個にする
    final int displayCoins = math.min(initialCoinCount, 25);
    
    for (int i = 0; i < displayCoins; i++) {
      final coinRecord = coinRecords.isNotEmpty ? coinRecords[i % coinRecords.length] : null;
      final type = coinRecord?['coin_type'] as String? ?? 'ordinary';
      final appearance = CoinStyleService.buildCoinAppearance(coinType: type);
      final color = appearance['color'] as Color;
      final icon = appearance['icon'] as IconData;

      final x = (size.x / 2) + (rnd.nextDouble() - 0.5) * (bellyWidth * 0.4);
      final y = (size.y / 2) - (bellyHeight * 0.2) + (rnd.nextDouble() * 20);

      add(CoinBody(initialPosition: Vector2(x, y), radius: 24.0 + rnd.nextDouble() * 6.0, color: color, icon: icon));
    }

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!isMounted) return;
      // Y軸は通常通り（下向きが正）、X軸は左右反転が必要な場合がある
      _currentGravity = Vector2(-event.x * 20.0, (event.y) * 20.0);
    });
  }

  Vector2 _dragGravity = Vector2.zero();

  void updateDragGravity(Offset offset) {
    // スワイプの勢いを重力に変換
    _dragGravity = Vector2(offset.dx * 5.0, offset.dy * 5.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // センサーの重力（通常） ＋ スワイプの重力（疑似的な傾き）
    world.gravity = _currentGravity + _dragGravity;
    
    // スワイプ重力を徐々に元に戻す（減衰）
    if (_dragGravity.length > 0.1) {
      _dragGravity.scale(0.9);
    } else {
      _dragGravity.setZero();
    }
  }

  @override
  void onRemove() {
    _accelerometerSubscription?.cancel();
    super.onRemove();
  }

  void _createBellyBounds() {
    final center = Vector2(size.x / 2 + size.x * 0.038, size.y / 2 - size.y * 0.02);
    final w = bellyWidth;
    final h = bellyHeight;

    final shape = ChainShape();
    final List<Vector2> vertices = [];
    
    // 0 から 2*pi （完全な楕円形のボウル）
    for (double angle = 0; angle <= 2 * math.pi; angle += math.pi / 16) {
      final x = center.x + math.cos(angle) * w / 2.0;
      final y = center.y + math.sin(angle) * h / 2.0;
      vertices.add(Vector2(x, y));
    }
    // createLoop()が自動的に最初と最後の点をつなぐので、最後の点は追加しない
    
    shape.createLoop(vertices);
    final fixtureDef = FixtureDef(shape, friction: 0.3, restitution: 0.2);
    final bodyDef = BodyDef(type: BodyType.static);
    final body = world.createBody(bodyDef);
    body.createFixture(fixtureDef);
  }

}

class CoinBody extends BodyComponent {
  final Vector2 initialPosition;
  final double radius;
  final Color color;
  final IconData icon;

  CoinBody({required this.initialPosition, required this.radius, required this.color, required this.icon});

  @override
  Body createBody() {
    // 物理的な当たり判定を少し小さくする（70%）ことで、視覚的にコインが重なり合って3Dのように見えるようにする
    final shape = CircleShape()..radius = radius * 0.7;
    final fixtureDef = FixtureDef(shape, density: 1.0, friction: 0.3, restitution: 0.6);
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset.zero;

    // Front Face (Soft matte gradient)
    final faceGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(color)
            .withLightness(
              math.min(1.0, HSLColor.fromColor(color).lightness + 0.15),
            )
            .toColor(),
        color,
        HSLColor.fromColor(color)
            .withLightness(
              math.max(0.0, HSLColor.fromColor(color).lightness - 0.1),
            )
            .toColor(),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()..shader = faceGradient;
    canvas.drawCircle(center, radius, paint);

    final innerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, innerShadow);

    // Embossed Icon
    final iconSize = radius * 0.9;
    final textPainterShadow = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.black.withValues(alpha: 0.15),
        ),
      ),
    );
    textPainterShadow.layout();
    textPainterShadow.paint(
      canvas,
      Offset(-textPainterShadow.width / 2, -textPainterShadow.height / 2 + 1.5),
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
