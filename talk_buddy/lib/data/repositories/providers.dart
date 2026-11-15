import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../services/speech_analyzer.dart';
import '../services/speech_service.dart';
import 'demo_data.dart';

final settingsServiceProvider = Provider<SettingsService>(
  (_) => throw UnimplementedError('main() içinde override edilir'),
);

class SettingsController extends StateNotifier<AppSettings> {
  final SettingsService _service;
  SettingsController(this._service) : super(_service.load());

  Future<void> update(AppSettings next) async {
    state = next;
    await _service.save(next);
  }

  Future<void> patch({
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
      update(
        state.copyWith(
          provider: provider,
          apiKey: apiKey,
          useProxy: useProxy,
          proxyUrl: proxyUrl,
          speechRate: speechRate,
          speechPitch: speechPitch,
          sessionLimitMinutes: sessionLimitMinutes,
          silenceTimeoutSeconds: silenceTimeoutSeconds,
          redactPii: redactPii,
          storeTranscripts: storeTranscripts,
          childName: childName,
          childAgeMonths: childAgeMonths,
          childAvatar: childAvatar,
        ),
      );

  Future<void> removeApiKey() async {
    await _service.clearApiKey();
    state = state.copyWith(apiKey: '', provider: AiProvider.offline);
    await _service.save(state);
  }

  Future<void> resetAll() async {
    await _service.clearAll();
    state = const AppSettings();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(ref.watch(settingsServiceProvider)),
);

final aiServiceProvider = Provider<AiService>(
  (ref) => AiService.from(ref.watch(settingsProvider)),
);

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService()..applySettings(ref.read(settingsProvider));
  ref.listen<AppSettings>(
    settingsProvider,
    (_, next) => service.applySettings(next),
  );
  ref.onDispose(service.dispose);
  return service;
});

final analyzerProvider = Provider<SpeechAnalyzer>((_) => SpeechAnalyzer());

final roleProvider = StateProvider<AppRole?>((_) => null);

final activeChildProvider = Provider<ChildProfile>((ref) {
  final s = ref.watch(settingsProvider);
  return DemoData.activeChild.copyWith(
    name: s.childName,
    ageMonths: s.childAgeMonths,
    avatar: s.childAvatar,
  );
});

final childrenProvider = Provider<List<ChildProfile>>((ref) {
  final active = ref.watch(activeChildProvider);
  return [
    active,
    ...DemoData.children.where((c) => c.id != active.id),
  ];
});

final trendProvider =
    Provider.family<List<DailyPoint>, ({String childId, int days})>(
  (ref, arg) => DemoData.trend(arg.childId, days: arg.days),
);

final metricsProvider = Provider.family<SpeechMetrics, String>(
  (ref, childId) => DemoData.latestMetrics(childId),
);

final sessionsProvider = Provider.family<List<Session>, String>(
  (ref, childId) => DemoData.sessions(childId),
);

final alertsProvider = Provider<List<SpecialistAlert>>((_) => DemoData.alerts());

final activitiesProvider = Provider<List<Activity>>((_) => DemoData.activities);

final rangeProvider = StateProvider<int>((_) => 30);
