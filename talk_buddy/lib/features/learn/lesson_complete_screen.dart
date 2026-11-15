import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/curriculum/content_library.dart';
import '../../data/curriculum/curriculum_models.dart';
import '../../data/curriculum/phonology.dart';
import '../shared/widgets/buddy_avatar.dart';

class LessonCompleteScreen extends ConsumerWidget {
  final LessonResult result;
  const LessonCompleteScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ContentLibrary.lessonById(result.lessonId);
    final unit = ContentLibrary.unitById(result.unitId);
    final color = Color(unit?.colorValue ?? 0xFF5B6CFF);
    final passed = result.passed;

    return Theme(
      data: AppTheme.child,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4FF),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Center(
                child: BuddyAvatar(
                  mood: passed ? BuddyMood.happy : BuddyMood.idle,
                  size: 104,
                ),
              ),
              Center(
                child: Text(
                  passed ? 'Tebrikler!' : 'İyi çalıştın!',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${unit?.emoji ?? ''} ${lesson?.title ?? ''}',
                  style: const TextStyle(
                    fontSize: 15.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _Stars(stars: result.stars, max: result.maxStars, color: color),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      emoji: '⭐',
                      value: '${result.stars}',
                      label: 'yıldız',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Tile(
                      emoji: '✅',
                      value:
                          '${result.results.where((r) => r.verdict.advances).length}'
                          '/${result.results.length}',
                      label: 'alıştırma',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Tile(
                      emoji: '⏱️',
                      value: '${result.duration.inMinutes}',
                      label: 'dakika',
                    ),
                  ),
                ],
              ),

              if (!passed) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💙', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Bu ders biraz zorlayıcıydı ama sen pes etmedin. '
                          'Tekrar denediğinde çok daha kolay gelecek.',
                          style: TextStyle(fontSize: 14, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
              const Divider(),
              const SizedBox(height: 14),

              const Row(
                children: [
                  Icon(
                    Icons.family_restroom_rounded,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AİLEYE NOT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ParentNote(result: result),

              if (result.processCounts.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ProcessCard(counts: result.processCounts),
              ],

              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/child'),
                child: const Text('Öğrenme yoluna dön'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/parent'),
                child: const Text('Detaylı raporu gör'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int stars;
  final int max;
  final Color color;
  const _Stars({required this.stars, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : stars / max;
    final filled = (ratio * 3).round().clamp(0, 3);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final on = i < filled;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: on ? 1 : 0.4),
              duration: Duration(milliseconds: 400 + i * 180),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(
                scale: 0.6 + v * 0.55,
                child: child,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.star_rounded,
                  size: 52,
                  color: on ? AppColors.lemon : AppColors.line,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          '$stars / $max puan',
          style: const TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _Tile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 23)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _ParentNote extends StatelessWidget {
  final LessonResult result;
  const _ParentNote({required this.result});

  @override
  Widget build(BuildContext context) {
    final struggling = result.strugglingPhonemes;
    final intel = result.meanIntelligibility;

    final buffer = StringBuffer()
      ..write(
        '${result.results.length} alıştırmanın '
        '${result.results.where((r) => r.verdict.advances).length} tanesinde '
        'hedefe ulaştı. ',
      );

    if (intel > 0) {
      buffer.write(
        'Konuşma netliği bu derste ortalama %${(intel * 100).round()}. ',
      );
    }

    if (struggling.isEmpty) {
      buffer.write('Belirgin bir zorlanma gözlenmedi.');
    } else {
      buffer.write(
        'En çok zorlandığı sesler: '
        '${struggling.map((p) => '"$p"').join(', ')}. '
        'Bu sesleri günlük konuşmada oyunlaştırarak tekrar etmek faydalı olur.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: kCardShadow,
      ),
      child: Text(
        buffer.toString(),
        style: const TextStyle(fontSize: 14.5, height: 1.5),
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  final Map<String, int> counts;
  const _ProcessCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gözlenen ses süreçleri',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bunlar gelişimsel olarak normal olabilir; uzman paneline iletildi.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          ...sorted.take(3).map((e) {
            final p = TurkishPhonology.processById(e.key);
            if (p == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.label,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${e.value} kez',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.explanation,
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                  Text(
                    'Genellikle ${(p.typicalResolutionMonths / 12).toStringAsFixed(0)} '
                    'yaş civarında kendiliğinden düzelir.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
                      fontStyle: FontStyle.italic,
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
