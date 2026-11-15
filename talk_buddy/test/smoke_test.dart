import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talk_buddy/data/models/models.dart';
import 'package:talk_buddy/data/services/settings_service.dart';
import 'package:talk_buddy/data/services/speech_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    test('varsayilan degerler cevrimdisi moddur', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = await SettingsService.create();
      final s = svc.load();

      expect(s.provider, AiProvider.offline);
      expect(s.apiKey, isEmpty);
      expect(s.isConfigured, isTrue);
      expect(s.sessionLimitMinutes, 12);
    });

    test('kaydedilen ayarlar geri okunur', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = await SettingsService.create();

      await svc.save(
        const AppSettings(
          provider: AiProvider.gemini,
          apiKey: 'AIzaTESTKEY0123456789',
          childName: 'Kerem',
          childAgeMonths: 41,
          sessionLimitMinutes: 8,
        ),
      );

      final s = svc.load();
      expect(s.provider, AiProvider.gemini);
      expect(s.childName, 'Kerem');
      expect(s.sessionLimitMinutes, 8);
      expect(s.isConfigured, isTrue);
    });

    test('anahtar maskeleme son 4 haneyi birakir', () {
      const s = AppSettings(apiKey: 'AIzaSyABCDEFGHIJKLMNOP1234');
      expect(s.maskedKey.startsWith('AIzaSy'), isTrue);
      expect(s.maskedKey.endsWith('1234'), isTrue);
      expect(s.maskedKey.contains('GHIJ'), isFalse);
    });

    test('anahtarsiz bulut saglayici yapilandirilmamis sayilir', () {
      const s = AppSettings(provider: AiProvider.gemini, apiKey: '');
      expect(s.isConfigured, isFalse);
    });
  });

  group('SpeechAnalyzer', () {
    final analyzer = SpeechAnalyzer();

    ChatTurn child(String text, double conf) => ChatTurn(
          speaker: Speaker.child,
          text: text,
          at: DateTime.now(),
          confidence: conf,
        );

    test('bos seans sifir metrik dondurur', () {
      final m = analyzer.analyze(
        turns: const [],
        duration: const Duration(minutes: 1),
        ageMonths: 48,
      );
      expect(m.totalWords, 0);
      expect(m.overall, 0);
    });

    test('kelime sayisi ve hiz hesaplanir', () {
      final m = analyzer.analyze(
        turns: [
          child('bugun parka gittik ve kaydiraktan kaydim', 0.9),
          child('sonra salincakla oynadim cok mutlu oldum', 0.85),
        ],
        duration: const Duration(minutes: 1),
        ageMonths: 52,
      );

      expect(m.totalWords, 13);
      expect(m.wordsPerMinute, closeTo(13, 0.5));
      expect(m.meanUtteranceLength, closeTo(6.5, 0.1));
      expect(m.articulation, closeTo(0.875, 0.01));
    });

    test('dusuk guvenli turlarda zorlanilan sesler isaretlenir', () {
      final m = analyzer.analyze(
        turns: [
          child('rrr kar sar rar', 0.4),
          child('ras kir sor rir', 0.35),
        ],
        duration: const Duration(minutes: 1),
        ageMonths: 48,
      );
      expect(m.difficultPhonemes, isNotEmpty);
      expect(m.difficultPhonemes.contains('r'), isTrue);
    });

    test('tekrar akiciligi dusurur', () {
      final tekrarli = analyzer.analyze(
        turns: [child('ben ben ben ben okula okula gittim', 0.9)],
        duration: const Duration(seconds: 6),
        ageMonths: 52,
      );
      final duzgun = analyzer.analyze(
        turns: [child('ben bugun okula yuruyerek gittim ve arkadasimi', 0.9)],
        duration: const Duration(seconds: 6),
        ageMonths: 52,
      );
      expect(tekrarli.fluency, lessThan(duzgun.fluency));
    });

    test('yas normlari artan sirada', () {
      expect(SpeechAnalyzer.expectedMlu(30), lessThan(SpeechAnalyzer.expectedMlu(48)));
      expect(SpeechAnalyzer.expectedMlu(48), lessThan(SpeechAnalyzer.expectedMlu(72)));
      final (min3, max3) = SpeechAnalyzer.expectedWpm(36);
      expect(min3, lessThan(max3));
    });
  });

  group('Redactor', () {
    test('telefon numarasi maskelenir', () {
      final out = Redactor.scrub('annemin numarasi 0532 111 22 33 diyor');
      expect(out.contains('0532'), isFalse);
      expect(out.contains('[telefon]'), isTrue);
    });

    test('kimlik numarasi maskelenir', () {
      final out = Redactor.scrub('kimlik 12345678901 olarak yazili');
      expect(out.contains('[kimlik]'), isTrue);
    });

    test('adres ifadeleri maskelenir', () {
      final out = Redactor.scrub('Bahce sokak numarasi burada');
      expect(out.contains('[adres]'), isTrue);
    });

    test('temiz metin degismeden gecer', () {
      const t = 'bugun parka gittik ve cok eglendik';
      expect(Redactor.scrub(t), t);
      expect(Redactor.containsPii(t), isFalse);
    });
  });

  group('ChildProfile', () {
    test('yas etiketi dogru bicimlenir', () {
      ChildProfile p(int months) => ChildProfile(
            id: 'x',
            name: 'Test',
            ageMonths: months,
            avatar: '🐰',
            createdAt: DateTime(2026),
          );

      expect(p(52).ageLabel, '4 yaş 4 ay');
      expect(p(48).ageLabel, '4 yaş');
      expect(p(11).ageLabel, '11 aylık');
    });
  });

  group('SpeechMetrics', () {
    test('genel skor agirlikli ortalamadir', () {
      const m = SpeechMetrics(
        articulation: 1.0,
        fluency: 0.5,
        vocabulary: 0.0,
        wordsPerMinute: 80,
        meanUtteranceLength: 4,
        sentiment: 0,
        totalWords: 100,
      );
      expect(m.overall, closeTo(0.4 + 0.15, 0.001));
    });

    test('json donusumu kayipsiz', () {
      const m = SpeechMetrics(
        articulation: 0.71,
        fluency: 0.64,
        vocabulary: 0.58,
        wordsPerMinute: 78,
        meanUtteranceLength: 4.2,
        sentiment: 0.3,
        totalWords: 86,
        difficultPhonemes: ['r', 'ş'],
      );
      final back = SpeechMetrics.fromJson(m.toJson());
      expect(back.articulation, m.articulation);
      expect(back.difficultPhonemes, m.difficultPhonemes);
      expect(back.totalWords, m.totalWords);
    });
  });
}
