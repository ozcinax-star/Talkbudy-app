import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/curriculum/curriculum_models.dart';
import '../../data/curriculum/progress_store.dart';
import '../../data/repositories/learn_providers.dart';
import '../shared/widgets/buddy_avatar.dart';
import '../shared/widgets/parent_gate.dart';

class PathScreen extends ConsumerWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeAccountProvider);
    final progress = ref.watch(activeProgressProvider);
    final units = ref.watch(unitsProvider);
    final next = progress.nextLesson;

    return Theme(
      data: AppTheme.child,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                name: child.name,
                avatar: child.avatar,
                stars: progress.totalStars,
                streak: progress.streakDays,
                completion: progress.overallCompletion,
              ),
            ),
            if (next != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: _ContinueCard(
                    lesson: next,
                    onTap: () => context.push('/lesson/${next.id}'),
                  ),
                ),
              ),
            SliverList.builder(
              itemCount: units.length,
              itemBuilder: (context, i) => _UnitBlock(
                unit: units[i],
                progress: progress,
                isFirst: i == 0,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String avatar;
  final int stars;
  final int streak;
  final double completion;

  const _Header({
    required this.name,
    required this.avatar,
    required this.stars,
    required this.streak,
    required this.completion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: kCardShadow,
                ),
                child: Text(avatar, style: const TextStyle(fontSize: 23)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba $name!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Yolculuğun %${(completion * 100).round()} tamamlandı',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              _Chip(emoji: '⭐', label: '$stars'),
              const SizedBox(width: 7),
              _Chip(emoji: '🔥', label: '$streak'),
              const SizedBox(width: 7),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => showParentGate(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: completion),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 9,
                backgroundColor: AppColors.line,
                valueColor: const AlwaysStoppedAnimation(AppColors.brand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String emoji;
  final String label;
  const _Chip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: kCardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  const _ContinueCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      color: AppColors.brand,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brand, AppColors.brandDark],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: kSoftShadow,
          ),
          child: Row(
            children: [
              const BuddyAvatar(mood: BuddyMood.happy, size: 54),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KALDIĞIN YERDEN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitBlock extends StatelessWidget {
  final Unit unit;
  final LearnerProgress progress;
  final bool isFirst;

  const _UnitBlock({
    required this.unit,
    required this.progress,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isUnitUnlocked(unit);
    final color = Color(unit.colorValue);
    final done = unit.lessons.where((l) => progress.isLessonComplete(l.id)).length;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, isFirst ? 12 : 26, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: unlocked ? 1 : 0.45,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(unit.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        unit.subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!unlocked)
                  const Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: AppColors.inkSoft,
                  )
                else
                  Text(
                    '$done/${unit.lessons.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < unit.lessons.length; i++)
            _LessonNode(
              unit: unit,
              lesson: unit.lessons[i],
              progress: progress,
              alignRight: i.isOdd,
              isLast: i == unit.lessons.length - 1,
            ),
        ],
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  final Unit unit;
  final Lesson lesson;
  final LearnerProgress progress;
  final bool alignRight;
  final bool isLast;

  const _LessonNode({
    required this.unit,
    required this.lesson,
    required this.progress,
    required this.alignRight,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isLessonUnlocked(unit, lesson);
    final complete = progress.isLessonComplete(lesson.id);
    final stars = progress.starsFor(lesson.id);
    final color = Color(unit.colorValue);

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 10,
        left: alignRight ? 48 : 0,
        right: alignRight ? 0 : 48,
      ),
      child: Opacity(
        opacity: unlocked ? 1 : 0.42,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: unlocked
                ? () => context.push('/lesson/${lesson.id}')
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Önce bir önceki dersi tamamla'),
                        duration: Duration(seconds: 2),
                      ),
                    ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: unlocked ? kCardShadow : null,
                border: unlocked
                    ? null
                    : Border.all(color: AppColors.line, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: complete
                          ? color
                          : (unlocked
                              ? color.withOpacity(0.14)
                              : AppColors.canvas),
                      shape: BoxShape.circle,
                    ),
                    child: complete
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : Icon(
                            unlocked
                                ? Icons.play_arrow_rounded
                                : Icons.lock_rounded,
                            color: unlocked ? color : AppColors.inkSoft,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lesson.exerciseCount} alıştırma',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (complete)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: i < (stars / lesson.exerciseCount * 3).round()
                              ? AppColors.lemon
                              : AppColors.line,
                        ),
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
