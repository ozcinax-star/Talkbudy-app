import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/curriculum/answer_evaluator.dart';
import '../../data/curriculum/content_library.dart';
import '../../data/curriculum/curriculum_models.dart';
import '../../data/repositories/learn_providers.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/buddy_avatar.dart';
import 'lesson_complete_screen.dart';
import 'lesson_controller.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final _textCtrl = TextEditingController();
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(lessonControllerProvider(widget.lessonId).notifier).start();
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_finished || !mounted) return;
    _finished = true;

    final ctrl = ref.read(lessonControllerProvider(widget.lessonId).notifier);
    final result = ctrl.buildResult();
    final child = ref.read(activeAccountProvider);
    await ref.read(progressProvider(child.id).notifier).submit(result);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LessonCompleteScreen(result: result),
      ),
    );
  }

  Future<void> _quit() async {
    final ctrl = ref.read(lessonControllerProvider(widget.lessonId).notifier);
    final state = ref.read(lessonControllerProvider(widget.lessonId));

    if (state.results.isEmpty) {
      await ctrl.abandon();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Dersten çıkalım mı?'),
        content: const Text(
          'Şimdiye kadarki çalışman kaydedilecek. İstediğin zaman '
          'kaldığın yerden devam edebilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );

    if (leave != true || !mounted) return;
    await ctrl.abandon();
    await _complete();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonControllerProvider(widget.lessonId));
    final ctrl = ref.read(lessonControllerProvider(widget.lessonId).notifier);
    final speech = ref.watch(speechServiceProvider);

    ref.listen<LessonState>(
      lessonControllerProvider(widget.lessonId),
      (prev, next) {
        if (next.phase == LessonPhase.complete && !_finished) {
          Future<void>.delayed(
            const Duration(milliseconds: 900),
            _complete,
          );
        }
      },
    );

    final lesson = ContentLibrary.lessonById(widget.lessonId);
    final unit = lesson == null
        ? null
        : ContentLibrary.unitById(lesson.unitId);
    final color = Color(unit?.colorValue ?? 0xFF5B6CFF);
    final ex = state.current;

    final mood = switch (state.phase) {
      LessonPhase.listening => BuddyMood.listening,
      LessonPhase.speaking || LessonPhase.intro => BuddyMood.talking,
      LessonPhase.evaluating => BuddyMood.thinking,
      LessonPhase.feedback ||
      LessonPhase.complete =>
        state.evaluation?.verdict == Verdict.retry
            ? BuddyMood.idle
            : BuddyMood.happy,
      _ => BuddyMood.idle,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _quit();
      },
      child: Theme(
        data: AppTheme.child,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(color, Colors.white, 0.87)!,
                  const Color(0xFFF7F8FC),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    progress: state.progress,
                    index: state.index,
                    total: state.total,
                    stars: state.stars,
                    color: color,
                    onQuit: _quit,
                  ),

                  if (state.phase == LessonPhase.micDenied)
                    Expanded(child: _MicDenied(onRetry: ctrl.start))
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Column(
                          children: [
                            ValueListenableBuilder<double>(
                              valueListenable: speech.level,
                              builder: (context, level, _) => BuddyAvatar(
                                mood: mood,
                                size: 116,
                                level: level,
                              ),
                            ),
                            _PhaseLabel(phase: state.phase, color: color),
                            const SizedBox(height: 10),

                            if (state.banner != null)
                              _Banner(text: state.banner!)
                            else if (ex != null)
                              _PromptCard(exercise: ex, color: color),

                            if (ex != null &&
                                ex.emoji.isNotEmpty &&
                                ex.options.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  ex.emoji,
                                  style: const TextStyle(fontSize: 76),
                                ),
                              ),

                            if (ex != null && ex.options.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _Options(
                                  exercise: ex,
                                  color: color,
                                  enabled: state.phase == LessonPhase.awaiting,
                                  onPick: ctrl.submitChoice,
                                ),
                              ),

                            if (state.partial.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: _HeardBubble(
                                  text: state.partial,
                                  color: color,
                                ),
                              ),

                            if (state.evaluation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: _FeedbackCard(
                                  evaluation: state.evaluation!,
                                  heard: state.heard,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  if (state.phase != LessonPhase.micDenied)
                    _BottomBar(
                      state: state,
                      color: color,
                      controller: ctrl,
                      textController: _textCtrl,
                      levelListenable: speech.level,
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

class _TopBar extends StatelessWidget {
  final double progress;
  final int index;
  final int total;
  final int stars;
  final Color color;
  final VoidCallback onQuit;

  const _TopBar({
    required this.progress,
    required this.index,
    required this.total,
    required this.stars,
    required this.color,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onQuit,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.inkSoft,
            iconSize: 24,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 12,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: kCardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: AppColors.lemon,
                ),
                const SizedBox(width: 4),
                Text(
                  '$stars',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  final LessonPhase phase;
  final Color color;
  const _PhaseLabel({required this.phase, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = switch (phase) {
      LessonPhase.loading => 'Hazırlanıyor...',
      LessonPhase.intro || LessonPhase.speaking => 'Buddy konuşuyor',
      LessonPhase.awaiting => 'Sıra sende',
      LessonPhase.listening => 'Seni dinliyorum...',
      LessonPhase.evaluating => 'Düşünüyorum...',
      LessonPhase.feedback => '',
      LessonPhase.scaffolding => 'Birlikte deneyelim',
      LessonPhase.complete => 'Bitti!',
      LessonPhase.micDenied => '',
    };

    if (text.isEmpty) return const SizedBox(height: 22);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  const _Banner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: kSoftShadow,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final Exercise exercise;
  final Color color;
  const _PromptCard({required this.exercise, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  exercise.type.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                exercise.domain.emoji,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exercise.prompt,
            style: const TextStyle(
              fontSize: 19,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (exercise.targetWord != null &&
              exercise.type == ExerciseType.listenRepeat) ...[
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  exercise.targetWord!,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Options extends StatelessWidget {
  final Exercise exercise;
  final Color color;
  final bool enabled;
  final ValueChanged<int> onPick;

  const _Options({
    required this.exercise,
    required this.color,
    required this.enabled,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isEmoji = exercise.type == ExerciseType.choosePicture;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < exercise.options.length; i++)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              onTap: enabled ? () => onPick(i) : null,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Container(
                width: isEmoji ? 92 : 132,
                height: isEmoji ? 92 : 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: kCardShadow,
                  border: Border.all(
                    color: enabled ? color.withOpacity(0.35) : AppColors.line,
                    width: 2,
                  ),
                ),
                child: Text(
                  exercise.options[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isEmoji ? 42 : 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeardBubble extends StatelessWidget {
  final String text;
  final Color color;
  const _HeardBubble({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.35), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Evaluation evaluation;
  final String heard;
  const _FeedbackCard({required this.evaluation, required this.heard});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (evaluation.verdict) {
      Verdict.pass => (AppColors.success, Icons.check_circle_rounded),
      Verdict.partial => (AppColors.lemon, Icons.thumb_up_rounded),
      Verdict.retry => (AppColors.brand, Icons.refresh_rounded),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  evaluation.feedback,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (evaluation.scaffold?.hint != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 17,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    evaluation.scaffold!.hint!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final LessonState state;
  final Color color;
  final LessonController controller;
  final TextEditingController textController;
  final ValueListenable<double> levelListenable;

  const _BottomBar({
    required this.state,
    required this.color,
    required this.controller,
    required this.textController,
    required this.levelListenable,
  });

  @override
  Widget build(BuildContext context) {
    final ex = state.current;
    final showMic = ex != null &&
        ex.type.needsVoice &&
        (state.phase == LessonPhase.listening ||
            state.phase == LessonPhase.awaiting);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMic)
            _MicRow(
              listening: state.phase == LessonPhase.listening,
              color: color,
              levelListenable: levelListenable,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SmallButton(
                icon: Icons.replay_rounded,
                label: 'Tekrar dinle',
                onTap: controller.repeatPrompt,
              ),
              const SizedBox(width: 10),
              if (state.phase == LessonPhase.awaiting &&
                  ex != null &&
                  ex.type.needsVoice)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.listen,
                    icon: const Icon(Icons.mic_rounded),
                    label: const Text('Konuş'),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(0, 54),
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 10),
              _SmallButton(
                icon: Icons.skip_next_rounded,
                label: 'Atla',
                onTap: controller.skip,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicRow extends StatelessWidget {
  final bool listening;
  final Color color;
  final ValueListenable<double> levelListenable;

  const _MicRow({
    required this.listening,
    required this.color,
    required this.levelListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: levelListenable,
      builder: (context, level, _) => SizedBox(
        height: 38,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(13, (i) {
            final center = (6 - (i - 6).abs()) / 6;
            final h = listening ? 6 + level * 30 * (0.3 + center * 0.7) : 6.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 5,
              height: h.clamp(6, 36),
              decoration: BoxDecoration(
                color: listening ? color : AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.inkSoft),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicDenied extends StatelessWidget {
  final VoidCallback onRetry;
  const _MicDenied({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mic_off_rounded,
              size: 52,
              color: AppColors.inkSoft,
            ),
            const SizedBox(height: 18),
            const Text(
              'Mikrofona ihtiyacım var',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Buddy ile konuşabilmen için mikrofon iznine ihtiyacımız var. '
              'Telefon ayarlarından izin verip tekrar deneyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
