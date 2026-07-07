// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '5_collection.dart';
import 'dart:math' as math; // 必要であれば

// lib/screens/1_home.dart 内の HomeScreen クラスを修正
class HomeScreen extends StatefulWidget {
  // 🌟 ここで引数を受け取れるようにします
  final String savedNote;
  final int currentCoins;

  const HomeScreen({
    super.key, 
    this.savedNote = '', 
    this.currentCoins = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _coinCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoinCount();
  }

  Future<void> _fetchCoinCount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('happy_coins')
          .select('id')
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          _coinCount = (data as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('コイン数取得エラー: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7EE),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF4A4A4A)),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('貯まったコイン', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 40),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Text('$_coinCount', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
                  const Text('枚', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),
              PiggyBankCard(currentCoins: _coinCount), // あやかさんの描画用カード
            ],
          ),
        ),
      ),
    );
  }
}


class PiggyBankCard extends StatelessWidget {
  const PiggyBankCard({
    super.key,
    this.currentCoins = 7,
    this.fallingCoin,
    this.showCollectionButton = true,
  });

  final int currentCoins;
  final Widget? fallingCoin;
  final bool showCollectionButton;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CollectionScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            height: 400,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Landscape (Gradient, Grass, Flowers, Hearts)
                Positioned.fill(
                  child: CustomPaint(painter: PiggyBankBackgroundPainter()),
                ),

                // Glass Piggy Bank UI
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GlassPiggyBank(
                      currentCoins: currentCoins,
                      fallingCoin: fallingCoin,
                    ),
                  ),
                ),

                // Button overlay
                if (showCollectionButton)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFF06292),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'コレクションを見る',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PiggyBankBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. 空のグラデーション
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFFF0F5), // 薄いピンク
        const Color(0xFFFCF5EE), // クリーム
        const Color(0xFFF0F8FF), // 薄い水色
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = skyGradient.createShader(rect));

    // 光のオーブ（空に浮かぶキラキラ）
    void drawBokeh(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    drawBokeh(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.3,
      Colors.white.withValues(alpha: 0.5),
    );
    drawBokeh(
      Offset(size.width * 0.8, size.height * 0.4),
      size.width * 0.4,
      const Color(0xFFFFFACD).withValues(alpha: 0.3),
    );

    // 2. 芝生の丘（丸みのある丘をいくつか重ねる）
    final hillPaint1 = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE2F0D9), Color(0xFFC5E0B4)],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
          );

    final hillPaint2 = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD5E8D4), Color(0xFFA9C4A0)],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
          );

    // 奥の丘
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.2, size.height * 0.9),
        width: size.width * 1.5,
        height: size.height * 0.6,
      ),
      hillPaint1,
    );
    // 手前の丘
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.95),
        width: size.width * 1.5,
        height: size.height * 0.5,
      ),
      hillPaint2,
    );

    // 3. 芝生の葉っぱ
    void drawGrass(Offset pos, double scale) {
      final paint = Paint()
        ..color = const Color(0xFF9CC864).withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      void drawBlade(double angleDeg, double height) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(angleDeg * math.pi / 180);
        final path = Path();
        path.moveTo(-3 * scale, 0);
        path.quadraticBezierTo(0, -height * 0.5 * scale, 0, -height * scale);
        path.quadraticBezierTo(3 * scale, -height * 0.5 * scale, 3 * scale, 0);
        canvas.drawPath(path, paint);
        canvas.restore();
      }

      drawBlade(-15, 20);
      drawBlade(0, 30);
      drawBlade(15, 18);
    }

    drawGrass(Offset(size.width * 0.15, size.height * 0.85), 1.0);
    drawGrass(Offset(size.width * 0.85, size.height * 0.9), 1.2);
    drawGrass(Offset(size.width * 0.4, size.height * 0.95), 0.8);
    drawGrass(Offset(size.width * 0.7, size.height * 0.8), 0.9);

    // 4. お花
    void drawFlower(Offset pos, double sizeParam, Color petalColor) {
      final petalPaint = Paint()..color = petalColor;
      // 影
      canvas.drawCircle(
        pos + const Offset(0, 2),
        sizeParam * 1.2,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * math.pi) / 5;
        final cx = pos.dx + math.cos(angle) * sizeParam * 0.7;
        final cy = pos.dy + math.sin(angle) * sizeParam * 0.7;
        canvas.drawCircle(Offset(cx, cy), sizeParam * 0.55, petalPaint);
      }
      // 中心
      canvas.drawCircle(
        pos,
        sizeParam * 0.45,
        Paint()..color = const Color(0xFFFFD54F),
      );
    }

    drawFlower(
      Offset(size.width * 0.22, size.height * 0.88),
      10,
      const Color(0xFFFFF2ED),
    );
    drawFlower(
      Offset(size.width * 0.8, size.height * 0.92),
      12,
      const Color(0xFFFFE4E1),
    );
    drawFlower(
      Offset(size.width * 0.1, size.height * 0.8),
      8,
      const Color(0xFFE0FFFF),
    );

    // 5. 蝶々（♡）
    void drawButterflyHeart(
      Offset pos,
      double sizeParam,
      double rotation,
      Color color,
    ) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotation);

      final paint = Paint()..color = color;
      final path = Path();
      path.moveTo(0, sizeParam * 0.3);
      path.cubicTo(
        -sizeParam,
        -sizeParam * 0.5,
        -sizeParam * 0.2,
        -sizeParam,
        0,
        -sizeParam * 0.3,
      );
      path.cubicTo(
        sizeParam * 0.2,
        -sizeParam,
        sizeParam,
        -sizeParam * 0.5,
        0,
        sizeParam * 0.3,
      );
      canvas.drawPath(path, paint);

      canvas.restore();
    }

    drawButterflyHeart(
      Offset(size.width * 0.15, size.height * 0.5),
      10,
      -0.2,
      const Color(0xFFFFB6C1).withValues(alpha: 0.9),
    );
    drawButterflyHeart(
      Offset(size.width * 0.82, size.height * 0.3),
      14,
      0.3,
      const Color(0xFFFF69B4).withValues(alpha: 0.8),
    );
    drawButterflyHeart(
      Offset(size.width * 0.75, size.height * 0.55),
      8,
      0.1,
      const Color(0xFFFFC0CB).withValues(alpha: 0.9),
    );
    drawButterflyHeart(
      Offset(size.width * 0.3, size.height * 0.2),
      12,
      -0.4,
      const Color(0xFFFFA07A).withValues(alpha: 0.8),
    );

    // 6. 星（キラキラ）
    void drawSparkle(Offset center, double sizeParam, double opacity) {
      final path = Path();
      path.moveTo(center.dx, center.dy - sizeParam);
      path.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx + sizeParam,
        center.dy,
      );
      path.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx,
        center.dy + sizeParam,
      );
      path.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx - sizeParam,
        center.dy,
      );
      path.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx,
        center.dy - sizeParam,
      );
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }

    drawSparkle(Offset(size.width * 0.85, size.height * 0.15), 12, 0.8);
    drawSparkle(Offset(size.width * 0.1, size.height * 0.7), 10, 0.6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassPiggyBank extends StatelessWidget {
  final int currentCoins;
  final Widget? fallingCoin;
  const GlassPiggyBank({
    super.key,
    required this.currentCoins,
    this.fallingCoin,
  });

  @override
  Widget build(BuildContext context) {
    final mockCategories = [
      {'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFF64B5F6)},
      {'icon': Icons.favorite_rounded, 'color': const Color(0xFFF06292)},
      {'icon': Icons.home_rounded, 'color': const Color(0xFFFFB74D)},
      {'icon': Icons.star_rounded, 'color': const Color(0xFFFFD54F)},
      {'icon': Icons.restaurant_rounded, 'color': const Color(0xFF81C784)},
      {'icon': Icons.music_note_rounded, 'color': const Color(0xFFBA68C8)},
      {'icon': Icons.directions_run_rounded, 'color': const Color(0xFF4DB6AC)},
    ];

    final rnd = math.Random(88);

    final List<Widget> coins = [];
    final int displayCoins = math.min(currentCoins, 25);

    final double areaSize = 350.0;
    // 豚らしい横長の楕円形（Oval）のサイズ
    final double bellyWidth = areaSize * 0.8;
    final double bellyHeight = areaSize * 0.65;
    final double bellyCenterX = areaSize * 0.5;
    final double bellyCenterY = areaSize * 0.5;

    for (int i = 0; i < displayCoins; i++) {
      // 楕円の下半分にコインを配置
      final double angle = rnd.nextDouble() * math.pi;
      final double r = math.sqrt(rnd.nextDouble());

      final double cx =
          bellyCenterX + math.cos(angle) * (bellyWidth / 2 * 0.85) * r;
      final double cy =
          bellyCenterY +
          (bellyHeight * 0.1) +
          (math.sin(angle) * (bellyHeight / 2 * 0.75) * r) -
          (i * 1.5);

      final category = mockCategories[rnd.nextInt(mockCategories.length)];
      final double coinSize = 35.0 + rnd.nextDouble() * 10.0;

      final double angleX = (rnd.nextDouble() - 0.5) * 0.6;
      final double angleY = (rnd.nextDouble() - 0.5) * 0.6;
      final double angleZ = rnd.nextDouble() * 2 * math.pi;

      coins.add(
        Positioned(
          left: cx - (coinSize / 2),
          top: cy - (coinSize / 2),
          child: Coin3D(
            category: category,
            size: coinSize,
            angleX: angleX,
            angleY: angleY,
            angleZ: angleZ,
          ),
        ),
      );
    }

    coins.sort((a, b) {
      final posA = a as Positioned;
      final posB = b as Positioned;
      return posA.top!.compareTo(posB.top!);
    });

    return Center(
      child: SizedBox(
        width: areaSize,
        height: areaSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. 背面のガラス層
            Positioned.fill(
              child: CustomPaint(painter: GlassPiggyBankBackPainter()),
            ),

            // 2. コイン層（ガラスからはみ出ないように楕円でクリップ）
            Positioned.fill(
              child: ClipPath(
                clipper: PiggyBankBellyClipper(
                  center: Offset(bellyCenterX, bellyCenterY),
                  width: bellyWidth * 0.9,
                  height: bellyHeight * 0.9,
                ),
                child: Stack(clipBehavior: Clip.none, children: coins),
              ),
            ),

            // 落下中のコイン
            if (fallingCoin != null) fallingCoin!,

            // 3. 前面のガラス層
            Positioned.fill(
              child: CustomPaint(painter: GlassPiggyBankFrontPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class PiggyBankBellyClipper extends CustomClipper<Path> {
  final Offset center;
  final double width;
  final double height;
  PiggyBankBellyClipper({
    required this.center,
    required this.width,
    required this.height,
  });

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCenter(center: center, width: width, height: height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// ---------------------------------------------------------
// Pure Code 3D Glass Painters (Pig Shape)
// ---------------------------------------------------------

/// 貯金箱の背面（後ろの足、後ろの耳、背面のガラス壁）
class GlassPiggyBankBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final width = size.width * 0.8;
    final height = size.width * 0.65;

    void drawBackLeg(Offset legCenter) {
      final legRect = Rect.fromCenter(
        center: legCenter,
        width: width * 0.12,
        height: height * 0.25,
      );
      final legRRect = RRect.fromRectAndRadius(
        legRect,
        const Radius.circular(15),
      );

      // 暗めのガラス影
      canvas.drawRRect(
        legRRect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      // ガラスのハイライト（背面でも少し光る）
      canvas.drawRRect(
        legRRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.4),
            ],
          ).createShader(legRect),
      );
      // エッジのハイライトで輪郭を強調して視認性アップ
      final highlightPath = Path()
        ..moveTo(legRect.left + 3, legRect.top + 5)
        ..lineTo(legRect.left + 3, legRect.bottom - 5);
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 後ろの左足と右足（奥まった位置に配置して4本足に）
    drawBackLeg(Offset(center.dx - width * 0.1, center.dy + height * 0.35));
    drawBackLeg(Offset(center.dx + width * 0.35, center.dy + height * 0.35));

    // 背面のガラスの厚み（内側のシャドウとわずかなシアンで奥行きを表現）
    final bodyRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    final backBodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.08),
          const Color(0xFFE0F7FA).withValues(alpha: 0.4),
        ],
        stops: const [0.7, 0.9, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, backBodyPaint);

    // 投入口の奥側（暗いスリット線）
    final slotCenter = Offset(
      center.dx + width * 0.05,
      center.dy - height * 0.48,
    );
    final slotWidth = width * 0.22;
    final slotDarkPath = Path();
    slotDarkPath.moveTo(slotCenter.dx - slotWidth * 0.5, slotCenter.dy);
    slotDarkPath.quadraticBezierTo(
      slotCenter.dx,
      slotCenter.dy - height * 0.02,
      slotCenter.dx + slotWidth * 0.5,
      slotCenter.dy + height * 0.015,
    );

    canvas.drawPath(
      slotDarkPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 貯金箱の前面（お腹の手前のガラス、鼻、目、手前の耳、足、しっぽ）
class GlassPiggyBankFrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final width = size.width * 0.8;
    final height = size.width * 0.65;
    final bodyRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    // 1. お腹の前面ガラス（シャドウで球体の立体感を出す）
    final bodyShadow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, 0.3), // 左上から光、右下に影
        radius: 0.8,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
        stops: const [0.6, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyShadow);

    // フレネル反射（フチを白く飛ばす）
    final frontBodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.95),
        ],
        stops: const [0.5, 0.85, 0.95, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, frontBodyPaint);

    // 底面の極厚ガラスハイライト
    canvas.save();
    canvas.clipPath(Path()..addOval(bodyRect));
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: width * 0.96,
        height: height * 0.96,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();

    // 2. スペキュラハイライト（シャープな窓の反射で硬いガラスを表現）
    final windowHighlight = Path();
    windowHighlight.moveTo(center.dx - width * 0.3, center.dy - height * 0.4);
    windowHighlight.quadraticBezierTo(
      center.dx,
      center.dy - height * 0.48,
      center.dx + width * 0.25,
      center.dy - height * 0.3,
    );
    windowHighlight.lineTo(center.dx + width * 0.2, center.dy - height * 0.25);
    windowHighlight.quadraticBezierTo(
      center.dx,
      center.dy - height * 0.4,
      center.dx - width * 0.25,
      center.dy - height * 0.33,
    );
    windowHighlight.close();

    canvas.drawPath(
      windowHighlight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent,
          ], // 透明度を下げて柔らかく
        ).createShader(windowHighlight.getBounds()),
    );

    // 3. 手前の足
    void drawFrontLeg(Offset legCenter) {
      final legRect = Rect.fromCenter(
        center: legCenter,
        width: width * 0.14,
        height: height * 0.28,
      );
      final legRRect = RRect.fromRectAndRadius(
        legRect,
        const Radius.circular(15),
      );

      canvas.drawRRect(
        legRRect,
        Paint()..color = Colors.white.withValues(alpha: 0.15),
      );
      // 右側の影
      canvas.drawRRect(
        legRRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
          ).createShader(legRect),
      );
      // 左側のハイライト
      final highlightPath = Path()
        ..moveTo(legRect.left + 5, legRect.top + 8)
        ..lineTo(legRect.left + 5, legRect.bottom - 8);
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }

    drawFrontLeg(Offset(center.dx - width * 0.25, center.dy + height * 0.45));
    drawFrontLeg(Offset(center.dx + width * 0.2, center.dy + height * 0.45));

    // 4. 鼻 (Snout) を少し小さく、透明感を持たせる
    final snoutCenter = Offset(
      center.dx - width * 0.4,
      center.dy + height * 0.05,
    );
    final snoutWidth = width * 0.22;
    final snoutHeight = height * 0.32;
    final snoutRect = Rect.fromCenter(
      center: snoutCenter,
      width: snoutWidth,
      height: snoutHeight,
    );

    // 白いプラスチック/ガラスの土台フチ（細くする）
    canvas.drawOval(
      snoutRect.inflate(2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    // 少し透明感のあるリアルなピンクの鼻
    canvas.drawOval(
      snoutRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            const Color(0xFFFCE4EC).withValues(alpha: 0.9), // ハイライトピンク
            const Color(0xFFF8BBD0).withValues(alpha: 0.75), // ベースピンク
            const Color(0xFFE91E63).withValues(alpha: 0.4), // シャドウ
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(snoutRect),
    );

    // 鼻の穴
    final leftNostril = Rect.fromCenter(
      center: Offset(snoutCenter.dx - snoutWidth * 0.12, snoutCenter.dy),
      width: snoutWidth * 0.12,
      height: snoutHeight * 0.25,
    );
    final rightNostril = Rect.fromCenter(
      center: Offset(snoutCenter.dx + snoutWidth * 0.12, snoutCenter.dy),
      width: snoutWidth * 0.12,
      height: snoutHeight * 0.25,
    );
    final nostrilPaint = Paint()
      ..color = const Color(0xFFAD1457).withValues(alpha: 0.6);
    canvas.drawOval(leftNostril, nostrilPaint);
    canvas.drawOval(rightNostril, nostrilPaint);

    // 5. 目 (Eyes)
    void drawEye(Offset eyeCenter) {
      final eyeRect = Rect.fromCenter(
        center: eyeCenter,
        width: width * 0.045,
        height: height * 0.12,
      );
      // ツヤのある黒目
      canvas.drawOval(eyeRect, Paint()..color = const Color(0xFF2C2C2C));
      // 上の強いハイライト
      canvas.drawCircle(
        Offset(eyeCenter.dx - 2, eyeCenter.dy - 4),
        2.5,
        Paint()..color = Colors.white,
      );
      // 下の照り返し
      canvas.drawCircle(
        Offset(eyeCenter.dx + 1.5, eyeCenter.dy + 3),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }

    drawEye(Offset(center.dx - width * 0.23, center.dy - height * 0.15));
    drawEye(Offset(center.dx - width * 0.03, center.dy - height * 0.15));

    // 6. 手前の耳（左耳）と奥の耳（右耳）をここで両方描画（体のエッジハイライトの上に重ねるため）
    void drawEar(Path earPath, bool isFront) {
      canvas.drawPath(
        earPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: isFront ? 0.6 : 0.4),
              Colors.white.withValues(alpha: 0.1),
            ],
          ).createShader(earPath.getBounds()),
      );
      canvas.drawPath(
        earPath,
        Paint()
          ..color = Colors.white.withValues(alpha: isFront ? 0.95 : 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }

    // 奥の耳（右耳）
    final backEarPath = Path();
    backEarPath.moveTo(center.dx - width * 0.05, center.dy - height * 0.4);
    backEarPath.quadraticBezierTo(
      center.dx - width * 0.05,
      center.dy - height * 0.55,
      center.dx + width * 0.1,
      center.dy - height * 0.6,
    );
    backEarPath.quadraticBezierTo(
      center.dx + width * 0.2,
      center.dy - height * 0.5,
      center.dx + width * 0.15,
      center.dy - height * 0.4,
    );
    backEarPath.close();
    drawEar(backEarPath, false);

    // 手前の耳（左耳）
    final frontEarPath = Path();
    frontEarPath.moveTo(center.dx - width * 0.35, center.dy - height * 0.3);
    frontEarPath.quadraticBezierTo(
      center.dx - width * 0.45,
      center.dy - height * 0.5,
      center.dx - width * 0.28,
      center.dy - height * 0.55,
    );
    frontEarPath.quadraticBezierTo(
      center.dx - width * 0.1,
      center.dy - height * 0.45,
      center.dx - width * 0.15,
      center.dy - height * 0.35,
    );
    frontEarPath.close();
    drawEar(frontEarPath, true);

    // 7. 投入口の手前側のガラスエッジ（奥の暗い線と合わせてリアルなスリットにする）
    final slotCenter = Offset(
      center.dx + width * 0.05,
      center.dy - height * 0.48,
    );
    final slotWidth = width * 0.22;
    final rimPath = Path();
    rimPath.moveTo(slotCenter.dx - slotWidth * 0.48, slotCenter.dy + 2);
    rimPath.quadraticBezierTo(
      slotCenter.dx,
      slotCenter.dy - height * 0.02 + 2,
      slotCenter.dx + slotWidth * 0.48,
      slotCenter.dy + height * 0.015 + 2,
    );

    canvas.drawPath(
      rimPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 8. しっぽ (Tail)
    final tailPath = Path();
    tailPath.moveTo(center.dx + width * 0.48, center.dy + height * 0.1);
    tailPath.quadraticBezierTo(
      center.dx + width * 0.65,
      center.dy + height * 0.05,
      center.dx + width * 0.6,
      center.dy - height * 0.05,
    );
    tailPath.quadraticBezierTo(
      center.dx + width * 0.5,
      center.dy - height * 0.1,
      center.dx + width * 0.55,
      center.dy + height * 0.05,
    );

    // しっぽの影（立体感）
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // しっぽのガラス芯
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------
// 3D Metallic Coin (With physical thickness and glossy face)
// ---------------------------------------------------------
class Coin3D extends StatelessWidget {
  final Map<String, dynamic> category;
  final double size;
  final double angleX;
  final double angleY;
  final double angleZ;

  const Coin3D({
    super.key,
    required this.category,
    required this.size,
    required this.angleX,
    required this.angleY,
    required this.angleZ,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = category['color'] is Color
        ? category['color'] as Color
        : const Color(0xFF64B5F6);
    final IconData icon = category['icon'] is IconData
        ? category['icon'] as IconData
        : Icons.monetization_on;

    // Stack multiple translated layers to create 3D extruded side walls
    List<Widget> layers = [];
    final int depth = 8;
    final double thickness = size * 0.12;

    for (int i = 0; i < depth; i++) {
      bool isFront = (i == depth - 1);
      double t = i / (depth - 1);

      layers.add(
        Transform.translate(
          // Translate along Z axis relative to parent's 3D rotation
          offset: Offset(0, 0),
          child: Transform(
            transform: Matrix4.identity()..translate(0.0, 0.0, t * thickness),
            child: CustomPaint(
              size: Size(size, size),
              painter: _Coin3DPainter(
                baseColor: baseColor,
                icon: icon,
                isFront: isFront,
                angleZ: angleZ,
              ),
            ),
          ),
        ),
      );
    }

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.003) // Perspective distortion
        ..rotateX(angleX)
        ..rotateY(angleY)
        ..rotateZ(angleZ),
      alignment: Alignment.center,
      child: Stack(clipBehavior: Clip.none, children: layers),
    );
  }
}

class _Coin3DPainter extends CustomPainter {
  final Color baseColor;
  final IconData icon;
  final bool isFront;
  final double angleZ;

  _Coin3DPainter({
    required this.baseColor,
    required this.icon,
    required this.isFront,
    required this.angleZ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (!isFront) {
      // Side of the coin (smooth dark pastel, no ribs)
      final hsl = HSLColor.fromColor(baseColor);
      final edgeColor = hsl
          .withLightness(math.max(0.0, hsl.lightness - 0.15))
          .toColor();
      final paint = Paint()..color = edgeColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    // Front Face (Soft matte gradient)
    final faceGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(baseColor)
            .withLightness(
              math.min(1.0, HSLColor.fromColor(baseColor).lightness + 0.15),
            )
            .toColor(),
        baseColor,
        HSLColor.fromColor(baseColor)
            .withLightness(
              math.max(0.0, HSLColor.fromColor(baseColor).lightness - 0.1),
            )
            .toColor(),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()..shader = faceGradient;
    canvas.drawCircle(center, radius, paint);

    // Soft rim (Inner glow and outer shadow)
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, rimPaint);

    final innerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 4, innerShadow);

    // Embossed Icon
    final iconSize = radius * 0.85;

    // Soft shadow for deboss
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
      center -
          Offset(
            textPainterShadow.width / 2 - 1,
            textPainterShadow.height / 2 - 1,
          ),
    );

    // Base color icon (highlighted edge)
    final textPainterFront = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: HSLColor.fromColor(baseColor)
              .withLightness(
                math.min(1.0, HSLColor.fromColor(baseColor).lightness + 0.15),
              )
              .toColor(),
        ),
      ),
    );
    textPainterFront.layout();
    textPainterFront.paint(
      canvas,
      center -
          Offset(
            textPainterFront.width / 2 + 1,
            textPainterFront.height / 2 + 1,
          ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------
// Soft Volumetric Glass Piggy Bank Painters
// ---------------------------------------------------------
class PiggyBankBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Soft, diffused ambient ground shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF6B8E23).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height + 5),
        width: radius * 1.5,
        height: 40,
      ),
      shadowPaint,
    );

    // Deep volumetric inner glass shadow (replaces thick strokes)
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.25),
        ],
        stops: const [0.75, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PiggyBankFrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Tail (Soft Volumetric)
    _drawTail(canvas, Offset(size.width * 0.92, size.height * 0.45));

    // Draw Back Legs
    _drawLeg(canvas, Offset(size.width * 0.25, size.height * 0.95), 35);
    _drawLeg(canvas, Offset(size.width * 0.80, size.height * 0.88), 30);

    // Draw Back Ears
    _drawEar(canvas, Offset(size.width * 0.20, size.height * 0.18), -0.5);
    _drawEar(canvas, Offset(size.width * 0.80, size.height * 0.28), 0.5);

    // Front legs
    _drawLeg(canvas, Offset(size.width * 0.45, size.height * 0.98), 40);
    _drawLeg(canvas, Offset(size.width * 0.65, size.height * 0.95), 38);

    // Main Body Glass Caustics (Soft white glow around edge, NO strokes)
    final whiteRim = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.95),
        ],
        stops: const [0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, whiteRim);

    // Soft Window Reflection (Top Left)
    final windowHighlight = Path();
    windowHighlight.moveTo(center.dx - radius * 0.65, center.dy - radius * 0.2);
    windowHighlight.quadraticBezierTo(
      center.dx - radius * 0.35,
      center.dy - radius * 0.85,
      center.dx + radius * 0.2,
      center.dy - radius * 0.8,
    );
    windowHighlight.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.6);
    windowHighlight.quadraticBezierTo(
      center.dx - radius * 0.1,
      center.dy - radius * 0.65,
      center.dx - radius * 0.45,
      center.dy - radius * 0.1,
    );
    windowHighlight.close();

    final winPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(windowHighlight.getBounds())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(windowHighlight, winPaint);

    // Front Ear
    _drawEar(canvas, Offset(size.width * 0.28, size.height * 0.12), -0.2);

    // Snout
    _drawSnout(canvas, size);

    // Eyes (Thick, rounded soft arcs)
    final eyePaint = Paint()
      ..color = const Color(0xFF2B1F1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    // left eye
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.42),
        width: 18,
        height: 16,
      ),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      eyePaint,
    );
    // right eye
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.45),
        width: 18,
        height: 16,
      ),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      eyePaint,
    );
  }

  void _drawSnout(Canvas canvas, Size size) {
    final snoutCenter = Offset(size.width * 0.28, size.height * 0.55);
    final snoutRadius = size.width * 0.18;

    // Soft outer shadow (drop shadow inside the body)
    final snoutShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      snoutCenter + const Offset(-4, 8),
      snoutRadius * 0.9,
      snoutShadow,
    );

    // Soft glass gradient fill (no hard strokes)
    final snoutPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.95),
        ],
        stops: const [0.3, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: snoutCenter, radius: snoutRadius));
    canvas.drawCircle(snoutCenter, snoutRadius, snoutPaint);

    // Internal depth rim (soft shadow inside the snout)
    final snoutInner = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
            stops: const [0.7, 1.0],
          ).createShader(
            Rect.fromCircle(center: snoutCenter, radius: snoutRadius - 2),
          );
    canvas.drawCircle(snoutCenter, snoutRadius - 2, snoutInner);

    // Nose holes (soft indented shapes)
    final holePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final holeHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Left hole
    final leftHole = Rect.fromCenter(
      center: snoutCenter + const Offset(-12, 2),
      width: 10,
      height: 20,
    );
    canvas.drawOval(leftHole.translate(1, 1), holeHighlight);
    canvas.drawOval(leftHole, holePaint);

    // Right hole
    final rightHole = Rect.fromCenter(
      center: snoutCenter + const Offset(12, -2),
      width: 10,
      height: 20,
    );
    canvas.drawOval(rightHole.translate(1, 1), holeHighlight);
    canvas.drawOval(rightHole, holePaint);
  }

  void _drawLeg(Canvas canvas, Offset pos, double size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: size, height: size * 1.4),
      const Radius.circular(20),
    );

    // Internal refraction shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rect.shift(const Offset(0, 6)), shadow);

    // Soft volumetric glass fill
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.9),
        ],
        stops: const [0.3, 0.8, 1.0],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, paint);
  }

  void _drawEar(Canvas canvas, Offset pos, double rotation) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);

    final path = Path();
    path.moveTo(-20, 15);
    path.cubicTo(-10, -40, -5, -60, 15, -50);
    path.cubicTo(35, -35, 25, 0, 25, 20);

    // Volumetric fill (no strokes)
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, paint);

    // Edge highlight (soft)
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, highlight);

    canvas.restore();
  }

  void _drawTail(Canvas canvas, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(25, -25, 45, 15, 25, 30);
    path.cubicTo(5, 40, -10, 20, 5, 10);

    // Soft volumetric pipe
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PiggyBankSlotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final slotCenter = Offset(size.width * 0.55, size.height * 0.02);

    // The deep hole
    final slotDark = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final slotRect = Rect.fromCenter(
      center: slotCenter + const Offset(0, -2),
      width: 55,
      height: 14,
    );
    canvas.drawArc(slotRect, 0, math.pi, false, slotDark);

    // Thick shiny white lip
    final slotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawArc(slotRect, 0, math.pi, false, slotPaint);

    // Beveled highlight below
    final hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCenter(
        center: slotCenter + const Offset(0, 2),
        width: 60,
        height: 16,
      ),
      0,
      math.pi,
      false,
      hlPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
