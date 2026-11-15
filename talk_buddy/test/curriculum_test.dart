import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talk_buddy/data/curriculum/answer_evaluator.dart';
import 'package:talk_buddy/data/curriculum/content_library.dart';
import 'package:talk_buddy/data/curriculum/curriculum_models.dart';
import 'package:talk_buddy/data/curriculum/dialogue_engine.dart';
import 'package:talk_buddy/data/curriculum/phonology.dart';
import 'package:talk_buddy/data/curriculum/progress_store.dart';

Exercise wordExercise(String word, {List<String> phonemes = const ['k']}) =>
    Exercise(
      templateId: 'test',
      type: ExerciseType.listenRepeat,
      domain: SkillDomain.articulation,
      prompt: 'Söyle: $word',
      targetWord: word,
      accepted: [word],
      targetPhonemes: phonemes,
    );

void main() {
  group('Türkçe fonoloji', () {
    test('gelişimsel ses değişimleri tanınır', () {
      const m = PhonologyMatcher(ageMonths: 44);

      final fronting = m.matchWord('tedi', 'kedi');
      expect(fronting.score, greaterThan(0.7));
      expect(fronting.processes, contains('fronting'));

      final gliding = m.matchWord('ayaba', 'araba');
      expect(gliding.score, greaterThan(0.7));
      expect(gliding.processes, contains('gliding'));

      final stopping = m.matchWord('tu', 'su');
      expect(stopping.processes, contains('stopping'));

      final cluster = m.matchWord('ten', 'tren');
      expect(cluster.processes, contains('clusterReduction'));

      final finalDel = m.matchWord('kita', 'kitap');
      expect(finalDel.processes, contains('finalDeletion'));
    });

    test('alakasız kelime eşleşmez', () {
      const m = PhonologyMatcher(ageMonths: 48);
      expect(m.matchWord('köpek', 'kedi').score, lessThan(0.45));
      expect(m.matchWord('kalem', 'araba').score, lessThan(0.45));
    });

    test('tam eşleşme işaretlenir', () {
      const m = PhonologyMatcher(ageMonths: 48);
      final r = m.matchWord('kedi', 'kedi');
      expect(r.exact, isTrue);
      expect(r.score, 1.0);
      expect(r.processes, isEmpty);
    });

    test('ek almış hâller köke indirgenir', () {
      const m = PhonologyMatcher(ageMonths: 48);
      expect(m.matchWord('arabayı', 'araba').score, greaterThan(0.8));
      expect(m.matchWord('kitaplar', 'kitap').score, greaterThan(0.8));
    });

    test('cümle içinden hedef kelime bulunur', () {
      const m = PhonologyMatcher(ageMonths: 48);
      final r = m.matchPhrase('bu bir kedi galiba', ['kedi']);
      expect(r.score, greaterThan(0.9));
    });

    test('edinim sırası yaşla artar', () {
      expect(TurkishPhonology.acquisitionOrder['p']!,
          lessThan(TurkishPhonology.acquisitionOrder['k']!));
      expect(TurkishPhonology.acquisitionOrder['k']!,
          lessThan(TurkishPhonology.acquisitionOrder['r']!));
    });
  });

  group('Cevap değerlendirme', () {
    test('telaffuz hatası bölümü engellemez', () {
      final e = AnswerEvaluator(ageMonths: 40, seed: 1);
      final r = e.evaluate(
        exercise: wordExercise('kedi'),
        heard: 'tedi',
        confidence: 0.55,
        attempt: 1,
      );
      expect(r.verdict, Verdict.pass);
      expect(r.processes, contains('fronting'));
    });

    test('sessizlik tekrar ister ve ipucu verir', () {
      final e = AnswerEvaluator(ageMonths: 44, seed: 2);
      final r = e.evaluate(
        exercise: wordExercise('kalem'),
        heard: '',
        confidence: 0,
        attempt: 1,
      );
      expect(r.verdict, Verdict.retry);
      expect(r.scaffold, isNotNull);
      expect(r.scaffold!.level, ScaffoldLevel.slowModel);
    });

    test('ikinci denemede ilk hece ipucu gelir', () {
      final e = AnswerEvaluator(ageMonths: 44, seed: 3);
      final r = e.evaluate(
        exercise: wordExercise('kalem'),
        heard: 'mmm',
        confidence: 0.2,
        attempt: 2,
      );
      expect(r.scaffold?.level, ScaffoldLevel.choices);
      expect(r.scaffold?.hint, startsWith('kal'));
    });

    test('üçüncü denemede asla başarısız sayılmaz', () {
      final e = AnswerEvaluator(ageMonths: 44, seed: 4);
      final r = e.evaluate(
        exercise: wordExercise('kalem'),
        heard: 'zzz',
        confidence: 0.1,
        attempt: 3,
      );
      expect(r.verdict, isNot(Verdict.retry));
    });

    test('üçüncü denemede birlikte söyleme ipucu verilir', () {
      final e = AnswerEvaluator(ageMonths: 44, seed: 8);
      final r = e.evaluate(
        exercise: wordExercise('kalem'),
        heard: 'zzz',
        confidence: 0.1,
        attempt: 3,
      );
      expect(r.scaffold, isNotNull);
      expect(r.scaffold!.level, ScaffoldLevel.together);
      expect(r.scaffold!.hint, 'kalem');
    });

    test('ipucu merdiveni sırayla yükselir', () {
      final e = AnswerEvaluator(ageMonths: 44, seed: 9);
      final ex = wordExercise('portakal');
      final levels = [
        for (var a = 1; a <= 3; a++)
          e
              .evaluate(exercise: ex, heard: '', confidence: 0, attempt: a)
              .scaffold
              ?.level,
      ];
      expect(levels, [
        ScaffoldLevel.slowModel,
        ScaffoldLevel.choices,
        ScaffoldLevel.together,
      ]);
    });

    test('açık uçlu soruda uzunluk yeterli', () {
      final e = AnswerEvaluator(ageMonths: 52, seed: 5);
      const open = Exercise(
        templateId: 'aq',
        type: ExerciseType.answerQuestion,
        domain: SkillDomain.pragmatics,
        prompt: 'Bugün seni ne mutlu etti?',
      );
      final r = e.evaluate(
        exercise: open,
        heard: 'bugün parka gittim çok eğlendim',
        confidence: 0.9,
        attempt: 1,
      );
      expect(r.verdict, Verdict.pass);
    });

    test('duygu sorusunda eş anlamlılar kabul edilir', () {
      final e = AnswerEvaluator(ageMonths: 52, seed: 6);
      const em = Exercise(
        templateId: 'em',
        type: ExerciseType.emotionMatch,
        domain: SkillDomain.pragmatics,
        prompt: 'Balonu patladı. Ne hissetti?',
        accepted: ['üzgün', 'üzüldü', 'kötü', 'ağladı'],
      );
      final r = e.evaluate(
        exercise: em,
        heard: 'çok üzüldü',
        confidence: 0.85,
        attempt: 1,
      );
      expect(r.verdict, Verdict.pass);
    });

    test('çoktan seçmeli ikinci hatada ilerletir', () {
      final e = AnswerEvaluator(ageMonths: 44, seed: 7);
      const ex = Exercise(
        templateId: 'cp',
        type: ExerciseType.choosePicture,
        domain: SkillDomain.auditory,
        prompt: 'Kediyi bul',
        options: ['🐱', '🐶'],
        correctOption: 0,
      );
      expect(e.evaluateChoice(exercise: ex, chosen: 0, attempt: 1).verdict,
          Verdict.pass);
      expect(e.evaluateChoice(exercise: ex, chosen: 1, attempt: 1).verdict,
          Verdict.retry);
      expect(e.evaluateChoice(exercise: ex, chosen: 1, attempt: 2).verdict,
          Verdict.partial);
    });
  });

  group('Diyalog motoru', () {
    GenerationContext ctx({int seed = 1, Map<String, PhonemeMastery>? m}) =>
        GenerationContext(
          childName: 'Elif',
          ageMonths: 52,
          seed: seed,
          mastery: m ?? const {},
        );

    test('ders istenen sayıda alıştırma üretir', () {
      final lesson = ContentLibrary.lessonById('u3l1')!;
      final ex = DialogueEngine(ctx: ctx()).buildLesson(lesson);
      expect(ex.length, lesson.exerciseCount);
      expect(ex.every((e) => e.prompt.isNotEmpty), isTrue);
    });

    test('farklı seed farklı içerik üretir', () {
      final lesson = ContentLibrary.lessonById('u3l1')!;
      final a = DialogueEngine(ctx: ctx(seed: 1)).buildLesson(lesson);
      final b = DialogueEngine(ctx: ctx(seed: 999)).buildLesson(lesson);
      final same = List.generate(a.length, (i) => a[i].prompt == b[i].prompt)
          .where((x) => x)
          .length;
      expect(same, lessThan(a.length));
    });

    test('aynı ders içinde kelime tekrarı olmaz', () {
      final lesson = ContentLibrary.lessonById('u1l1')!;
      final ex = DialogueEngine(ctx: ctx(seed: 42)).buildLesson(lesson);
      final words =
          ex.map((e) => e.targetWord).whereType<String>().toList();
      expect(words.toSet().length, words.length);
    });

    test('zayıf sesler daha sık seçilir', () {
      final weak = {
        'r': PhonemeMastery(
          phoneme: 'r',
          score: 0.15,
          box: 0,
          lastSeen: DateTime.now().subtract(const Duration(days: 10)),
          attempts: 6,
        ),
      };
      final lesson = ContentLibrary.lessonById('u7l2')!;
      final ex =
          DialogueEngine(ctx: ctx(seed: 7, m: weak)).buildLesson(lesson);
      final rCount =
          ex.where((e) => e.targetPhonemes.contains('r')).length;
      expect(rCount, greaterThan(0));
    });

    test('her şablon geçerli alıştırmaya dönüşür', () {
      final engine = DialogueEngine(ctx: ctx(seed: 3));
      for (final lesson in ContentLibrary.allLessons) {
        final ex = engine.buildLesson(lesson);
        expect(ex, isNotEmpty, reason: lesson.id);
        for (final e in ex) {
          expect(e.prompt.trim(), isNotEmpty, reason: '${lesson.id}/${e.templateId}');
          expect(e.prompt.contains('{'), isFalse,
              reason: 'doldurulmamış yuva: ${e.prompt}');
          if (!e.type.needsVoice) {
            expect(e.options.length, greaterThanOrEqualTo(2),
                reason: '${e.templateId} seçenek üretmedi');
            expect(e.correctOption, lessThan(e.options.length));
          }
        }
      }
    });

    test('kombinasyon havuzu yeterince geniş', () {
      expect(DialogueEngine.combinationCount(), greaterThan(1500));
    });
  });

  group('Müfredat yapısı', () {
    test('tüm dersler geçerli şablonlara işaret eder', () {
      for (final u in ContentLibrary.units) {
        for (final l in u.lessons) {
          expect(l.templateIds, isNotEmpty, reason: l.id);
          for (final t in l.templateIds) {
            expect(ContentLibrary.byId(t), isNotNull,
                reason: '${l.id} -> $t bulunamadı');
          }
        }
      }
    });

    test('ünite yaş sırası edinim sırasıyla uyumlu', () {
      final artic = ContentLibrary.units
          .where((u) => u.domain == SkillDomain.articulation)
          .toList();
      for (var i = 1; i < artic.length; i++) {
        expect(artic[i].minAgeMonths,
            greaterThanOrEqualTo(artic[i - 1].minAgeMonths),
            reason: '${artic[i].id} sıralaması bozuk');
      }
    });

    test('ders kimlikleri benzersiz', () {
      final ids = ContentLibrary.allLessons.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('İlerleme', () {
    LessonResult result({required bool good}) {
      final ex = wordExercise('kedi');
      return LessonResult(
        lessonId: 'u3l1',
        unitId: 'u3',
        duration: const Duration(minutes: 4),
        results: List.generate(
          5,
          (i) => ExerciseResult(
            exercise: ex,
            heardText: 'kedi',
            intelligibility: good ? 0.9 : 0.3,
            targetMatch: good ? 1 : 0.1,
            semanticMatch: good ? 1 : 0.1,
            verdict: good ? Verdict.pass : Verdict.retry,
            attempts: 1,
            feedback: '',
          ),
        ),
      );
    }

    test('başarılı ders geçer, başarısız geçmez', () {
      expect(result(good: true).passed, isTrue);
      expect(result(good: false).passed, isFalse);
    });

    test('ilk ünite açık, ikincisi kilitli', () {
      const p = LearnerProgress();
      expect(p.isUnitUnlocked(ContentLibrary.units.first), isTrue);
      expect(p.isUnitUnlocked(ContentLibrary.units[1]), isFalse);
    });

    test('ders tamamlanınca sonraki açılır', () {
      final unit = ContentLibrary.units.first;
      final p = LearnerProgress(
        lessons: {
          unit.lessons.first.id: LessonProgress(
            lessonId: unit.lessons.first.id,
            completions: 1,
            bestStars: 12,
          ),
        },
      );
      expect(p.isLessonUnlocked(unit, unit.lessons[1]), isTrue);
      expect(p.isLessonUnlocked(unit, unit.lessons[2]), isFalse);
    });

    test('sıradaki ders doğru bulunur', () {
      const p = LearnerProgress();
      expect(p.nextLesson?.id, ContentLibrary.units.first.lessons.first.id);
    });

    test('ustalık tek derste kazanılmaz, üç derste kazanılır', () {
      final store = ProgressStore(_FakePrefs());
      var p = const LearnerProgress();

      p = store.applyResult(p, result(good: true));
      expect(p.mastery['k']!.isMastered, isFalse,
          reason: 'tek ders ustalık için yetmemeli');

      p = store.applyResult(p, result(good: true));
      p = store.applyResult(p, result(good: true));
      expect(p.mastery['k']!.isMastered, isTrue);
      expect(p.mastery['k']!.box, greaterThanOrEqualTo(3));
    });

    test('fonolojik süreçler kalıcı kaydedilir', () {
      final store = ProgressStore(_FakePrefs());
      final ex = wordExercise('kedi');
      final res = LessonResult(
        lessonId: 'u3l1',
        unitId: 'u3',
        duration: const Duration(minutes: 4),
        results: List.generate(
          4,
          (_) => ExerciseResult(
            exercise: ex,
            heardText: 'tedi',
            intelligibility: 0.6,
            targetMatch: 0.9,
            semanticMatch: 0.6,
            verdict: Verdict.pass,
            attempts: 1,
            feedback: '',
            phonologicalProcesses: const ['fronting'],
          ),
        ),
      );

      final p = store.applyResult(const LearnerProgress(), res);
      expect(p.processes['fronting'], isNotNull);
      expect(p.processes['fronting']!.count, 4);
      expect(p.processes['fronting']!.lessons, 1);
      expect(p.topProcesses().first.meta?.label, 'Öne alma');
    });

    test('yaşa göre geç süreç işaretlenir', () {
      final rec = ProcessRecord(
        id: 'fronting',
        count: 5,
        lessons: 2,
        lastSeen: DateTime.now(),
      );
      expect(rec.isLateFor(36), isFalse);
      expect(rec.isLateFor(67), isTrue);
    });
  });
}

class _FakePrefs implements SharedPreferences {
  final Map<String, Object> _store = {};

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
