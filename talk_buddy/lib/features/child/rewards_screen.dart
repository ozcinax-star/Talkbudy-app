import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/demo_data.dart';
import '../../data/repositories/providers.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    final earned = DemoData.badges.where((b) => b.$4).length;

    return Theme(
      data: AppTheme.child,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F4FF),
          automaticallyImplyLeading: false,
          title: const Text('Rozetlerim'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.lemon, Color(0xFFFF9F1C)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: kSoftShadow,
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 48)),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${child.stars}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Text(
                        'yıldız topladın!',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: kCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Sıradaki rozet: 30 Gün Seri',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${child.streakDays}/30',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.coral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: child.streakDays / 30,
                      minHeight: 12,
                      backgroundColor: AppColors.line,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.coral),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${30 - child.streakDays} gün daha konuşursan kazanacaksın!',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Tüm Rozetler',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '$earned / ${DemoData.badges.length}',
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: DemoData.badges.length,
              itemBuilder: (context, i) {
                final (emoji, title, desc, gotIt) = DemoData.badges[i];
                return Opacity(
                  opacity: gotIt ? 1 : 0.45,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: gotIt ? kCardShadow : null,
                      border: gotIt
                          ? null
                          : Border.all(color: AppColors.line, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(emoji,
                                style: const TextStyle(fontSize: 30)),
                            const Spacer(),
                            if (!gotIt)
                              const Icon(Icons.lock_rounded,
                                  size: 16, color: AppColors.inkSoft),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkSoft,
                              height: 1.25),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
