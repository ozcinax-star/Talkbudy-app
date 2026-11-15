import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/buddy_avatar.dart';
import 'conversation_controller.dart';

class SessionResultScreen extends ConsumerWidget {
  final SessionResult result;
  final Activity activity;

  const SessionResultScreen({
    super.key,
    required this.result,
    required this.activity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = result.metrics;

    return Theme(
      data: AppTheme.child,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4FF),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const SizedBox(height: 8),
              const Center(
                child: BuddyAvatar(mood: BuddyMood.happy, size: 104),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Harikaydın!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '${activity.emoji} ${activity.title}',
                  style: const TextStyle(
                      fontSize: 17, color: AppColors.inkSoft),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _RewardTile(
                      emoji: '⭐',
                      value: '+${result.stars}',
                      label: 'yıldız',
                      color: AppColors.lemon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RewardTile(
                      emoji: '💬',
                      value: '${m.totalWords}',
                      label: 'kelime',
                      color: AppColors.mint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RewardTile(
                      emoji: '⏱️',
                      value: '${result.duration.inMinutes}',
                      label: 'dakika',
                      color: AppColors.sky,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(Icons.family_restroom_rounded,
                      size: 20, color: AppColors.inkSoft),
                  const SizedBox(width: 8),
                  Text(
                    'Aileye not',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: kCardShadow,
                ),
                child: Text(
                  result.summary,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: AppColors.ink,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _MetricRow(
                label: 'Telaffuz netliği',
                value: m.articulation,
                icon: Icons.record_voice_over_rounded,
              ),
              _MetricRow(
                label: 'Akıcılık',
                value: m.fluency,
                icon: Icons.waves_rounded,
              ),
              _MetricRow(
                label: 'Kelime çeşitliliği',
                value: m.vocabulary,
                icon: Icons.auto_stories_rounded,
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      title: 'Konuşma hızı',
                      value: '${m.wordsPerMinute.round()}',
                      unit: 'kelime/dk',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      title: 'Ort. cümle',
                      value: m.meanUtteranceLength.toStringAsFixed(1),
                      unit: 'kelime',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      title: 'Duygu',
                      value: m.sentiment >= 0.2
                          ? '🙂'
                          : m.sentiment <= -0.2
                              ? '😔'
                              : '😐',
                      unit: m.sentiment >= 0.2
                          ? 'olumlu'
                          : m.sentiment <= -0.2
                              ? 'olumsuz'
                              : 'nötr',
                    ),
                  ),
                ],
              ),

              if (m.difficultPhonemes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 20, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bu seansta zorlanılan sesler: '
                          '${m.difficultPhonemes.map((p) => '"$p"').join(", ")}. '
                          'Uzmanın paneline otomatik iletildi.',
                          style: const TextStyle(
                              fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => context.go('/child'),
                child: const Text('Ana sayfaya dön'),
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

class _RewardTile extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _RewardTile({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forScore(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 10),
          SizedBox(
            width: 138,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.inkSoft)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '%${(value * 100).round()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title, value, unit;
  const _MiniStat({
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          Text(unit,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}
