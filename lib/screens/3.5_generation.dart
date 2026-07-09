import 'package:flutter/material.dart';
import 'dart:math' as math;
import '1_home.dart';
import '../services/coin_style_service.dart';

class PiggyBankTransitionScreen extends StatefulWidget {
  final Map<String, dynamic> coinCategory;
  final int currentCoins;

  const PiggyBankTransitionScreen({
    super.key,
    required this.coinCategory,
    required this.currentCoins,
  });

  @override
  State<PiggyBankTransitionScreen> createState() =>
      _PiggyBankTransitionScreenState();
}

class _PiggyBankTransitionScreenState extends State<PiggyBankTransitionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fallAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Y position drops from above the piggy bank down to the slot
    _fallAnimation = Tween<double>(begin: -150.0, end: 45.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeIn),
      ),
    );

    // Scale shrinks slightly as it enters the slot
    _scaleAnimation = Tween<double>(begin: 1.5, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.65, curve: Curves.easeOut),
      ),
    );

    // Opacity fades out once it enters the slot
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 0.75)),
    );

    _controller.forward();

    // Automatically navigate back to home after animation completes
    // initState 内の addStatusListener をこう修正してください
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 戻るときに、今のコイン数（widget.currentCoins）をホームへ知らせる
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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

    // Determine TimeOfDayTheme based on current hour
    final hour = DateTime.now().hour;
    TimeOfDayTheme theme;
    if (hour >= 5 && hour < 10) {
      theme = TimeOfDayTheme.morning;
    } else if (hour >= 10 && hour < 16) {
      theme = TimeOfDayTheme.day;
    } else if (hour >= 16 && hour < 19) {
      theme = TimeOfDayTheme.evening;
    } else {
      theme = TimeOfDayTheme.night;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Background
          Positioned.fill(
            child: CustomPaint(
              painter: PiggyBankBackgroundPainter(theme: theme),
            ),
          ),
          
          // Foreground
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '幸せを貯金しています........',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B3B3B),
                        ),
                      ),
                    ],
                  ),
                ),
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
                                        ..rotateY(
                                          _controller.value * math.pi * 8,
                                        ),
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
