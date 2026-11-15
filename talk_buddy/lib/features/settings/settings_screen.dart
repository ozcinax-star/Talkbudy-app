import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../data/services/settings_service.dart';
import 'widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StatusBanner(settings: s),
          const SizedBox(height: 20),

          const SettingsSectionTitle('Yapay Zeka'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.cloud_outlined,
                iconColor: AppColors.brand,
                title: 'Servis sağlayıcı',
                subtitle: s.provider.label,
                onTap: () => context.push('/settings/ai'),
              ),
              SettingsTile(
                icon: Icons.key_outlined,
                iconColor: AppColors.grape,
                title: 'API anahtarı',
                subtitle: s.provider == AiProvider.offline
                    ? 'Çevrimdışı modda gerekmez'
                    : (s.useProxy
                        ? 'Sunucu üzerinden yönetiliyor'
                        : (s.apiKey.isEmpty
                            ? 'Tanımlı değil'
                            : s.maskedKey)),
                trailing: s.provider != AiProvider.offline && !s.isConfigured
                    ? const StatusDot(color: AppColors.danger)
                    : null,
                onTap: () => context.push('/settings/ai'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const SettingsSectionTitle('Çocuk Profili'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.face_outlined,
                iconColor: AppColors.mint,
                title: 'Profil bilgileri',
                subtitle: '${s.childAvatar}  ${s.childName} · '
                    '${s.childAgeMonths ~/ 12} yaş ${s.childAgeMonths % 12} ay',
                onTap: () => context.push('/settings/child'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const SettingsSectionTitle('Konuşma ve Ses'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.graphic_eq_rounded,
                iconColor: AppColors.sky,
                title: 'Ses ve seans ayarları',
                subtitle: 'Konuşma hızı, ton, seans süresi',
                onTap: () => context.push('/settings/speech'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const SettingsSectionTitle('Gizlilik'),
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                icon: Icons.shield_outlined,
                iconColor: AppColors.success,
                title: 'Kişisel veri filtresi',
                subtitle:
                    'Telefon, adres ve kimlik bilgileri buluta gönderilmeden '
                    'maskelenir',
                value: s.redactPii,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).patch(redactPii: v),
              ),
              SettingsSwitchTile(
                icon: Icons.history_outlined,
                iconColor: AppColors.warning,
                title: 'Konuşma dökümünü sakla',
                subtitle: 'Kapatılırsa yalnızca sayısal metrikler kaydedilir',
                value: s.storeTranscripts,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .patch(storeTranscripts: v),
              ),
              SettingsTile(
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.danger,
                title: 'Tüm verileri sıfırla',
                subtitle: 'Ayarlar ve kayıtlı anahtar silinir',
                titleColor: AppColors.danger,
                onTap: () => _confirmReset(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const SettingsSectionTitle('Uygulama'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.swap_horiz_rounded,
                iconColor: AppColors.inkSoft,
                title: 'Rol değiştir',
                subtitle: 'Çocuk, ebeveyn veya uzman görünümü',
                onTap: () => context.go('/'),
              ),
              const SettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.inkSoft,
                title: 'Sürüm',
                subtitle: '0.9.0 (beta)',
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Talk Buddy bir tanı aracı değildir ve uzman değerlendirmesinin '
              'yerini almaz. Beta sürümünde veriler yalnızca bu cihazda tutulur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Tüm verileri sıfırla'),
        content: const Text(
          'Kayıtlı API anahtarı, profil ve tüm ayarlar silinecek. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    await ref.read(settingsProvider.notifier).resetAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm veriler sıfırlandı')),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final AppSettings settings;
  const _StatusBanner({required this.settings});

  @override
  Widget build(BuildContext context) {
    final offline = settings.provider == AiProvider.offline;
    final missing = settings.provider.needsKey && !settings.isConfigured;

    final (color, icon, title, body) = missing
        ? (
            AppColors.danger,
            Icons.error_outline_rounded,
            'Kurulum tamamlanmadı',
            '${settings.provider.label} seçili ancak API anahtarı girilmemiş. '
                'Konuşma seansları çevrimdışı yanıtlarla çalışır.',
          )
        : offline
            ? (
                AppColors.warning,
                Icons.wifi_off_rounded,
                'Çevrimdışı demo modu',
                'Hazır yanıtlarla çalışıyor. Gerçek yapay zeka için bir servis '
                    'sağlayıcı seçip anahtar girin.',
              )
            : (
                AppColors.success,
                Icons.check_circle_outline_rounded,
                'Bağlantı hazır',
                '${settings.provider.label} yapılandırıldı. '
                    'Seanslar gerçek yapay zeka ile çalışıyor.',
              );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.ink,
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
