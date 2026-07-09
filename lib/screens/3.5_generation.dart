import 'package:flutter/material.dart';
import 'dart:math' as math;
import '1_home.dart';
import '../services/coin_style_service.dart';

class PiggyBankTransitionScreen extends StatefulWidget {
  final Map<String, dynamic> coinCategory;
  final int currentCoins;
  final List<Map<String, dynamic>> coinRecords;

  const PiggyBankTransitionScreen({
    super.key,
    required this.coinCategory,
    required this.currentCoins,
    this.coinRecords = const [],
  });

  @override
  State<PiggyBankTransitionScreen> createState() => _PiggyBankTransitionScreenState();
}

class _PiggyBankTransitionScreenState extends State<PiggyBankTransitionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fallAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fallAnimation = Tween<double>(begin: -100, end: 150).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.bounceOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      // 終了後、少し待ってからホームに戻る
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = CoinStyleService.buildCoinAppearance(
      coinType: widget.coinCategory['coin_type'] as String?,
    );

    final hour = DateTime.now().hour;
    TimeOfDayTheme theme;
    if (hour >= 5 && hour < 10) theme = TimeOfDayTheme.morning;
    else if (hour >= 10 && hour < 16) theme = TimeOfDayTheme.day;
    else if (hour >= 16 && hour < 19) theme = TimeOfDayTheme.evening;
    else theme = TimeOfDayTheme.night;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PiggyBankBackgroundPainter(theme: theme),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '幸せを貯金しています.........',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B3B3B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return IgnorePointer(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: GlassPiggyBank(
                              currentCoins: widget.currentCoins,
                              coinRecords: widget.coinRecords,
                              fallingCoin: Positioned(
                                left: 164,
                                top: _fallAnimation.value,
                                child: Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Opacity(
                                    opacity: _opacityAnimation.value,
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(_controller.value * math.pi * 8),
                                      child: Coin3D(
                                        category: {
                                          'icon': appearance['icon'],
                                          'color': appearance['color'],
                                        },
                                        size: 50,
                                        angleX: 0.2,
                                        angleY: 0,
                                        angleZ: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}