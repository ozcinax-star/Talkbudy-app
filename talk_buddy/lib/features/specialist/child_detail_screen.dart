import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/stat_widgets.dart';

class ChildDetailScreen extends ConsumerStatefulWidget {
  final String childId;
  const ChildDetailScreen({super.key, required this.childId});

  @override
  ConsumerState<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends ConsumerState<ChildDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _tabs.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(childrenProvider);
    final child = children.firstWhere(
      (c) => c.id == widget.childId,
      orElse: () => children.first,
    );
    final metrics = ref.watch(metricsProvider(child.id));
    final sessions = ref.watch(sessionsProvider(child.id));
    final trend = ref.watch(trendProvider((childId: child.id, days: 60)));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Text(child.avatar, style: const TextStyle(fontSize: 21)),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                child.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              child.ageLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.inkSoft,
          indicatorColor: AppColors.brand,
          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Genel'),
            Tab(text: 'Seanslar'),
            Tab(text: 'Notlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(metrics: metrics, trend: trend),
          _SessionsTab(sessions: sessions),
          _NotesTab(controller: _noteCtrl, childName: child.name),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final SpeechMetrics metrics;
  final List<DailyPoint> trend;

  const _OverviewTab({required this.metrics, required this.trend});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ScoreRing(value: metrics.overall, size: 66),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Genel Gelişim Skoru',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Telaffuz %40 · Akıcılık %30 · Kelime %30',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Tag(
                    text: '${metrics.totalWords} kelime/seans',
                    color: AppColors.brand,
                  ),
                  Tag(
                    text: 'MLU ${metrics.meanUtteranceLength.toStringAsFixed(1)}',
                    color: AppColors.grape,
                  ),
                  if (metrics.difficultPhonemes.isNotEmpty)
                    Tag(
                      text: 'zorlanma: ${metrics.difficultPhonemes.join(", ")}',
                      color: AppColors.warning,
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const SectionHeader(title: '60 Günlük Eğilim'),
        const SizedBox(height: 12),
        _MultiTrendChart(points: trend),

        const SizedBox(height: 20),
        const SectionHeader(title: 'Beceri Profili'),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Expanded(child: _RadarProfile(metrics: metrics)),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LegendDot(color: AppColors.brand, label: 'Danışan'),
                  SizedBox(width: 16),
                  LegendDot(color: Color(0xFFCFD4E4), label: 'Yaş normu'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const SectionHeader(title: 'Fonolojik Harita'),
        const SizedBox(height: 12),
        _PhonemeGrid(difficult: metrics.difficultPhonemes),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 19,
                color: AppColors.brand,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seans Önerisi',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      metrics.difficultPhonemes.isEmpty
                          ? 'Mevcut program sürdürülebilir. Cümle uzunluğunu '
                              'artırmaya yönelik anlatı görevleri eklenebilir.'
                          : '"${metrics.difficultPhonemes.first}" sesi için '
                              'sözcük başı konumda minimal çift çalışması '
                              'önerilir. Hayvanlar Ülkesi etkinliği bu sesi '
                              'hedefleyecek şekilde ağırlıklandırıldı.',
                      style: const TextStyle(fontSize: 13, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiTrendChart extends StatelessWidget {
  final List<DailyPoint> points;
  const _MultiTrendChart({required this.points});

  List<FlSpot> _series(double offset, double scale) => [
        for (var i = 0; i < points.length; i++)
          FlSpot(
            i.toDouble(),
            ((points[i].overall * scale + offset) * 100).clamp(0, 100),
          ),
      ];

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.35,
        color: color,
        barWidth: 2.2,
        dotData: const FlDotData(show: false),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 216,
      padding: const EdgeInsets.fromLTRB(6, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LegendDot(color: AppColors.brand, label: 'Telaffuz'),
              SizedBox(width: 12),
              LegendDot(color: AppColors.mint, label: 'Akıcılık'),
              SizedBox(width: 12),
              LegendDot(color: AppColors.grape, label: 'Kelime'),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        '%${v.toInt()}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('d/M').format(points[i].day),
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.inkSoft,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(_series(0.04, 1.0), AppColors.brand),
                  _line(_series(-0.06, 0.95), AppColors.mint),
                  _line(_series(0.10, 0.88), AppColors.grape),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarProfile extends StatelessWidget {
  final SpeechMetrics metrics;
  const _RadarProfile({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 4,
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
        radarBorderData: const BorderSide(color: AppColors.line),
        gridBorderData: const BorderSide(color: AppColors.line, width: 1),
        tickBorderData: const BorderSide(color: Colors.transparent),
        titlePositionPercentageOffset: 0.16,
        titleTextStyle: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
        getTitle: (i, _) => switch (i) {
          0 => const RadarChartTitle(text: 'Telaffuz'),
          1 => const RadarChartTitle(text: 'Akıcılık'),
          2 => const RadarChartTitle(text: 'Kelime'),
          3 => const RadarChartTitle(text: 'Cümle'),
          _ => const RadarChartTitle(text: 'Duygu'),
        },
        dataSets: [
          RadarDataSet(
            fillColor: AppColors.line.withOpacity(0.45),
            borderColor: const Color(0xFFCFD4E4),
            entryRadius: 0,
            borderWidth: 1,
            dataEntries: const [
              RadarEntry(value: 0.72),
              RadarEntry(value: 0.72),
              RadarEntry(value: 0.72),
              RadarEntry(value: 0.72),
              RadarEntry(value: 0.72),
            ],
          ),
          RadarDataSet(
            fillColor: AppColors.brand.withOpacity(0.22),
            borderColor: AppColors.brand,
            entryRadius: 2.6,
            borderWidth: 2.2,
            dataEntries: [
              RadarEntry(value: metrics.articulation),
              RadarEntry(value: metrics.fluency),
              RadarEntry(value: metrics.vocabulary),
              RadarEntry(
                value: (metrics.meanUtteranceLength / 6).clamp(0.0, 1.0),
              ),
              RadarEntry(value: ((metrics.sentiment + 1) / 2).clamp(0.0, 1.0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhonemeGrid extends StatelessWidget {
  final List<String> difficult;
  const _PhonemeGrid({required this.difficult});

  static const _phonemes = [
    'p', 'b', 't', 'd', 'k', 'g', 'f', 'v', 's', 'z',
    'ş', 'j', 'ç', 'c', 'm', 'n', 'l', 'r', 'y', 'h',
  ];
  static const _late = ['r', 'ş', 'j', 'z', 's'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: _phonemes.length,
            itemBuilder: (context, i) {
              final p = _phonemes[i];
              final flagged = difficult.contains(p);
              final color = flagged
                  ? AppColors.danger
                  : (_late.contains(p) ? AppColors.warning : AppColors.success);
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(flagged ? 0.18 : 0.09),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: flagged ? Border.all(color: color, width: 1.4) : null,
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              LegendDot(
                color: AppColors.success,
                label: 'Kazanılmış',
                circle: true,
              ),
              LegendDot(
                color: AppColors.warning,
                label: 'İzlemede',
                circle: true,
              ),
              LegendDot(
                color: AppColors.danger,
                label: 'Zorlanma',
                circle: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  final List<Session> sessions;
  const _SessionsTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: EdgeInsets.zero,
              leading: ScoreRing(value: s.metrics.overall, size: 38),
              title: Text(
                s.activity,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${DateFormat('d MMM yyyy, HH:mm', 'tr').format(s.startedAt)}'
                ' · ${s.duration.inMinutes} dk',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          s.summary,
                          style: const TextStyle(fontSize: 12.5, height: 1.45),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'KONUŞMA DÖKÜMÜ',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...s.turns.map((t) => _TurnRow(turn: t)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TurnRow extends StatelessWidget {
  final ChatTurn turn;
  const _TurnRow({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isChild = turn.speaker == Speaker.child;
    final lowConf = (turn.confidence ?? 1) < 0.72;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                isChild ? 'Çocuk' : 'Buddy',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isChild ? AppColors.brand : AppColors.inkSoft,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: isChild
                    ? (lowConf
                        ? AppColors.warning.withOpacity(0.09)
                        : AppColors.brandSoft)
                    : AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: lowConf && isChild
                    ? Border.all(
                        color: AppColors.warning.withOpacity(0.45),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turn.text,
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                  if (isChild && turn.confidence != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          lowConf
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          size: 11,
                          color:
                              lowConf ? AppColors.warning : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'netlik %${(turn.confidence! * 100).round()}'
                            '${turn.flaggedPhonemes.isEmpty ? "" : " · ${turn.flaggedPhonemes.map((p) => '"$p"').join(", ")}"}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: lowConf
                                  ? AppColors.warning
                                  : AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final TextEditingController controller;
  final String childName;
  const _NotesTab({required this.controller, required this.childName});

  static const _history = <(String, String, bool)>[
    (
      '22 Temmuz 2026',
      'Sözcük sonu /r/ üretimi tutarlı hale geldi. Sözcük başı /r/ hâlâ '
          'atlanıyor. Minimal çift çalışmasına devam.',
      true,
    ),
    (
      '15 Temmuz 2026',
      'Uygulama verisi ile klinik gözlem örtüşüyor. Ailenin evde günlük '
          '5 dakika pratiği sürdürmesi konuşuldu.',
      true,
    ),
    (
      '8 Temmuz 2026',
      'İlk değerlendirme. MLU 2.9 (yaş beklentisi 4.5). Fonolojik süreç: '
          'sıvı ünsüz basitleştirme.',
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: '$childName için seans notu ekleyin',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  controller.clear();
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not kaydedildi')),
                  );
                },
                icon: const Icon(Icons.save_outlined, size: 19),
                label: const Text('Kaydet'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aileye iletildi')),
                ),
                icon: const Icon(Icons.share_outlined, size: 19),
                label: const Text('Paylaş'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Geçmiş Notlar'),
        const SizedBox(height: 12),
        ..._history.map(
          (n) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      n.$1,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const Spacer(),
                    if (n.$3)
                      const Tag(
                        text: 'aileye iletildi',
                        color: AppColors.success,
                        icon: Icons.check,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  n.$2,
                  style: const TextStyle(fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
