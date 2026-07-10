// ignore_for_file: file_names
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import '3_generation.dart';

import '2.5_venting.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({
    super.key,
    required this.initialText,
    required this.onSave,
    required this.onBack,
  });

  final String initialText;
  final void Function(String) onSave;
  final VoidCallback onBack;

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  late final TextEditingController _controller;
  static const int _maxLength = 200;
  int _currentLength = 0;
  bool _isLoading = false; // 処理中のローディング状態

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _currentLength = _controller.text.length;
    _controller.addListener(() {
      setState(() {
        _currentLength = _controller.text.length;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🌟 バックエンド連携を組み込んだ保存処理
  Future<void> _save() async {
    if (_controller.text.isEmpty) return;

    final memoText = _controller.text;
    
    // UIの入力をリセット
    widget.onSave(memoText);
    
    // 即座に生成画面へ遷移し、裏で処理を行う
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GenerationScreen(memo: memoText),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final horizontalPadding = isCompact ? 16.0 : 24.0;
    final titleFontSize = isCompact ? 16.0 : 18.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isCompact ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: const Icon(Icons.arrow_back, color: Color(0xFF5A5A5A), size: 24),
                  ),
                  const SizedBox(width: 12),
                

                  Expanded(
                    child: Text(
                      'ちょっとポジティブなことは？',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A4A4A),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Input Area
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFAF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0D4C3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Stack(
                          children: [
                            TextField(
                              controller: _controller,
                              maxLines: null,
                              expands: true, // 🌟 これを追加！これで枠全体がタップ可能になります
                              textAlignVertical: TextAlignVertical.top, // 🌟 入力開始位置を左上に固定
                              maxLength: _maxLength,
                              style: TextStyle(
                                fontSize: isCompact ? 15 : 16,
                                color: const Color(0xFF4A4A4A),
                                height: 1.6,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'ここに入力してみよう...',
                                counterText: '',
                                hintStyle: TextStyle(
                                  color: const Color(0xFFBCAAA4),
                                  fontSize: isCompact ? 14 : 16,
                                  fontFamily: 'serif',
                                ),
                                // 🌟 以下の行を追加しておくと、さらにタップ領域が広がりミスが減ります
                                contentPadding: EdgeInsets.zero, 
                              ),
                            ),
                            // Counter at top right
                            Positioned(
                              top: 36,
                              right: 0,
                              child: Text(
                                '$_currentLength / $_maxLength',
                                style: const TextStyle(
                                  color: Color(0xFFAFAFAF),
                                  fontSize: 13,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                            // 非常ボタン（愚痴ボタン） at bottom right
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Tooltip(
                                message: '誰にも言えない愚痴を吐き出す',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => VentingScreen(
                                          onVented: () {
                                            Navigator.of(context).pop(); // VentingScreenを閉じる
                                            widget.onBack(); // RootScreenのタブをホーム(0)に戻す
                                          },
                                        ),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.redAccent,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Sparkles overlay at bottom right
                    Positioned(
                      bottom: -30,
                      right: -10,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: CustomPaint(
                            painter: SparklePainter(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Buttons
              // 以前の Row(...) から始まる塊を、以下に置き換えてください
                    Container(
                      width: double.infinity, // 🌟 画面横幅いっぱいに広がる
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF16E85),
                            Color(0xFFD64A62),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD64A62).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                '保存する ✨',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isCompact ? 15 : 16,
                                ),
                              ),
                      ),
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final brightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    void drawSparkle(Offset center, double radius) {
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius * 0.4, brightPaint);
    }

    // Draw some scattered sparkles
    drawSparkle(Offset(size.width * 0.2, size.height * 0.8), 2.5);
    drawSparkle(Offset(size.width * 0.4, size.height * 0.9), 4);
    drawSparkle(Offset(size.width * 0.6, size.height * 0.7), 3);
    drawSparkle(Offset(size.width * 0.8, size.height * 0.85), 5);
    drawSparkle(Offset(size.width * 0.5, size.height * 0.6), 2);
    drawSparkle(Offset(size.width * 0.7, size.height * 0.5), 3.5);
    drawSparkle(Offset(size.width * 0.9, size.height * 0.4), 2);
    drawSparkle(Offset(size.width * 0.75, size.height * 0.95), 2);
    drawSparkle(Offset(size.width * 0.3, size.height * 0.95), 1.5);
    drawSparkle(Offset(size.width * 0.85, size.height * 0.65), 1.5);
    drawSparkle(Offset(size.width * 0.95, size.height * 0.75), 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}