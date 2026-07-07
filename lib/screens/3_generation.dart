// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '5_collection.dart';
import '3.5_generation.dart';

class GenerationScreen extends StatefulWidget {
  final Map<String, dynamic> aiResult;

  const GenerationScreen({super.key, required this.aiResult});

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

  // AIの結果をUI用に変換するヘルパー
  Map<String, dynamic> get _displayData {
    return {
      'title': widget.aiResult['short_title'] ?? 'ポジティブ発見',
      'icon': Icons.star_rounded,
      'color': const Color(0xFFFF7A8F),
      'date': DateTime.now().toString().substring(0, 10),
      'detail': widget.aiResult['ai_comment'] ?? '素敵な出来事でしたね！',
      'isAcquired': true,
    };
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack)),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _coinOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.4)),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: -20.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeInOutSine)),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 6 * 3.141592653589793).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic)),
    );

    // 演出完了後、少し待ってから自動的にトランジション画面へ遷移
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PiggyBankTransitionScreen(
              coinCategory: dummyCategory,
              currentCoins: 7,
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
          Positioned.fill(
            child: MagicalBackgroundEffect(
              introController: _controller,
              loopController: _loopController,
              baseColor: _displayData['color'] as Color,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    const Text('分析完了！', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF3B3B3B))),
                    const SizedBox(height: 14),
                    const Text('AIがあなたの出来事を\nコインに変換しました ✨', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF5A5A5A), height: 1.6)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 480,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
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
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateY(_rotationAnimation.value)
                                      ..scale(_scaleAnimation.value),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: CoinWidget(
                              category: _displayData,
                              isAcquired: true,
                              size: 180,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
                    ),
                    FadeTransition(
                      opacity: _opacityAnimation,
                      child: Column(
                        children: [
                          Text(_displayData['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
                          const SizedBox(height: 8),
                          Text(_displayData['detail'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF7A7A7A), height: 1.6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A79),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      ),
                      child: const Text('ホームに戻る', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ],
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

  const MagicalBackgroundEffect({super.key, required this.introController, required this.loopController, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([introController, loopController]),
      builder: (context, child) => CustomPaint(
        painter: _MagicalPainter(introProgress: introController.value, loopProgress: loopController.value, color: baseColor),
      ),
    );
  }
}

class _MagicalPainter extends CustomPainter {
  final double introProgress;
  final double loopProgress;
  final Color color;

  _MagicalPainter({required this.introProgress, required this.loopProgress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final glowPaint = Paint()..shader = RadialGradient(colors: [color.withOpacity(0.5 * (introProgress * 1.5).clamp(0.0, 1.0)), color.withOpacity(0.15 * (introProgress * 1.5).clamp(0.0, 1.0)), Colors.transparent], stops: const [0.0, 0.5, 0.9]).createShader(Rect.fromCircle(center: center, radius: size.width));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
    
    // ... (残りの描画ロジックは以前のまま)
    final ringPaint = Paint()..color = Colors.white.withOpacity((1.0 - introProgress).clamp(0.0, 1.0) * 0.9)..style = PaintingStyle.stroke..strokeWidth = 6.0;
    if (introProgress > 0 && introProgress < 1.0) canvas.drawCircle(center, introProgress * size.width * 0.9, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _MagicalPainter oldDelegate) => true;
}