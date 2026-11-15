import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import 'widgets/settings_widgets.dart';

const _avatars = [
  '🐰', '🦊', '🐢', '🐥', '🦕', '🐨', '🐼', '🦉',
  '🐬', '🦁', '🐯', '🐸', '🐝', '🦄', '🐙', '🐧',
];

class ChildSettingsScreen extends ConsumerStatefulWidget {
  const ChildSettingsScreen({super.key});

  @override
  ConsumerState<ChildSettingsScreen> createState() =>
      _ChildSettingsScreenState();
}

class _ChildSettingsScreenState extends ConsumerState<ChildSettingsScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(settingsProvider).childName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final years = s.childAgeMonths ~/ 12;
    final months = s.childAgeMonths % 12;

    return Scaffold(
      appBar: AppBar(title: const Text('Çocuk Profili')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: Text(
                s.childAvatar,
                style: const TextStyle(fontSize: 44),
              ),
            ),
          ),
          const SizedBox(height: 22),

          const SettingsSectionTitle('Adı'),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Çocuğun adı',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
            onChanged: (v) => ctrl.patch(
              childName: v.trim().isEmpty ? 'Buddy Dostu' : v.trim(),
            ),
          ),

          const SizedBox(height: 22),
          const SettingsSectionTitle('Yaş'),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Yaş',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      months == 0 ? '$years yaş' : '$years yaş $months ay',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: s.childAgeMonths.toDouble().clamp(24, 108),
                  min: 24,
                  max: 108,
                  divisions: 84,
                  onChanged: (v) => ctrl.patch(childAgeMonths: v.round()),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: Text(
                    'Yaş bilgisi, konuşma hızı ve cümle uzunluğu ölçümlerinin '
                    'hangi norma göre değerlendirileceğini belirler.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const SettingsSectionTitle('Avatar'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _avatars.length,
              itemBuilder: (context, i) {
                final a = _avatars[i];
                final sel = a == s.childAvatar;
                return InkWell(
                  onTap: () => ctrl.patch(childAvatar: a),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.brandSoft : AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: sel
                          ? Border.all(color: AppColors.brand, width: 2)
                          : null,
                    ),
                    child: Text(a, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
