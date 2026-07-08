// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import '3_generation.dart';

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

    setState(() => _isLoading = true);

    try {
      // 1. AI分析
      final aiData = await AiService.analyzeHappyMemo(_controller.text);
      
      // 2. DB保存
      await DbService.insertCoinData(_controller.text, aiData);

      // 3. 成功したら画面遷移（aiDataを渡す！）
      widget.onSave(_controller.text);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GenerationScreen(aiResult: aiData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F1), // Warmer cream background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  const Text(
                    '今日のちょっとポジティブなことは？',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A4A),
                      letterSpacing: 1.1,
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
                              maxLength: _maxLength,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4A4A4A),
                                height: 1.6,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'ここに入力してみよう...',
                                counterText: '', // Hide default counter
                                hintStyle: TextStyle(
                                  color: Color(0xFFBCAAA4),
                                  fontSize: 16,
                                  fontFamily: 'serif',
                                ),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: const BorderSide(color: Color(0xFFE2C9C5), width: 1.5),
                        backgroundColor: const Color(0xFFFDF9F1),
                      ),
                      child: const Text(
                        '戻る',
                        style: TextStyle(
                          color: Color(0xFFC77A85),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
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
                            : const Text(
                                '保存する ✨',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
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