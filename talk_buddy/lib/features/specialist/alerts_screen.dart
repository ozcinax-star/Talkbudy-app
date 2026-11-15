import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../shared/widgets/stat_widgets.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final urgent = alerts.where((a) => a.level == AlertLevel.urgent).toList();
    final watch = alerts.where((a) => a.level == AlertLevel.watch).toList();
    final info = alerts.where((a) => a.level == AlertLevel.info).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Uyarılar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.error_outline_rounded,
                  label: 'Acil',
                  value: '${urgent.length}',
                  unit: 'bekliyor',
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.visibility_outlined,
                  label: 'İzlemede',
                  value: '${watch.length}',
                  unit: 'danışan',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.info_outline_rounded,
                  label: 'Bilgi',
                  value: '${info.length}',
                  unit: 'not',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (urgent.isNotEmpty) ...[
            const SectionHeader(title: 'Acil'),
            const SizedBox(height: 10),
            ...urgent.map((a) => AlertCard(alert: a)),
            const SizedBox(height: 18),
          ],
          if (watch.isNotEmpty) ...[
            const SectionHeader(title: 'İzlemede'),
            const SizedBox(height: 10),
            ...watch.map((a) => AlertCard(alert: a)),
            const SizedBox(height: 18),
          ],
          if (info.isNotEmpty) ...[
            const SectionHeader(title: 'Bilgi'),
            const SizedBox(height: 10),
            ...info.map((a) => AlertCard(alert: a)),
          ],
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final SpecialistAlert alert;
  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (alert.level) {
      AlertLevel.urgent => (AppColors.danger, Icons.error_outline_rounded),
      AlertLevel.watch => (AppColors.warning, Icons.visibility_outlined),
      AlertLevel.info => (AppColors.info, Icons.info_outline_rounded),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push('/specialist/child/${alert.childId}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          alert.childName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _ago(alert.at),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: const TextStyle(fontSize: 13, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    if (d.inHours < 24) return '${d.inHours} sa önce';
    return '${d.inDays} gün önce';
  }
}
