class BuildConfig {
  BuildConfig._();

  static const String appName = 'Talk Buddy';
  static const String versionName = '0.9.0';
  static const String channel = 'beta';

  static const String sttLocale = 'tr_TR';
  static const String ttsLanguage = 'tr-TR';

  static const String defaultProxyBaseUrl =
      String.fromEnvironment('PROXY_BASE_URL');

  static const String seedApiKey = String.fromEnvironment('AI_API_KEY');
  static const String seedProvider =
      String.fromEnvironment('AI_PROVIDER', defaultValue: 'offline');

  static const int minSessionMinutes = 3;
  static const int maxSessionMinutes = 20;
  static const int minChildAgeMonths = 24;
  static const int maxChildAgeMonths = 108;
}
