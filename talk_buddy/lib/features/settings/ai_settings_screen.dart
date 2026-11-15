import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/settings_service.dart';
import '../../data/repositories/providers.dart';
import 'widgets/settings_widgets.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  late final TextEditingController _keyCtrl;
  late final TextEditingController _proxyCtrl;
  bool _obscure = true;
  bool _testing = false;
  ConnectionTest? _testResult;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _keyCtrl = TextEditingController(text: s.apiKey);
    _proxyCtrl = TextEditingController(text: s.proxyUrl);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _proxyCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    await ref.read(settingsProvider.notifier).patch(
          apiKey: _keyCtrl.text.trim(),
          proxyUrl: _proxyCtrl.text.trim(),
        );

    final service = AiService.from(ref.read(settingsProvider));
    final result = await service.testConnection();

    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Yapay Zeka Servisi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SettingsSectionTitle('Servis sağlayıcı'),
          ...AiProvider.values.map(
            (p) => _ProviderCard(
              provider: p,
              selected: s.provider == p,
              onTap: () {
                ctrl.patch(provider: p);
                setState(() => _testResult = null);
              },
            ),
          ),

          if (s.provider.needsKey) ...[
            const SizedBox(height: 22),
            const SettingsSectionTitle('Bağlantı yöntemi'),
            SettingsGroup(
              children: [
                SettingsSwitchTile(
                  icon: Icons.dns_outlined,
                  iconColor: AppColors.grape,
                  title: 'Kendi sunucum üzerinden bağlan',
                  subtitle:
                      'Anahtar cihazda tutulmaz. Yayına çıkarken önerilir.',
                  value: s.useProxy,
                  onChanged: (v) {
                    ctrl.patch(useProxy: v);
                    setState(() => _testResult = null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (s.useProxy)
              _Field(
                controller: _proxyCtrl,
                label: 'Sunucu adresi',
                hint: 'https://api.alanadiniz.com/v1',
                icon: Icons.link_rounded,
                keyboardType: TextInputType.url,
                onChanged: (v) => ctrl.patch(proxyUrl: v.trim()),
              )
            else ...[
              _Field(
                controller: _keyCtrl,
                label: '${s.provider.label} API anahtarı',
                hint: s.provider.keyHint,
                icon: Icons.key_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                onChanged: (v) {
                  ctrl.patch(apiKey: v.trim());
                  setState(() => _testResult = null);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 15,
                    color: AppColors.inkSoft,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Anahtar almak için: ${s.provider.consoleUrl}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: s.provider.consoleUrl),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adres kopyalandı')),
                      );
                    },
                    child: const Text('Kopyala'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _testing ? null : _test,
              icon: _testing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.wifi_tethering_rounded),
              label: Text(_testing ? 'Deneniyor...' : 'Bağlantıyı test et'),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 14),
              _TestResultCard(result: _testResult!),
            ],

            if (s.apiKey.isNotEmpty && !s.useProxy) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  await ctrl.removeApiKey();
                  _keyCtrl.clear();
                  if (mounted) setState(() => _testResult = null);
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                label: const Text('Kayıtlı anahtarı sil'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size(0, 48),
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.warning.withOpacity(0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Anahtar bu cihazda şifresiz saklanır. Uygulamayı mağazada '
                    'yayınlarken anahtarı cihaza gömmek yerine kendi sunucunuz '
                    'üzerinden bağlanmanız gerekir.',
                    style: TextStyle(fontSize: 12.5, height: 1.5),
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

class _ProviderCard extends StatelessWidget {
  final AiProvider provider;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (provider) {
      AiProvider.offline => AppColors.inkSoft,
      AiProvider.gemini => AppColors.sky,
      AiProvider.claude => AppColors.coral,
      AiProvider.openai => AppColors.mint,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  provider == AiProvider.offline
                      ? Icons.wifi_off_rounded
                      : Icons.auto_awesome_rounded,
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      provider.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.brand : AppColors.line,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffix,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TestResultCard extends StatelessWidget {
  final ConnectionTest result;
  const _TestResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.ok ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.ok
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.ok ? 'Başarılı' : 'Başarısız',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  result.message,
                  style: const TextStyle(fontSize: 12.5, height: 1.45),
                ),
                if (result.ok && result.latency > Duration.zero)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Yanıt süresi: ${result.latency.inMilliseconds} ms',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
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
