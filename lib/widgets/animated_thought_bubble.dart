import 'package:flutter/material.dart';

class AnimatedThoughtBubble extends StatefulWidget {
  final VoidCallback onTap;
  const AnimatedThoughtBubble({super.key, required this.onTap});

  @override
  State<AnimatedThoughtBubble> createState() => _AnimatedThoughtBubbleState();
}

class _AnimatedThoughtBubbleState extends State<AnimatedThoughtBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: GestureDetector(
            onTap: widget.onTap,
            child: SizedBox(
              width: 80,
              height: 70,
              child: CustomPaint(
                painter: ThoughtBubblePainter(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ThoughtBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path = Path();
    
    // Main cloud body
    path.addOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.4), width: size.width * 0.65, height: size.height * 0.5));
    
    // Bumps around the main body to make it fluffy
    path.addOval(Rect.fromCenter(center: Offset(size.width * 0.3, size.height * 0.3), width: size.width * 0.4, height: size.width * 0.4));
    path.addOval(Rect.fromCenter(center: Offset(size.width * 0.7, size.height * 0.3), width: size.width * 0.45, height: size.width * 0.45));
    path.addOval(Rect.fromCenter(center: Offset(size.width * 0.25, size.height * 0.5), width: size.width * 0.35, height: size.width * 0.35));
    path.addOval(Rect.fromCenter(center: Offset(size.width * 0.75, size.height * 0.5), width: size.width * 0.35, height: size.width * 0.35));
    path.addOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.6), width: size.width * 0.5, height: size.width * 0.35));

    // Tail dots pointing towards the pig (bottom right)
    path.addOval(Rect.fromCenter(center: Offset(size.width * 0.7, size.height * 0.8), width: size.width * 0.15, height: size.width * 0.15));
    path.addOval(Rect.fromCenter(center: Offset(size.width * 0.8, size.height * 0.95), width: size.width * 0.08, height: size.width * 0.08));

    // Draw shadow then fill
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
