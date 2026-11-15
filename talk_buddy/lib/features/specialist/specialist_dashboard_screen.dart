import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/stat_widgets.dart';

class SpecialistDashboardScreen extends ConsumerWidget {
  const SpecialistDashboardScreen({super.key});

  static double riskScore(ChildProfile c, SpeechMetrics m) =>
      (1 - m.overall) + (c.streakDays == 0 ? 0.4 : 0.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider);
    final alerts = ref.watch(alertsProvider);

    final sorted = [...children]..sort(
        (a, b) => riskScore(b, ref.read(metricsProvider(b.id)))
            .compareTo(riskScore(a, ref.read(metricsProvider(a.id)))),
      );

    final urgent = alerts.where((a) => a.level == AlertLevel.urgent).length;
    final active = children.where((c) => c.streakDays > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danışanlarım'),
        actions: [
          IconButton(
            tooltip: 'Ebeveyn görünümü',
            onPressed: () => context.go('/parent'),
            icon: const Icon(Icons.family_restroom_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.people_outline_rounded,
                  label: 'Danışan',
                  value: '${children.length}',
                  unit: 'toplam',
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.bolt_rounded,
                  label: 'Aktif',
                  value: '$active',
                  unit: 'bu hafta',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.notifications_active_outlined,
                  label: 'Acil',
                  value: '$urgent',
                  unit: 'uyarı',
                  color: AppColors.danger,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              const SectionHeader(title: 'Risk sırasına göre'),
              const Spacer(),
              Tooltip(
                message: 'Düşük gelişim skoru ve seans yapmama durumuna göre '
                    'sıralanır',
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 17,
                  color: AppColors.inkSoft.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...sorted.map((c) {
            final m = ref.watch(metricsProvider(c.id));
            final trend = ref.watch(trendProvider((childId: c.id, days: 14)));
            return _ChildRow(child: c, metrics: m, trend: trend);
          }),

          const SizedBox(height: 12),
          const SectionHeader(title: 'Haftalık Seans Yükü'),
          const SizedBox(height: 12),
          const _CaseloadChart(),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  final ChildProfile child;
  final SpeechMetrics metrics;
  final List<DailyPoint> trend;

  const _ChildRow({
    required this.child,
    required this.metrics,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = child.streakDays == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: inactive
              ? AppColors.danger.withOpacity(0.35)
              : AppColors.line,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/specialist/child/${child.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      child.avatar,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          child.ageLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 62,
                    height: 30,
                    child: _Sparkline(points: trend),
                  ),
                  const SizedBox(width: 10),
                  ScoreRing(value: metrics.overall, size: 42),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (inactive)
                    const Tag(
                      text: '6 gün pasif',
                      color: AppColors.danger,
                      icon: Icons.warning_amber_rounded,
                    )
                  else
                    Tag(
                      text: '${child.streakDays} gün seri',
                      color: AppColors.success,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  const SizedBox(width: 6),
                  if (metrics.difficultPhonemes.isNotEmpty)
                    Flexible(
                      child: Tag(
                        text: metrics.difficultPhonemes
                            .map((p) => '"$p"')
                            .join(' '),
                        color: AppColors.warning,
                      ),
                    ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkSoft,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<DailyPoint> points;
  const _Sparkline({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final rising = points.last.overall >= points.first.overall;
    final color = rising ? AppColors.success : AppColors.warning;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].overall),
            ],
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseloadChart extends StatelessWidget {
  const _CaseloadChart();

  static const _load = [6, 8, 5, 9, 7, 3, 1];
  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      padding: const EdgeInsets.fromLTRB(8, 18, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: BarChart(
        BarChartData(
          maxY: 12,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 4,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _days[v.toInt()],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < _load.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: _load[i].toDouble(),
                    width: 16,
                    borderRadius: BorderRadius.circular(5),
                    color: _load[i] >= 8 ? AppColors.warning : AppColors.brand,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
