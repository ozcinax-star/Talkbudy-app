import 'dart:math' as math;

import '../models/models.dart';

class SpeechAnalyzer {

  static const lateAcquiredPhonemes = ['r', 'ş', 'j', 'z', 's', 'ç', 'l', 'k', 'g'];

  static (double min, double max) expectedWpm(int ageMonths) {
    if (ageMonths < 36) return (25, 60);
    if (ageMonths < 48) return (40, 90);
    if (ageMonths < 60) return (60, 110);
    if (ageMonths < 84) return (80, 130);
    return (100, 160);
  }

  static double expectedMlu(int ageMonths) {
    if (ageMonths < 30) return 2.0;
    if (ageMonths < 36) return 2.8;
    if (ageMonths < 48) return 3.6;
    if (ageMonths < 60) return 4.5;
    return 5.5;
  }

  SpeechMetrics analyze({
    required List<ChatTurn> turns,
    required Duration duration,
    required int ageMonths,
  }) {
    final childTurns = turns.where((t) => t.speaker == Speaker.child).toList();
    if (childTurns.isEmpty) return SpeechMetrics.empty;

    final allWords = <String>[];
    for (final t in childTurns) {
      allWords.addAll(_tokenize(t.text));
    }
    if (allWords.isEmpty) return SpeechMetrics.empty;

    final confidences =
        childTurns.map((t) => t.confidence ?? 0.0).where((c) => c > 0).toList();
    final articulation = confidences.isEmpty
        ? 0.5
        : confidences.reduce((a, b) => a + b) / confidences.length;

    final minutes = math.max(duration.inMilliseconds / 60000.0, 0.05);
    final wpm = allWords.length / minutes;

    final (wpmMin, wpmMax) = expectedWpm(ageMonths);
    double fluency;
    if (wpm >= wpmMin && wpm <= wpmMax) {
      fluency = 1.0;
    } else if (wpm < wpmMin) {
      fluency = (wpm / wpmMin).clamp(0.0, 1.0);
    } else {
      fluency = (wpmMax / wpm).clamp(0.0, 1.0);
    }
    fluency -= _repetitionPenalty(allWords);
    fluency -= _fillerPenalty(allWords);
    fluency = fluency.clamp(0.0, 1.0);

    final unique = allWords.map(_stem).toSet().length;
    final rttr = unique / math.sqrt(allWords.length);

    final vocabulary = (rttr / 7.0).clamp(0.0, 1.0);

    final mlu = allWords.length / childTurns.length;

    final sentiment = _sentiment(allWords);

    final difficult = _difficultPhonemes(childTurns);

    return SpeechMetrics(
      articulation: articulation,
      fluency: fluency,
      vocabulary: vocabulary,
      wordsPerMinute: wpm,
      meanUtteranceLength: mlu,
      sentiment: sentiment,
      totalWords: allWords.length,
      difficultPhonemes: difficult,
    );
  }

  List<String> _tokenize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\wçğıöşü\s]', unicode: true), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  String _stem(String w) {
    const suffixes = [
      'lerimiz', 'larımız', 'lerini', 'larını', 'lerde', 'larda',
      'lerin', 'ların', 'ler', 'lar', 'imiz', 'ımız', 'iniz', 'ınız',
      'de', 'da', 'te', 'ta', 'den', 'dan', 'ten', 'tan',
      'yi', 'yı', 'yu', 'yü', 'i', 'ı', 'u', 'ü', 'e', 'a',
    ];
    for (final s in suffixes) {
      if (w.length > s.length + 2 && w.endsWith(s)) {
        return w.substring(0, w.length - s.length);
      }
    }
    return w;
  }

  double _repetitionPenalty(List<String> words) {
    if (words.length < 3) return 0;
    var reps = 0;
    for (var i = 1; i < words.length; i++) {
      if (words[i] == words[i - 1]) reps++;
    }
    return (reps / words.length * 2.5).clamp(0.0, 0.35);
  }

  static const _fillers = {'ıı', 'ee', 'şey', 'hani', 'yani', 'aa', 'mm', 'hmm'};

  double _fillerPenalty(List<String> words) {
    final n = words.where(_fillers.contains).length;
    return (n / words.length * 1.5).clamp(0.0, 0.25);
  }

  static const _positive = {
    'güzel', 'iyi', 'sevdim', 'seviyorum', 'mutlu', 'harika', 'eğlenceli',
    'komik', 'süper', 'evet', 'oyun', 'gülmek', 'arkadaş', 'seviyor'
  };
  static const _negative = {
    'kötü', 'üzgün', 'korktum', 'korkuyorum', 'ağladım', 'istemiyorum',
    'sıkıldım', 'yapamıyorum', 'zor', 'hayır', 'canım', 'acı'
  };

  double _sentiment(List<String> words) {
    var score = 0;
    for (final w in words) {
      if (_positive.contains(w)) score++;
      if (_negative.contains(w)) score--;
    }
    if (words.isEmpty) return 0;
    return (score / math.sqrt(words.length)).clamp(-1.0, 1.0);
  }

  List<String> _difficultPhonemes(List<ChatTurn> childTurns) {
    final counts = <String, int>{};
    for (final t in childTurns) {
      final c = t.confidence ?? 1.0;
      if (c >= 0.72) continue;
      for (final ch in t.text.toLowerCase().split('')) {
        if (lateAcquiredPhonemes.contains(ch)) {
          counts[ch] = (counts[ch] ?? 0) + 1;
        }
      }
    }
    final sorted = counts.entries.where((e) => e.value >= 2).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }
}

class Redactor {
  static final _phone = RegExp(r'\b(0?5\d{2}[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2})\b');
  static final _tckn = RegExp(r'\b[1-9]\d{10}\b');
  static final _address =
      RegExp(r'\b(mahalle\w*|sokak|sokağ\w*|cadde\w*|apartman\w*|daire|no:?\s*\d+)\b',
          caseSensitive: false, unicode: true);

  static String scrub(String text) {
    return text
        .replaceAll(_phone, '[telefon]')
        .replaceAll(_tckn, '[kimlik]')
        .replaceAll(_address, '[adres]');
  }

  static bool containsPii(String text) =>
      _phone.hasMatch(text) || _tckn.hasMatch(text) || _address.hasMatch(text);
}
