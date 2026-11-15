import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../data/services/speech_service.dart';
import 'widgets/settings_widgets.dart';

class SpeechSettingsScreen extends ConsumerStatefulWidget {
  const SpeechSettingsScreen({super.key});

  @override
  ConsumerState<SpeechSettingsScreen> createState() =>
      _SpeechSettingsScreenState();
}

class _SpeechSettingsScreenState extends ConsumerState<SpeechSettingsScreen> {
  SpeechStatus? _status;
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final st = await ref.read(speechServiceProvider).init();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = st;
    });
  }

  Future<void> _preview() async {
    final speech = ref.read(speechServiceProvider);
    await speech.speak(
      'Merhaba! Ben Buddy. Sesim böyle çıkıyor, beğendin mi?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ses ve Seans')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SettingsSectionTitle('Buddy sesi'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                SettingsSlider(
                  label: 'Konuşma hızı',
                  valueLabel: _rateLabel(s.speechRate),
                  value: s.speechRate,
                  min: 0.25,
                  max: 0.75,
                  divisions: 10,
                  onChanged: (v) => ctrl.patch(speechRate: v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SettingsSlider(
                  label: 'Ses tonu',
                  valueLabel: _pitchLabel(s.speechPitch),
                  value: s.speechPitch,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  onChanged: (v) => ctrl.patch(speechPitch: v),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _preview,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Sesi dinle'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const SettingsSectionTitle('Seans'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                SettingsSlider(
                  label: 'Seans süre sınırı',
                  valueLabel: '${s.sessionLimitMinutes} dakika',
                  value: s.sessionLimitMinutes.toDouble(),
                  min: 3,
                  max: 20,
                  divisions: 17,
                  onChanged: (v) =>
                      ctrl.patch(sessionLimitMinutes: v.round()),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SettingsSlider(
                  label: 'Sessizlik toleransı',
                  valueLabel: '${s.silenceTimeoutSeconds} saniye',
                  value: s.silenceTimeoutSeconds.toDouble(),
                  min: 3,
                  max: 12,
                  divisions: 9,
                  onChanged: (v) =>
                      ctrl.patch(silenceTimeoutSeconds: v.round()),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    'Çocuk bu süre boyunca sessiz kalırsa Buddy sorusunu '
                    'yeniden sorar.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const SettingsSectionTitle('Mikrofon durumu'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.mic_none_rounded,
                iconColor: _statusColor,
                title: 'Konuşma tanıma',
                subtitle: _statusText,
                trailing: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _checking ? null : _check,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Konuşma tanıma cihaz üzerinde çalışır; ses kaydı sunucuya '
              'gönderilmez. Türkçe paketi yüklü değilse Android ayarlarından '
              '"Ses girişi" bölümüne girip Türkçe dil paketini indirin.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor => switch (_status) {
        SpeechStatus.ready => AppColors.success,
        SpeechStatus.denied || SpeechStatus.error => AppColors.danger,
        SpeechStatus.unsupported => AppColors.warning,
        _ => AppColors.inkSoft,
      };

  String get _statusText => switch (_status) {
        SpeechStatus.ready => 'Hazır, Türkçe destekleniyor',
        SpeechStatus.denied => 'Mikrofon izni verilmedi',
        SpeechStatus.unsupported => 'Türkçe dil paketi bulunamadı',
        SpeechStatus.error => 'Başlatılamadı',
        _ => 'Kontrol etmek için dokunun',
      };

  String _rateLabel(double v) {
    if (v <= 0.33) return 'Çok yavaş';
    if (v <= 0.42) return 'Yavaş';
    if (v <= 0.52) return 'Normal';
    if (v <= 0.63) return 'Hızlı';
    return 'Çok hızlı';
  }

  String _pitchLabel(double v) {
    if (v <= 0.95) return 'Kalın';
    if (v <= 1.15) return 'Doğal';
    if (v <= 1.35) return 'Neşeli';
    return 'Çok ince';
  }
}
