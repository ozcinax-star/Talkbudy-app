import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/stat_widgets.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  static double _delta(List<DailyPoint> t) {
    if (t.length < 14) return 0;
    double avg(Iterable<DailyPoint> x) =>
        x.fold<double>(0, (a, b) => a + b.overall) / x.length;
    return avg(t.sublist(t.length - 7)) -
        avg(t.sublist(t.length - 14, t.length - 7));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    final range = ref.watch(rangeProvider);
    final trend = ref.watch(trendProvider((childId: child.id, days: range)));
    final metrics = ref.watch(metricsProvider(child.id));
    final sessions = ref.watch(sessionsProvider(child.id));

    final weekMinutes = trend
        .skip(trend.length > 7 ? trend.length - 7 : 0)
        .fold<int>(0, (a, b) => a + b.minutes);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Text(child.avatar, style: const TextStyle(fontSize: 23)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    child.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    child.ageLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Çocuk modu',
            onPressed: () => context.go('/child'),
            icon: const Icon(Icons.child_care_rounded),
          ),
          IconButton(
            tooltip: 'Uzman paneli',
            onPressed: () => context.go('/specialist'),
            icon: const Icon(Icons.medical_services_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _HeadlineCard(delta: _delta(trend), childName: child.name),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Bu hafta',
                  value: '$weekMinutes',
                  unit: 'dakika',
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Seri',
                  value: '${child.streakDays}',
                  unit: 'gün',
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Seans',
                  value: '${sessions.length}',
                  unit: 'kayıt',
                  color: AppColors.mint,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          SectionHeader(
            title: 'Gelişim Eğrisi',
            trailing: SegmentedRange(
              value: range,
              onChanged: (v) => ref.read(rangeProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 12),
          _TrendChart(points: trend),

          const SizedBox(height: 20),
          const SectionHeader(title: 'Beceri Kırılımı'),
          const SizedBox(height: 12),
          _SkillBreakdown(metrics: metrics),

          const SizedBox(height: 20),
          const SectionHeader(title: 'Günlük Pratik'),
          const SizedBox(height: 12),
          _PracticeBars(
            points: trend.length > 14
                ? trend.sublist(trend.length - 14)
                : trend,
          ),

          const SizedBox(height: 20),
          const SectionHeader(title: 'Bu Hafta Ne Yapalım?'),
          const SizedBox(height: 12),
          _AdviceCard(metrics: metrics, childName: child.name),

          const SizedBox(height: 20),
          SectionHeader(
            title: 'Son Seanslar',
            trailing: TextButton(
              onPressed: () => context.go('/parent/sessions'),
              child: const Text('Tümü'),
            ),
          ),
          const SizedBox(height: 8),
          ...sessions.take(4).map(
                (s) => _SessionTile(
                  session: s,
                  onTap: () => context.go('/parent/sessions'),
                ),
              ),
        ],
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final double delta;
  final String childName;
  const _HeadlineCard({required this.delta, required this.childName});

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    final pct = (delta.abs() * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      up
                          ? Icons.trending_up_rounded
                          : Icons.trending_flat_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      up ? '%$pct artış' : '%$pct değişim',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'son 7 gün',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            up
                ? '$childName bu hafta geçen haftaya göre daha iyi konuştu.'
                : '$childName bu hafta biraz durağan. Kısa ama düzenli '
                    'seanslar iyi gelir.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<DailyPoint> points;
  const _TrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox(height: 190);

    return Container(
      height: 196,
      padding: const EdgeInsets.fromLTRB(4, 18, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  '%${v.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (points.length / 4).ceilToDouble(),
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      DateFormat('d MMM', 'tr').format(points[i].day),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched.map((t) {
                final p = points[t.x.toInt()];
                return LineTooltipItem(
                  '${DateFormat('d MMMM', 'tr').format(p.day)}\n'
                  '%${(p.overall * 100).round()} · ${p.minutes} dk · '
                  '${p.words} kelime',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].overall * 100),
              ],
              isCurved: true,
              curveSmoothness: 0.32,
              color: AppColors.brand,
              barWidth: 2.8,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brand.withOpacity(0.28),
                    AppColors.brand.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillBreakdown extends StatelessWidget {
  final SpeechMetrics metrics;
  const _SkillBreakdown({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          SkillBar(
            label: 'Telaffuz netliği',
            hint: 'Kelimeleri ne kadar net söylüyor',
            value: metrics.articulation,
          ),
          SkillBar(
            label: 'Akıcılık',
            hint: 'Takılmadan, uygun hızda konuşma',
            value: metrics.fluency,
          ),
          SkillBar(
            label: 'Kelime çeşitliliği',
            hint: 'Ne kadar farklı kelime kullanıyor',
            value: metrics.vocabulary,
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: CompareStat(
                  title: 'Konuşma hızı',
                  value: metrics.wordsPerMinute,
                  unit: 'kelime/dk',
                  expected: 85,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.line),
              Expanded(
                child: CompareStat(
                  title: 'Ort. cümle',
                  value: metrics.meanUtteranceLength,
                  unit: 'kelime',
                  expected: 4.5,
                  decimals: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticeBars extends StatelessWidget {
  final List<DailyPoint> points;
  const _PracticeBars({required this.points});

  static const _dayInitials = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];

  @override
  Widget build(BuildContext context) {
    final maxY = points.fold<int>(0, (a, b) => b.minutes > a ? b.minutes : a);

    return Container(
      height: 158,
      padding: const EdgeInsets.fromLTRB(8, 18, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: BarChart(
        BarChartData(
          maxY: (maxY + 4).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 26),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _dayInitials[points[i].day.weekday - 1],
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.inkSoft,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].minutes.toDouble(),
                    width: 11,
                    borderRadius: BorderRadius.circular(4),
                    color: points[i].minutes >= 5
                        ? AppColors.brand
                        : AppColors.line,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final SpeechMetrics metrics;
  final String childName;
  const _AdviceCard({required this.metrics, required this.childName});

  @override
  Widget build(BuildContext context) {
    final p = metrics.difficultPhonemes;
    final advice = p.isEmpty
        ? 'Bu hafta belirgin bir zorlanma gözlenmedi. Mevcut düzeni sürdürün.'
        : '"${p.first}" sesi $childName için henüz oturmamış. Günde 5 dakika '
            'Hayvanlar Ülkesi etkinliğini deneyin; bu etkinlik "${p.first}" '
            'sesi içeren kelimeleri öne çıkarır.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              advice,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  const _SessionTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              ScoreRing(value: session.metrics.overall, size: 40),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.activity,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormat('d MMMM, HH:mm', 'tr').format(session.startedAt)}'
                      ' · ${session.duration.inMinutes} dk',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkSoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
