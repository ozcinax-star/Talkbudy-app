import 'dart:math' as math;

import 'curriculum_models.dart';
import 'phonology.dart';

enum ScaffoldLevel { none, slowModel, choices, together }

class ScaffoldStep {
  final ScaffoldLevel level;
  final String instruction;
  final List<String> choices;
  final String? hint;

  const ScaffoldStep({
    required this.level,
    required this.instruction,
    this.choices = const [],
    this.hint,
  });
}

class Evaluation {
  final Verdict verdict;
  final double intelligibility;
  final double targetMatch;
  final double semanticMatch;
  final List<String> processes;
  final String feedback;
  final ScaffoldStep? scaffold;

  const Evaluation({
    required this.verdict,
    required this.intelligibility,
    required this.targetMatch,
    required this.semanticMatch,
    required this.feedback,
    this.processes = const [],
    this.scaffold,
  });
}

class AnswerEvaluator {
  final int ageMonths;
  final math.Random _rnd;

  AnswerEvaluator({required this.ageMonths, int? seed})
      : _rnd = math.Random(seed);

  late final PhonologyMatcher _matcher = PhonologyMatcher(ageMonths: ageMonths);

  static const _minWordsForOpenEnded = 2;

  Evaluation evaluate({
    required Exercise exercise,
    required String heard,
    required double confidence,
    required int attempt,
  }) {
    final text = TurkishPhonology.normalize(heard);

    if (text.isEmpty) {
      return Evaluation(
        verdict: Verdict.retry,
        intelligibility: 0,
        targetMatch: 0,
        semanticMatch: 0,
        feedback: _pick(_silenceFeedback),
        scaffold: _scaffoldFor(exercise, attempt),
      );
    }

    final targets = <String>[
      if (exercise.targetWord != null) exercise.targetWord!,
      ...exercise.accepted,
    ];

    final match = targets.isEmpty
        ? WordMatch.none
        : _matcher.matchPhrase(text, targets);

    final semantic = _semanticScore(exercise, text);
    final intelligibility = _intelligibility(confidence, match, text);

    final verdict = _decide(
      exercise: exercise,
      targetMatch: match.score,
      semantic: semantic,
      attempt: attempt,
      wordCount: TurkishPhonology.tokenize(text).length,
    );

    return Evaluation(
      verdict: verdict,
      intelligibility: intelligibility,
      targetMatch: match.score,
      semanticMatch: semantic,
      processes: match.score >= 0.5 ? match.processes : const [],
      feedback: _feedback(exercise, verdict, match, text),
      scaffold: verdict == Verdict.retry
          ? _scaffoldFor(exercise, attempt)
          : (attempt >= 3 && exercise.targetWord != null
              ? _scaffoldFor(exercise, 3)
              : null),
    );
  }

  Evaluation evaluateChoice({
    required Exercise exercise,
    required int chosen,
    required int attempt,
  }) {
    final correct = chosen == exercise.correctOption;
    return Evaluation(
      verdict: correct
          ? Verdict.pass
          : (attempt >= 2 ? Verdict.partial : Verdict.retry),
      intelligibility: 1,
      targetMatch: correct ? 1 : 0,
      semanticMatch: correct ? 1 : 0,
      feedback: correct
          ? _pick(_correctChoice)
          : (attempt >= 2
              ? 'Doğrusu bu. Şimdi birlikte bakalım.'
              : _pick(_wrongChoice)),
      scaffold: correct || attempt >= 2
          ? null
          : const ScaffoldStep(
              level: ScaffoldLevel.slowModel,
              instruction: 'Bir daha dinleyelim, kulağını ver.',
            ),
    );
  }

  Verdict _decide({
    required Exercise exercise,
    required double targetMatch,
    required double semantic,
    required int attempt,
    required int wordCount,
  }) {
    if (attempt >= 3) {
      return targetMatch >= 0.35 || semantic >= 0.3
          ? Verdict.partial
          : Verdict.partial;
    }

    if (exercise.type.isOpenEnded) {
      if (wordCount >= _minWordsForOpenEnded && semantic >= 0.45) {
        return Verdict.pass;
      }
      if (wordCount >= 1 && semantic >= 0.2) return Verdict.partial;
      if (wordCount >= 3) return Verdict.partial;
      return Verdict.retry;
    }

    if (targetMatch >= 0.7 || semantic >= 0.6) return Verdict.pass;
    if (targetMatch >= 0.45 || semantic >= 0.35) return Verdict.partial;
    return Verdict.retry;
  }

  double _intelligibility(double confidence, WordMatch match, String text) {
    if (confidence <= 0) {
      return match.exact ? 0.85 : (match.score * 0.8).clamp(0.0, 0.9);
    }
    final blended = confidence * 0.65 + match.score * 0.35;
    return blended.clamp(0.0, 1.0);
  }

  double _semanticScore(Exercise exercise, String text) {
    final words = TurkishPhonology.tokenize(text).map(TurkishPhonology.stem).toSet();
    if (words.isEmpty) return 0;

    if (exercise.accepted.isEmpty && exercise.targetWord == null) {
      final n = words.length;
      if (n >= 5) return 0.75;
      if (n >= 3) return 0.6;
      if (n >= 2) return 0.45;
      return 0.25;
    }

    final accepted = <String>{
      if (exercise.targetWord != null)
        ...TurkishPhonology.tokenize(exercise.targetWord!).map(TurkishPhonology.stem),
      for (final a in exercise.accepted)
        ...TurkishPhonology.tokenize(a).map(TurkishPhonology.stem),
    };

    if (accepted.isEmpty) return 0.4;

    final hits = words.where(accepted.contains).length;
    if (hits > 0) return math.min(1.0, 0.55 + hits * 0.2);

    var fuzzy = 0.0;
    for (final w in words) {
      for (final a in accepted) {
        fuzzy = math.max(fuzzy, TurkishPhonology.similarity(w, a));
      }
    }
    if (fuzzy >= 0.75) return 0.5;
    if (fuzzy >= 0.6) return 0.35;

    return words.length >= 3 ? 0.3 : 0.12;
  }

  ScaffoldStep _scaffoldFor(Exercise exercise, int attempt) {
    if (attempt <= 1) {
      return ScaffoldStep(
        level: ScaffoldLevel.slowModel,
        instruction: exercise.targetWord != null
            ? 'Yavaşça tekrar söyleyeyim, sonra sen dene.'
            : 'Acele yok, bir daha deneyelim.',
        hint: exercise.targetWord,
      );
    }

    if (attempt == 2) {
      final target = exercise.targetWord;
      if (target != null && target.length >= 3) {
        return ScaffoldStep(
          level: ScaffoldLevel.choices,
          instruction: 'İpucu vereyim mi? İlk hecesi şöyle:',
          hint: _firstSyllable(target),
        );
      }
      return const ScaffoldStep(
        level: ScaffoldLevel.choices,
        instruction: 'Tek kelime bile olur, aklına ilk geleni söyle.',
      );
    }

    return ScaffoldStep(
      level: ScaffoldLevel.together,
      instruction: 'Hadi birlikte söyleyelim!',
      hint: exercise.targetWord,
    );
  }

  static String _firstSyllable(String word) {
    final w = TurkishPhonology.normalize(word);
    var seenVowel = false;
    for (var i = 0; i < w.length; i++) {
      if (TurkishPhonology.isVowel(w[i])) {
        seenVowel = true;
      } else if (seenVowel) {
        return '${w.substring(0, i + 1)}...';
      }
    }
    return '${w.isEmpty ? '' : w[0]}...';
  }

  String _feedback(
    Exercise exercise,
    Verdict verdict,
    WordMatch match,
    String text,
  ) {
    switch (verdict) {
      case Verdict.pass:
        if (match.exact && exercise.targetWord != null) {
          return _fill(_pick(_exactPraise), exercise.targetWord!);
        }
        if (match.processes.isNotEmpty && exercise.targetWord != null) {
          return _fill(_pick(_shapingPraise), exercise.targetWord!);
        }
        return _pick(_generalPraise);

      case Verdict.partial:
        if (exercise.targetWord != null) {
          return _fill(_pick(_partialPraise), exercise.targetWord!);
        }
        return _pick(_partialOpen);

      case Verdict.retry:
        return _pick(_retryFeedback);
    }
  }

  String _fill(String template, String word) =>
      template.replaceAll('{kelime}', word);

  String _pick(List<String> pool) => pool[_rnd.nextInt(pool.length)];

  static const _exactPraise = [
    '"{kelime}" kelimesini çok net söyledin!',
    'Tam istediğim gibi: "{kelime}". Harikasın!',
    'Bunu duyunca çok mutlu oldum. "{kelime}" mükemmeldi.',
    'Vay canına, "{kelime}" pırıl pırıl çıktı!',
    'İşte bu! "{kelime}" tam yerinde.',
  ];

  static const _shapingPraise = [
    'Çok yaklaştın! Benim söyleyişim şöyle: "{kelime}". Sen de çok güzel dedin.',
    'Neredeyse aynısı! Kulağıma "{kelime}" gibi geldi, aferin.',
    'Güzel denedin. Ben "{kelime}" diyorum, sen de gittikçe yaklaşıyorsun.',
    'Bunu duydum ve beğendim. "{kelime}" böyle söyleniyor, sen de çok iyisin.',
  ];

  static const _generalPraise = [
    'Bunu çok güzel anlattın!',
    'Harika bir cevap, seni dinlemek keyifli.',
    'Aklına gelenleri söylemen çok hoşuma gitti.',
    'Bravo, tam olması gerektiği gibi.',
    'Çok güzel düşünmüşsün!',
  ];

  static const _partialPraise = [
    'Güzel deneme! "{kelime}" biraz zor, ama sen cesurca söyledin.',
    'Sesini duydum ve bu çok değerli. "{kelime}" böyle söyleniyor.',
    'Denemen bile büyük iş. Beraber tekrar edelim: "{kelime}".',
    'İyi gidiyorsun, "{kelime}" yavaş yavaş oturuyor.',
  ];

  static const _partialOpen = [
    'Söylediklerin güzeldi. Biraz daha anlatmak ister misin?',
    'Seni duydum, teşekkür ederim. Devam edelim.',
    'Güzel başladın. Bir dahakine biraz daha uzun anlat.',
  ];

  static const _retryFeedback = [
    'Bir daha deneyelim, acelemiz yok.',
    'Buradayım, seni bekliyorum. Tekrar dener misin?',
    'Hiç sorun değil, birlikte tekrar bakalım.',
    'Dene bakalım, ben yanındayım.',
  ];

  static const _silenceFeedback = [
    'Seni duyamadım. Biraz daha yüksek sesle söyler misin?',
    'Sessiz kaldın galiba. Hazır olduğunda başlayalım.',
    'Mikrofonuma yakın konuşursan seni daha iyi duyarım.',
  ];

  static const _correctChoice = [
    'Doğru! Kulakların çok keskin.',
    'Evet, tam olarak bu!',
    'Bildin! Çok iyi dinledin.',
    'Harika, doğru olanı seçtin.',
  ];

  static const _wrongChoice = [
    'Bu değildi ama iyi denedin. Bir daha dinleyelim mi?',
    'Yaklaştın. Tekrar dinleyip deneyelim.',
    'Olsun, bir kere daha bakalım.',
  ];
}
