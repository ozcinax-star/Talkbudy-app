import 'dart:math' as math;

import 'content_library.dart';
import 'curriculum_models.dart';

class GenerationContext {
  final String childName;
  final int ageMonths;
  final Map<String, PhonemeMastery> mastery;
  final Set<String> recentPrompts;
  final Set<String> recentWords;
  final int seed;

  const GenerationContext({
    required this.childName,
    required this.ageMonths,
    this.mastery = const {},
    this.recentPrompts = const {},
    this.recentWords = const {},
    this.seed = 0,
  });
}

class DialogueEngine {
  final math.Random _rnd;
  final GenerationContext ctx;

  final Set<String> _usedPrompts = {};
  final Set<String> _usedSlots = {};

  DialogueEngine({required this.ctx}) : _rnd = math.Random(ctx.seed);

  List<Exercise> buildLesson(Lesson lesson) {
    final templates = lesson.templateIds
        .map(ContentLibrary.byId)
        .whereType<ExerciseTemplate>()
        .toList();

    if (templates.isEmpty) return const [];

    final out = <Exercise>[];
    final order = _interleave(templates, lesson.exerciseCount);

    for (final t in order) {
      out.add(_materialize(t));
    }
    return out;
  }

  List<ExerciseTemplate> _interleave(
    List<ExerciseTemplate> templates,
    int count,
  ) {
    final weighted = <ExerciseTemplate>[];
    for (final t in templates) {
      final w = _templateWeight(t);
      for (var i = 0; i < w; i++) {
        weighted.add(t);
      }
    }

    final out = <ExerciseTemplate>[];
    ExerciseTemplate? last;

    for (var i = 0; i < count; i++) {
      final pool = weighted.where((t) => t.id != last?.id).toList();
      final pick = (pool.isEmpty ? weighted : pool)[
          _rnd.nextInt(pool.isEmpty ? weighted.length : pool.length)];
      out.add(pick);
      last = pick;
    }

    out.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    if (out.length > 2) {
      final mid = out.removeAt(out.length - 1);
      out.insert(out.length ~/ 2 + 1, mid);
    }
    return out;
  }

  int _templateWeight(ExerciseTemplate t) {
    var w = 3;

    for (final p in t.targetPhonemes) {
      final m = ctx.mastery[p];
      if (m == null) {
        w += 2;
      } else {
        if (m.score < 0.4) {
          w += 3;
        } else if (m.score < 0.7) {
          w += 1;
        } else if (m.isMastered) {
          w -= 1;
        }
        if (m.isDue) w += 2;
      }
    }

    final ageGap = t.difficulty * 12 + 24 - ctx.ageMonths;
    if (ageGap > 18) w -= 2;

    return w.clamp(1, 12);
  }

  Exercise _materialize(ExerciseTemplate t) {
    final prompt = _pickPrompt(t);
    final fills = <String, String>{};

    for (final slot in t.slots) {
      fills[slot.key] = _pickSlot(t.id, slot);
    }

    return switch (t.type) {
      ExerciseType.listenRepeat => _buildWordExercise(t, prompt, fills),
      ExerciseType.namePicture => _buildPicture(t, prompt, fills),
      ExerciseType.choosePicture => _buildChoosePicture(t, prompt, fills),
      ExerciseType.minimalPair => _buildMinimalPair(t, prompt, fills),
      ExerciseType.completeSentence => _buildComplete(t, prompt, fills),
      ExerciseType.emotionMatch => _buildEmotion(t, prompt, fills),
      ExerciseType.retellStory => _buildStory(t, prompt, fills),
      ExerciseType.tongueTwister => _buildTwister(t, prompt, fills),
      ExerciseType.answerQuestion => _buildOpen(t, prompt, fills),
    };
  }

  String _pickPrompt(ExerciseTemplate t) {
    final fresh = t.prompts
        .where((p) => !_usedPrompts.contains('${t.id}|$p'))
        .where((p) => !ctx.recentPrompts.contains('${t.id}|$p'))
        .toList();

    final pool = fresh.isNotEmpty
        ? fresh
        : t.prompts.where((p) => !_usedPrompts.contains('${t.id}|$p')).toList();

    final chosen = (pool.isEmpty ? t.prompts : pool)[
        _rnd.nextInt(pool.isEmpty ? t.prompts.length : pool.length)];
    _usedPrompts.add('${t.id}|$chosen');
    return chosen;
  }

  String _pickSlot(String templateId, SlotFill slot) {
    final key = '$templateId|${slot.key}';
    final fresh = slot.values
        .where((v) => !_usedSlots.contains('$key|$v'))
        .where((v) => !ctx.recentWords.contains(v.split('|').first))
        .toList();

    final pool = fresh.isNotEmpty
        ? fresh
        : slot.values.where((v) => !_usedSlots.contains('$key|$v')).toList();

    final chosen = (pool.isEmpty ? slot.values : pool)[
        _rnd.nextInt(pool.isEmpty ? slot.values.length : pool.length)];
    _usedSlots.add('$key|$chosen');
    return chosen;
  }

  String _apply(String prompt, Map<String, String> fills) {
    var out = prompt;
    fills.forEach((k, v) {
      out = out.replaceAll('{$k}', v.split('|').first);
    });
    out = out.replaceAll('{ad}', ctx.childName);
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Exercise _buildWordExercise(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    final word = fills['kelime'] ?? '';
    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: _apply(prompt, fills),
      targetWord: word,
      accepted: [word],
      emoji: t.emoji,
      targetPhonemes: t.targetPhonemes,
      difficulty: t.difficulty,
    );
  }

  Exercise _buildPicture(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    final raw = fills['görsel'] ?? '❓|şey';
    final parts = raw.split('|');
    final emoji = parts.first;
    final word = parts.length > 1 ? parts[1] : '';
    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: _apply(prompt, {}),
      targetWord: word,
      accepted: [word],
      emoji: emoji,
      targetPhonemes: t.targetPhonemes,
      difficulty: t.difficulty,
    );
  }

  Exercise _buildChoosePicture(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    final raw = fills['set'] ?? 'kedi|🐱🐶🐦|0';
    final parts = raw.split('|');
    final target = parts[0];
    final emojis = parts.length > 1 ? parts[1].runes : ''.runes;
    final correct = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    final options = _splitEmoji(parts.length > 1 ? parts[1] : '');

    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: _apply(prompt, {'hedef': target}),
      targetWord: target,
      accepted: [target],
      options: options,
      correctOption: correct.clamp(0, math.max(0, options.length - 1)),
      emoji: emojis.isEmpty ? '' : '',
      targetPhonemes: t.targetPhonemes,
      difficulty: t.difficulty,
    );
  }

  Exercise _buildMinimalPair(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    final raw = fills['çift'] ?? 'tam|dam|0';
    final parts = raw.split('|');
    final a = parts[0];
    final b = parts.length > 1 ? parts[1] : '';
    final correct = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    final flip = _rnd.nextBool();
    final options = flip ? [b, a] : [a, b];
    final correctIndex = flip ? (1 - correct) : correct;
    final target = options[correctIndex];

    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: '${_apply(prompt, {})} $target',
      targetWord: target,
      accepted: [target],
      options: options,
      correctOption: correctIndex,
      targetPhonemes: t.targetPhonemes,
      difficulty: t.difficulty,
    );
  }

  Exercise _buildComplete(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    final raw = fills['cümle'] ?? '';
    final parts = raw.split('|');
    final stem = parts.first.trim();
    final answer = parts.length > 1 ? parts[1].trim() : '';

    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: _apply(prompt, {'cümle': stem}),
      targetWord: answer.isEmpty ? null : answer,
      accepted: answer.isEmpty ? const [] : [answer],
      targetPhonemes: t.targetPhonemes,
      difficulty: t.difficulty,
    );
  }

  Exercise _buildEmotion(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    final raw = fills['durum'] ?? '';
    final parts = raw.split('|');
    final scene = parts.first.trim();
    final accepted = parts.skip(1).map((e) => e.trim()).toList();

    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: _apply(prompt, {'durum': scene}),
      accepted: accepted,
      emoji: '💛',
      difficulty: t.difficulty,
    );
  }

  Exercise _buildStory(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    final story = fills['hikâye'] ?? '';
    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: _apply(prompt, {'hikâye': story}),
      emoji: '📖',
      difficulty: t.difficulty,
    );
  }

  Exercise _buildTwister(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    final line = fills['tekerleme'] ?? '';
    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: _apply(prompt, {'tekerleme': line}),
      targetWord: line,
      accepted: [line],
      emoji: '🎵',
      targetPhonemes: t.targetPhonemes,
      difficulty: t.difficulty,
    );
  }

  Exercise _buildOpen(
    ExerciseTemplate t,
    String prompt,
    Map<String, String> fills,
  ) {
    return Exercise(
      templateId: t.id,
      type: t.type,
      domain: t.domain,
      prompt: _apply(prompt, fills),
      emoji: t.emoji,
      difficulty: t.difficulty,
    );
  }

  String opener(String unitTitle) {
    final line = ContentLibrary
        .openers[_rnd.nextInt(ContentLibrary.openers.length)];
    return line
        .replaceAll('{ad}', ctx.childName)
        .replaceAll('{ünite}', unitTitle);
  }

  String closer() {
    final line = ContentLibrary
        .closers[_rnd.nextInt(ContentLibrary.closers.length)];
    return line.replaceAll('{ad}', ctx.childName);
  }

  String transition() => ContentLibrary
      .transitions[_rnd.nextInt(ContentLibrary.transitions.length)];

  static List<String> _splitEmoji(String s) {
    final out = <String>[];
    final it = s.runes.iterator;
    while (it.moveNext()) {
      out.add(String.fromCharCode(it.current));
    }
    return out;
  }

  static int combinationCount() {
    var total = 0;
    for (final t in ContentLibrary.templates) {
      var slotProduct = 1;
      for (final s in t.slots) {
        slotProduct *= s.values.length;
      }
      total += t.prompts.length * slotProduct;
    }
    return total;
  }
}
