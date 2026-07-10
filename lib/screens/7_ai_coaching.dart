import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';

class AiCoachingScreen extends StatefulWidget {
  const AiCoachingScreen({Key? key}) : super(key: key);

  @override
  State<AiCoachingScreen> createState() => _AiCoachingScreenState();
}

class _AiCoachingScreenState extends State<AiCoachingScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  String _mindmapDataText = "";

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _collectMindmapData();
    
    // 初回メッセージをAIにリクエストする
    setState(() {
      _messages.add({
        'role': 'user',
        'content': '私のマインドマップを分析して、幸せの傾向と、自己分析を深めるための質問を1つ教えて！'
      });
    });

    await _sendMessageToAi();
  }

  Future<void> _collectMindmapData() async {
    final prefs = await SharedPreferences.getInstance();
    String dataText = "【ユーザーのマインドマップ】\n";

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final response = await client
          .from('happy_coins')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final records = (response as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      
      for (final time in ['朝', '昼', '夕', '夜']) {
        // time分類は createdAtのhourから算出するか、time_categoryカラムがあるならそれを使う。
        // MindmapScreenに合わせてhourで分類する。
        final timeRecords = records.where((r) {
          final createdAt = DateTime.tryParse(r['created_at'].toString())?.toLocal();
          if (createdAt == null) return false;
          final h = createdAt.hour;
          if (time == '朝' && h >= 5 && h < 11) return true;
          if (time == '昼' && h >= 11 && h < 17) return true;
          if (time == '夕' && h >= 17 && h < 20) return true;
          if (time == '夜' && (h >= 20 || h < 5)) return true;
          return false;
        }).toList();

        if (timeRecords.isNotEmpty) {
          dataText += "■ $time\n";
          for (final record in timeRecords) {
            final title = record['memo']?.toString() ?? record['note']?.toString() ?? '無題';
            final id = record['id']?.toString() ?? '';
            dataText += "  - 出来事: $title\n";
            
            String fetchDives(String parentId, int depth) {
              String res = "";
              final diveJson = prefs.getString('deep_dives_$parentId');
              if (diveJson != null) {
                try {
                  final List decoded = jsonDecode(diveJson);
                  for (final dive in decoded) {
                    final indent = "  " * (depth + 1);
                    res += "$indent- 深掘り: ${dive['label']}\n";
                    res += fetchDives(dive['id'], depth + 1);
                  }
                } catch (_) {}
              }
              return res;
            }
            if (id.isNotEmpty) {
              dataText += fetchDives(id, 1);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error collecting data: $e');
    }

    _mindmapDataText = dataText;
  }

  Future<void> _sendMessageToAi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reply = await AiService.chatCoaching(_messages, _mindmapDataText);
      setState(() {
        _messages.add({
          'role': 'model',
          'content': reply,
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'model',
          'content': 'ごめんね、エラーが起きちゃったブヒ…通信環境を確認してもう一度試してほしいブヒ！',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text.trim(),
      });
    });
    
    _textController.clear();
    _scrollToBottom();
    _sendMessageToAi();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _summarizeAndEnd() async {
    setState(() {
      _isLoading = true;
    });

    final insightText = await AiService.summarizeChatToNodes(_messages);

    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('deep_dives_root');
    List<Map<String, dynamic>> rootDives = [];
    if (existingJson != null) {
      try {
        rootDives = List<Map<String, dynamic>>.from(jsonDecode(existingJson));
      } catch (_) {}
    }
    
    rootDives.add({
      'id': UniqueKey().toString(),
      'label': insightText,
      'type': 'ai_insight',
      'isExpanded': true,
      'children': [],
    });

    await prefs.setString('deep_dives_root', jsonEncode(rootDives));

    if (mounted) {
      Navigator.pop(context); // チャット画面を閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('マップの中心に「AIからの気づき」を追加しました！✨', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFFA718F),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 最初のユーザーメッセージ（分析指示）は画面に表示しないようにフィルタリングする
    final displayMessages = _messages.skip(1).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      appBar: AppBar(
        title: const Text('AIリフレクションルーム', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFFFA718F),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: (_isLoading || displayMessages.length < 2) ? null : _summarizeAndEnd,
            icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
            label: const Text('追加して終了', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: displayMessages.isEmpty && _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFA718F)),
                        SizedBox(height: 16),
                        Text('ハピブーがあなたのマップを読み解いているブヒ…🐷', style: TextStyle(color: Color(0xFF4A4A4A))),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: displayMessages.length,
                    itemBuilder: (context, index) {
                      final message = displayMessages[index];
                      final isUser = message['role'] == 'user';
                      return _buildMessageBubble(message['content'] ?? '', isUser);
                    },
                  ),
          ),
          if (_isLoading && displayMessages.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFFFA718F)),
            ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFFFA718F),
              child: Text('🐷', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFFA718F) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF4A4A4A),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'ハピブーに返信する...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: _handleSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFA718F),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
