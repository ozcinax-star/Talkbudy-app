import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/curriculum/content_library.dart';
import '../../data/curriculum/progress_store.dart';
import '../../data/repositories/learn_providers.dart';
import '../../data/services/profile_service.dart';
import '../shared/widgets/stat_widgets.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(accountProvider);
    final store = ref.watch(progressStoreProvider);

    final rows = acc.children
        .map((c) => (child: c, progress: store.load(c.id)))
        .toList()
      ..sort((a, b) => a.progress.overallCompletion
          .compareTo(b.progress.overallCompletion));

    final active = rows.where((r) => r.progress.streakDays > 0).length;
    final avgCompletion = rows.isEmpty
        ? 0.0
        : rows.fold<double>(0, (a, r) => a + r.progress.overallCompletion) /
            rows.length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Öğretmen Paneli'),
        actions: [
          IconButton(
            tooltip: 'Rol değiştir',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.logout_rounded),
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
                  icon: Icons.groups_outlined,
                  label: 'Öğrenci',
                  value: '${acc.children.length}',
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
                  icon: Icons.school_outlined,
                  label: 'Ort. ilerleme',
                  value: '%${(avgCompletion * 100).round()}',
                  unit: 'müfredat',
                  color: AppColors.grape,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          for (final room in acc.classrooms) ...[
            _ClassroomBlock(
              classroom: room,
              rows: rows.where((r) => r.child.classroomId == room.id).toList(),
            ),
            const SizedBox(height: 20),
          ],

          if (rows.any((r) => r.child.classroomId == null)) ...[
            const SectionHeader(title: 'Sınıfsız Öğrenciler'),
            const SizedBox(height: 10),
            ...rows
                .where((r) => r.child.classroomId == null)
                .map((r) => _StudentRow(child: r.child, progress: r.progress)),
          ],
        ],
      ),
    );
  }
}

class _ClassroomBlock extends StatelessWidget {
  final Classroom classroom;
  final List<({ChildAccount child, LearnerProgress progress})> rows;

  const _ClassroomBlock({required this.classroom, required this.rows});

  @override
  Widget build(BuildContext context) {
    final avg = rows.isEmpty
        ? 0.0
        : rows.fold<double>(0, (a, r) => a + r.progress.overallCompletion) /
            rows.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Text('🏫', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${rows.length} öğrenci · ortalama %${(avg * 100).round()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Bu sınıfta henüz öğrenci yok.',
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          )
        else
          ...rows.map(
            (r) => _StudentRow(child: r.child, progress: r.progress),
          ),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  final ChildAccount child;
  final LearnerProgress progress;

  const _StudentRow({required this.child, required this.progress});

  @override
  Widget build(BuildContext context) {
    final completion = progress.overallCompletion;
    final weak = progress.weakestPhonemes;
    final inactive = progress.streakDays == 0;
    final next = progress.nextLesson;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: inactive
              ? AppColors.warning.withOpacity(0.35)
              : AppColors.line,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/teacher/student/${child.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      child.avatar,
                      style: const TextStyle(fontSize: 21),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '%${(completion * 100).round()}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forScore(completion + 0.2),
                        ),
                      ),
                      Text(
                        '⭐ ${progress.totalStars}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: completion,
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (inactive)
                    const Tag(
                      text: 'pasif',
                      color: AppColors.warning,
                      icon: Icons.pause_circle_outline_rounded,
                    )
                  else
                    Tag(
                      text: '${progress.streakDays} gün',
                      color: AppColors.success,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  const SizedBox(width: 6),
                  if (weak.isNotEmpty)
                    Flexible(
                      child: Tag(
                        text: weak.take(3).map((m) => '"${m.phoneme}"').join(' '),
                        color: AppColors.danger,
                      ),
                    )
                  else if (next != null)
                    Flexible(
                      child: Tag(
                        text: 'sıradaki: ${next.title}',
                        color: AppColors.brand,
                      ),
                    ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: AppColors.inkSoft,
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

class TeacherStudentScreen extends ConsumerWidget {
  final String studentId;
  const TeacherStudentScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(accountProvider);
    final child = acc.children.firstWhere(
      (c) => c.id == studentId,
      orElse: () => acc.children.first,
    );
    final progress = ref.watch(progressStoreProvider).load(child.id);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Text(child.avatar, style: const TextStyle(fontSize: 21)),
            const SizedBox(width: 9),
            Text(child.name),
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
                    ScoreRing(value: progress.overallCompletion, size: 62),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Müfredat İlerlemesi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${progress.lessons.values.where((l) => l.isComplete).length}'
                            ' / ${ContentLibrary.allLessons.length} ders tamamlandı',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Mini(
                        label: 'Yıldız',
                        value: '${progress.totalStars}',
                      ),
                    ),
                    Container(width: 1, height: 34, color: AppColors.line),
                    Expanded(
                      child: _Mini(
                        label: 'Seri',
                        value: '${progress.streakDays} gün',
                      ),
                    ),
                    Container(width: 1, height: 34, color: AppColors.line),
                    Expanded(
                      child: _Mini(
                        label: 'Ort. ustalık',
                        value: '%${(progress.averageMastery * 100).round()}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionHeader(title: 'Ses Ustalığı'),
          const SizedBox(height: 12),
          _MasteryGrid(progress: progress),

          if (progress.topProcesses().isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Gözlenen Ses Süreçleri'),
            const SizedBox(height: 12),
            ...progress.topProcesses().map(
                  (r) => _ProcessTile(
                    record: r,
                    ageMonths: child.ageMonths,
                  ),
                ),
          ],

          const SizedBox(height: 20),
          const SectionHeader(title: 'Ünite Durumu'),
          const SizedBox(height: 12),
          ...ContentLibrary.units.map((u) {
            final done =
                u.lessons.where((l) => progress.isLessonComplete(l.id)).length;
            final unlocked = progress.isUnitUnlocked(u);
            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: unlocked ? 1 : 0.4,
                    child: Text(
                      u.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: done / u.lessons.length,
                            minHeight: 5,
                            backgroundColor: AppColors.line,
                            valueColor: AlwaysStoppedAnimation(
                              Color(u.colorValue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    '$done/${u.lessons.length}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _ProcessTile extends StatelessWidget {
  final ProcessRecord record;
  final int ageMonths;

  const _ProcessTile({required this.record, required this.ageMonths});

  @override
  Widget build(BuildContext context) {
    final meta = record.meta;
    if (meta == null) return const SizedBox.shrink();
    final late_ = record.isLateFor(ageMonths);
    final color = late_ ? AppColors.danger : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: late_ ? color.withOpacity(0.4) : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                meta.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Tag(text: '${record.count} kez', color: color),
              const Spacer(),
              Text(
                '${record.lessons} derste',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            meta.explanation,
            style: const TextStyle(fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            late_
                ? 'Bu süreç genellikle '
                    '${(meta.typicalResolutionMonths / 12).toStringAsFixed(1)} '
                    'yaşında çözülür. Yaşa göre gecikme var, değerlendirme önerilir.'
                : 'Genellikle '
                    '${(meta.typicalResolutionMonths / 12).toStringAsFixed(1)} '
                    'yaş civarında kendiliğinden düzelir.',
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: late_ ? color : AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryGrid extends StatelessWidget {
  final LearnerProgress progress;
  const _MasteryGrid({required this.progress});

  static const _phonemes = [
    'p', 'b', 'm', 'n', 't', 'd', 'k', 'g', 'f', 'v',
    's', 'z', 'ş', 'ç', 'c', 'l', 'r', 'j', 'y', 'h',
  ];

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
              final m = progress.mastery[p];
              final color = m == null
                  ? AppColors.line
                  : AppColors.forScore(m.score);
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: m == null
                      ? AppColors.canvas
                      : color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: m?.isMastered == true
                      ? Border.all(color: color, width: 1.5)
                      : null,
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: m == null ? AppColors.inkSoft : color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              LegendDot(color: AppColors.line, label: 'Çalışılmadı', circle: true),
              LegendDot(color: AppColors.danger, label: 'Zayıf', circle: true),
              LegendDot(color: AppColors.lemon, label: 'Gelişiyor', circle: true),
              LegendDot(color: AppColors.success, label: 'Kazanıldı', circle: true),
            ],
          ),
        ],
      ),
    );
  }
}
