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
  int _turnCount = 0;
  bool _isChatEnded = false;

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
            dataText += "  - 出来事(ID: $id): $title\n";
            
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
          'content': 'ごめんなさい、エラーが発生してしまいました…。通信環境を確認して、もう一度試してみてください！',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || _isChatEnded) return;
    
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text.trim(),
      });
      _turnCount++;
    });
    
    _textController.clear();
    _scrollToBottom();
    
    if (_turnCount >= 3) {
      _summarizeAndEnd();
    } else {
      _sendMessageToAi();
    }
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
      _isChatEnded = true;
    });

    try {
      final result = await AiService.summarizeChatToNodes(_messages, _mindmapDataText);
      final insightText = result['insight']?.toString() ?? '自己分析の新たな気づき';
      final recordId = result['record_id']?.toString() ?? '';

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSelfAnalysisResult(insightText, recordId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChatEnded = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エラーが発生しました。もう一度お試しください。')),
        );
      }
    }
  }

  void _showSelfAnalysisResult(String insightText, String recordId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('🌟 あなたの自己分析', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(insightText, style: const TextStyle(fontSize: 15, height: 1.5)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(c);
                await _saveAnalysis(insightText, recordId, keep: false);
              },
              child: const Text('閉じる', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(c);
                await _saveAnalysis(insightText, recordId, keep: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFA718F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('キープする', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAnalysis(String insightText, String recordId, {required bool keep}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // マインドマップへの気づきとして保存
    final targetKey = recordId.isNotEmpty ? 'deep_dives_$recordId' : 'deep_dives_root';
    final existingJson = prefs.getString(targetKey);
    List<Map<String, dynamic>> targetDives = [];
    if (existingJson != null) {
      try {
        targetDives = List<Map<String, dynamic>>.from(jsonDecode(existingJson));
      } catch (_) {}
    }
    
    targetDives.add({
      'id': UniqueKey().toString(),
      'label': insightText,
      'type': 'ai_insight',
      'isExpanded': true,
      'children': [],
      'chat_history': _messages,
    });

    await prefs.setString(targetKey, jsonEncode(targetDives));

    // キープする場合はコレクション用（DB）にも保存
    if (keep) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.from('self_analyses').insert({
            'user_id': userId,
            'insight': insightText,
          });
        }
      } catch (e) {
        debugPrint('DB Save Error: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context); // チャット画面を閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            keep ? '自己分析をコレクションに保存しました！✨' : 'マップの中心に「AIからの気づき」を追加しました！✨',
            style: const TextStyle(fontWeight: FontWeight.bold)
          ),
          backgroundColor: const Color(0xFFFA718F),
          duration: const Duration(seconds: 4),
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
            onPressed: (_isLoading || _isChatEnded || displayMessages.length < 2) ? null : _summarizeAndEnd,
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
          if (_isLoading && displayMessages.isNotEmpty && !_isChatEnded)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFFFA718F)),
            ),
          if (!_isChatEnded) _buildTextComposer(),
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
