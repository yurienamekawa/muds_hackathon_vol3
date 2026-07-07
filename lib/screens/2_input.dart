// ignore_for_file: file_names
import 'package:supabase_flutter/supabase_flutter.dart';
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
      // 🌟 ここを修正：currentUser?.id ではなく currentSession?.user.id を使うか、
      // より確実に auth.currentUser を参照する方法に変えます
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) throw Exception('ログインしていません');
      final userId = user.id; // これでエラーは消えるはずです！

      // 2. AI分析
      final aiData = await AiService.analyzeHappyMemo(_controller.text);
      
      // 3. DB保存
      await DbService.insertCoinData(
        _controller.text, 
        aiData, 
      );

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
      backgroundColor: const Color(0xFFFDF7EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFF4A4A4A),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '今日のちょっとポジティブなことは？',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _controller,
                          maxLines: null,
                          maxLength: _maxLength,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'ここに入力してみよう...',
                            counterText: '',
                            hintStyle: TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text('$_currentLength / $_maxLength', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        side: const BorderSide(color: Color(0xFFFFA1AB)),
                      ),
                      child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('戻る', style: TextStyle(color: Color(0xFFFF5A79), fontWeight: FontWeight.bold))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save, // ローディング中は押せないようにする
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A79),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('保存する ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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