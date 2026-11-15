import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/buddy_avatar.dart';
import 'conversation_controller.dart';
import 'session_result_screen.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final Activity activity;
  const SessionScreen({super.key, required this.activity});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(conversationProvider(widget.activity).notifier).start();
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final result =
        await ref.read(conversationProvider(widget.activity).notifier).finish();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SessionResultScreen(
          result: result,
          activity: widget.activity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider(widget.activity));
    final speech = ref.watch(speechServiceProvider);
    final settings = ref.watch(settingsProvider);
    final color = Color(widget.activity.colorValue);

    final size = MediaQuery.sizeOf(context);
    final buddySize = (size.height * 0.21).clamp(120.0, 180.0);

    final mood = switch (state.phase) {
      TurnPhase.listening => BuddyMood.listening,
      TurnPhase.buddySpeaking => BuddyMood.talking,
      TurnPhase.thinking => BuddyMood.thinking,
      TurnPhase.finished => BuddyMood.happy,
      _ => BuddyMood.idle,
    };

    final hint = switch (state.phase) {
      TurnPhase.listening => 'Seni dinliyorum...',
      TurnPhase.buddySpeaking => 'Buddy konuşuyor',
      TurnPhase.thinking => 'Düşünüyorum...',
      TurnPhase.finished => 'Bitti!',
      TurnPhase.error => 'Bir sorun oldu',
      TurnPhase.idle => 'Hazırlanıyor...',
    };

    final showingChild =
        state.phase == TurnPhase.listening && state.partial.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
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
                  Color.lerp(color, Colors.white, 0.86)!,
                  const Color(0xFFF7F8FC),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                    child: Row(
                      children: [
                        _RoundButton(
                          icon: Icons.close_rounded,
                          onTap: _finish,
                        ),
                        const Spacer(),
                        _TimeChip(
                          elapsed: state.elapsed,
                          limit: settings.sessionLimit,
                          emoji: widget.activity.emoji,
                          color: color,
                        ),
                        const Spacer(),
                        _RoundButton(
                          icon: Icons.star_rounded,
                          color: AppColors.lemon,
                          label: '${state.starsEarned}',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _ErrorBar(message: state.errorMessage!),
                    ),

                  const Spacer(flex: 2),

                  ValueListenableBuilder<double>(
                    valueListenable: speech.level,
                    builder: (context, level, _) => BuddyAvatar(
                      mood: mood,
                      size: buddySize,
                      level: level,
                    ),
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      hint,
                      key: ValueKey(hint),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: color.withOpacity(0.9),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SpeechBubble(
                      text: showingChild
                          ? state.partial
                          : (state.lastBuddyTurn?.text ?? ''),
                      isChild: showingChild,
                      color: color,
                    ),
                  ),

                  const Spacer(flex: 3),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      children: [
                        _MicIndicator(
                          active: state.phase == TurnPhase.listening,
                          color: color,
                          levelListenable: speech.level,
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _finishing ? null : _finish,
                          icon: _finishing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _finishing ? 'Hazırlanıyor...' : 'Bitirdim',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ],
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

class _ErrorBar extends StatelessWidget {
  final String message;
  const _ErrorBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.danger,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final Duration elapsed;
  final Duration limit;
  final String emoji;
  final Color color;

  const _TimeChip({
    required this.elapsed,
    required this.limit,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsed.inSeconds / limit.inSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: kCardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColors.line,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? label;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: label == null ? 12 : 15),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color ?? AppColors.inkSoft, size: 22),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final bool isChild;
  final Color color;

  const _SpeechBubble({
    required this.text,
    required this.isChild,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox(height: 92);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      constraints: const BoxConstraints(minHeight: 92),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isChild ? color.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isChild
            ? Border.all(color: color.withOpacity(0.4), width: 2)
            : null,
        boxShadow: isChild ? null : kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isChild ? 'SEN' : 'BUDDY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: isChild ? color : AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _MicIndicator extends StatelessWidget {
  final bool active;
  final Color color;
  final ValueListenable<double> levelListenable;

  const _MicIndicator({
    required this.active,
    required this.color,
    required this.levelListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: levelListenable,
      builder: (context, level, _) {
        return SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(11, (i) {
              final center = (5 - (i - 5).abs()) / 5;
              final h =
                  active ? 8 + level * 40 * (0.35 + center * 0.65) : 8.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: h.clamp(8, 48),
                decoration: BoxDecoration(
                  color: active ? color : AppColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
