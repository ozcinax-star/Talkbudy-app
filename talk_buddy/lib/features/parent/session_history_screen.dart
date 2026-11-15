import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/stat_widgets.dart';

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    final sessions = ref.watch(sessionsProvider(child.id));

    final grouped = <String, List<Session>>{};
    for (final s in sessions) {
      final key = DateFormat('d MMMM yyyy', 'tr').format(s.startedAt);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Seans Geçmişi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            ...entry.value.map((s) => _HistoryCard(session: s)),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Session session;
  const _HistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final m = session.metrics;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScoreRing(value: m.overall, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.activity,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormat('HH:mm').format(session.startedAt)}'
                      ' · ${session.duration.inMinutes} dakika'
                      ' · ${m.totalWords} kelime',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              session.summary,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Mini(
                    label: 'Telaffuz',
                    value: m.articulation),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: _Mini(label: 'Akıcılık', value: m.fluency)),
              const SizedBox(width: 8),
              Expanded(
                  child: _Mini(label: 'Kelime', value: m.vocabulary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final double value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forScore(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.inkSoft)),
            const Spacer(),
            Text('%${(value * 100).round()}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
