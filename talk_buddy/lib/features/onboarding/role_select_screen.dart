import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../../data/services/settings_service.dart';
import '../shared/widgets/buddy_avatar.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final needsSetup = settings.provider.needsKey && !settings.isConfigured;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEF0FF), Color(0xFFF7F8FC)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxHeight < 700;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                    children: [
                      Center(
                        child: BuddyAvatar(
                          mood: BuddyMood.happy,
                          size: compact ? 88 : 112,
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Talk Buddy',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'Çünkü her çocuk anlaşılmayı hak eder.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 22 : 34),

                      if (needsSetup) ...[
                        _SetupBanner(
                          onTap: () => context.push('/settings/ai'),
                        ),
                        const SizedBox(height: 14),
                      ],

                      _RoleCard(
                        emoji: '🧸',
                        title: 'Çocuk',
                        subtitle: 'Buddy ile konuş, oyunlar oyna',
                        color: AppColors.brand,
                        onTap: () {
                          ref.read(roleProvider.notifier).state = AppRole.child;
                          context.go('/child');
                        },
                      ),
                      const SizedBox(height: 10),
                      _RoleCard(
                        emoji: '👨‍👩‍👧',
                        title: 'Ebeveyn',
                        subtitle: 'Gelişimi takip et, raporları gör',
                        color: AppColors.mint,
                        onTap: () {
                          ref.read(roleProvider.notifier).state =
                              AppRole.parent;
                          context.go('/parent');
                        },
                      ),
                      const SizedBox(height: 10),
                      _RoleCard(
                        emoji: '🩺',
                        title: 'Uzman',
                        subtitle: 'Danışanlarını yönet, veriyi incele',
                        color: AppColors.grape,
                        onTap: () {
                          ref.read(roleProvider.notifier).state =
                              AppRole.specialist;
                          context.go('/specialist');
                        },
                      ),

                      const SizedBox(height: 18),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Ayarlar'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'Beta sürüm 0.9.0\n'
                          'Talk Buddy bir tanı aracı değildir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.55,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.settings_suggest_outlined,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Yapay zeka servisi henüz ayarlanmadı. '
                  'Dokunarak API anahtarınızı girin.',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: kCardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
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
