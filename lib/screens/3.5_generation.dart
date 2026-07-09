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
                    builder: (context, child) {
                      // 統合: 他の人の GlassPiggyBank レイアウトを使いつつ
                      // ローカルの情報（coinRecords や showCollectionButton）を保持
                      // 必要なら GlassPiggyBank にパラメータを追加して渡してください。
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: GlassPiggyBank(
                            currentCoins: widget.currentCoins,
                            theme: theme,
                            // coinRecords: widget.coinRecords, // uncomment if supported
                            // showCollectionButton: false, // uncomment if supported
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
                      );
                    },
    else theme = TimeOfDayTheme.night;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 背景
          Positioned.fill(
            child: CustomPaint(
              painter: PiggyBankBackgroundPainter(theme: theme),
            ),
          ),
          
          // 2. 前面コンテンツ
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
                // ここでアニメーションを適用
                Expanded(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return IgnorePointer(
                        child: PiggyBankCard(
                          theme: theme,
                          currentCoins: widget.currentCoins,
                          coinRecords: widget.coinRecords,
                          showCollectionButton: false,
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
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: GlassPiggyBank(
                              currentCoins: widget.currentCoins,
                              theme: theme, // Pass theme to color tint the pig
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
                                        ..rotateY(
                                          _controller.value * math.pi * 8,
                                        ),
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