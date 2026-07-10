import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/coin_style_service.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  int _selectedIndex = 0;
  bool _isLoadingFootprints = true;
  List<Map<String, dynamic>> _footprintRecords = [];
  Set<String> _unlockedCategories = {};
  Map<String, Map<String, dynamic>> _latestAcquiredByCategory = {};

  bool _isLoadingAnalyses = true;
  List<Map<String, dynamic>> _savedAnalyses = [];

  final List<Map<String, dynamic>> categories = [
    {
      'id': 'sunny_blue',
      'title': '日常・景色',
      'subtitle': '青空、散歩など',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFF64B5F6),
      'hint':
          '毎日のちいさな景色や日常に幸せを見つけています。今日は見慣れた風景の中で、いつもと違う「いいな」と感じる瞬間を探してみましょう。',
    },
    {
      'id': 'heart_pink',
      'title': '友達・対人',
      'subtitle': 'カフェ、会話など',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFF06292),
      'hint': '友達や大切な人との交流で幸せを感じやすいようです。近いうちに「ありがとう」や「元気？」の一言を送ってみてください。',
    },
    {
      'id': 'home_orange',
      'title': '家族',
      'subtitle': '家族団らん、手伝いなど',
      'icon': Icons.home_rounded,
      'color': const Color(0xFFFFB74D),
      'hint':
          'これまでのメモには家族とのあたたかい時間が多く書かれています。次は一緒に料理や散歩をして、もっと穏やかな時間を増やしてみましょう。',
    },
    {
      'id': 'star_yellow',
      'title': '仕事・学校',
      'subtitle': '褒められた、テストなど',
      'icon': Icons.star_rounded,
      'color': const Color(0xFFFFD54F),
      'hint': '日々の頑張りや達成感が大きな支えになっています。小さなひとつを終えた後に、自分をほめる時間を作ってみてください。',
    },
    {
      'id': 'food_green',
      'title': '食事',
      'subtitle': '美味しいもの、自炊など',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFF81C784),
      'hint': '美味しい食事やごはんの時間から幸せを感じています。次はゆっくり味わえる食事を用意して、自分へのご褒美にしてみましょう。',
    },
    {
      'id': 'music_purple',
      'title': '趣味・推し',
      'subtitle': '音楽、読書、映画など',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFFBA68C8),
      'hint': '好きなことに触れる時間があなたの元気のもとになっています。少しだけ趣味や推し活動に時間を使ってみると、心が軽くなります。',
    },
    {
      'id': 'run_teal',
      'title': '運動・健康',
      'subtitle': '筋トレ、よく寝たなど',
      'icon': Icons.directions_run_rounded,
      'color': const Color(0xFF4DB6AC),
      'hint': '体を動かしたときに気分がすっきりしやすいようです。短い散歩や軽い体操を習慣にして、もう少し自分の体と向き合ってみましょう。',
    },
    {
      'id': 'car_indigo',
      'title': 'お出かけ',
      'subtitle': '旅行、買い物など',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF7986CB),
      'hint': '新しい風景や外出で心がリフレッシュしています。近場のお出かけでもいいので、気になる場所に行ってみるといいでしょう。',
    },
    {
      'id': 'bulb_red',
      'title': '自己成長',
      'subtitle': '新しい発見、挑戦など',
      'icon': Icons.lightbulb_rounded,
      'color': const Color(0xFFE57373),
      'hint': '挑戦や学びを通じて幸せを感じる傾向があります。今日の経験を振り返り、次にやってみたいことを小さく決めてみてください。',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFootprints();
    _loadAnalyses();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final crossAxisCount = screenWidth < 360
        ? 2
        : screenWidth < 700
        ? 3
        : 4;
    final childAspectRatio = screenWidth < 360
        ? 0.70
        : screenWidth < 700
        ? 0.68
        : 0.72;
    final horizontalPadding = isCompact ? 12.0 : 16.0;
    final selectedCategory = categories[_selectedIndex];
    final bool isSelectedAcquired = _unlockedCategories.contains(
      selectedCategory['id'],
    );
    final selectedRecord = _latestAcquiredByCategory[selectedCategory['id']];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF7EE),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
            onPressed: () => Navigator.pop(context),
          ),

          bottom: const TabBar(
            indicatorColor: Color(0xFFFF5A79),
            labelColor: Color(0xFF4A4A4A),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'コレクション'),
              Tab(text: 'あしあと'),
              Tab(text: '自己分析'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 8.0,
                    ),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = _selectedIndex == index;
                            final bool isAcquired = _unlockedCategories
                                .contains(category['id']);
                            final lastRecord =
                                _latestAcquiredByCategory[category['id']];
                            final lastDate = lastRecord != null
                                ? _formatDateTime(
                                    lastRecord['created_at'],
                                  ).split(' ').first
                                : null;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isAcquired
                                      ? Colors.white
                                      : const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isAcquired
                                              ? category['color'].withOpacity(
                                                  0.6,
                                                )
                                              : Colors.grey.withOpacity(0.4))
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CoinWidget(
                                      category: category,
                                      isAcquired: isAcquired,
                                      size: isCompact ? 54.0 : 68.0,
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      child: Text(
                                        isAcquired ? category['title'] : '？',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isAcquired
                                              ? const Color(0xFF4A4A4A)
                                              : Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      child: Text(
                                        isAcquired
                                            ? (lastDate != null
                                                  ? '最後の獲得: $lastDate'
                                                  : category['subtitle'])
                                            : '????/??/??',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isAcquired
                                              ? Colors.grey
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelectedAcquired
                          ? selectedCategory['color'].withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CoinWidget(
                        category: selectedCategory,
                        isAcquired: isSelectedAcquired,
                        size: isCompact ? 52.0 : 64.0,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSelectedAcquired
                                  ? selectedCategory['title']
                                  : '？',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelectedAcquired
                                    ? const Color(0xFF4A4A4A)
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSelectedAcquired
                                  ? (selectedRecord != null
                                        ? _formatDateTime(
                                            selectedRecord['created_at'],
                                          ).split(' ').first
                                        : '獲得済み')
                                  : '未解禁',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedCategory['hint'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6A6A6A),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: _isLoadingFootprints
                  ? const Center(child: CircularProgressIndicator())
                  : _footprintRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.track_changes,
                            size: 72,
                            color: Color(0xFFFF5A79),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'まだ記録がありません。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A4A4A),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '気になった出来事を書いて、コメントを受け取ってみましょう。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B6B6B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _footprintRecords.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = _footprintRecords[index];
                        final memo = record['memo'] as String? ?? '';
                        final aiComment = record['ai_comment'] as String? ?? '';
                        final createdAt = _formatDateTime(record['created_at']);
                        final coinType = record['coin_type'] as String?;

                        // Map legacy coin_types for display colors too
                        String mappedCoinType = coinType ?? '';
                        const legacyMap = {
                          'star_blue': 'sunny_blue',
                          'leaf_green': 'run_teal',
                          'star_purple': 'music_purple',
                          'flower_orange': 'home_orange',
                          'flower_pink': 'heart_pink',
                          'note_blue': 'sunny_blue',
                        };
                        if (legacyMap.containsKey(mappedCoinType)) {
                          mappedCoinType = legacyMap[mappedCoinType]!;
                        }

                        final appearance = CoinStyleService.buildCoinAppearance(
                          coinType: mappedCoinType,
                        );
                        final aiColor = appearance['color'] as Color;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.circle, size: 8, color: aiColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      createdAt,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8A8A8A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  memo,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF333333),
                                    height: 1.5,
                                  ),
                                ),
                                if (aiComment.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: aiColor.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: aiColor.withOpacity(0.28),
                                        width: 1.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'コメント',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color.lerp(
                                              aiColor,
                                              Colors.black,
                                              0.25,
                                            )!,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          aiComment,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color.lerp(
                                              aiColor,
                                              Colors.black,
                                              0.45,
                                            )!,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: _isLoadingAnalyses
                  ? const Center(child: CircularProgressIndicator())
                  : _savedAnalyses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.auto_awesome, size: 72, color: Color(0xFFFF5A79)),
                          SizedBox(height: 16),
                          Text(
                            '自己分析はまだありません。',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'AI分析ルームで対話をして、自己分析をキープしてみましょう。',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _savedAnalyses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final analysis = _savedAnalyses[index];
                        final content = analysis['insight'] as String? ?? '';
                        final createdAt = _formatDateTime(analysis['created_at']);
                        final id = analysis['id']?.toString() ?? UniqueKey().toString();
                        return Dismissible(
                          key: Key(id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: const Text('確認', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: const Text('この自己分析を削除してよろしいですか？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Text('削除する', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            _deleteAnalysis(index, id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('自己分析を削除しました'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Color(0xFFFFD54F)),
                                      const SizedBox(width: 8),
                                      Text(
                                        createdAt,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    content,
                                    style: const TextStyle(fontSize: 15, color: Color(0xFF333333), height: 1.5),
                                  ),
                                ],
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
    );
  }

  Future<void> _deleteAnalysis(int index, String id) async {
    setState(() {
      _savedAnalyses.removeAt(index);
    });
    try {
      await Supabase.instance.client.from('self_analyses').delete().eq('id', id);
    } catch (e) {
      debugPrint('Delete analysis error: $e');
    }
  }

  Future<void> _loadFootprints() async {
    setState(() {
      _isLoadingFootprints = true;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        setState(() {
          _footprintRecords = [];
          _isLoadingFootprints = false;
        });
        return;
      }

      final data = await client
          .from('happy_coins')
          .select('memo, ai_comment, coin_type, category, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final records =
          (data as List<dynamic>?)?.cast<Map<String, dynamic>>().toList() ?? [];

      final unlocked = <String>{};
      final latestByCategory = <String, Map<String, dynamic>>{};

      for (final record in records) {
        String? coinType = (record['coin_type'] as String?)?.trim();

        const legacyMap = {
          'star_blue': 'sunny_blue',
          'leaf_green': 'run_teal',
          'star_purple': 'music_purple',
          'flower_orange': 'home_orange',
          'flower_pink': 'heart_pink',
          'note_blue': 'sunny_blue',
        };

        if (legacyMap.containsKey(coinType)) {
          coinType = legacyMap[coinType];
        }

        if (coinType == null || coinType.isEmpty) continue;

        unlocked.add(coinType);

        final current = latestByCategory[coinType];
        final recordDate = _parseCreatedAt(record['created_at']);
        if (recordDate == null) continue;

        if (current == null) {
          latestByCategory[coinType] = record;
        } else {
          final currentDate = _parseCreatedAt(current['created_at']);
          if (currentDate != null && recordDate.isAfter(currentDate)) {
            latestByCategory[coinType] = record;
          }
        }
      }

      setState(() {
        _footprintRecords = records;
        _unlockedCategories = unlocked;
        _latestAcquiredByCategory = latestByCategory;
      });
    } catch (e) {
      debugPrint('Footprint load error: $e');
      setState(() {
        _footprintRecords = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFootprints = false;
        });
      }
    }
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoadingAnalyses = true;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('self_analyses')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        
        setState(() {
          _savedAnalyses = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Analyses load error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnalyses = false;
        });
      }
    }
  }

  DateTime? _parseCreatedAt(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDateTime(dynamic value) {
    final date = _parseCreatedAt(value);
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class CoinWidget extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isAcquired;
  final double size;

  const CoinWidget({
    super.key,
    required this.category,
    required this.isAcquired,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAcquired) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE8E8E8),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFC0C0C0),
            ),
          ),
        ),
      );
    }

    final Color baseColor = category['color'] is Color
        ? category['color'] as Color
        : const Color(0xFF64B5F6);
    final double grooveSize = size * 0.85;
    final double innerSize = size * 0.76;
    final double iconSize = size * 0.45;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.4),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Outer rim (convex)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(baseColor, Colors.white, 0.4)!,
                  baseColor,
                  Color.lerp(baseColor, Colors.black, 0.2)!,
                ],
              ),
            ),
          ),
          // 2. Groove (concave)
          Container(
            width: grooveSize,
            height: grooveSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(baseColor, Colors.black, 0.2)!,
                  baseColor,
                  Color.lerp(baseColor, Colors.white, 0.4)!,
                ],
              ),
            ),
          ),
          // 3. Inner circle (convex)
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(baseColor, Colors.white, 0.3)!,
                  baseColor,
                  Color.lerp(baseColor, Colors.black, 0.1)!,
                ],
              ),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Icon Shadow (bottom-right)
                  Positioned(
                    top: iconSize * 0.08,
                    left: iconSize * 0.08,
                    child: Icon(
                      category['icon'],
                      color: Color.lerp(baseColor, Colors.black, 0.3),
                      size: iconSize,
                    ),
                  ),
                  // Icon Highlight (top-left)
                  Positioned(
                    top: -(iconSize * 0.06),
                    left: -(iconSize * 0.06),
                    child: Icon(
                      category['icon'],
                      color: Color.lerp(baseColor, Colors.white, 0.7),
                      size: iconSize,
                    ),
                  ),
                  // Icon Base
                  Icon(
                    category['icon'],
                    color: Color.lerp(baseColor, Colors.white, 0.3),
                    size: iconSize,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
