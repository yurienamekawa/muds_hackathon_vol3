// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:sensors_plus/sensors_plus.dart';
import '5_collection.dart';
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
                      title: const Text('退会しますか?'),
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
                  child: Center(
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
                        theme: _currentTheme,
                      ),
                    ),
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
                      theme: theme,
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
  void paint(Canvas canvas, Size size) {
    Color skyTop;
    Color skyBottom;
    Color leftHillColor;
    Color rightHillColor;
    Color groundColor;
    Color treeTrunkColor = const Color(0xFF5D4037);
    Color treeColor;
    Color treeShadowColor;
    Color groundSpotColor;
    bool showMoonAndStars = false;

    switch (theme) {
      case TimeOfDayTheme.morning:
        skyTop = const Color(0xFFF7D1D6);
        skyBottom = const Color(0xFFFBF1CA);
        leftHillColor = const Color(0xFFC5E1A5);
        rightHillColor = const Color(0xFFAED581);
        groundColor = const Color(0xFF81C784);
        treeColor = const Color(0xFF9CCC65);
        treeShadowColor = const Color(0xFF7CB342).withValues(alpha: 0.5);
        groundSpotColor = Colors.white.withValues(alpha: 0.6);
        break;
      case TimeOfDayTheme.day:
        skyTop = const Color(0xFF90CAF9);
        skyBottom = const Color(0xFFFFF59D);
        leftHillColor = const Color(0xFF689F38);
        rightHillColor = const Color(0xFF558B2F);
        groundColor = const Color(0xFF33691E);
        treeColor = const Color(0xFF7CB342);
        treeShadowColor = const Color(0xFF33691E).withValues(alpha: 0.5);
        groundSpotColor = const Color(0xFF9CCC65).withValues(alpha: 0.5);
        break;
      case TimeOfDayTheme.evening:
        skyTop = const Color(0xFFE53935);
        skyBottom = const Color(0xFFFFB300);
        leftHillColor = const Color(0xFF4E342E);
        rightHillColor = const Color(0xFF3E2723);
        groundColor = const Color(0xFF263238);
        treeColor = const Color(0xFF5D4037);
        treeShadowColor = Colors.black.withValues(alpha: 0.4);
        groundSpotColor = const Color(0xFFFFB300).withValues(alpha: 0.3);
        break;
      case TimeOfDayTheme.night:
        skyTop = const Color(0xFF283593);
        skyBottom = const Color(0xFF3949AB);
        leftHillColor = const Color(0xFF1A237E);
        rightHillColor = const Color(0xFF151B54);
        groundColor = const Color(0xFF0D47A1);
        treeColor = const Color(0xFF283593);
        treeShadowColor = Colors.black.withValues(alpha: 0.5);
        groundSpotColor = Colors.white.withValues(alpha: 0.2);
        showMoonAndStars = true;
        break;
    }

    // 1. Sky
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBottom],
          stops: const [0.0, 0.7],
        ).createShader(skyRect),
    );

    // 2. Stars and Moon (if night)
    if (showMoonAndStars) {
      // Moon
      final moonOuter = Path()
        ..addOval(Rect.fromCircle(center: Offset(size.width * 0.85, size.height * 0.15), radius: size.width * 0.07));
      final moonInner = Path()
        ..addOval(Rect.fromCircle(center: Offset(size.width * 0.82, size.height * 0.12), radius: size.width * 0.065));
      final moonPath = Path.combine(PathOperation.difference, moonOuter, moonInner);
      
      canvas.drawPath(moonPath, Paint()..color = const Color(0xFFFFF59D));

      // Stars
      void drawStar(Offset center) {
        final path = Path();
        path.moveTo(center.dx, center.dy - 6);
        path.quadraticBezierTo(center.dx, center.dy, center.dx + 6, center.dy);
        path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + 6);
        path.quadraticBezierTo(center.dx, center.dy, center.dx - 6, center.dy);
        path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - 6);
        canvas.drawPath(path, Paint()..color = const Color(0xFFFFF9C4));
      }
      drawStar(Offset(size.width * 0.1, size.height * 0.2));
      drawStar(Offset(size.width * 0.9, size.height * 0.4));
      drawStar(Offset(size.width * 0.2, size.height * 0.6));
      drawStar(Offset(size.width * 0.8, size.height * 0.8));
    }

    // Fireflies / Sparkles for Day/Morning/Evening
    if (!showMoonAndStars) {
      void drawSparkle(Offset center, Color c) {
        final path = Path();
        path.moveTo(center.dx, center.dy - 4);
        path.quadraticBezierTo(center.dx, center.dy, center.dx + 4, center.dy);
        path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + 4);
        path.quadraticBezierTo(center.dx, center.dy, center.dx - 4, center.dy);
        path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - 4);
        canvas.drawPath(path, Paint()..color = c);
      }
      final sColor = theme == TimeOfDayTheme.evening ? const Color(0xFFFFCC80) : Colors.white;
      drawSparkle(Offset(size.width * 0.15, size.height * 0.3), sColor);
      drawSparkle(Offset(size.width * 0.85, size.height * 0.25), sColor);
      drawSparkle(Offset(size.width * 0.75, size.height * 0.5), sColor);
    }

    // 3. Background Hills
    // Right hill (behind left hill)
    final rightHillPath = Path();
    rightHillPath.moveTo(size.width, size.height * 0.25);
    rightHillPath.quadraticBezierTo(size.width * 0.5, size.height * 0.25, 0, size.height * 0.45);
    rightHillPath.lineTo(0, size.height);
    rightHillPath.lineTo(size.width, size.height);
    canvas.drawPath(rightHillPath, Paint()..color = rightHillColor);

    // Left hill
    final leftHillPath = Path();
    leftHillPath.moveTo(0, size.height * 0.25);
    leftHillPath.quadraticBezierTo(size.width * 0.6, size.height * 0.2, size.width, size.height * 0.45);
    leftHillPath.lineTo(size.width, size.height);
    leftHillPath.lineTo(0, size.height);
    canvas.drawPath(leftHillPath, Paint()..color = leftHillColor);

    // 4. Ground (Foreground)
    final groundPath = Path();
    groundPath.moveTo(0, size.height * 0.4);
    groundPath.quadraticBezierTo(size.width * 0.5, size.height * 0.35, size.width, size.height * 0.4);
    groundPath.lineTo(size.width, size.height);
    groundPath.lineTo(0, size.height);
    canvas.drawPath(groundPath, Paint()..color = groundColor);

    // Shadow on ground for depth (overall background gradient)
    final shadowPath = Path();
    shadowPath.moveTo(0, size.height * 0.45);
    shadowPath.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.45);
    shadowPath.lineTo(size.width, size.height * 0.6);
    shadowPath.quadraticBezierTo(size.width * 0.5, size.height * 0.55, 0, size.height * 0.6);
    canvas.drawPath(shadowPath, Paint()..color = Colors.black.withValues(alpha: 0.1));

    // Shadow directly under the piggy bank to anchor it and fill the bottom space
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.8),
        width: size.width * 0.6,
        height: size.height * 0.12,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Ground spots (small floating petals or grass spots) - spread them out more
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.1, size.height * 0.48), width: 6, height: 12), Paint()..color = groundSpotColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.9, size.height * 0.52), width: 6, height: 12), Paint()..color = groundSpotColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.25, size.height * 0.68), width: 6, height: 12), Paint()..color = groundSpotColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.75, size.height * 0.62), width: 6, height: 12), Paint()..color = groundSpotColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.15, size.height * 0.82), width: 7, height: 14), Paint()..color = groundSpotColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.85, size.height * 0.78), width: 7, height: 14), Paint()..color = groundSpotColor);

    // 5. Trees
    void drawTree(Offset pos, double scale) {
      canvas.drawRect(
        Rect.fromCenter(center: pos + Offset(0, 15 * scale), width: 8 * scale, height: 25 * scale),
        Paint()..color = treeTrunkColor,
      );
      // Main circle
      canvas.drawCircle(pos, 22 * scale, Paint()..color = treeColor);
      // Inner shadow
      canvas.drawCircle(pos + Offset(0, 4 * scale), 16 * scale, Paint()..color = treeShadowColor);
    }

    drawTree(Offset(size.width * 0.08, size.height * 0.28), 1.0);
    drawTree(Offset(size.width * 0.18, size.height * 0.32), 0.7);
    drawTree(Offset(size.width * 0.82, size.height * 0.30), 0.7);
    drawTree(Offset(size.width * 0.92, size.height * 0.25), 1.1);

    // 6. Flowers
    // Daisy (Left)
    final daisyPos = Offset(size.width * 0.05, size.height * 0.45);
    final petalPaint = Paint()..color = const Color(0xFFFFD54F);
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi) / 5;
      canvas.drawCircle(daisyPos + Offset(math.cos(angle) * 7, math.sin(angle) * 7), 5, petalPaint);
    }
    canvas.drawCircle(daisyPos, 5, Paint()..color = const Color(0xFFFFF9C4));

    // Tulip (Mid-Left)
    final tulipPos = Offset(size.width * 0.12, size.height * 0.52);
    final tulipPath = Path();
    tulipPath.moveTo(tulipPos.dx, tulipPos.dy + 8);
    tulipPath.quadraticBezierTo(tulipPos.dx - 10, tulipPos.dy + 4, tulipPos.dx - 8, tulipPos.dy - 6);
    tulipPath.quadraticBezierTo(tulipPos.dx - 4, tulipPos.dy, tulipPos.dx, tulipPos.dy - 8);
    tulipPath.quadraticBezierTo(tulipPos.dx + 4, tulipPos.dy, tulipPos.dx + 8, tulipPos.dy - 6);
    tulipPath.quadraticBezierTo(tulipPos.dx + 10, tulipPos.dy + 4, tulipPos.dx, tulipPos.dy + 8);
    canvas.drawPath(tulipPath, Paint()..color = const Color(0xFFAB47BC)); // Purple tulip
    // Tulip stem
    canvas.drawLine(tulipPos + const Offset(0, 8), tulipPos + const Offset(0, 20), Paint()..color = const Color(0xFF81C784)..strokeWidth = 3);

    // Pink Flower (Right)
    final pinkPos = Offset(size.width * 0.96, size.height * 0.43);
    final pinkPetal = Paint()..color = const Color(0xFFF06292);
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi) / 5;
      canvas.drawCircle(pinkPos + Offset(math.cos(angle) * 6, math.sin(angle) * 6), 4.5, pinkPetal);
    }
    canvas.drawCircle(pinkPos, 4, Paint()..color = const Color(0xFFFFCA28));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassPiggyBank extends StatefulWidget {
  final int currentCoins;
  final Widget? fallingCoin;
  final List<Map<String, dynamic>> coinRecords;
  final TimeOfDayTheme? theme;
  const GlassPiggyBank({
    super.key,
    required this.currentCoins,
    this.fallingCoin,
    this.coinRecords = const [],
    this.theme,
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
    final double bellyWidth = areaSize * 0.85;
    final double bellyHeight = areaSize * 0.85;
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


                  // 2. コイン層（画像のお腹の形に合わせてクリップ）
                  Positioned.fill(
                    child: ClipPath(
                      clipper: PiggyBankBellyClipper(
                        center: Offset(bellyCenterX, bellyCenterY + areaSize * 0.05),
                        width: bellyWidth * 0.85,
                        height: bellyHeight * 0.8,
                      ),
                      child: Stack(clipBehavior: Clip.none, children: coins),
                    ),
                  ),

                  // 落下中のコイン
                  if (widget.fallingCoin != null) widget.fallingCoin!,

                  // 3. 前面のガラス層（画像を透過して配置し、テーマ色で色付け）
                  Positioned.fill(
                    child: Builder(
                      builder: (context) {
                        Color? tintColor;
                        if (widget.theme == TimeOfDayTheme.morning) tintColor = const Color(0xFFF7D1D6).withValues(alpha: 0.3);
                        if (widget.theme == TimeOfDayTheme.day) tintColor = const Color(0xFFFFF59D).withValues(alpha: 0.3);
                        if (widget.theme == TimeOfDayTheme.evening) tintColor = const Color(0xFFFFB300).withValues(alpha: 0.3);
                        if (widget.theme == TimeOfDayTheme.night) tintColor = const Color(0xFF3949AB).withValues(alpha: 0.3);

                        return Opacity(
                          opacity: 0.85, // 中のコインがしっかり見えるように透過
                          child: Image.asset(
                            'assets/pig_pig2.png',
                            fit: BoxFit.contain,
                            color: tintColor,
                            colorBlendMode: tintColor != null ? BlendMode.srcATop : null,
                          ),
                        );
                      }
                    ),
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

// Removed unused GlassPiggyBankBackPainter and GlassPiggyBankFrontPainter

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
    // 白い枠は削除しました

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
