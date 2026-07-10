import 'package:flutter/material.dart';
import 'dart:math' as math;
import '1_home.dart';

class VentingScreen extends StatefulWidget {
  final VoidCallback onVented;
  const VentingScreen({super.key, required this.onVented});

  @override
  State<VentingScreen> createState() => _VentingScreenState();
}

enum VentingState { input, tapping, shattering }

class _VentingScreenState extends State<VentingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  VentingState _state = VentingState.input;

  int _tapCount = 0;
  final int _maxTaps = 7;

  // Intro coin animation
  late AnimationController _introController;
  late Animation<double> _coinScaleIn;

  // Shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAngle;

  // Shatter animation
  late AnimationController _shatterController;
  late Animation<double> _shatterScale;
  late Animation<double> _shatterOpacity;

  @override
  void initState() {
    super.initState();

    // Intro
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _coinScaleIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.elasticOut),
    );

    // Shake
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shakeAngle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    // Shatter
    _shatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shatterScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _shatterController, curve: Curves.easeOutExpo),
    );
    _shatterOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _shatterController, curve: Curves.easeInQuint),
    );

    _shatterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onVented();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _introController.dispose();
    _shakeController.dispose();
    _shatterController.dispose();
    super.dispose();
  }

  void _onStartTapping() {
    if (_controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _state = VentingState.tapping;
    });
    _introController.forward(from: 0.0);
  }

  void _onCoinTapped() {
    if (_state != VentingState.tapping) return;

    setState(() {
      _tapCount++;
    });

    _shakeController.forward(from: 0.0);

    if (_tapCount >= _maxTaps) {
      setState(() {
        _state = VentingState.shattering;
      });
      _shatterController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- INPUT MODE ---
            if (_state == VentingState.input)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'どうしたんだい？',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'serif',
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'モヤモヤ、イライラ、悲しみ...\nストレス発散しない？',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 18,
                            height: 1.6,
                          ),
                          border: InputBorder.none,
                        ),
                        cursorColor: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E24AA), Color(0xFF311B92)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF311B92,
                            ).withValues(alpha: 0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onStartTapping,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'コイン生成',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            // --- TAPPING / SHATTERING MODE ---
            if (_state == VentingState.tapping ||
                _state == VentingState.shattering)
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_state == VentingState.tapping)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Text(
                          '連打して嫌なことを砕こう！',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                    GestureDetector(
                      onTap: _onCoinTapped,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _introController,
                          _shakeController,
                          _shatterController,
                        ]),
                        builder: (context, child) {
                          double scale = _coinScaleIn.value;
                          double rotation = _shakeAngle.value;
                          double opacity = 1.0;

                          double crackProgress = _tapCount / _maxTaps;
                          double shatterProgress = 0.0;

                          if (_state == VentingState.shattering) {
                            scale = _shatterScale.value;
                            opacity = _shatterOpacity.value;
                            shatterProgress = _shatterController.value;
                          }

                          if (crackProgress > 1.0) crackProgress = 1.0;

                          return Opacity(
                            opacity: opacity,
                            child: Transform.rotate(
                              angle: rotation,
                              child: Transform.scale(
                                scale: scale,
                                child: CustomPaint(
                                  size: const Size(200, 200),
                                  painter: ShatterCoinPainter(
                                    crackProgress: crackProgress,
                                    shatterProgress: shatterProgress,
                                  ),
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
          ],
        ),
      ),
    );
  }
}

class ShatterCoinPainter extends CustomPainter {
  final double crackProgress;
  final double shatterProgress;

  ShatterCoinPainter({
    required this.crackProgress,
    required this.shatterProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Define crack center (slightly off-center for realism)
    final crackCenter = Offset(
      center.dx + radius * 0.1,
      center.dy - radius * 0.15,
    );

    // Define 6 shards
    final angles = [
      0.0,
      math.pi / 3,
      math.pi * 0.8,
      math.pi * 1.2,
      math.pi * 1.6,
      math.pi * 2.0,
    ];

    for (int i = 0; i < angles.length - 1; i++) {
      final startAngle = angles[i];
      final sweepAngle = angles[i + 1] - angles[i];

      final path = Path();
      path.moveTo(crackCenter.dx, crackCenter.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();

      // Calculate the direction this shard should move
      final midAngle = startAngle + sweepAngle / 2;
      final moveDir = Offset(math.cos(midAngle), math.sin(midAngle));

      // crackProgress pushes them slightly apart to simulate cracks
      // shatterProgress explodes them outwards
      final crackOffset = moveDir * (crackProgress * 15.0);
      final explodeOffset = moveDir * (shatterProgress * 200.0);
      final totalOffset = crackOffset + explodeOffset;

      // Individual rotation for each shard during shatter
      final shardRotation = shatterProgress * (i % 2 == 0 ? 1 : -1) * math.pi;

      canvas.save();

      // Move to the shard's visual center to apply rotation, then move back
      final arcMidPoint = Offset(
        center.dx + radius * 0.5 * math.cos(midAngle),
        center.dy + radius * 0.5 * math.sin(midAngle),
      );

      canvas.translate(
        arcMidPoint.dx + totalOffset.dx,
        arcMidPoint.dy + totalOffset.dy,
      );
      canvas.rotate(shardRotation);
      canvas.translate(-arcMidPoint.dx, -arcMidPoint.dy);

      // --- Draw the shard ---
      canvas.clipPath(path);

      // Base color
      final paintBase = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF424242), Color(0xFF212121), Color(0xFF000000)],
          stops: [0.5, 0.9, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, paintBase);

      // Inner rim
      final paintRim = Paint()
        ..color = const Color(0xFF616161)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(center, radius * 0.85, paintRim);

      // Lightning icon
      final boltPath = Path();
      boltPath.moveTo(center.dx + 5, center.dy - 30);
      boltPath.lineTo(center.dx - 20, center.dy + 5);
      boltPath.lineTo(center.dx - 5, center.dy + 5);
      boltPath.lineTo(center.dx - 10, center.dy + 35);
      boltPath.lineTo(center.dx + 25, center.dy - 5);
      boltPath.lineTo(center.dx + 5, center.dy - 5);
      boltPath.close();

      final boltPaint = Paint()..color = const Color(0xFF9E9E9E);
      canvas.drawPath(boltPath, boltPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ShatterCoinPainter oldDelegate) {
    return oldDelegate.crackProgress != crackProgress ||
        oldDelegate.shatterProgress != shatterProgress;
  }
}
