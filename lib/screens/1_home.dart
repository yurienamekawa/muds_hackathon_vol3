// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:sensors_plus/sensors_plus.dart';
import '5_collection.dart';
import '6_mindmap.dart';
import '../widgets/animated_thought_bubble.dart';
import '../services/coin_style_service.dart';

enum TimeOfDayTheme { morning, day, evening, night }

class HomeScreen extends StatefulWidget {
  final String savedNote;
  final int currentCoins;

  const HomeScreen({super.key, this.savedNote = '', this.currentCoins = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  

  int _coinCount = 0;
  List<Map<String, dynamic>> _coinRecords = [];
  late TimeOfDayTheme _currentTheme;

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 10) {
      _currentTheme = TimeOfDayTheme.morning;
    } else if (hour >= 10 && hour < 16) {
      _currentTheme = TimeOfDayTheme.day;
    } else if (hour >= 16 && hour < 19) {
      _currentTheme = TimeOfDayTheme.evening;
    } else {
      _currentTheme = TimeOfDayTheme.night;
    }
    _fetchCoinCount();
  }

  Future<void> _fetchCoinCount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('happy_coins')
          .select('id, coin_type, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _coinRecords = (data as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .toList() ??
              [];
          _coinCount = _coinRecords.length;
        });
      }
    } catch (e) {
      print('コイン数取得エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      drawer: Drawer(
        backgroundColor: const Color(0xFFFDF7EE),
        child: SafeArea(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'メニュー',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('退会', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('退会しますか？'),
                      content: const Text('アカウントと全てのデータが削除されます。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            '退会する',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      await Supabase.instance.client.rpc('delete_user');
                      await Supabase.instance.client.auth.signOut();
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A4A4A)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Landscape
          Positioned.fill(
            child: CustomPaint(
              painter: PiggyBankBackgroundPainter(theme: _currentTheme),
            ),
          ),
          
          // Foreground Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildTimeSelector(),
                // Glass Piggy Bank (Fills the remaining space)
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CollectionScreen(),
                              ),
                            );
                          },
                          child: GlassPiggyBank(
                            currentCoins: _coinCount,
                            coinRecords: _coinRecords,
                          ),
                        ),
                      ),
                      // Mindmap Button
                      Positioned(
                        top: 80,
                        left: 60,
                        child: AnimatedThoughtBubble(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MindmapScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Collection Button at the bottom
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CollectionScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFFF5A79),
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'コレクション',
                              style: TextStyle(
                                color: Color(0xFFFF5A79),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _buildSegment(TimeOfDayTheme.morning, '朝', Icons.wb_twilight, true, false),
                _buildDivider(),
                _buildSegment(TimeOfDayTheme.day, '昼', Icons.wb_sunny_rounded, false, false),
                _buildDivider(),
                _buildSegment(TimeOfDayTheme.evening, '夕', Icons.wb_cloudy_outlined, false, false),
                _buildDivider(),
                _buildSegment(TimeOfDayTheme.night, '夜', Icons.nightlight_round, false, true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 18,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildSegment(
    TimeOfDayTheme theme,
    String label,
    IconData icon,
    bool isFirst,
    bool isLast,
  ) {
    final isSelected = _currentTheme == theme;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTheme = theme;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(18) : Radius.zero,
                    right: isLast ? const Radius.circular(18) : Radius.zero,
                  ),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PiggyBankCard extends StatelessWidget {
  const PiggyBankCard({
    super.key,
    this.currentCoins = 7,
    this.fallingCoin,
    this.showCollectionButton = true,
    this.theme = TimeOfDayTheme.day,
    this.height = 400.0,
    this.coinRecords = const [],
  });

  final int currentCoins;
  final Widget? fallingCoin;
  final bool showCollectionButton;
  final TimeOfDayTheme theme;
  final double height;
  final List<Map<String, dynamic>> coinRecords;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 1_home.dart の退会ボタンの onTap を以下のようにします
      // 1_home.dart の退会ボタンの onTap をこれに差し替えてください
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CollectionScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Landscape (Gradient, Grass, Flowers, Hearts)
                Positioned.fill(
                  child: CustomPaint(
                    painter: PiggyBankBackgroundPainter(theme: theme),
                  ),
                ),

                // Glass Piggy Bank UI
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GlassPiggyBank(
                      currentCoins: currentCoins,
                      fallingCoin: fallingCoin,
                      coinRecords: coinRecords,
                    ),
                  ),
                ),

                // Mindmap Button
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MindmapScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        '💭',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),

                // Button overlay
                if (showCollectionButton)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CollectionScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFF06292),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'コレクションを見る',
                              style: TextStyle(
                                color: Color(0xFF4A4A4A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PiggyBankBackgroundPainter extends CustomPainter {
  final TimeOfDayTheme theme;
  PiggyBankBackgroundPainter({required this.theme});
  @override
  @override
  void paint(Canvas canvas, Size size) {
    List<Color> skyColors;
    Color distantHillColor;
    Color treeTrunkColor;
    Color treeLeafColor;
    Color treeLeafHighlight;
    Color groundMainColor;
    Color groundGradientColor;
    Color shadowColor;
    Color bushColor;
    Color daisyColor;
    Color blueFlowerColor;
    Color redFlowerColor;
    Color tulipColor;
    Color sparkleColor;
    Color heartColor;

    switch (theme) {
      case TimeOfDayTheme.morning:
        skyColors = [const Color(0xFFFFF7E0), const Color(0xFFFFE5C4)];
        distantHillColor = const Color(0xFFC5E1A5);
        treeTrunkColor = const Color(0xFFA1887F);
        treeLeafColor = const Color(0xFFAED581);
        treeLeafHighlight = const Color(0xFFC5E1A5).withValues(alpha: 0.8);
        groundMainColor = const Color(0xFFA5D6A7);
        groundGradientColor = const Color(0xFF81C784);
        shadowColor = Colors.black.withValues(alpha: 0.08);
        bushColor = const Color(0xFF66BB6A);
        daisyColor = Colors.white.withValues(alpha: 0.85);
        blueFlowerColor = const Color(0xFF90CAF9);
        redFlowerColor = const Color(0xFFEF9A9A);
        tulipColor = const Color(0xFFFFB74D);
        sparkleColor = Colors.white;
        heartColor = const Color(0xFFF06292);
        break;
      case TimeOfDayTheme.day:
        skyColors = [
          const Color(0xFFE1F5FE),
          const Color(0xFFFFF9C4),
        ]; // Light blue to pale yellow
        distantHillColor = const Color(0xFFAED581); // Slightly more vibrant
        treeTrunkColor = const Color(0xFF8D6E63);
        treeLeafColor = const Color(0xFF81C784);
        treeLeafHighlight = const Color(0xFFAED581).withValues(alpha: 0.8);
        groundMainColor = const Color(0xFF81C784);
        groundGradientColor = const Color(0xFF66BB6A);
        shadowColor = Colors.black.withValues(alpha: 0.1);
        bushColor = const Color(0xFF4CAF50);
        daisyColor = Colors.white.withValues(alpha: 0.9);
        blueFlowerColor = const Color(0xFF64B5F6);
        redFlowerColor = const Color(0xFFE57373);
        tulipColor = const Color(0xFFFFA726);
        sparkleColor = Colors.white;
        heartColor = const Color(0xFFEC407A);
        break;
      case TimeOfDayTheme.evening:
        skyColors = [
          const Color(0xFFEF5350),
          const Color(0xFFFFB74D),
        ]; // Red to orange
        distantHillColor = const Color(0xFF8D6E63); // Brownish
        treeTrunkColor = const Color(0xFF5D4037);
        treeLeafColor = const Color(0xFF795548);
        treeLeafHighlight = const Color(0xFF8D6E63).withValues(alpha: 0.8);
        groundMainColor = const Color(0xFF795548);
        groundGradientColor = const Color(0xFF5D4037);
        shadowColor = Colors.black.withValues(alpha: 0.2);
        bushColor = const Color(0xFF4E342E);
        daisyColor = const Color(0xFFFFE0B2).withValues(alpha: 0.8);
        blueFlowerColor = const Color(0xFFCE93D8);
        redFlowerColor = const Color(0xFFD32F2F);
        tulipColor = const Color(0xFFFF7043);
        sparkleColor = const Color(0xFFFFCC80);
        heartColor = const Color(0xFFC2185B);
        break;
      case TimeOfDayTheme.night:
        skyColors = [
          const Color(0xFF1A237E),
          const Color(0xFF3949AB),
        ]; // Dark navy
        distantHillColor = const Color(0xFF283593);
        treeTrunkColor = const Color(0xFF1A237E);
        treeLeafColor = const Color(0xFF303F9F);
        treeLeafHighlight = const Color(0xFF3949AB).withValues(alpha: 0.8);
        groundMainColor = const Color(0xFF283593);
        groundGradientColor = const Color(0xFF1A237E);
        shadowColor = Colors.black.withValues(alpha: 0.3);
        bushColor = const Color(0xFF1A237E);
        daisyColor = Colors.white.withValues(alpha: 0.4);
        blueFlowerColor = const Color(0xFF5C6BC0);
        redFlowerColor = const Color(0xFF7986CB);
        tulipColor = const Color(0xFF5C6BC0);
        sparkleColor = const Color(0xFFFFF59D); // Yellow fireflies
        heartColor = const Color(0xFF9FA8DA);
        break;
    }

    // 1. Sky Gradient
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: skyColors,
      stops: const [0.0, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      Paint()
        ..shader = skyGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
        ),
    );

    // Draw Sun or Moon
    if (theme == TimeOfDayTheme.morning || theme == TimeOfDayTheme.evening) {
      // Glow
      canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.4),
        size.width * 0.3,
        Paint()
          ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      // Sun
      canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.45),
        size.width * 0.15,
        Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.8),
      );
    } else if (theme == TimeOfDayTheme.day) {
      // High Sun
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.3),
        size.width * 0.25,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
    } else if (theme == TimeOfDayTheme.night) {
      // Moon
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.15),
        size.width * 0.08,
        Paint()..color = const Color(0xFFFFF9C4),
      );
      // Moon inner cut out to make it crescent
      canvas.drawCircle(
        Offset(size.width * 0.77, size.height * 0.13),
        size.width * 0.08,
        Paint()..color = skyColors[0],
      );
    }

    // 2. Distant Hills (Background)
    final distantHillPaint = Paint()..color = distantHillColor;
    // Left distant hill
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.2, size.height * 0.45),
        width: size.width * 0.8,
        height: size.height * 0.3,
      ),
      distantHillPaint,
    );
    // Right distant hill
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.45),
        width: size.width * 0.8,
        height: size.height * 0.3,
      ),
      distantHillPaint,
    );

    // 3. Trees
    void drawTree(Offset pos, double scale) {
      // Trunk
      canvas.drawRect(
        Rect.fromCenter(
          center: pos + Offset(0, 15 * scale),
          width: 6 * scale,
          height: 20 * scale,
        ),
        Paint()..color = treeTrunkColor,
      );
      // Leaves (round)
      canvas.drawCircle(pos, 18 * scale, Paint()..color = treeLeafColor);
      // Highlight on leaves
      canvas.drawCircle(
        pos + Offset(-4 * scale, -4 * scale),
        8 * scale,
        Paint()..color = treeLeafHighlight,
      );
    }

    drawTree(Offset(size.width * 0.1, size.height * 0.35), 1.2);
    drawTree(Offset(size.width * 0.22, size.height * 0.38), 0.8);
    drawTree(Offset(size.width * 0.88, size.height * 0.32), 1.4);

    // 4. Main Ground (Mid-ground)
    final groundPath = Path();
    groundPath.moveTo(0, size.height * 0.45);
    groundPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.4,
      size.width,
      size.height * 0.42,
    );
    groundPath.lineTo(size.width, size.height);
    groundPath.lineTo(0, size.height);
    groundPath.close();

    canvas.drawPath(groundPath, Paint()..color = groundMainColor);

    // Add a darker green gradient towards the bottom
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [groundMainColor.withValues(alpha: 0.0), groundGradientColor],
    );
    canvas.drawPath(
      groundPath,
      Paint()
        ..shader = groundGradient.createShader(
          Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
        ),
    );

    // 5. Shadow under the pig
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.85),
        width: size.width * 0.7,
        height: size.height * 0.15,
      ),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 6. Foreground Bushes
    final bushPaint = Paint()..color = bushColor;

    // Bottom-left bushes
    canvas.drawCircle(
      Offset(size.width * 0.0, size.height * 0.95),
      size.width * 0.2,
      bushPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 1.0),
      size.width * 0.15,
      bushPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 1.05),
      size.width * 0.15,
      bushPaint,
    );

    // Bottom-right bushes
    canvas.drawCircle(
      Offset(size.width * 1.0, size.height * 0.92),
      size.width * 0.25,
      bushPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 1.0),
      size.width * 0.18,
      bushPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 1.05),
      size.width * 0.15,
      bushPaint,
    );

    // 7. Flowers
    void drawFlower(
      Offset pos,
      double sizeParam,
      Color petalColor, {
      bool hasStem = false,
    }) {
      if (hasStem) {
        // Draw stem
        final stemPath = Path();
        stemPath.moveTo(pos.dx, pos.dy);
        stemPath.quadraticBezierTo(
          pos.dx - 5,
          pos.dy + 15,
          pos.dx + 2,
          pos.dy + 30,
        );
        canvas.drawPath(
          stemPath,
          Paint()
            ..color = distantHillColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        // Draw leaf
        canvas.drawOval(
          Rect.fromCenter(
            center: pos + const Offset(-6, 15),
            width: 8,
            height: 4,
          ),
          Paint()..color = distantHillColor,
        );
      }

      final petalPaint = Paint()..color = petalColor;
      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * math.pi) / 5;
        final cx = pos.dx + math.cos(angle) * sizeParam * 0.6;
        final cy = pos.dy + math.sin(angle) * sizeParam * 0.6;
        canvas.drawCircle(Offset(cx, cy), sizeParam * 0.5, petalPaint);
      }
      // Center
      canvas.drawCircle(
        pos,
        sizeParam * 0.4,
        Paint()..color = const Color(0xFFFFCA28),
      );
    }

    // White daisies
    drawFlower(Offset(size.width * 0.15, size.height * 0.6), 6, daisyColor);
    drawFlower(Offset(size.width * 0.85, size.height * 0.5), 5, daisyColor);
    drawFlower(Offset(size.width * 0.2, size.height * 0.8), 8, daisyColor);

    // Blue flower
    drawFlower(
      Offset(size.width * 0.1, size.height * 0.7),
      9,
      blueFlowerColor,
      hasStem: true,
    );

    // Red flowers
    drawFlower(
      Offset(size.width * 0.9, size.height * 0.58),
      8,
      redFlowerColor,
      hasStem: true,
    );
    drawFlower(
      Offset(size.width * 0.92, size.height * 0.75),
      9,
      redFlowerColor,
      hasStem: true,
    );

    // Tulip/Orange flower
    void drawTulip(Offset pos, double scale) {
      final path = Path();
      path.moveTo(pos.dx, pos.dy + 10 * scale);
      path.quadraticBezierTo(
        pos.dx - 8 * scale,
        pos.dy + 5 * scale,
        pos.dx - 6 * scale,
        pos.dy - 5 * scale,
      );
      path.quadraticBezierTo(
        pos.dx - 3 * scale,
        pos.dy,
        pos.dx,
        pos.dy - 8 * scale,
      );
      path.quadraticBezierTo(
        pos.dx + 3 * scale,
        pos.dy,
        pos.dx + 6 * scale,
        pos.dy - 5 * scale,
      );
      path.quadraticBezierTo(
        pos.dx + 8 * scale,
        pos.dy + 5 * scale,
        pos.dx,
        pos.dy + 10 * scale,
      );
      canvas.drawPath(path, Paint()..color = tulipColor);
    }

    drawTulip(Offset(size.width * 0.8, size.height * 0.85), 1.2);

    // Grass blades
    void drawGrassBlade(Offset pos) {
      final path = Path();
      path.moveTo(pos.dx, pos.dy);
      path.quadraticBezierTo(pos.dx - 2, pos.dy - 8, pos.dx + 2, pos.dy - 12);
      path.quadraticBezierTo(pos.dx + 4, pos.dy - 6, pos.dx + 2, pos.dy);
      canvas.drawPath(path, Paint()..color = distantHillColor);
    }

    drawGrassBlade(Offset(size.width * 0.1, size.height * 0.52));
    drawGrassBlade(Offset(size.width * 0.25, size.height * 0.55));
    drawGrassBlade(Offset(size.width * 0.8, size.height * 0.55));
    drawGrassBlade(Offset(size.width * 0.35, size.height * 0.88));

    // 8. Sparkles (Stars / Fireflies)
    void drawSparkle(Offset center, double sizeParam, double opacity) {
      final path = Path();
      path.moveTo(center.dx, center.dy - sizeParam);
      path.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx + sizeParam,
        center.dy,
      );
      path.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx,
        center.dy + sizeParam,
      );
      path.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx - sizeParam,
        center.dy,
      );
      path.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx,
        center.dy - sizeParam,
      );
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = sparkleColor.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }

    if (theme == TimeOfDayTheme.night) {
      // Fireflies / Stars
      drawSparkle(Offset(size.width * 0.15, size.height * 0.1), 10, 0.8);
      drawSparkle(Offset(size.width * 0.1, size.height * 0.4), 6, 0.6);
      drawSparkle(Offset(size.width * 0.85, size.height * 0.65), 8, 0.7);
      drawSparkle(Offset(size.width * 0.4, size.height * 0.2), 5, 0.8);
      drawSparkle(Offset(size.width * 0.7, size.height * 0.4), 7, 0.9);
      drawSparkle(Offset(size.width * 0.2, size.height * 0.8), 8, 0.6);
      drawSparkle(Offset(size.width * 0.9, size.height * 0.85), 5, 0.7);
    } else {
      drawSparkle(Offset(size.width * 0.15, size.height * 0.1), 10, 0.8);
      drawSparkle(Offset(size.width * 0.1, size.height * 0.4), 6, 0.6);
      drawSparkle(Offset(size.width * 0.85, size.height * 0.65), 8, 0.7);
    }

    // 9. Floating Heart
    void drawHeart(Offset pos, double scale) {
      final path = Path();
      path.moveTo(pos.dx, pos.dy + 4 * scale);
      path.cubicTo(
        pos.dx - 5 * scale,
        pos.dy,
        pos.dx - 5 * scale,
        pos.dy - 6 * scale,
        pos.dx,
        pos.dy - 2 * scale,
      );
      path.moveTo(pos.dx, pos.dy + 4 * scale);
      path.cubicTo(
        pos.dx + 5 * scale,
        pos.dy,
        pos.dx + 5 * scale,
        pos.dy - 6 * scale,
        pos.dx,
        pos.dy - 2 * scale,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = heartColor
          ..style = PaintingStyle.fill,
      );
    }

    if (theme != TimeOfDayTheme.night) {
      drawHeart(Offset(size.width * 0.85, size.height * 0.15), 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassPiggyBank extends StatefulWidget {
  final int currentCoins;
  final Widget? fallingCoin;
  final List<Map<String, dynamic>> coinRecords;
  const GlassPiggyBank({
    super.key,
    required this.currentCoins,
    this.fallingCoin,
    this.coinRecords = const [],
  });

  @override
  State<GlassPiggyBank> createState() => _GlassPiggyBankState();
}

class _GlassPiggyBankState extends State<GlassPiggyBank>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  Offset _sensorOffset = Offset.zero;
  Offset _mouseOffset = Offset.zero;
  late final AnimationController _springController;
  late Animation<Offset> _springAnimation;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _springController.addListener(() {
      setState(() {
        _dragOffset = _springAnimation.value;
      });
    });

    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!mounted) return;
      setState(() {
        // デバイスの傾きや加速度をオフセットに変換（Xは左右、Yは上下）
        // 画面の向きに合わせてX軸は反転させることで、重力に従って動く感覚を出す
        _sensorOffset = Offset(-event.x * 2.5, (event.y - 9.8) * 2.5);
      });
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      double maxDrag = 60.0;
      if (_dragOffset.distance > maxDrag) {
        _dragOffset = (_dragOffset / _dragOffset.distance) * maxDrag;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _springAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
        );
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final rnd = math.Random(88);

    final List<Widget> coins = [];
    final int displayCoins = math.min(widget.currentCoins, 25);

    final double areaSize = math.min(
      350.0,
      MediaQuery.of(context).size.width * 0.82,
    );
    // 豚らしい横長の楕円形（Oval）のサイズ
    final double bellyWidth = areaSize * 0.8;
    final double bellyHeight = areaSize * 0.65;
    final double bellyCenterX = areaSize * 0.5;
    final double bellyCenterY = areaSize * 0.5;

    for (int i = 0; i < displayCoins; i++) {
      // 楕円の下半分にコインを配置
      final double angle = rnd.nextDouble() * math.pi;
      final double r = math.sqrt(rnd.nextDouble());

      final double cx =
          bellyCenterX + math.cos(angle) * (bellyWidth / 2 * 0.85) * r;
      final double cy =
          bellyCenterY +
          (bellyHeight * 0.1) +
          (math.sin(angle) * (bellyHeight / 2 * 0.75) * r) -
          (i * 1.5);

      final coinRecord = widget.coinRecords.isNotEmpty
          ? widget.coinRecords[i % widget.coinRecords.length]
          : null;
      final appearance = CoinStyleService.buildCoinAppearance(
        coinType: coinRecord?['coin_type'] as String?,
      );
      final double coinSize = 35.0 + rnd.nextDouble() * 10.0;

      final double angleX = (rnd.nextDouble() - 0.5) * 0.6;
      final double angleY = (rnd.nextDouble() - 0.5) * 0.6;
      final double angleZ = rnd.nextDouble() * 2 * math.pi;

      // 物理演算（揺れ＋加速度センサー＋マウス）の適用
      final double parallax = 1.0 + (i % 4) * 0.2;

      // ドラッグの揺れ、デバイスの傾き（センサー）、マウスホバーの傾きの全てを加算
      final Offset coinOffset =
          (_dragOffset * parallax) +
          (_sensorOffset * (parallax * 1.2)) +
          (_mouseOffset * parallax);

      final double finalCx = cx + coinOffset.dx;
      final double finalCy = cy + coinOffset.dy;

      // 揺れに合わせて少し回転させる
      final double shakeRotX =
          angleX +
          (_dragOffset.dy * 0.015 * parallax) +
          (_sensorOffset.dy * 0.02) +
          (_mouseOffset.dy * 0.015);
      final double shakeRotY =
          angleY +
          (_dragOffset.dx * 0.015 * parallax) +
          (_sensorOffset.dx * 0.02) +
          (_mouseOffset.dx * 0.015);

      coins.add(
        Positioned(
          left: finalCx - (coinSize / 2),
          top: finalCy - (coinSize / 2),
          child: Coin3D(
            category: {
              'icon': appearance['icon'],
              'color': appearance['color'],
            },
            size: coinSize,
            angleX: shakeRotX,
            angleY: shakeRotY,
            angleZ: angleZ,
          ),
        ),
      );
    }

    coins.sort((a, b) {
      final posA = a as Positioned;
      final posB = b as Positioned;
      return posA.top!.compareTo(posB.top!);
    });

    return Center(
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            // マウスの位置を貯金箱の中心(areaSize/2)からの相対位置として取得し、傾きに変換
            final double dx = event.localPosition.dx - (areaSize / 2);
            final double dy = event.localPosition.dy - (areaSize / 2);
            _mouseOffset = Offset(dx * 0.15, dy * 0.15);
          });
        },
        onExit: (event) {
          setState(() {
            _mouseOffset = Offset.zero;
          });
        },
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          // ガラス全体も少しだけ揺れる
          child: Transform.translate(
            offset: _dragOffset * 0.2,
            child: SizedBox(
              width: areaSize,
              height: areaSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. 背面のガラス層
                  Positioned.fill(
                    child: CustomPaint(painter: GlassPiggyBankBackPainter()),
                  ),

                  // 2. コイン層（ガラスからはみ出ないように楕円でクリップ）
                  Positioned.fill(
                    child: ClipPath(
                      clipper: PiggyBankBellyClipper(
                        center: Offset(bellyCenterX, bellyCenterY),
                        width: bellyWidth * 0.9,
                        height: bellyHeight * 0.9,
                      ),
                      child: Stack(clipBehavior: Clip.none, children: coins),
                    ),
                  ),

                  // 落下中のコイン
                  if (widget.fallingCoin != null) widget.fallingCoin!,

                  // 3. 前面のガラス層
                  Positioned.fill(
                    child: CustomPaint(painter: GlassPiggyBankFrontPainter()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PiggyBankBellyClipper extends CustomClipper<Path> {
  final Offset center;
  final double width;
  final double height;
  PiggyBankBellyClipper({
    required this.center,
    required this.width,
    required this.height,
  });

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCenter(center: center, width: width, height: height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// ---------------------------------------------------------
// Pure Code 3D Glass Painters (Pig Shape)
// ---------------------------------------------------------

/// 貯金箱の背面（後ろの足、後ろの耳、背面のガラス壁）
class GlassPiggyBankBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final width = size.width * 0.8;
    final height = size.width * 0.65;

    void drawBackLeg(Offset legCenter) {
      final legRect = Rect.fromCenter(
        center: legCenter,
        width: width * 0.12,
        height: height * 0.25,
      );
      final legRRect = RRect.fromRectAndRadius(
        legRect,
        const Radius.circular(15),
      );

      // 暗めのガラス影
      canvas.drawRRect(
        legRRect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      // ガラスのハイライト（背面でも少し光る）
      canvas.drawRRect(
        legRRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.4),
            ],
          ).createShader(legRect),
      );
      // エッジのハイライトで輪郭を強調して視認性アップ
      final highlightPath = Path()
        ..moveTo(legRect.left + 3, legRect.top + 5)
        ..lineTo(legRect.left + 3, legRect.bottom - 5);
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 後ろの左足と右足（奥まった位置に配置して4本足に）
    drawBackLeg(Offset(center.dx - width * 0.1, center.dy + height * 0.35));
    drawBackLeg(Offset(center.dx + width * 0.35, center.dy + height * 0.35));

    // 背面のガラスの厚み（内側のシャドウとわずかなシアンで奥行きを表現）
    final bodyRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    final backBodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.25), // Stronger frosted glass base
          Colors.black.withValues(alpha: 0.05),
          const Color(0xFFE0F7FA).withValues(alpha: 0.6), // Stronger rim light
        ],
        stops: const [0.0, 0.85, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, backBodyPaint);

    // 投入口の奥側（暗いスリット線）
    final slotCenter = Offset(
      center.dx + width * 0.05,
      center.dy - height * 0.48,
    );
    final slotWidth = width * 0.22;
    final slotDarkPath = Path();
    slotDarkPath.moveTo(slotCenter.dx - slotWidth * 0.5, slotCenter.dy);
    slotDarkPath.quadraticBezierTo(
      slotCenter.dx,
      slotCenter.dy - height * 0.02,
      slotCenter.dx + slotWidth * 0.5,
      slotCenter.dy + height * 0.015,
    );

    canvas.drawPath(
      slotDarkPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 貯金箱の前面（お腹の手前のガラス、鼻、目、手前の耳、足、しっぽ）
class GlassPiggyBankFrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final width = size.width * 0.8;
    final height = size.width * 0.65;
    final bodyRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    // 1. お腹の前面ガラス（シャドウで球体の立体感を出す）
    final bodyShadow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, 0.3), // 左上から光、右下に影
        radius: 0.8,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
        stops: const [0.6, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyShadow);

    // フレネル反射（フチを白く飛ばす）
    final frontBodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 1.0),
        ],
        stops: const [0.5, 0.85, 0.95, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, frontBodyPaint);

    // 底面の極厚ガラスハイライト
    canvas.save();
    canvas.clipPath(Path()..addOval(bodyRect));
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: width * 0.96,
        height: height * 0.96,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();

    // 2. スペキュラハイライト（シャープな窓の反射で硬いガラスを表現）
    final windowHighlight = Path();
    windowHighlight.moveTo(center.dx - width * 0.3, center.dy - height * 0.4);
    windowHighlight.quadraticBezierTo(
      center.dx,
      center.dy - height * 0.48,
      center.dx + width * 0.25,
      center.dy - height * 0.3,
    );
    windowHighlight.lineTo(center.dx + width * 0.2, center.dy - height * 0.25);
    windowHighlight.quadraticBezierTo(
      center.dx,
      center.dy - height * 0.4,
      center.dx - width * 0.25,
      center.dy - height * 0.33,
    );
    windowHighlight.close();

    canvas.drawPath(
      windowHighlight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.5), // Stronger highlight
            Colors.white.withValues(alpha: 0.1),
          ],
        ).createShader(windowHighlight.getBounds()),
    );

    // 3. 手前の足
    void drawFrontLeg(Offset legCenter) {
      final legRect = Rect.fromCenter(
        center: legCenter,
        width: width * 0.14,
        height: height * 0.28,
      );
      final legRRect = RRect.fromRectAndRadius(
        legRect,
        const Radius.circular(15),
      );

      canvas.drawRRect(
        legRRect,
        Paint()..color = Colors.white.withValues(alpha: 0.15),
      );
      // 右側の影
      canvas.drawRRect(
        legRRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
          ).createShader(legRect),
      );
      // 左側のハイライト
      final highlightPath = Path()
        ..moveTo(legRect.left + 5, legRect.top + 8)
        ..lineTo(legRect.left + 5, legRect.bottom - 8);
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }

    drawFrontLeg(Offset(center.dx - width * 0.25, center.dy + height * 0.45));
    drawFrontLeg(Offset(center.dx + width * 0.2, center.dy + height * 0.45));

    // 4. 鼻 (Snout) を少し小さく、透明感を持たせる
    final snoutCenter = Offset(
      center.dx - width * 0.4,
      center.dy + height * 0.05,
    );
    final snoutWidth = width * 0.22;
    final snoutHeight = height * 0.32;
    final snoutRect = Rect.fromCenter(
      center: snoutCenter,
      width: snoutWidth,
      height: snoutHeight,
    );

    // 白いプラスチック/ガラスの土台フチ（細くする）
    canvas.drawOval(
      snoutRect.inflate(2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    // 少し透明感のあるリアルなピンクの鼻
    canvas.drawOval(
      snoutRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            const Color(0xFFFCE4EC).withValues(alpha: 0.9), // ハイライトピンク
            const Color(0xFFF8BBD0).withValues(alpha: 0.75), // ベースピンク
            const Color(0xFFE91E63).withValues(alpha: 0.4), // シャドウ
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(snoutRect),
    );

    // 鼻の穴
    final leftNostril = Rect.fromCenter(
      center: Offset(snoutCenter.dx - snoutWidth * 0.12, snoutCenter.dy),
      width: snoutWidth * 0.12,
      height: snoutHeight * 0.25,
    );
    final rightNostril = Rect.fromCenter(
      center: Offset(snoutCenter.dx + snoutWidth * 0.12, snoutCenter.dy),
      width: snoutWidth * 0.12,
      height: snoutHeight * 0.25,
    );
    final nostrilPaint = Paint()
      ..color = const Color(0xFFAD1457).withValues(alpha: 0.6);
    canvas.drawOval(leftNostril, nostrilPaint);
    canvas.drawOval(rightNostril, nostrilPaint);

    // 5. 目 (Eyes)
    void drawEye(Offset eyeCenter) {
      final eyeRect = Rect.fromCenter(
        center: eyeCenter,
        width: width * 0.045,
        height: height * 0.12,
      );
      // ツヤのある黒目
      canvas.drawOval(eyeRect, Paint()..color = const Color(0xFF2C2C2C));
      // 上の強いハイライト
      canvas.drawCircle(
        Offset(eyeCenter.dx - 2, eyeCenter.dy - 4),
        2.5,
        Paint()..color = Colors.white,
      );
      // 下の照り返し
      canvas.drawCircle(
        Offset(eyeCenter.dx + 1.5, eyeCenter.dy + 3),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }

    drawEye(Offset(center.dx - width * 0.23, center.dy - height * 0.15));
    drawEye(Offset(center.dx - width * 0.03, center.dy - height * 0.15));

    // 6. 手前の耳（左耳）と奥の耳（右耳）をここで両方描画（体のエッジハイライトの上に重ねるため）
    void drawEar(Path earPath, bool isFront) {
      canvas.drawPath(
        earPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: isFront ? 0.6 : 0.4),
              Colors.white.withValues(alpha: 0.1),
            ],
          ).createShader(earPath.getBounds()),
      );
      canvas.drawPath(
        earPath,
        Paint()
          ..color = Colors.white.withValues(alpha: isFront ? 0.95 : 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }

    // 奥の耳（右耳）
    final backEarPath = Path();
    backEarPath.moveTo(center.dx - width * 0.05, center.dy - height * 0.4);
    backEarPath.quadraticBezierTo(
      center.dx - width * 0.05,
      center.dy - height * 0.55,
      center.dx + width * 0.1,
      center.dy - height * 0.6,
    );
    backEarPath.quadraticBezierTo(
      center.dx + width * 0.2,
      center.dy - height * 0.5,
      center.dx + width * 0.15,
      center.dy - height * 0.4,
    );
    backEarPath.close();
    drawEar(backEarPath, false);

    // 手前の耳（左耳）
    final frontEarPath = Path();
    frontEarPath.moveTo(center.dx - width * 0.35, center.dy - height * 0.3);
    frontEarPath.quadraticBezierTo(
      center.dx - width * 0.45,
      center.dy - height * 0.5,
      center.dx - width * 0.28,
      center.dy - height * 0.55,
    );
    frontEarPath.quadraticBezierTo(
      center.dx - width * 0.1,
      center.dy - height * 0.45,
      center.dx - width * 0.15,
      center.dy - height * 0.35,
    );
    frontEarPath.close();
    drawEar(frontEarPath, true);

    // 7. 投入口の手前側のガラスエッジ（奥の暗い線と合わせてリアルなスリットにする）
    final slotCenter = Offset(
      center.dx + width * 0.05,
      center.dy - height * 0.48,
    );
    final slotWidth = width * 0.22;
    final rimPath = Path();
    rimPath.moveTo(slotCenter.dx - slotWidth * 0.48, slotCenter.dy + 2);
    rimPath.quadraticBezierTo(
      slotCenter.dx,
      slotCenter.dy - height * 0.02 + 2,
      slotCenter.dx + slotWidth * 0.48,
      slotCenter.dy + height * 0.015 + 2,
    );

    canvas.drawPath(
      rimPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 8. しっぽ (Tail)
    final tailPath = Path();
    tailPath.moveTo(center.dx + width * 0.48, center.dy + height * 0.1);
    tailPath.quadraticBezierTo(
      center.dx + width * 0.65,
      center.dy + height * 0.05,
      center.dx + width * 0.6,
      center.dy - height * 0.05,
    );
    tailPath.quadraticBezierTo(
      center.dx + width * 0.5,
      center.dy - height * 0.1,
      center.dx + width * 0.55,
      center.dy + height * 0.05,
    );

    // しっぽの影（立体感）
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // しっぽのガラス芯
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------
// 3D Metallic Coin (With physical thickness and glossy face)
// ---------------------------------------------------------
class Coin3D extends StatelessWidget {
  final Map<String, dynamic> category;
  final double size;
  final double angleX;
  final double angleY;
  final double angleZ;

  const Coin3D({
    super.key,
    required this.category,
    required this.size,
    required this.angleX,
    required this.angleY,
    required this.angleZ,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = category['color'] is Color
        ? category['color'] as Color
        : const Color(0xFF64B5F6);
    final IconData icon = category['icon'] is IconData
        ? category['icon'] as IconData
        : Icons.monetization_on;

    // Stack multiple translated layers to create 3D extruded side walls
    List<Widget> layers = [];
    final int depth = 8;
    final double thickness = size * 0.12;

    for (int i = 0; i < depth; i++) {
      bool isFront = (i == depth - 1);
      double t = i / (depth - 1);

      layers.add(
        Transform.translate(
          // Translate along Z axis relative to parent's 3D rotation
          offset: Offset(0, 0),
          child: Transform(
            transform: Matrix4.identity()..translate(0.0, 0.0, t * thickness),
            child: CustomPaint(
              size: Size(size, size),
              painter: _Coin3DPainter(
                baseColor: baseColor,
                icon: icon,
                isFront: isFront,
                angleZ: angleZ,
              ),
            ),
          ),
        ),
      );
    }

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.003) // Perspective distortion
        ..rotateX(angleX)
        ..rotateY(angleY)
        ..rotateZ(angleZ),
      alignment: Alignment.center,
      child: Stack(clipBehavior: Clip.none, children: layers),
    );
  }
}

class _Coin3DPainter extends CustomPainter {
  final Color baseColor;
  final IconData icon;
  final bool isFront;
  final double angleZ;

  _Coin3DPainter({
    required this.baseColor,
    required this.icon,
    required this.isFront,
    required this.angleZ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (!isFront) {
      // Side of the coin (smooth dark pastel, no ribs)
      final hsl = HSLColor.fromColor(baseColor);
      final edgeColor = hsl
          .withLightness(math.max(0.0, hsl.lightness - 0.15))
          .toColor();
      final paint = Paint()..color = edgeColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    // Front Face (Soft matte gradient)
    final faceGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(baseColor)
            .withLightness(
              math.min(1.0, HSLColor.fromColor(baseColor).lightness + 0.15),
            )
            .toColor(),
        baseColor,
        HSLColor.fromColor(baseColor)
            .withLightness(
              math.max(0.0, HSLColor.fromColor(baseColor).lightness - 0.1),
            )
            .toColor(),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()..shader = faceGradient;
    canvas.drawCircle(center, radius, paint);

    // Soft rim (Inner glow and outer shadow)
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, rimPaint);

    final innerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 4, innerShadow);

    // Embossed Icon
    final iconSize = radius * 0.85;

    // Soft shadow for deboss
    final textPainterShadow = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.black.withValues(alpha: 0.15),
        ),
      ),
    );
    textPainterShadow.layout();
    textPainterShadow.paint(
      canvas,
      center -
          Offset(
            textPainterShadow.width / 2 - 1,
            textPainterShadow.height / 2 - 1,
          ),
    );

    // Base color icon (highlighted edge)
    final textPainterFront = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: HSLColor.fromColor(baseColor)
              .withLightness(
                math.min(1.0, HSLColor.fromColor(baseColor).lightness + 0.15),
              )
              .toColor(),
        ),
      ),
    );
    textPainterFront.layout();
    textPainterFront.paint(
      canvas,
      center -
          Offset(
            textPainterFront.width / 2 + 1,
            textPainterFront.height / 2 + 1,
          ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------
// Soft Volumetric Glass Piggy Bank Painters
// ---------------------------------------------------------
class PiggyBankBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Soft, diffused ambient ground shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF6B8E23).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height + 5),
        width: radius * 1.5,
        height: 40,
      ),
      shadowPaint,
    );

    // Deep volumetric inner glass shadow (replaces thick strokes)
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.25),
        ],
        stops: const [0.75, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PiggyBankFrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Tail (Soft Volumetric)
    _drawTail(canvas, Offset(size.width * 0.92, size.height * 0.45));

    // Draw Back Legs
    _drawLeg(canvas, Offset(size.width * 0.25, size.height * 0.95), 35);
    _drawLeg(canvas, Offset(size.width * 0.80, size.height * 0.88), 30);

    // Draw Back Ears
    _drawEar(canvas, Offset(size.width * 0.20, size.height * 0.18), -0.5);
    _drawEar(canvas, Offset(size.width * 0.80, size.height * 0.28), 0.5);

    // Front legs
    _drawLeg(canvas, Offset(size.width * 0.45, size.height * 0.98), 40);
    _drawLeg(canvas, Offset(size.width * 0.65, size.height * 0.95), 38);

    // Main Body Glass Caustics (Soft white glow around edge, NO strokes)
    final whiteRim = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.95),
        ],
        stops: const [0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, whiteRim);

    // Soft Window Reflection (Top Left)
    final windowHighlight = Path();
    windowHighlight.moveTo(center.dx - radius * 0.65, center.dy - radius * 0.2);
    windowHighlight.quadraticBezierTo(
      center.dx - radius * 0.35,
      center.dy - radius * 0.85,
      center.dx + radius * 0.2,
      center.dy - radius * 0.8,
    );
    windowHighlight.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.6);
    windowHighlight.quadraticBezierTo(
      center.dx - radius * 0.1,
      center.dy - radius * 0.65,
      center.dx - radius * 0.45,
      center.dy - radius * 0.1,
    );
    windowHighlight.close();

    final winPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(windowHighlight.getBounds())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(windowHighlight, winPaint);

    // Front Ear
    _drawEar(canvas, Offset(size.width * 0.28, size.height * 0.12), -0.2);

    // Snout
    _drawSnout(canvas, size);

    // Eyes (Thick, rounded soft arcs)
    final eyePaint = Paint()
      ..color = const Color(0xFF2B1F1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    // left eye
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.42),
        width: 18,
        height: 16,
      ),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      eyePaint,
    );
    // right eye
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.45),
        width: 18,
        height: 16,
      ),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      eyePaint,
    );
  }

  void _drawSnout(Canvas canvas, Size size) {
    final snoutCenter = Offset(size.width * 0.28, size.height * 0.55);
    final snoutRadius = size.width * 0.18;

    // Soft outer shadow (drop shadow inside the body)
    final snoutShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      snoutCenter + const Offset(-4, 8),
      snoutRadius * 0.9,
      snoutShadow,
    );

    // Soft glass gradient fill (no hard strokes)
    final snoutPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.95),
        ],
        stops: const [0.3, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: snoutCenter, radius: snoutRadius));
    canvas.drawCircle(snoutCenter, snoutRadius, snoutPaint);

    // Internal depth rim (soft shadow inside the snout)
    final snoutInner = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
            stops: const [0.7, 1.0],
          ).createShader(
            Rect.fromCircle(center: snoutCenter, radius: snoutRadius - 2),
          );
    canvas.drawCircle(snoutCenter, snoutRadius - 2, snoutInner);

    // Nose holes (soft indented shapes)
    final holePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final holeHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Left hole
    final leftHole = Rect.fromCenter(
      center: snoutCenter + const Offset(-12, 2),
      width: 10,
      height: 20,
    );
    canvas.drawOval(leftHole.translate(1, 1), holeHighlight);
    canvas.drawOval(leftHole, holePaint);

    // Right hole
    final rightHole = Rect.fromCenter(
      center: snoutCenter + const Offset(12, -2),
      width: 10,
      height: 20,
    );
    canvas.drawOval(rightHole.translate(1, 1), holeHighlight);
    canvas.drawOval(rightHole, holePaint);
  }

  void _drawLeg(Canvas canvas, Offset pos, double size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: size, height: size * 1.4),
      const Radius.circular(20),
    );

    // Internal refraction shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rect.shift(const Offset(0, 6)), shadow);

    // Soft volumetric glass fill
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.9),
        ],
        stops: const [0.3, 0.8, 1.0],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, paint);
  }

  void _drawEar(Canvas canvas, Offset pos, double rotation) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);

    final path = Path();
    path.moveTo(-20, 15);
    path.cubicTo(-10, -40, -5, -60, 15, -50);
    path.cubicTo(35, -35, 25, 0, 25, 20);

    // Volumetric fill (no strokes)
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, paint);

    // Edge highlight (soft)
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, highlight);

    canvas.restore();
  }

  void _drawTail(Canvas canvas, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(25, -25, 45, 15, 25, 30);
    path.cubicTo(5, 40, -10, 20, 5, 10);

    // Soft volumetric pipe
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PiggyBankSlotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final slotCenter = Offset(size.width * 0.55, size.height * 0.02);

    // The deep hole
    final slotDark = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final slotRect = Rect.fromCenter(
      center: slotCenter + const Offset(0, -2),
      width: 55,
      height: 14,
    );
    canvas.drawArc(slotRect, 0, math.pi, false, slotDark);

    // Thick shiny white lip
    final slotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawArc(slotRect, 0, math.pi, false, slotPaint);

    // Beveled highlight below
    final hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCenter(
        center: slotCenter + const Offset(0, 2),
        width: 60,
        height: 16,
      ),
      0,
      math.pi,
      false,
      hlPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
