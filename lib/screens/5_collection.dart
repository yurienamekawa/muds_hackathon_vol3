import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static const Map<String, Color> _coinColorMap = {
    'heart_pink': Color(0xFFF06292),
    'star_blue': Color(0xFF64B5F6),
    'star_yellow': Color(0xFFFFD54F),
    'leaf_green': Color(0xFF81C784),
    'star_purple': Color(0xFFBA68C8),
    'flower_orange': Color(0xFFFF8A65),
    'flower_pink': Color(0xFFF48FB1),
    'note_blue': Color(0xFF4FC3F7),
  };

  final List<Map<String, dynamic>> categories = [
    {
      'title': '日常・景色',
      'subtitle': '青空、散歩など',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFF64B5F6),
      'hint': '朝の散歩やきれいな景色を見たときの出来事を書いてみよう。',
    },
    {
      'title': '友達・対人',
      'subtitle': 'カフェ、会話など',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFF06292),
      'hint': '友だちとの楽しい時間や、誰かとのつながりを感じた出来事を記録しよう。',
    },
    {
      'title': '家族',
      'subtitle': '家族団らん、手伝いなど',
      'icon': Icons.home_rounded,
      'color': const Color(0xFFFFB74D),
      'hint': '家族とのあたたかい時間や、お手伝いした出来事を書こう。',
    },
    {
      'title': '仕事・学校',
      'subtitle': '褒められた、テストなど',
      'icon': Icons.star_rounded,
      'color': const Color(0xFFFFD54F),
      'hint': '頑張ったことや達成感を感じた体験をメモしてみよう。',
    },
    {
      'title': '食事',
      'subtitle': '美味しいもの、自炊など',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFF81C784),
      'hint': 'おいしかった食事や、料理したときの気持ちを書いてみよう。',
    },
    {
      'title': '趣味・推し',
      'subtitle': '音楽、読書、映画など',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFFBA68C8),
      'hint': '好きなことに夢中になった瞬間や、新しい発見を書こう。',
    },
    {
      'title': '運動・健康',
      'subtitle': '筋トレ、よく寝たなど',
      'icon': Icons.directions_run_rounded,
      'color': const Color(0xFF4DB6AC),
      'hint': '体を動かしたり、休息できた気持ちよさを書き留めよう。',
    },
    {
      'title': 'お出かけ',
      'subtitle': '旅行、買い物など',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF7986CB),
      'hint': '外に出かけた体験や、小さな冒険を書いてみよう。',
    },
    {
      'title': '自己成長',
      'subtitle': '新しい発見、挑戦など',
      'icon': Icons.lightbulb_rounded,
      'color': const Color(0xFFE57373),
      'hint': '新しいことに挑戦したり、成長を感じた出来事を書こう。',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFootprints();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = categories[_selectedIndex];
    final bool isSelectedAcquired = _unlockedCategories.contains(
      selectedCategory['title'],
    );
    final selectedRecord = _latestAcquiredByCategory[selectedCategory['title']];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF7EE),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              const Text(
                'コレクション',
                style: TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(${_unlockedCategories.length} / ${categories.length})',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF5A79),
            labelColor: Color(0xFF4A4A4A),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'コレクション'),
              Tab(text: 'あしあと'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.68,
                          ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = _selectedIndex == index;
                        final bool isAcquired = _unlockedCategories.contains(
                          category['title'],
                        );
                        final lastRecord =
                            _latestAcquiredByCategory[category['title']];
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
                                          ? category['color'].withOpacity(0.6)
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
                                  size: 68.0,
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
                                        : category['hint'],
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
                        size: 64.0,
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
                            '気になった出来事を書いて、AIコメントを受け取ってみましょう。',
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
                        final aiColor =
                            _coinColorMap[coinType] ?? const Color(0xFF9E2B4F);

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
                                          'AIからの返答',
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
          ],
        ),
      ),
    );
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
        final categoryName = (record['category'] as String?)?.trim();
        if (categoryName == null || categoryName.isEmpty) continue;

        unlocked.add(categoryName);

        final current = latestByCategory[categoryName];
        final recordDate = _parseCreatedAt(record['created_at']);
        if (recordDate == null) continue;

        if (current == null) {
          latestByCategory[categoryName] = record;
        } else {
          final currentDate = _parseCreatedAt(current['created_at']);
          if (currentDate != null && recordDate.isAfter(currentDate)) {
            latestByCategory[categoryName] = record;
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
