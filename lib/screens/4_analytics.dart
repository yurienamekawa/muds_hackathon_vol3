import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _adviceMessage = 'これまでの記録をもとに、あなたに合った幸せのヒントをお届けします。';
  late Map<String, double> _averageScores;
  late Map<DateTime, int> _dailyCounts;
  late String _topCategory;

  static const Map<String, String> _scoreLabels = {
    'score_tsunagari': 'つながり度',
    'score_wakuwaku': 'ワクワク度',
    'score_kansha': '感謝度',
    'score_tassei': '達成度',
    'score_iyashi': 'リラックス度',
  };

  @override
  void initState() {
    super.initState();
    _averageScores = {
      'score_tsunagari': 3.0,
      'score_wakuwaku': 3.0,
      'score_kansha': 3.0,
      'score_tassei': 3.0,
      'score_iyashi': 3.0,
    };
    _dailyCounts = {};
    _topCategory = '日常・景色';
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = await client
          .from('happy_coins')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final records =
          (data as List<dynamic>?)?.cast<Map<String, dynamic>>().toList() ?? [];
      _dailyCounts = _buildDailyCounts(records, 365);
      _averageScores = _buildAverageScores(records);
      _topCategory = _buildTopCategory(records);
      _adviceMessage = _buildAdviceMessage(records, _topCategory);
    } catch (e) {
      debugPrint('Analytics load error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime? _parseCreatedAt(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<DateTime, int> _buildDailyCounts(
    List<Map<String, dynamic>> records,
    int days,
  ) {
    final today = DateTime.now();
    final grid = <DateTime, int>{};
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      grid[day] = 0;
    }
    for (final record in records) {
      final created = _parseCreatedAt(record['created_at']);
      if (created == null) continue;
      final dayKey = DateTime(created.year, created.month, created.day);
      if (grid.containsKey(dayKey)) {
        grid[dayKey] = grid[dayKey]! + 1;
      }
    }
    return grid;
  }

  Map<String, double> _buildAverageScores(List<Map<String, dynamic>> records) {
    final sums = {
      'score_tsunagari': 0.0,
      'score_wakuwaku': 0.0,
      'score_kansha': 0.0,
      'score_tassei': 0.0,
      'score_iyashi': 0.0,
    };
    final counts = {
      'score_tsunagari': 0,
      'score_wakuwaku': 0,
      'score_kansha': 0,
      'score_tassei': 0,
      'score_iyashi': 0,
    };
    for (final record in records) {
      for (final key in sums.keys) {
        final value = record[key];
        if (value is num) {
          sums[key] = sums[key]! + value.toDouble();
          counts[key] = counts[key]! + 1;
        } else if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            sums[key] = sums[key]! + parsed;
            counts[key] = counts[key]! + 1;
          }
        }
      }
    }
    return sums.map((key, sum) {
      final count = counts[key]!;
      return MapEntry(key, count > 0 ? sum / count : 3.0);
    });
  }

  String _buildTopCategory(List<Map<String, dynamic>> records) {
    final counter = <String, int>{};
    for (final record in records) {
      final category = (record['category'] as String?)?.trim();
      if (category == null || category.isEmpty) continue;
      counter[category] = (counter[category] ?? 0) + 1;
    }
    if (counter.isEmpty) return '日常・景色';
    return counter.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String _buildAdviceMessage(
    List<Map<String, dynamic>> records,
    String topCategory,
  ) {
    if (records.isEmpty) {
      return 'まだ記録がありません。今日の幸せをひとつ書いてみましょう。';
    }

    final advice = {
      '家族': 'これまでのメモには家族とのあたたかい時間が多く書かれています。次は一緒に料理や散歩をして、もっと穏やかな時間を増やしてみましょう。',
      '友達・対人': '友達や大切な人との交流で幸せを感じやすいようです。近いうちに「ありがとう」や「元気？」の一言を送ってみてください。',
      '趣味・推し': '好きなことに触れる時間があなたの元気のもとになっています。少しだけ趣味や推し活動に時間を使ってみると、心が軽くなります。',
      '食事': '美味しい食事やごはんの時間から幸せを感じています。次はゆっくり味わえる食事を用意して、自分へのご褒美にしてみましょう。',
      '仕事・学校': '日々の頑張りや達成感が大きな支えになっています。小さなひとつを終えた後に、自分をほめる時間を作ってみてください。',
      '運動・健康': '体を動かしたときに気分がすっきりしやすいようです。短い散歩や軽い体操を習慣にして、もう少し自分の体と向き合ってみましょう。',
      'お出かけ': '新しい風景や外出で心がリフレッシュしています。近場のお出かけでもいいので、気になる場所に行ってみるといいでしょう。',
      '自己成長': '挑戦や学びを通じて幸せを感じる傾向があります。今日の経験を振り返り、次にやってみたいことを小さく決めてみてください。',
      '日常・景色':
          '毎日のちいさな景色や日常に幸せを見つけています。今日は見慣れた風景の中で、いつもと違う「いいな」と感じる瞬間を探してみましょう。',
    };

    final message =
        advice[topCategory] ??
        'これまでの記録から、あなたが感じる幸せのヒントが見えてきました。日々の中で心地よいことを大切にしてみましょう。';
    return 'これまでのメモをもとに、あなたがどんなときに幸せを感じやすいかを分析しました。$message';
  }

  String _buildRadarSummary() {
    if (_averageScores.isEmpty) {
      return 'まだ分析できる記録がありません。';
    }
    final sorted = _averageScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = sorted.first;
    final label = _scoreLabels[best.key] ?? best.key;
    final rounded = best.value.toStringAsFixed(1);
    return 'あなたの一番高い項目は「$label」で、平均は $rounded です。';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('分析'),
        centerTitle: false,
        foregroundColor: const Color(0xFF3B3B3B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: const Color(0xFF6B8E23),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildContributionCard(),
                    const SizedBox(height: 16),
                    _buildRadarCard(),
                    const SizedBox(height: 16),
                    _buildAdviceCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日の記録✏️',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '本日保存した数: $_todayCount 件',
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 12),
            Text(
              'これまでの記録: $_totalEntries 件',
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8EE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _insightMessage,
                style: const TextStyle(color: Color(0xFF4A4A4A), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '記録の継続グラフ📈',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '今日の記録数に応じて草🌱が育ちます。',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 16),
            ContributionGrid(dailyCounts: _dailyCounts),
            const SizedBox(height: 16),
            Row(
              children: const [
                _ContributionLegendDot(color: Color(0xFFF1F1F1), label: '未記録'),
                SizedBox(width: 12),
                _ContributionLegendDot(color: Color(0xFFB6D7A8), label: '1件'),
                SizedBox(width: 12),
                _ContributionLegendDot(color: Color(0xFF6B8E23), label: '2件以上'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '感情のバランス📊',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'これまでの記録をもとに、あなたの幸せの傾向を可視化します。',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 320,
              child: RadarChart(values: _averageScores, labels: _scoreLabels),
            ),
            const SizedBox(height: 12),
            Text(
              _buildRadarSummary(),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A4A),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'AIからのメッセージ💌',
          children: [
            const Text(
              'AIからのメッセージ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _adviceMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A4A),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContributionGrid extends StatelessWidget {
  final Map<DateTime, int> dailyCounts;
  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  const ContributionGrid({super.key, required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    final sortedDays = dailyCounts.keys.toList()..sort();
    if (sortedDays.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstDate = sortedDays.first;
    final lastDate = sortedDays.last;
    final firstColumnStart = firstDate.subtract(
      Duration(days: firstDate.weekday - 1),
    );
    final totalColumns = lastDate.difference(firstColumnStart).inDays ~/ 7 + 1;

    final grid = List.generate(
      7,
      (_) => List<DateTime?>.filled(totalColumns, null),
    );
    for (final date in sortedDays) {
      final diffDays = date.difference(firstColumnStart).inDays;
      final column = diffDays ~/ 7;
      final row = date.weekday - 1;
      if (column >= 0 && column < totalColumns) {
        grid[row][column] = date;
      }
    }

    final monthLabels = <int, String>{};
    int? currentMonth;
    for (final date in sortedDays) {
      if (date.month != currentMonth) {
        final column = date.difference(firstColumnStart).inDays ~/ 7;
        monthLabels[column] = '${date.month}月';
        currentMonth = date.month;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const leftLabelWidth = 28.0;
        const cellSize = 18.0;
        const cellGap = 2.0;
        final totalWidth =
            leftLabelWidth +
            totalColumns * cellSize +
            math.max(0, totalColumns - 1) * cellGap;
        final labelHeight = 20.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: labelHeight,
                  child: Row(
                    children: [
                      SizedBox(width: leftLabelWidth),
                      for (var col = 0; col < totalColumns; col++) ...[
                        SizedBox(
                          width: cellSize,
                          child: Center(
                            child: Text(
                              monthLabels[col] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B6B6B),
                              ),
                            ),
                          ),
                        ),
                        if (col != totalColumns - 1)
                          const SizedBox(width: cellGap),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                for (var rowIndex = 0; rowIndex < 7; rowIndex++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: leftLabelWidth,
                        child: Text(
                          _weekdayLabels[rowIndex],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                      ),
                      for (var col = 0; col < totalColumns; col++) ...[
                        SizedBox(
                          width: cellSize,
                          height: cellSize,
                          child: _ContributionCell(
                            count: dailyCounts[grid[rowIndex][col]] ?? 0,
                          ),
                        ),
                        if (col != totalColumns - 1)
                          const SizedBox(width: cellGap),
                      ],
                    ],
                  ),
                  if (rowIndex != 6) const SizedBox(height: cellGap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContributionCell extends StatelessWidget {
  final int count;

  const _ContributionCell({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = count == 0
        ? const Color(0xFFECECEC)
        : count == 1
        ? const Color(0xFFB6D7A8)
        : const Color(0xFF6B8E23);
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _ContributionLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ContributionLegendDot({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
        ),
      ],
    );
  }
}

class RadarChart extends StatelessWidget {
  final Map<String, double> values;
  final Map<String, String> labels;

  const RadarChart({super.key, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarChartPainter(values: values, labels: labels),
      child: Container(),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> values;
  final Map<String, String> labels;

  _RadarChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    final pointCount = values.length;
    final angleStep = 2 * math.pi / pointCount;

    final gridPaint = Paint()
      ..color = const Color(0xFFEBF4EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPaint = Paint()
      ..color = const Color(0xFF94BF8B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int level = 1; level <= 5; level++) {
      final levelRadius = radius * level / 5;
      final path = Path();
      for (int index = 0; index < pointCount; index++) {
        final angle = angleStep * index - math.pi / 2;
        final point = Offset(
          center.dx + levelRadius * math.cos(angle),
          center.dy + levelRadius * math.sin(angle),
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }
    canvas.drawCircle(center, radius, borderPaint);

    final fillPath = Path();
    final pointPaint = Paint()
      ..color = const Color(0xFFFFA7BC).withAlpha((0.35 * 255).round())
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFFFA718F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    int index = 0;
    for (final entry in values.entries) {
      final value = entry.value.clamp(0.0, 5.0);
      final angle = angleStep * index - math.pi / 2;
      final pointRadius = radius * (value / 5.0);
      final point = Offset(
        center.dx + pointRadius * math.cos(angle),
        center.dy + pointRadius * math.sin(angle),
      );
      if (index == 0) {
        fillPath.moveTo(point.dx, point.dy);
      } else {
        fillPath.lineTo(point.dx, point.dy);
      }
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFFFF6A8F));
      index += 1;
    }
    fillPath.close();
    canvas.drawPath(fillPath, pointPaint);
    canvas.drawPath(fillPath, outlinePaint);

    index = 0;
    for (final entry in values.entries) {
      final label = labels[entry.key] ?? entry.key;
      final angle = angleStep * index - math.pi / 2;
      final labelRadius = radius + 46;
      final labelPoint = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A4A)),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 72);
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      final dx = cosAngle > 0.5
          ? labelPoint.dx
          : cosAngle < -0.5
          ? labelPoint.dx - textPainter.width
          : labelPoint.dx - textPainter.width / 2;
      final dy = sinAngle > 0.5
          ? labelPoint.dy
          : sinAngle < -0.5
          ? labelPoint.dy - textPainter.height
          : labelPoint.dy - textPainter.height / 2;
      canvas.save();
      canvas.translate(dx, dy);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
      index += 1;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
