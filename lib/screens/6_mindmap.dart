import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '7_ai_coaching.dart';

class MindmapNode {
  final String id;
  final String label;
  final String type; // 'root', 'time', 'record', 'deep_dive', 'ai_insight'
  Offset position;
  final List<MindmapNode> children;
  bool isExpanded;
  final List<dynamic>? chatHistory;

  MindmapNode({
    required this.id,
    required this.label,
    required this.type,
    this.position = Offset.zero,
    List<MindmapNode>? children,
    this.isExpanded = true,
    this.chatHistory,
  }) : children = children ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'isExpanded': isExpanded,
      'children': children.map((c) => c.toJson()).toList(),
      if (chatHistory != null) 'chat_history': chatHistory,
    };
  }

  factory MindmapNode.fromJson(Map<String, dynamic> json) {
    return MindmapNode(
      id: json['id'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      isExpanded: json['isExpanded'] as bool? ?? true,
      chatHistory: json['chat_history'] as List<dynamic>?,
      children: (json['children'] as List?)
              ?.map((c) => MindmapNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MindmapScreen extends StatefulWidget {
  const MindmapScreen({super.key});

  @override
  State<MindmapScreen> createState() => _MindmapScreenState();
}

class _MindmapScreenState extends State<MindmapScreen> {
  bool _isLoading = true;
  MindmapNode? _rootNode;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      
      double initialScale = 0.75;
      double cx = 1000.0;
      double cy = 1000.0;
      
      double dx = screenWidth / 2 - cx * initialScale;
      double dy = screenHeight / 2.2 - cy * initialScale; 

      _transformationController.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(initialScale);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await client
          .from('happy_coins')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final records = (response as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      await _buildTree(records);
      
    } catch (e) {
      debugPrint('Mindmap load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _buildTree(List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();

    final root = MindmapNode(id: 'root', label: 'わたしの\n幸せリズム', type: 'root');
    final morningNode = MindmapNode(id: 'time_morning', label: '朝', type: 'time');
    final dayNode = MindmapNode(id: 'time_day', label: '昼', type: 'time');
    final eveningNode = MindmapNode(id: 'time_evening', label: '夕', type: 'time');
    final nightNode = MindmapNode(id: 'time_night', label: '夜', type: 'time');

    final recentRecords = records.take(20).toList();

    for (final record in recentRecords) {
      final createdAtStr = record['created_at'];
      if (createdAtStr == null) continue;
      
      final createdAt = DateTime.tryParse(createdAtStr.toString())?.toLocal();
      if (createdAt == null) continue;

      final note = record['memo']?.toString() ?? record['note']?.toString() ?? '無題';
      final id = record['id']?.toString() ?? UniqueKey().toString();

      final recordNode = MindmapNode(id: 'record_$id', label: note, type: 'record');

      // ローカルストレージから深掘りデータを読み込む
      final existingJson = prefs.getString('deep_dives_$id');
      if (existingJson != null) {
        try {
          final List decoded = jsonDecode(existingJson);
          recordNode.children.addAll(decoded.map((c) => MindmapNode.fromJson(c)));
        } catch (e) {
          debugPrint('Failed to parse deep dives for $id: $e');
        }
      }

      final hour = createdAt.hour;
      if (hour >= 5 && hour < 11) {
        morningNode.children.add(recordNode);
      } else if (hour >= 11 && hour < 17) {
        dayNode.children.add(recordNode);
      } else if (hour >= 17 && hour < 20) {
        eveningNode.children.add(recordNode);
      } else {
        nightNode.children.add(recordNode);
      }
    }

    if (morningNode.children.isNotEmpty) root.children.add(morningNode);
    if (dayNode.children.isNotEmpty) root.children.add(dayNode);
    if (eveningNode.children.isNotEmpty) root.children.add(eveningNode);
    if (nightNode.children.isNotEmpty) root.children.add(nightNode);

    // AIからの気づき（ルート直下の深掘り）を読み込む
    final existingRootDives = prefs.getString('deep_dives_root');
    if (existingRootDives != null) {
      try {
        final List decoded = jsonDecode(existingRootDives);
        root.children.addAll(decoded.map((c) => MindmapNode.fromJson(c)));
      } catch (e) {
        debugPrint('Failed to parse root deep dives: $e');
      }
    }

    _rootNode = root;
    _calculateLayout(_rootNode!);
  }

  void _calculateLayout(MindmapNode root) {
    const center = Offset(1000, 1000);
    root.position = center;

    final timeAngles = {
      '朝': -math.pi / 2, 
      '昼': 0.0,          
      '夜': math.pi / 2,  
      '夕': math.pi,      
    };

    void calculateChildren(MindmapNode node, double radius, double baseAngle, double spread) {
      if (!node.isExpanded) return;
      final children = node.children;
      final n = children.length;
      if (n == 0) return;

      final startAngle = baseAngle - spread / 2;
      final step = spread / (n + 1);

      for (int i = 0; i < n; i++) {
        final child = children[i];
        final childAngle = startAngle + step * (i + 1);
        
        // 箱が被らないように、奇数番目の要素は半径を少し遠くする（ジグザグ配置）
        double currentRadius = radius;
        if (child.type == 'ai_insight' || child.type == 'deep_dive') {
          currentRadius += (i % 2 != 0) ? 100.0 : 0.0;
        }

        child.position = center + Offset(currentRadius * math.cos(childAngle), currentRadius * math.sin(childAngle));
        
        // 深掘りの深掘りにも対応するため再帰的に計算。広がる角度を少しずつ狭める
        calculateChildren(child, currentRadius + 180.0, childAngle, spread * 0.8);
      }
    }

    for (final child in root.children) {
      if (!root.isExpanded) break;

      if (child.type == 'time') {
        final baseAngle = timeAngles[child.label] ?? 0.0;
        child.position = center + Offset(150.0 * math.cos(baseAngle), 150.0 * math.sin(baseAngle));
        calculateChildren(child, 330.0, baseAngle, math.pi / 1.5);
      }
    }

    // AIからの気づきノードの配置（朝昼夕夜の隙間、右下45度付近に配置）
    final aiInsights = root.children.where((n) => n.type == 'ai_insight').toList();
    for (int i = 0; i < aiInsights.length; i++) {
      if (!root.isExpanded) break;
      final node = aiInsights[i];
      final angle = (math.pi / 4) + (i * 0.3); // 重ならないように少しずつ角度をずらす
      node.position = center + Offset(220.0 * math.cos(angle), 220.0 * math.sin(angle));
      calculateChildren(node, 370.0, angle, math.pi / 2);
    }
  }

  void _onNodeTap(MindmapNode node) {
    if (node.type == 'time' || node.type == 'root') {
      setState(() {
        node.isExpanded = !node.isExpanded;
        if (_rootNode != null) _calculateLayout(_rootNode!);
      });
      // 開閉状態も保存しておく
      _saveAllDeepDives();
    } else if (node.type == 'ai_insight' && node.chatHistory != null && node.chatHistory!.isNotEmpty) {
      _showChatHistoryDialog(node);
    }
  }

  void _showChatHistoryDialog(MindmapNode node) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('AIとの対話履歴', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: node.chatHistory!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final message = node.chatHistory![index] as Map<String, dynamic>;
                final isUser = message['role'] == 'user';
                if (isUser && index == 0) return const SizedBox.shrink(); // Hide initial prompt
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFFA718F) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isUser
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Text(
                      message['content']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isUser ? Colors.white : const Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }



  Future<void> _saveAllDeepDives() async {
    if (_rootNode == null) return;
    final prefs = await SharedPreferences.getInstance();
    
    void traverseAndSave(MindmapNode n) {
      if (n.type == 'record') {
        final recordId = n.id.replaceAll('record_', '');
        final jsonStr = jsonEncode(n.children.map((c) => c.toJson()).toList());
        prefs.setString('deep_dives_$recordId', jsonStr);
      } else {
        for (final c in n.children) traverseAndSave(c);
      }
    }
    
    traverseAndSave(_rootNode!);
  }

  Future<void> _resetDeepDives() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('deep_dives_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('幸せの深掘りマップ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        foregroundColor: const Color(0xFF4A4A4A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '深掘りをリセット',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('リセットしますか？'),
                  content: const Text('保存されたすべての深掘りデータが消去されます。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false), 
                      child: const Text('キャンセル', style: TextStyle(color: Colors.grey))
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true), 
                      child: const Text('リセット', style: TextStyle(color: Colors.red))
                    ),
                  ],
                )
              );
              if (confirm == true) {
                await _resetDeepDives();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFA718F)))
          : _rootNode == null
              ? const Center(child: Text('データがありません'))
              : InteractiveViewer(
                  transformationController: _transformationController,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(600),
                  minScale: 0.1,
                  maxScale: 3.0,
                  child: SizedBox(
                    width: 2000,
                    height: 2000,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: const Size(2000, 2000),
                          painter: MindmapEdgePainter(_rootNode!),
                        ),
                        ..._buildNodeWidgets(_rootNode!),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _isLoading || _rootNode == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'ai_btn',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiCoachingScreen()),
                    );
                  },
                  backgroundColor: const Color(0xFFFA718F),
                  elevation: 4,
                  icon: const Text('✨', style: TextStyle(fontSize: 18)),
                  label: const Text('AI分析ルームへ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildNodeWidgets(MindmapNode node, {Offset offset = Offset.zero}) {
    final widgets = <Widget>[];
    widgets.add(
      Positioned(
        left: node.position.dx + offset.dx,
        top: node.position.dy + offset.dy,
        child: GestureDetector(
          onTap: () => _onNodeTap(node),
          child: _buildNodeCard(node),
        ),
      ),
    );
    if (node.isExpanded) {
      for (final child in node.children) {
        widgets.addAll(_buildNodeWidgets(child, offset: offset));
      }
    }
    return widgets;
  }

  Widget _buildNodeCard(MindmapNode node) {
    Color bgColor = Colors.white;
    Color textColor = const Color(0xFF4A4A4A);
    double fontSize = 14;
    IconData? icon;

    switch (node.type) {
      case 'root':
        bgColor = const Color(0xFFF48FB1);
        textColor = Colors.white;
        fontSize = 16;
        icon = Icons.favorite;
        break;
      case 'time':
        bgColor = const Color(0xFFFFB74D);
        textColor = Colors.white;
        fontSize = 15;
        if (node.label == '朝') icon = Icons.wb_twilight;
        if (node.label == '昼') icon = Icons.wb_sunny_rounded;
        if (node.label == '夕') icon = Icons.wb_cloudy_outlined;
        if (node.label == '夜') icon = Icons.nightlight_round;
        break;
      case 'deep_dive':
        bgColor = const Color(0xFF81C784);
        textColor = Colors.white;
        fontSize = 13;
        icon = Icons.lightbulb_outline;
        break;
      case 'ai_insight':
        bgColor = const Color(0xFFFFD54F); // ゴールド・黄色系
        textColor = const Color(0xFF4A4A4A);
        fontSize = 14;
        icon = Icons.auto_awesome;
        break;
      case 'record':
        bgColor = Colors.white;
        fontSize = 13;
        break;
    }

    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
          border: node.type == 'record' ? Border.all(color: const Color(0xFFF48FB1).withOpacity(0.3), width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: textColor, size: 18), const SizedBox(height: 4)],
            Text(
              node.label,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: node.type != 'record' ? FontWeight.bold : FontWeight.normal, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class MindmapEdgePainter extends CustomPainter {
  final MindmapNode root;
  final Offset offset;

  MindmapEdgePainter(this.root, {this.offset = Offset.zero});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFA718F).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    _drawEdges(canvas, paint, root);
  }

  void _drawEdges(Canvas canvas, Paint paint, MindmapNode node) {
    if (!node.isExpanded) return;

    final startPoint = node.position + offset;

    for (final child in node.children) {
      final endPoint = child.position + offset;
      
      canvas.drawLine(startPoint, endPoint, paint);
      
      _drawEdges(canvas, paint, child);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
