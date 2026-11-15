import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider { offline, gemini, claude, openai }

extension AiProviderX on AiProvider {
  String get id => name;

  String get label => switch (this) {
        AiProvider.offline => 'Çevrimdışı Demo',
        AiProvider.gemini => 'Google Gemini',
        AiProvider.claude => 'Anthropic Claude',
        AiProvider.openai => 'OpenAI',
      };

  String get description => switch (this) {
        AiProvider.offline =>
          'API anahtarı gerekmez. Hazır yanıtlarla çalışır, internet gerektirmez.',
        AiProvider.gemini =>
          'Ücretsiz kullanım kotası vardır. Düşük gecikme, Türkçe desteği iyi.',
        AiProvider.claude =>
          'Uzun bağlam ve tutarlı Türkçe. Kullanım başına ücretlendirilir.',
        AiProvider.openai =>
          'Yaygın kullanılan alternatif. Kullanım başına ücretlendirilir.',
      };

  String get keyHint => switch (this) {
        AiProvider.gemini => 'AIza ile başlar',
        AiProvider.claude => 'sk-ant- ile başlar',
        AiProvider.openai => 'sk- ile başlar',
        AiProvider.offline => '',
      };

  String get consoleUrl => switch (this) {
        AiProvider.gemini => 'aistudio.google.com/apikey',
        AiProvider.claude => 'console.anthropic.com',
        AiProvider.openai => 'platform.openai.com/api-keys',
        AiProvider.offline => '',
      };

  bool get needsKey => this != AiProvider.offline;

  static AiProvider parse(String? v) =>
      AiProvider.values.firstWhere((p) => p.id == v,
          orElse: () => AiProvider.offline);
}

@immutable
class AppSettings {
  final AiProvider provider;
  final String apiKey;
  final bool useProxy;
  final String proxyUrl;

  final double speechRate;
  final double speechPitch;
  final int sessionLimitMinutes;
  final int silenceTimeoutSeconds;

  final bool redactPii;
  final bool storeTranscripts;

  final String childName;
  final int childAgeMonths;
  final String childAvatar;

  const AppSettings({
    this.provider = AiProvider.offline,
    this.apiKey = '',
    this.useProxy = false,
    this.proxyUrl = '',
    this.speechRate = 0.44,
    this.speechPitch = 1.18,
    this.sessionLimitMinutes = 12,
    this.silenceTimeoutSeconds = 6,
    this.redactPii = true,
    this.storeTranscripts = true,
    this.childName = 'Elif',
    this.childAgeMonths = 52,
    this.childAvatar = '🐰',
  });

  bool get isConfigured =>
      provider == AiProvider.offline ||
      useProxy && proxyUrl.trim().isNotEmpty ||
      apiKey.trim().isNotEmpty;

  String get maskedKey {
    final k = apiKey.trim();
    if (k.isEmpty) return '';
    if (k.length <= 10) return '•' * k.length;
    return '${k.substring(0, 6)}${'•' * 12}${k.substring(k.length - 4)}';
  }

  Duration get sessionLimit => Duration(minutes: sessionLimitMinutes);
  Duration get silenceTimeout => Duration(seconds: silenceTimeoutSeconds);

  AppSettings copyWith({
    AiProvider? provider,
    String? apiKey,
    bool? useProxy,
    String? proxyUrl,
    double? speechRate,
    double? speechPitch,
    int? sessionLimitMinutes,
    int? silenceTimeoutSeconds,
    bool? redactPii,
    bool? storeTranscripts,
    String? childName,
    int? childAgeMonths,
    String? childAvatar,
  }) =>
      AppSettings(
        provider: provider ?? this.provider,
        apiKey: apiKey ?? this.apiKey,
        useProxy: useProxy ?? this.useProxy,
        proxyUrl: proxyUrl ?? this.proxyUrl,
        speechRate: speechRate ?? this.speechRate,
        speechPitch: speechPitch ?? this.speechPitch,
        sessionLimitMinutes: sessionLimitMinutes ?? this.sessionLimitMinutes,
        silenceTimeoutSeconds:
            silenceTimeoutSeconds ?? this.silenceTimeoutSeconds,
        redactPii: redactPii ?? this.redactPii,
        storeTranscripts: storeTranscripts ?? this.storeTranscripts,
        childName: childName ?? this.childName,
        childAgeMonths: childAgeMonths ?? this.childAgeMonths,
        childAvatar: childAvatar ?? this.childAvatar,
      );
}

class SettingsService {
  static const _kProvider = 'ai_provider';
  static const _kApiKey = 'ai_api_key';
  static const _kUseProxy = 'ai_use_proxy';
  static const _kProxyUrl = 'ai_proxy_url';
  static const _kRate = 'tts_rate';
  static const _kPitch = 'tts_pitch';
  static const _kLimit = 'session_limit';
  static const _kSilence = 'silence_timeout';
  static const _kRedact = 'redact_pii';
  static const _kStore = 'store_transcripts';
  static const _kName = 'child_name';
  static const _kAge = 'child_age_months';
  static const _kAvatar = 'child_avatar';

  final SharedPreferences _prefs;
  SettingsService(this._prefs);

  static Future<SettingsService> create() async =>
      SettingsService(await SharedPreferences.getInstance());

  AppSettings load() {
    const d = AppSettings();
    return AppSettings(
      provider: AiProviderX.parse(_prefs.getString(_kProvider)),
      apiKey: _prefs.getString(_kApiKey) ?? '',
      useProxy: _prefs.getBool(_kUseProxy) ?? d.useProxy,
      proxyUrl: _prefs.getString(_kProxyUrl) ?? '',
      speechRate: _prefs.getDouble(_kRate) ?? d.speechRate,
      speechPitch: _prefs.getDouble(_kPitch) ?? d.speechPitch,
      sessionLimitMinutes: _prefs.getInt(_kLimit) ?? d.sessionLimitMinutes,
      silenceTimeoutSeconds:
          _prefs.getInt(_kSilence) ?? d.silenceTimeoutSeconds,
      redactPii: _prefs.getBool(_kRedact) ?? d.redactPii,
      storeTranscripts: _prefs.getBool(_kStore) ?? d.storeTranscripts,
      childName: _prefs.getString(_kName) ?? d.childName,
      childAgeMonths: _prefs.getInt(_kAge) ?? d.childAgeMonths,
      childAvatar: _prefs.getString(_kAvatar) ?? d.childAvatar,
    );
  }

  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setString(_kProvider, s.provider.id),
      _prefs.setString(_kApiKey, s.apiKey),
      _prefs.setBool(_kUseProxy, s.useProxy),
      _prefs.setString(_kProxyUrl, s.proxyUrl),
      _prefs.setDouble(_kRate, s.speechRate),
      _prefs.setDouble(_kPitch, s.speechPitch),
      _prefs.setInt(_kLimit, s.sessionLimitMinutes),
      _prefs.setInt(_kSilence, s.silenceTimeoutSeconds),
      _prefs.setBool(_kRedact, s.redactPii),
      _prefs.setBool(_kStore, s.storeTranscripts),
      _prefs.setString(_kName, s.childName),
      _prefs.setInt(_kAge, s.childAgeMonths),
      _prefs.setString(_kAvatar, s.childAvatar),
    ]);
  }

  Future<void> clearApiKey() => _prefs.remove(_kApiKey);

  Future<void> clearAll() => _prefs.clear();
}
