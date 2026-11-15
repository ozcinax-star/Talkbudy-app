import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/buddy_avatar.dart';
import '../shared/widgets/parent_gate.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    final activities = ref.watch(activitiesProvider);
    final media = MediaQuery.sizeOf(context);
    final buddySize = (media.height * 0.17).clamp(96.0, 140.0);

    return Theme(
      data: AppTheme.child,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
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
                  child: Text(
                    child.avatar,
                    style: const TextStyle(fontSize: 23),
                  ),
                ),
                const Spacer(),
                _Pill(emoji: '⭐', label: '${child.stars}'),
                const SizedBox(width: 8),
                _Pill(emoji: '🔥', label: '${child.streakDays}'),
                const SizedBox(width: 8),
                _RoundIcon(
                  icon: Icons.lock_outline_rounded,
                  onTap: () => showParentGate(context),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Center(child: BuddyAvatar(mood: BuddyMood.idle, size: buddySize)),

            Center(
              child: Text(
                'Merhaba ${child.name}!',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Bugün ne konuşalım?',
                style: TextStyle(fontSize: 16, color: AppColors.inkSoft),
              ),
            ),

            const SizedBox(height: 18),
            _BigTalkButton(
              onTap: () => context.push('/session', extra: activities.first),
            ),

            const SizedBox(height: 26),
            const _RowHeader(title: 'Bugünün oyunları', target: '/child/activities'),
            const SizedBox(height: 12),

            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: activities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _ActivityCard(
                  activity: activities[i],
                  onTap: () =>
                      context.push('/session', extra: activities[i]),
                ),
              ),
            ),

            const SizedBox(height: 26),
            const _RowHeader(title: 'Rozetlerim', target: '/child/rewards'),
            const SizedBox(height: 12),
            const _BadgeStrip(),
          ],
        ),
      ),
    );
  }
}

class _RowHeader extends StatelessWidget {
  final String title;
  final String target;
  const _RowHeader({required this.title, required this.target});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        TextButton(
          onPressed: () => context.go(target),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 36),
          ),
          child: const Text('Tümü'),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String emoji;
  final String label;
  const _Pill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: kCardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 19, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}

class _BigTalkButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BigTalkButton({required this.onTap});

  @override
  State<_BigTalkButton> createState() => _BigTalkButtonState();
}

class _BigTalkButtonState extends State<_BigTalkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) =>
          Transform.scale(scale: 1 + _c.value * 0.022, child: child),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: Material(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_rounded, color: Colors.white, size: 29),
                SizedBox(width: 10),
                Text(
                  'Konuşalım!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  const _ActivityCard({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(activity.colorValue);
    return SizedBox(
      width: 138,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: kCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    activity.emoji,
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                const Spacer(),
                Text(
                  activity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${activity.estimatedMinutes} dk',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip();

  static const _badges = [
    ('🔥', true),
    ('🗣️', true),
    ('🦁', true),
    ('📖', true),
    ('⭐', true),
    ('🎵', false),
    ('🏆', false),
    ('🚀', false),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (emoji, earned) = _badges[i];
          return Opacity(
            opacity: earned ? 1 : 0.32,
            child: Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: earned ? kCardShadow : null,
                border:
                    earned ? null : Border.all(color: AppColors.line, width: 2),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 27)),
            ),
          );
        },
      ),
    );
  }
}
