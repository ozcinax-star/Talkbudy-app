import 'package:flutter/foundation.dart';

enum AppRole { child, parent, specialist }

extension AppRoleX on AppRole {
  String get label => switch (this) {
        AppRole.child => 'Çocuk',
        AppRole.parent => 'Ebeveyn',
        AppRole.specialist => 'Uzman',
      };
}

@immutable
class ChildProfile {
  final String id;
  final String name;
  final int ageMonths;
  final String avatar;
  final DateTime createdAt;
  final String? specialistId;
  final int stars;
  final int streakDays;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.ageMonths,
    required this.avatar,
    required this.createdAt,
    this.specialistId,
    this.stars = 0,
    this.streakDays = 0,
  });

  String get ageLabel {
    final y = ageMonths ~/ 12;
    final m = ageMonths % 12;
    if (y == 0) return '$m aylık';
    if (m == 0) return '$y yaş';
    return '$y yaş $m ay';
  }

  ChildProfile copyWith({
    String? name,
    int? ageMonths,
    String? avatar,
    String? specialistId,
    int? stars,
    int? streakDays,
  }) =>
      ChildProfile(
        id: id,
        name: name ?? this.name,
        ageMonths: ageMonths ?? this.ageMonths,
        avatar: avatar ?? this.avatar,
        createdAt: createdAt,
        specialistId: specialistId ?? this.specialistId,
        stars: stars ?? this.stars,
        streakDays: streakDays ?? this.streakDays,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ageMonths': ageMonths,
        'avatar': avatar,
        'createdAt': createdAt.toIso8601String(),
        'specialistId': specialistId,
        'stars': stars,
        'streakDays': streakDays,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        ageMonths: j['ageMonths'] as int,
        avatar: j['avatar'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        specialistId: j['specialistId'] as String?,
        stars: (j['stars'] ?? 0) as int,
        streakDays: (j['streakDays'] ?? 0) as int,
      );
}

@immutable
class SpeechMetrics {
  final double articulation;
  final double fluency;
  final double vocabulary;
  final double wordsPerMinute;
  final double meanUtteranceLength;
  final double sentiment;
  final int totalWords;
  final List<String> difficultPhonemes;

  const SpeechMetrics({
    required this.articulation,
    required this.fluency,
    required this.vocabulary,
    required this.wordsPerMinute,
    required this.meanUtteranceLength,
    required this.sentiment,
    required this.totalWords,
    this.difficultPhonemes = const [],
  });

  double get overall =>
      (articulation * 0.4) + (fluency * 0.3) + (vocabulary * 0.3);

  static const empty = SpeechMetrics(
    articulation: 0,
    fluency: 0,
    vocabulary: 0,
    wordsPerMinute: 0,
    meanUtteranceLength: 0,
    sentiment: 0,
    totalWords: 0,
  );

  Map<String, dynamic> toJson() => {
        'articulation': articulation,
        'fluency': fluency,
        'vocabulary': vocabulary,
        'wordsPerMinute': wordsPerMinute,
        'meanUtteranceLength': meanUtteranceLength,
        'sentiment': sentiment,
        'totalWords': totalWords,
        'difficultPhonemes': difficultPhonemes,
      };

  factory SpeechMetrics.fromJson(Map<String, dynamic> j) => SpeechMetrics(
        articulation: (j['articulation'] as num).toDouble(),
        fluency: (j['fluency'] as num).toDouble(),
        vocabulary: (j['vocabulary'] as num).toDouble(),
        wordsPerMinute: (j['wordsPerMinute'] as num).toDouble(),
        meanUtteranceLength: (j['meanUtteranceLength'] as num).toDouble(),
        sentiment: (j['sentiment'] as num).toDouble(),
        totalWords: j['totalWords'] as int,
        difficultPhonemes:
            (j['difficultPhonemes'] as List?)?.cast<String>() ?? const [],
      );
}

enum Speaker { child, buddy }

@immutable
class ChatTurn {
  final Speaker speaker;
  final String text;
  final DateTime at;
  final double? confidence;
  final List<String> flaggedPhonemes;

  const ChatTurn({
    required this.speaker,
    required this.text,
    required this.at,
    this.confidence,
    this.flaggedPhonemes = const [],
  });
}

@immutable
class Session {
  final String id;
  final String childId;
  final DateTime startedAt;
  final Duration duration;
  final SpeechMetrics metrics;
  final List<ChatTurn> turns;
  final String activity;
  final String summary;

  const Session({
    required this.id,
    required this.childId,
    required this.startedAt,
    required this.duration,
    required this.metrics,
    required this.activity,
    required this.summary,
    this.turns = const [],
  });
}

@immutable
class Activity {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final int colorValue;
  final String targetSkill;
  final String promptHint;
  final int estimatedMinutes;

  const Activity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colorValue,
    required this.targetSkill,
    required this.promptHint,
    this.estimatedMinutes = 5,
  });
}

enum AlertLevel { info, watch, urgent }

@immutable
class SpecialistAlert {
  final String id;
  final String childId;
  final String childName;
  final AlertLevel level;
  final String message;
  final DateTime at;

  const SpecialistAlert({
    required this.id,
    required this.childId,
    required this.childName,
    required this.level,
    required this.message,
    required this.at,
  });
}

@immutable
class DailyPoint {
  final DateTime day;
  final double overall;
  final int minutes;
  final int words;

  const DailyPoint({
    required this.day,
    required this.overall,
    required this.minutes,
    required this.words,
  });
}
