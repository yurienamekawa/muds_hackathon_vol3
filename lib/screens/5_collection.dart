import 'package:flutter/material.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {
      'title': '日常・景色',
      'subtitle': '青空、散歩など',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFF64B5F6),
      'date': '2024.07.19',
      'detail': '天気が良くて、近くの公園まで散歩した。青空が広がっていてとても気持ちよかった！',
      'isAcquired': true,
    },
    {
      'title': '友達・対人',
      'subtitle': 'カフェ、会話など',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFF06292),
      'date': '2024.07.20',
      'detail': '久しぶりに友達とカフェでゆっくり話せて、とても楽しかった！',
      'isAcquired': true,
    },
    {
      'title': '家族',
      'subtitle': '家族団らん、手伝いなど',
      'icon': Icons.home_rounded,
      'color': const Color(0xFFFFB74D),
      'date': '2024.07.15',
      'detail': '家族みんなで夕食を食べて、テレビを見ながらたくさん笑った。',
      'isAcquired': true,
    },
    {
      'title': '仕事・学校',
      'subtitle': '褒められた、テストなど',
      'icon': Icons.star_rounded,
      'color': const Color(0xFFFFD54F),
      'date': '2024.07.18',
      'detail': '今日のプレゼンで先輩に褒められた！頑張って準備してよかった。',
      'isAcquired': true,
    },
    {
      'title': '食事',
      'subtitle': '美味しいもの、自炊など',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFF81C784),
      'date': '2024.07.17',
      'detail': '新しくできたレストランでランチを食べた。パスタがすごく美味しかった。',
      'isAcquired': true,
    },
    {
      'title': '趣味・推し',
      'subtitle': '音楽、読書、映画など',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFFBA68C8),
      'date': '2024.07.12',
      'detail': '好きなアーティストの新曲をずっと聴いていた。元気が出る！',
      'isAcquired': true,
    },
    {
      'title': '運動・健康',
      'subtitle': '筋トレ、よく寝たなど',
      'icon': Icons.directions_run_rounded,
      'color': const Color(0xFF4DB6AC),
      'date': '2024.07.10',
      'detail': 'ジムで1時間筋トレした。汗を流してスッキリした気分。',
      'isAcquired': true,
    },
    {
      'title': 'お出かけ',
      'subtitle': '旅行、買い物など',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF7986CB),
      'date': '2024.07.05',
      'detail': '週末に少し遠出してショッピング。欲しかった服が買えた！',
      'isAcquired': false,
    },
    {
      'title': '自己成長',
      'subtitle': '新しい発見、挑戦など',
      'icon': Icons.lightbulb_rounded,
      'color': const Color(0xFFE57373),
      'date': '2024.07.01',
      'detail': 'ずっと気になっていたプログラミングの勉強を始めた。楽しい！',
      'isAcquired': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedCategory = categories[_selectedIndex];
    final bool isSelectedAcquired = selectedCategory['isAcquired'] ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'コレクション',
              style: TextStyle(
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '(7 / 9)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedIndex == index;
                  final bool isAcquired = category['isAcquired'] ?? true;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAcquired ? Colors.white : const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isAcquired ? category['color'].withOpacity(0.6) : Colors.grey.withOpacity(0.4))
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
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              isAcquired ? category['title'] : '未獲得',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAcquired ? const Color(0xFF4A4A4A) : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isAcquired)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                category['date'], // Displaying date instead of subtitle like the new mockup
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
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
          // Bottom detail view
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelectedAcquired ? selectedCategory['color'].withOpacity(0.3) : Colors.grey.withOpacity(0.3),
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
                        isSelectedAcquired ? selectedCategory['title'] : '未獲得のメダル',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelectedAcquired ? const Color(0xFF4A4A4A) : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSelectedAcquired ? selectedCategory['date'] : '---',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSelectedAcquired ? selectedCategory['detail'] : 'このメダルはまだ獲得していません。日常の出来事を記録して集めよう！',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6A6A6A),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Bottom safe area space
        ],
      ),
    );
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

    final Color baseColor = category['color'];
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
