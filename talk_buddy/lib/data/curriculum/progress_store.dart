import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_library.dart';
import 'curriculum_models.dart';
import 'phonology.dart';

@immutable
class ProcessRecord {
  final String id;
  final int count;
  final int lessons;
  final DateTime lastSeen;

  const ProcessRecord({
    required this.id,
    required this.count,
    required this.lessons,
    required this.lastSeen,
  });

  PhonologicalProcess? get meta => TurkishPhonology.processById(id);

  bool isLateFor(int ageMonths) {
    final m = meta;
    return m != null && ageMonths > m.typicalResolutionMonths + 6;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'count': count,
        'lessons': lessons,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory ProcessRecord.fromJson(Map<String, dynamic> j) => ProcessRecord(
        id: j['id'] as String,
        count: (j['count'] ?? 0) as int,
        lessons: (j['lessons'] ?? 0) as int,
        lastSeen: DateTime.parse(j['lastSeen'] as String),
      );
}

class LearnerProgress {
  final Map<String, LessonProgress> lessons;
  final Map<String, PhonemeMastery> mastery;
  final Map<String, ProcessRecord> processes;
  final Set<String> recentPrompts;
  final Set<String> recentWords;
  final int totalStars;
  final int streakDays;
  final DateTime? lastActiveDay;

  const LearnerProgress({
    this.lessons = const {},
    this.mastery = const {},
    this.processes = const {},
    this.recentPrompts = const {},
    this.recentWords = const {},
    this.totalStars = 0,
    this.streakDays = 0,
    this.lastActiveDay,
  });

  List<ProcessRecord> topProcesses([int limit = 3]) {
    final list = processes.values.where((p) => p.meta != null).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(limit).toList();
  }

  List<ProcessRecord> lateProcesses(int ageMonths) =>
      topProcesses(8).where((p) => p.isLateFor(ageMonths)).toList();

  bool isLessonComplete(String lessonId) =>
      lessons[lessonId]?.isComplete ?? false;

  int starsFor(String lessonId) => lessons[lessonId]?.bestStars ?? 0;

  bool isUnitUnlocked(Unit unit) {
    final index = ContentLibrary.units.indexWhere((u) => u.id == unit.id);
    if (index <= 0) return true;
    final prev = ContentLibrary.units[index - 1];
    return prev.lessons.every((l) => isLessonComplete(l.id));
  }

  bool isLessonUnlocked(Unit unit, Lesson lesson) {
    if (!isUnitUnlocked(unit)) return false;
    if (lesson.index == 0) return true;
    final prev = unit.lessons[lesson.index - 1];
    return isLessonComplete(prev.id);
  }

  Lesson? get nextLesson {
    for (final u in ContentLibrary.units) {
      if (!isUnitUnlocked(u)) continue;
      for (final l in u.lessons) {
        if (!isLessonComplete(l.id)) return l;
      }
    }
    return null;
  }

  double get overallCompletion {
    final all = ContentLibrary.allLessons;
    if (all.isEmpty) return 0;
    final done = all.where((l) => isLessonComplete(l.id)).length;
    return done / all.length;
  }

  List<PhonemeMastery> get weakestPhonemes {
    final list = mastery.values.where((m) => m.attempts >= 2).toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    return list.take(5).toList();
  }

  List<PhonemeMastery> get masteredPhonemes =>
      mastery.values.where((m) => m.isMastered).toList();

  double get averageMastery {
    if (mastery.isEmpty) return 0;
    return mastery.values.fold<double>(0, (a, m) => a + m.score) /
        mastery.length;
  }

  LearnerProgress copyWith({
    Map<String, LessonProgress>? lessons,
    Map<String, PhonemeMastery>? mastery,
    Map<String, ProcessRecord>? processes,
    Set<String>? recentPrompts,
    Set<String>? recentWords,
    int? totalStars,
    int? streakDays,
    DateTime? lastActiveDay,
  }) =>
      LearnerProgress(
        lessons: lessons ?? this.lessons,
        mastery: mastery ?? this.mastery,
        processes: processes ?? this.processes,
        recentPrompts: recentPrompts ?? this.recentPrompts,
        recentWords: recentWords ?? this.recentWords,
        totalStars: totalStars ?? this.totalStars,
        streakDays: streakDays ?? this.streakDays,
        lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      );

  Map<String, dynamic> toJson() => {
        'lessons': lessons.map((k, v) => MapEntry(k, v.toJson())),
        'mastery': mastery.map((k, v) => MapEntry(k, v.toJson())),
        'processes': processes.map((k, v) => MapEntry(k, v.toJson())),
        'recentPrompts': recentPrompts.toList(),
        'recentWords': recentWords.toList(),
        'totalStars': totalStars,
        'streakDays': streakDays,
        'lastActiveDay': lastActiveDay?.toIso8601String(),
      };

  factory LearnerProgress.fromJson(Map<String, dynamic> j) => LearnerProgress(
        lessons: (j['lessons'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            k,
            LessonProgress.fromJson(v as Map<String, dynamic>),
          ),
        ),
        mastery: (j['mastery'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            k,
            PhonemeMastery.fromJson(v as Map<String, dynamic>),
          ),
        ),
        processes: (j['processes'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            k,
            ProcessRecord.fromJson(v as Map<String, dynamic>),
          ),
        ),
        recentPrompts:
            ((j['recentPrompts'] as List?) ?? const []).cast<String>().toSet(),
        recentWords:
            ((j['recentWords'] as List?) ?? const []).cast<String>().toSet(),
        totalStars: (j['totalStars'] ?? 0) as int,
        streakDays: (j['streakDays'] ?? 0) as int,
        lastActiveDay: j['lastActiveDay'] == null
            ? null
            : DateTime.parse(j['lastActiveDay'] as String),
      );
}

class ProgressStore {
  static const _prefix = 'progress_';
  static const _recentCap = 40;

  final SharedPreferences _prefs;
  ProgressStore(this._prefs);

  static Future<ProgressStore> create() async =>
      ProgressStore(await SharedPreferences.getInstance());

  String _key(String profileId) => '$_prefix$profileId';

  LearnerProgress load(String profileId) {
    final raw = _prefs.getString(_key(profileId));
    if (raw == null || raw.isEmpty) return const LearnerProgress();
    try {
      return LearnerProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const LearnerProgress();
    }
  }

  Future<void> save(String profileId, LearnerProgress p) =>
      _prefs.setString(_key(profileId), jsonEncode(p.toJson()));

  Future<void> clear(String profileId) => _prefs.remove(_key(profileId));

  LearnerProgress applyResult(LearnerProgress current, LessonResult result) {
    final lessons = Map<String, LessonProgress>.from(current.lessons);
    final prev = lessons[result.lessonId];

    if (result.passed) {
      lessons[result.lessonId] = LessonProgress(
        lessonId: result.lessonId,
        bestStars: math.max(prev?.bestStars ?? 0, result.stars),
        completions: (prev?.completions ?? 0) + 1,
        lastCompletedAt: DateTime.now(),
      );
    } else if (prev == null) {
      lessons[result.lessonId] = LessonProgress(
        lessonId: result.lessonId,
        bestStars: result.stars,
        lastCompletedAt: DateTime.now(),
      );
    }

    final byPhoneme = <String, List<ExerciseResult>>{};
    for (final r in result.results) {
      for (final ph in r.exercise.targetPhonemes) {
        byPhoneme.putIfAbsent(ph, () => []).add(r);
      }
    }

    final mastery = Map<String, PhonemeMastery>.from(current.mastery);
    byPhoneme.forEach((ph, rs) {
      final passes = rs.where((r) => r.verdict == Verdict.pass).length;
      final partials = rs.where((r) => r.verdict == Verdict.partial).length;
      final rate = (passes + partials * 0.5) / rs.length;
      final success = rate >= 0.6;
      final delta = (rate - 0.45) * 0.32;

      final m = mastery[ph];
      if (m == null) {
        mastery[ph] = PhonemeMastery(
          phoneme: ph,
          score: (0.4 + delta).clamp(0.0, 1.0),
          box: success ? 1 : 0,
          lastSeen: DateTime.now(),
          attempts: rs.length,
          successes: passes,
        );
      } else {
        mastery[ph] = PhonemeMastery(
          phoneme: ph,
          score: (m.score + delta).clamp(0.0, 1.0),
          box: success ? math.min(4, m.box + 1) : math.max(0, m.box - 1),
          lastSeen: DateTime.now(),
          attempts: m.attempts + rs.length,
          successes: m.successes + passes,
        );
      }
    });

    final processes = Map<String, ProcessRecord>.from(current.processes);
    result.processCounts.forEach((id, n) {
      final prev = processes[id];
      processes[id] = ProcessRecord(
        id: id,
        count: (prev?.count ?? 0) + n,
        lessons: (prev?.lessons ?? 0) + 1,
        lastSeen: DateTime.now(),
      );
    });

    final prompts = <String>{
      ...current.recentPrompts,
      for (final r in result.results) '${r.exercise.templateId}|${r.exercise.prompt}',
    };
    final words = <String>{
      ...current.recentWords,
      for (final r in result.results)
        if (r.exercise.targetWord != null) r.exercise.targetWord!,
    };

    final today = DateTime.now();
    final last = current.lastActiveDay;
    var streak = current.streakDays;
    if (last == null) {
      streak = 1;
    } else {
      final diff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    }

    return current.copyWith(
      lessons: lessons,
      mastery: mastery,
      processes: processes,
      recentPrompts: _trim(prompts),
      recentWords: _trim(words),
      totalStars: current.totalStars + result.stars,
      streakDays: streak,
      lastActiveDay: today,
    );
  }

  static Set<String> _trim(Set<String> s) =>
      s.length <= _recentCap ? s : s.skip(s.length - _recentCap).toSet();
}
