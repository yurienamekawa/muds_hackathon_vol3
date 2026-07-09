import 'package:flutter/material.dart';
import 'dart:math' as math;
import '5_collection.dart';
import '3.5_generation.dart';
import '../services/db_service.dart';
import '../services/ai_service.dart';
import '../services/coin_style_service.dart';

class GenerationScreen extends StatefulWidget {
  final String? memo;
  const GenerationScreen({super.key, this.memo});

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _loopController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _coinOpacityAnimation;

  Map<String, dynamic>? _category;
  int _todayCoins = 1;
  bool _isProcessing = true;

  Color _resolveColor(dynamic colorValue) {
    return CoinStyleService.resolveColor(colorValue);
  }

  Map<String, dynamic> _buildCategory(Map<String, dynamic>? aiResult) {
    final category = (aiResult?['category'] as String?)?.trim() ?? '日常・景色';
    final title = (aiResult?['short_title'] as String?)?.trim();
    final detail = (aiResult?['ai_comment'] as String?)?.trim();
    String coinType = ((aiResult?['coin_type'] as String?)?.trim() ?? '').toLowerCase();

    const categoryToCoinType = {
      '日常・景色': 'sunny_blue',
      '友達・対人': 'heart_pink',
      '家族': 'home_orange',
      '仕事・学校': 'star_yellow',
      '食事': 'food_green',
      '趣味・推し': 'music_purple',
      '運動・健康': 'run_teal',
      'お出かけ': 'car_indigo',
      '自己成長': 'bulb_red',
    };

    // If the AI didn't provide a valid coin_type, infer it from the category
    if (!categoryToCoinType.values.contains(coinType)) {
      coinType = categoryToCoinType[category] ?? 'sunny_blue';
    }

    final appearance = CoinStyleService.buildCoinAppearance(
      coinType: coinType,
    );

    return {
      'title': title?.isNotEmpty == true ? title : category,
      'subtitle': category,
      'icon': appearance['icon'],
      'color': _resolveColor(appearance['color']),
      'date': DateTime.now().toString().split(' ').first,
      'detail': detail?.isNotEmpty == true ? detail : 'あなたのポジティブな瞬間がコインになりました。',
      'isAcquired': true,
      'coin_type': appearance['coin_type'],
    };
  }

  List<Map<String, dynamic>> _coinRecords = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _coinOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.4)),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: -20.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOutSine),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 6 * 3.141592653589793)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    // Fetch today's coin count and recent coin records
    DbService.getTodayCoinCount().then((count) {
      if (mounted) setState(() => _todayCoins = count);
    });
    DbService.getRecentCoinRecords().then((records) {
      if (mounted) setState(() => _coinRecords = records);
    });

    _processMemo();
  }

  Future<void> _processMemo() async {
    final memo = widget.memo;
    if (memo == null || memo.isEmpty) {
      // Fallback if no memo provided
      if (mounted) {
        setState(() {
          _category = _buildCategory(null);
          _isProcessing = false;
        });
        _controller.forward();
        _scheduleTransition();
      }
      return;
    }

    try {
      final aiData = await AiService.analyzeHappyMemo(memo);
      await DbService.insertCoinData(memo, aiData);

      if (mounted) {
        setState(() {
          _category = _buildCategory(aiData);
          _isProcessing = false;
        });
        _controller.forward();
        _scheduleTransition();
      }
    } catch (e) {
      // Error handling: proceed with fallback coin
      if (mounted) {
        setState(() {
          _category = _buildCategory(null);
          _isProcessing = false;
        });
        _controller.forward();
        _scheduleTransition();
      }
    }
  }

  void _scheduleTransition() {
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PiggyBankTransitionScreen(
              coinCategory: _category!,
              currentCoins: _todayCoins,
              coinRecords: _coinRecords,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      body: Stack(
        children: [
          // Magical Background
          Positioned.fill(
            child: MagicalBackgroundEffect(
              introController: _controller,
              loopController: _loopController,
              baseColor: _category?['color'] is Color
                  ? _category!['color'] as Color
                  : const Color(0xFF64B5F6),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isProcessing ? '分析中...' : '生成完了！',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B3B3B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _isProcessing
                            ? 'あなたのポジティブを\nAIが分析しています ✨'
                            : 'ポジティブな出来事が\n素敵なコインになりました！',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5A5A5A),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 480,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isProcessing)
                              RotationTransition(
                                turns: _loopController,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                            if (!_isProcessing && _category != null)
                              // The Coin (Animated)
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _slideAnimation.value),
                                    child: Opacity(
                                      opacity: _coinOpacityAnimation.value,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001) // perspective
                                          ..rotateY(
                                            _rotationAnimation.value,
                                          ) // 3D spin
                                          ..scale(
                                            _scaleAnimation.value,
                                          ), // scale up
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: CoinWidget(
                                  category: _category!,
                                  isAcquired: true,
                                  size: 180,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!_isProcessing && _category != null)
                        FadeTransition(
                          opacity: _opacityAnimation,
                          child: Column(
                            children: [
                              Text(
                                _category!['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A4A4A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  _category!['detail'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7A7A7A),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MagicalBackgroundEffect extends StatelessWidget {
  final AnimationController introController;
  final AnimationController loopController;
  final Color baseColor;

  const MagicalBackgroundEffect({
    super.key,
    required this.introController,
    required this.loopController,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([introController, loopController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _MagicalPainter(
            introProgress: introController.value,
            loopProgress: loopController.value,
            color: baseColor,
          ),
        );
      },
    );
  }
}

class _MagicalPainter extends CustomPainter {
  final double introProgress;
  final double loopProgress;
  final Color color;

  _MagicalPainter({
    required this.introProgress,
    required this.loopProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The visual center of the stack where the coin is
    final center = Offset(size.width / 2, size.height * 0.42);

    // Soft Glow Background
    double glowOpacity = (introProgress * 1.5).clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.5 * glowOpacity),
          color.withOpacity(0.15 * glowOpacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 0.9],
      ).createShader(Rect.fromCircle(center: center, radius: size.width));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // Spinning Light Rays
    if (introProgress > 0.1) {
      final rayOpacity = (introProgress - 0.1).clamp(0.0, 1.0);
      final rayPaint = Paint()..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(loopProgress * 2 * math.pi);

      int numRays = 16;
      for (int i = 0; i < numRays; i++) {
        canvas.save();
        canvas.rotate((i * 2 * math.pi) / numRays);

        final path = Path()
          ..moveTo(-12, 0)
          ..lineTo(12, 0)
          ..lineTo(50, size.width)
          ..lineTo(-50, size.width)
          ..close();

        rayPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.5 * rayOpacity),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(-50, 0, 50, size.width));

        canvas.drawPath(path, rayPaint);
        canvas.restore();
      }
      canvas.restore();
    }

    // Expanding Rings
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(
        (1.0 - introProgress).clamp(0.0, 1.0) * 0.9,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    double radius1 = introProgress * size.width * 0.9;
    if (radius1 > 0 && introProgress < 1.0)
      canvas.drawCircle(center, radius1, ringPaint);

    double progress2 = (introProgress - 0.2) * 1.25;
    if (progress2 > 0 && progress2 < 1.0) {
      final ring2Paint = Paint()
        ..color = Colors.white.withOpacity(
          (1.0 - progress2).clamp(0.0, 1.0) * 0.7,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0;
      double radius2 = progress2 * size.width * 0.8;
      canvas.drawCircle(center, radius2, ring2Paint);
    }

    // Floating Stars
    final starPaint = Paint();
    int numStars = 24;
    for (int i = 0; i < numStars; i++) {
      double angle = (i * 2 * math.pi) / numStars;
      double starProgress = (loopProgress * 3 + i / numStars) % 1.0;
      double distance = (starProgress * size.width * 0.7) + 50;
      double starSize = 4.0 + (i % 6);

      double sx = center.dx + distance * math.cos(angle);
      double sy = center.dy + distance * math.sin(angle);

      double starOpacity = math.sin(starProgress * math.pi);
      starPaint.color = Colors.white.withOpacity(starOpacity * introProgress);

      _drawStar(canvas, Offset(sx, sy), starSize, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset position, double size, Paint paint) {
    final path = Path();
    path.moveTo(position.dx, position.dy - size);
    path.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx + size / 2,
      position.dy,
    );
    path.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx,
      position.dy + size,
    );
    path.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx - size / 2,
      position.dy,
    );
    path.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx,
      position.dy - size,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MagicalPainter oldDelegate) {
    return oldDelegate.introProgress != introProgress ||
        oldDelegate.loopProgress != loopProgress ||
        oldDelegate.color != color;
  }
}
