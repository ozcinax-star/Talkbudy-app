import 'dart:math' as math;

class PhonologicalProcess {
  final String id;
  final String label;
  final String explanation;
  final int typicalResolutionMonths;

  const PhonologicalProcess({
    required this.id,
    required this.label,
    required this.explanation,
    required this.typicalResolutionMonths,
  });
}

class TurkishPhonology {
  TurkishPhonology._();

  static const acquisitionOrder = <String, int>{
    'p': 24, 'b': 24, 'm': 24, 'n': 24, 't': 26, 'd': 26,
    'h': 28, 'y': 30, 'k': 32, 'g': 34, 'f': 36, 'v': 38,
    'l': 42, 'ç': 44, 'c': 44, 's': 46, 'z': 48, 'ş': 50,
    'j': 54, 'r': 60,
  };

  static const processes = <PhonologicalProcess>[
    PhonologicalProcess(
      id: 'fronting',
      label: 'Öne alma',
      explanation: 'Arka damak sesleri (k, g) dil ucuyla üretiliyor: "kedi" yerine "tedi".',
      typicalResolutionMonths: 42,
    ),
    PhonologicalProcess(
      id: 'stopping',
      label: 'Durdurma',
      explanation: 'Sürtünmeli sesler (s, ş, f, v, z) patlamalıya dönüyor: "su" yerine "tu".',
      typicalResolutionMonths: 48,
    ),
    PhonologicalProcess(
      id: 'gliding',
      label: 'Kayma',
      explanation: 'Akıcı sesler (r, l) y sesine dönüyor: "araba" yerine "ayaba".',
      typicalResolutionMonths: 66,
    ),
    PhonologicalProcess(
      id: 'liquidSubstitution',
      label: 'Akıcı ses değişimi',
      explanation: '"r" yerine "l" ya da tersi kullanılıyor: "araba" yerine "alaba".',
      typicalResolutionMonths: 60,
    ),
    PhonologicalProcess(
      id: 'clusterReduction',
      label: 'Küme sadeleştirme',
      explanation: 'Yan yana iki ünsüzden biri düşüyor: "tren" yerine "ten".',
      typicalResolutionMonths: 48,
    ),
    PhonologicalProcess(
      id: 'finalDeletion',
      label: 'Son ses düşmesi',
      explanation: 'Kelimenin son sesi söylenmiyor: "kitap" yerine "kita".',
      typicalResolutionMonths: 36,
    ),
    PhonologicalProcess(
      id: 'syllableDeletion',
      label: 'Hece düşmesi',
      explanation: 'Vurgusuz hece atlanıyor: "kelebek" yerine "kebek".',
      typicalResolutionMonths: 48,
    ),
    PhonologicalProcess(
      id: 'devoicing',
      label: 'Ötümsüzleşme',
      explanation: 'Ötümlü ses ötümsüze dönüyor: "baba" yerine "papa".',
      typicalResolutionMonths: 40,
    ),
  ];

  static PhonologicalProcess? processById(String id) {
    for (final p in processes) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const _substitutions = <String, Map<String, String>>{
    'fronting': {'k': 't', 'g': 'd'},
    'stopping': {'s': 't', 'ş': 't', 'z': 'd', 'f': 'p', 'v': 'b', 'c': 'd', 'ç': 't', 'j': 'd'},
    'gliding': {'r': 'y', 'l': 'y'},
    'liquidSubstitution': {'r': 'l', 'l': 'r'},
    'devoicing': {'b': 'p', 'd': 't', 'g': 'k', 'c': 'ç', 'z': 's', 'v': 'f'},
  };

  static const vowels = 'aeıioöuüâî';
  static const consonants = 'bcçdfgğhjklmnprsştvyz';

  static bool isVowel(String c) => vowels.contains(c);
  static bool isConsonant(String c) => consonants.contains(c);

  static String normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll(RegExp(r'[^a-zçğıöşü\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> tokenize(String s) =>
      normalize(s).split(' ').where((w) => w.isNotEmpty).toList();

  static const _suffixes = [
    'lerimizi', 'larımızı', 'lerimiz', 'larımız', 'lerini', 'larını',
    'lerde', 'larda', 'lerin', 'ların', 'ecek', 'acak', 'iyor', 'ıyor',
    'uyor', 'üyor', 'miş', 'mış', 'muş', 'müş', 'ler', 'lar', 'den',
    'dan', 'ten', 'tan', 'nin', 'nın', 'nun', 'nün', 'de', 'da', 'te',
    'ta', 'yi', 'yı', 'yu', 'yü', 'ye', 'ya', 'im', 'ım', 'um', 'üm',
    'in', 'ın', 'un', 'ün', 'si', 'sı', 'su', 'sü', 'i', 'ı', 'u', 'ü',
    'e', 'a', 'm', 'n', 's',
  ];

  static String stem(String w) {
    var out = w;
    for (var pass = 0; pass < 2; pass++) {
      for (final s in _suffixes) {
        if (out.length > s.length + 2 && out.endsWith(s)) {
          out = out.substring(0, out.length - s.length);
          break;
        }
      }
    }
    return out;
  }

  static String applyProcess(String word, String processId) {
    final map = _substitutions[processId];
    if (map == null) return word;
    final sb = StringBuffer();
    for (final ch in word.split('')) {
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  static String reduceClusters(String word) {
    final sb = StringBuffer();
    var prevConsonant = false;
    for (final ch in word.split('')) {
      final isCons = isConsonant(ch);
      if (isCons && prevConsonant) continue;
      sb.write(ch);
      prevConsonant = isCons;
    }
    return sb.toString();
  }

  static String deleteFinal(String word) {
    if (word.length < 3) return word;
    return isConsonant(word[word.length - 1])
        ? word.substring(0, word.length - 1)
        : word;
  }

  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = math.min(
          math.min(curr[j] + 1, prev[j + 1] + 1),
          prev[j] + cost,
        );
      }
      prev = List<int>.from(curr);
    }
    return prev[b.length];
  }

  static double similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1;
    final maxLen = math.max(a.length, b.length);
    if (maxLen == 0) return 1;
    return 1 - levenshtein(a, b) / maxLen;
  }
}

class WordMatch {
  final double score;
  final List<String> processes;
  final bool exact;

  const WordMatch(this.score, this.processes, {this.exact = false});

  static const none = WordMatch(0, []);
}

class PhonologyMatcher {
  final int ageMonths;

  const PhonologyMatcher({required this.ageMonths});

  WordMatch matchWord(String heard, String target) {
    final h = TurkishPhonology.normalize(heard);
    final t = TurkishPhonology.normalize(target);
    if (h.isEmpty) return WordMatch.none;

    if (h == t) return const WordMatch(1.0, [], exact: true);

    final hs = TurkishPhonology.stem(h);
    final ts = TurkishPhonology.stem(t);
    if (hs == ts && hs.length >= 3) return const WordMatch(0.97, [], exact: true);

    final found = <String>[];
    var best = TurkishPhonology.similarity(h, t);

    for (final id in const [
      'fronting',
      'stopping',
      'gliding',
      'liquidSubstitution',
      'devoicing',
    ]) {
      final variant = TurkishPhonology.applyProcess(t, id);
      final sim = TurkishPhonology.similarity(h, variant);
      if (sim > best + 0.001) {
        best = sim;
        found
          ..clear()
          ..add(id);
      } else if (sim >= 0.99) {
        if (!found.contains(id)) found.add(id);
      }
    }

    final reduced = TurkishPhonology.reduceClusters(t);
    if (reduced != t) {
      final sim = TurkishPhonology.similarity(h, reduced);
      if (sim > best + 0.001) {
        best = sim;
        found
          ..clear()
          ..add('clusterReduction');
      }
    }

    final noFinal = TurkishPhonology.deleteFinal(t);
    if (noFinal != t) {
      final sim = TurkishPhonology.similarity(h, noFinal);
      if (sim > best + 0.001) {
        best = sim;
        found
          ..clear()
          ..add('finalDeletion');
      }
    }

    if (h.length < t.length &&
        t.length >= 6 &&
        TurkishPhonology.similarity(h, t) > 0.55) {
      if (!found.contains('syllableDeletion')) {
        final firstMatch = t.startsWith(h.substring(0, math.min(2, h.length)));
        if (firstMatch) {
          best = math.max(best, 0.72);
          found.add('syllableDeletion');
        }
      }
    }

    final ageAdjusted = _ageAdjust(best, found);
    return WordMatch(ageAdjusted, found);
  }

  double _ageAdjust(double raw, List<String> processes) {
    if (processes.isEmpty) return raw;
    var bonus = 0.0;
    for (final id in processes) {
      final p = TurkishPhonology.processById(id);
      if (p == null) continue;
      if (ageMonths <= p.typicalResolutionMonths) {
        bonus = math.max(bonus, 0.12);
      } else {
        bonus = math.max(bonus, 0.05);
      }
    }
    return math.min(1.0, raw + bonus);
  }

  WordMatch matchPhrase(String heard, List<String> targets) {
    if (targets.isEmpty) return WordMatch.none;
    final words = TurkishPhonology.tokenize(heard);
    if (words.isEmpty) return WordMatch.none;

    var best = WordMatch.none;
    for (final target in targets) {
      final targetWords = TurkishPhonology.tokenize(target);

      if (targetWords.length > 1) {
        final joined = words.join(' ');
        final m = matchWord(joined, target);
        if (m.score > best.score) best = m;
      }

      for (final w in words) {
        for (final tw in targetWords) {
          final m = matchWord(w, tw);
          if (m.score > best.score) best = m;
        }
      }
    }
    return best;
  }

  List<String> detectedProcesses(String heard, List<String> targets) {
    final m = matchPhrase(heard, targets);
    return m.score >= 0.5 ? m.processes : const [];
  }
}
