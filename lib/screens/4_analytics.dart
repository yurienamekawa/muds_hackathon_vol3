import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'あなたのポジティブ分析',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: '🌿 記録の継続グラフ',
                child: _StreakGraph(),
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: '感情のバランス',
                child: _EmotionBalanceChart(),
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: 'AIからのメッセージ',
                child: _AiMessageCard(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F3F3F),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StreakGraph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labels = ['月', '火', '水', '木', '金', '土', '日'];
    final months = ['5月', '7月', '8月', '9月'];
    
    // 各曜日のデータ（複数週分）
    final graphData = [
      [1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1],
      [0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0],
      [1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0],
      [0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0],
      [1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0],
      [0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0],
      [1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: SizedBox(
            height: 24,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(graphData[0].length, (colIndex) {
                  final weekIndex = colIndex ~/ 7;
                  final dayInWeek = colIndex % 7;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 20,
                      child: (dayInWeek == 0 && weekIndex < months.length)
                          ? Text(
                              months[weekIndex],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5A5A5A),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: List.generate(graphData.length, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        labels[rowIndex],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A7A7A),
                        ),
                      ),
                    ),
                    ...List.generate(graphData[rowIndex].length, (colIndex) {
                      final isActive = graphData[rowIndex][colIndex] == 1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF86C382) : const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendDot(color: Color(0xFF86C382), label: '記録した日'),
            SizedBox(width: 18),
            _LegendDot(color: Color(0xFFEAEAEA), label: '未記録'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7A7A7A),
          ),
        ),
      ],
    );
  }
}

class _EmotionBalanceChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBF5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            _RadarGrid(),
            _RadarShape(),
            _RadarLabels(),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 2,
              child: Center(
                child: Text(
                  '感情のバランス',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _RadarPainter(),
    );
  }
}

class _RadarShape extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _RadarShapePainter(),
    );
  }
}

class _RadarLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _RadarLabelPainter(),
    );
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDEEFD9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;
    for (int i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      canvas.drawCircle(center, r, paint);
    }

    final axisPaint = Paint()
      ..color = const Color(0xFFB8D8B3)
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final angle = (2 * 3.14159265 / 5) * i - 3.14159265 / 2;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, axisPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RadarShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;
    final points = [
      0.85,
      0.7,
      0.9,
      0.75,
      0.8,
    ];
    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final angle = (2 * 3.14159265 / 5) * i - 3.14159265 / 2;
      final r = radius * points[i];
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFFFFD6DC).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFFF7A8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RadarLabelPainter extends CustomPainter {
  final labels = ['つながり度', 'ワクワク度', '感謝度', '達成感度', 'リラックス度'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final labelRadius = radius * 1.15;

    for (int i = 0; i < labels.length; i++) {
      final angle = (2 * 3.14159265 / 5) * i - 3.14159265 / 2;
      final labelPos = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final textSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Color(0xFF7A7A7A),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AiMessageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'あなたは周りの人とのつながりを大切にしているね！その優しさが毎日をもっと素敵にしてるよ🌸\n明日も小さな幸せを見つけていこう！',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF5A5A5A),
          height: 1.6,
        ),
      ),
    );
  }
}
