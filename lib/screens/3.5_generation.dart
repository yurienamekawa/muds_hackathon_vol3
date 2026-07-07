import 'package:flutter/material.dart';
import 'dart:math' as math;
import '1_home.dart';
import '5_collection.dart'; // For Coin3D

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
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.75),
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
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
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return IgnorePointer(
                  child: PiggyBankCard(
                    // Show current coins (the new one will just fade in there after return)
                    currentCoins: widget.currentCoins,
                    showCollectionButton: false, // 落下演出中はボタンを隠す
                    fallingCoin: Positioned(
                      // Calculate slot X position based on GlassPiggyBank dimensions
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
                              ..rotateY(_controller.value * math.pi * 8), // Spin rapidly while falling
                            child: Coin3D(
                              category: widget.coinCategory,
                              size: 50,
                              angleX: 0.2,
                              angleY: 0, // Handled by Matrix4 above
                              angleZ: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
