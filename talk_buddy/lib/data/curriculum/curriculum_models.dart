import 'package:flutter/foundation.dart';

enum SkillDomain {
  articulation,
  auditory,
  vocabulary,
  syntax,
  narrative,
  pragmatics,
}

extension SkillDomainX on SkillDomain {
  String get label => switch (this) {
        SkillDomain.articulation => 'Sesletim',
        SkillDomain.auditory => 'İşitsel Ayırt Etme',
        SkillDomain.vocabulary => 'Kelime Dağarcığı',
        SkillDomain.syntax => 'Cümle Yapısı',
        SkillDomain.narrative => 'Anlatı',
        SkillDomain.pragmatics => 'Sosyal İletişim',
      };

  String get emoji => switch (this) {
        SkillDomain.articulation => '🗣️',
        SkillDomain.auditory => '👂',
        SkillDomain.vocabulary => '📚',
        SkillDomain.syntax => '🧩',
        SkillDomain.narrative => '📖',
        SkillDomain.pragmatics => '💛',
      };
}

enum ExerciseType {
  listenRepeat,
  namePicture,
  choosePicture,
  minimalPair,
  answerQuestion,
  completeSentence,
  retellStory,
  emotionMatch,
  tongueTwister,
}

extension ExerciseTypeX on ExerciseType {
  String get label => switch (this) {
        ExerciseType.listenRepeat => 'Dinle ve Tekrarla',
        ExerciseType.namePicture => 'Bu Ne?',
        ExerciseType.choosePicture => 'Doğrusunu Seç',
        ExerciseType.minimalPair => 'Hangisi?',
        ExerciseType.answerQuestion => 'Sohbet',
        ExerciseType.completeSentence => 'Cümleyi Tamamla',
        ExerciseType.retellStory => 'Hikâyeyi Anlat',
        ExerciseType.emotionMatch => 'Ne Hissetti?',
        ExerciseType.tongueTwister => 'Tekerleme',
      };

  bool get needsVoice => switch (this) {
        ExerciseType.choosePicture || ExerciseType.minimalPair => false,
        _ => true,
      };

  bool get isOpenEnded => switch (this) {
        ExerciseType.answerQuestion ||
        ExerciseType.retellStory ||
        ExerciseType.emotionMatch =>
          true,
        _ => false,
      };
}

@immutable
class SlotFill {
  final String key;
  final List<String> values;
  const SlotFill(this.key, this.values);
}

@immutable
class ExerciseTemplate {
  final String id;
  final ExerciseType type;
  final SkillDomain domain;

  final List<String> targetPhonemes;

  final List<String> prompts;

  final List<SlotFill> slots;

  final List<String> targetWords;

  final List<String> acceptAlso;

  final List<String> options;

  final int correctOption;

  final String emoji;

  final int difficulty;

  final List<String> encouragements;

  const ExerciseTemplate({
    required this.id,
    required this.type,
    required this.domain,
    required this.prompts,
    this.targetPhonemes = const [],
    this.slots = const [],
    this.targetWords = const [],
    this.acceptAlso = const [],
    this.options = const [],
    this.correctOption = 0,
    this.emoji = '',
    this.difficulty = 1,
    this.encouragements = const [],
  });
}

@immutable
class Exercise {
  final String templateId;
  final ExerciseType type;
  final SkillDomain domain;

  final String prompt;

  final String? targetWord;

  final List<String> accepted;

  final List<String> options;
  final int correctOption;

  final String emoji;
  final List<String> targetPhonemes;
  final int difficulty;

  const Exercise({
    required this.templateId,
    required this.type,
    required this.domain,
    required this.prompt,
    this.targetWord,
    this.accepted = const [],
    this.options = const [],
    this.correctOption = 0,
    this.emoji = '',
    this.targetPhonemes = const [],
    this.difficulty = 1,
  });

  String get spokenPrompt => prompt;
}

@immutable
class Lesson {
  final String id;
  final String unitId;
  final String title;
  final int index;
  final List<String> templateIds;
  final int exerciseCount;

  const Lesson({
    required this.id,
    required this.unitId,
    required this.title,
    required this.index,
    required this.templateIds,
    this.exerciseCount = 6,
  });
}

@immutable
class Unit {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final int colorValue;
  final SkillDomain domain;
  final List<String> targetPhonemes;

  final int minAgeMonths;

  final List<Lesson> lessons;

  const Unit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colorValue,
    required this.domain,
    required this.lessons,
    this.targetPhonemes = const [],
    this.minAgeMonths = 24,
  });
}

enum Verdict { pass, partial, retry }

extension VerdictX on Verdict {
  bool get advances => this != Verdict.retry;
}

@immutable
class ExerciseResult {
  final Exercise exercise;
  final String heardText;
  final double intelligibility;
  final double targetMatch;
  final double semanticMatch;
  final Verdict verdict;
  final int attempts;
  final List<String> phonologicalProcesses;
  final String feedback;

  const ExerciseResult({
    required this.exercise,
    required this.heardText,
    required this.intelligibility,
    required this.targetMatch,
    required this.semanticMatch,
    required this.verdict,
    required this.attempts,
    required this.feedback,
    this.phonologicalProcesses = const [],
  });

  int get stars => switch (verdict) {
        Verdict.pass => attempts <= 1 ? 3 : 2,
        Verdict.partial => 1,
        Verdict.retry => 0,
      };
}

@immutable
class LessonResult {
  final String lessonId;
  final String unitId;
  final List<ExerciseResult> results;
  final Duration duration;

  const LessonResult({
    required this.lessonId,
    required this.unitId,
    required this.results,
    required this.duration,
  });

  int get stars => results.fold(0, (a, r) => a + r.stars);
  int get maxStars => results.length * 3;

  double get successRate => results.isEmpty
      ? 0
      : results.where((r) => r.verdict.advances).length / results.length;

  bool get passed => successRate >= 0.6;

  double get meanIntelligibility {
    final voiced = results.where((r) => r.exercise.type.needsVoice).toList();
    if (voiced.isEmpty) return 0;
    return voiced.fold<double>(0, (a, r) => a + r.intelligibility) /
        voiced.length;
  }

  Map<String, int> get processCounts {
    final m = <String, int>{};
    for (final r in results) {
      for (final p in r.phonologicalProcesses) {
        m[p] = (m[p] ?? 0) + 1;
      }
    }
    return m;
  }

  List<String> get strugglingPhonemes {
    final counts = <String, int>{};
    for (final r in results.where((r) => r.verdict != Verdict.pass)) {
      for (final p in r.exercise.targetPhonemes) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }
}

@immutable
class LessonProgress {
  final String lessonId;
  final int bestStars;
  final int completions;
  final DateTime? lastCompletedAt;

  const LessonProgress({
    required this.lessonId,
    this.bestStars = 0,
    this.completions = 0,
    this.lastCompletedAt,
  });

  bool get isComplete => completions > 0;

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'bestStars': bestStars,
        'completions': completions,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      };

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        lessonId: j['lessonId'] as String,
        bestStars: (j['bestStars'] ?? 0) as int,
        completions: (j['completions'] ?? 0) as int,
        lastCompletedAt: j['lastCompletedAt'] == null
            ? null
            : DateTime.parse(j['lastCompletedAt'] as String),
      );
}

@immutable
class PhonemeMastery {
  final String phoneme;
  final double score;
  final int box;
  final DateTime lastSeen;
  final int attempts;
  final int successes;

  const PhonemeMastery({
    required this.phoneme,
    required this.score,
    required this.box,
    required this.lastSeen,
    this.attempts = 0,
    this.successes = 0,
  });

  static const boxIntervalDays = [0, 1, 3, 7, 16];

  bool get isDue {
    final days = boxIntervalDays[box.clamp(0, boxIntervalDays.length - 1)];
    return DateTime.now().difference(lastSeen).inDays >= days;
  }

  bool get isMastered => score >= 0.8 && box >= 3;

  Map<String, dynamic> toJson() => {
        'phoneme': phoneme,
        'score': score,
        'box': box,
        'lastSeen': lastSeen.toIso8601String(),
        'attempts': attempts,
        'successes': successes,
      };

  factory PhonemeMastery.fromJson(Map<String, dynamic> j) => PhonemeMastery(
        phoneme: j['phoneme'] as String,
        score: (j['score'] as num).toDouble(),
        box: j['box'] as int,
        lastSeen: DateTime.parse(j['lastSeen'] as String),
        attempts: (j['attempts'] ?? 0) as int,
        successes: (j['successes'] ?? 0) as int,
      );
}
