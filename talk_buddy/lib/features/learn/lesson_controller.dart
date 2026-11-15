import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/curriculum/answer_evaluator.dart';
import '../../data/curriculum/content_library.dart';
import '../../data/curriculum/curriculum_models.dart';
import '../../data/curriculum/dialogue_engine.dart';
import '../../data/repositories/learn_providers.dart';
import '../../data/repositories/providers.dart';
import '../../data/services/speech_service.dart';

enum LessonPhase {
  loading,
  intro,
  speaking,
  awaiting,
  listening,
  evaluating,
  feedback,
  scaffolding,
  complete,
  micDenied,
}

@immutable
class LessonState {
  final LessonPhase phase;
  final List<Exercise> exercises;
  final int index;
  final int attempt;
  final String partial;
  final String heard;
  final Evaluation? evaluation;
  final List<ExerciseResult> results;
  final int stars;
  final String? banner;
  final Duration elapsed;

  const LessonState({
    this.phase = LessonPhase.loading,
    this.exercises = const [],
    this.index = 0,
    this.attempt = 1,
    this.partial = '',
    this.heard = '',
    this.evaluation,
    this.results = const [],
    this.stars = 0,
    this.banner,
    this.elapsed = Duration.zero,
  });

  Exercise? get current =>
      index >= 0 && index < exercises.length ? exercises[index] : null;

  double get progress =>
      exercises.isEmpty ? 0 : (index / exercises.length).clamp(0.0, 1.0);

  int get total => exercises.length;

  bool get isListening => phase == LessonPhase.listening;

  LessonState copyWith({
    LessonPhase? phase,
    List<Exercise>? exercises,
    int? index,
    int? attempt,
    String? partial,
    String? heard,
    Evaluation? evaluation,
    bool clearEvaluation = false,
    List<ExerciseResult>? results,
    int? stars,
    String? banner,
    bool clearBanner = false,
    Duration? elapsed,
  }) =>
      LessonState(
        phase: phase ?? this.phase,
        exercises: exercises ?? this.exercises,
        index: index ?? this.index,
        attempt: attempt ?? this.attempt,
        partial: partial ?? this.partial,
        heard: heard ?? this.heard,
        evaluation: clearEvaluation ? null : (evaluation ?? this.evaluation),
        results: results ?? this.results,
        stars: stars ?? this.stars,
        banner: clearBanner ? null : (banner ?? this.banner),
        elapsed: elapsed ?? this.elapsed,
      );
}

class LessonController extends StateNotifier<LessonState> {
  final Lesson lesson;
  final Unit unit;
  final DialogueEngine engine;
  final AnswerEvaluator evaluator;
  final SpeechService speech;
  final bool voiceEnabled;

  Timer? _ticker;
  DateTime? _startedAt;
  bool _disposed = false;

  LessonController({
    required this.lesson,
    required this.unit,
    required this.engine,
    required this.evaluator,
    required this.speech,
    this.voiceEnabled = true,
  }) : super(const LessonState());

  Future<void> start() async {
    if (_startedAt != null) return;
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || _startedAt == null) return;
      state = state.copyWith(
        elapsed: DateTime.now().difference(_startedAt!),
      );
    });

    final exercises = engine.buildLesson(lesson);
    state = state.copyWith(
      exercises: exercises,
      phase: LessonPhase.intro,
      banner: engine.opener(unit.title),
    );

    if (voiceEnabled) {
      final status = await speech.init();
      if (status == SpeechStatus.denied && !_disposed) {
        state = state.copyWith(phase: LessonPhase.micDenied);
        return;
      }
    }

    await _speak(state.banner ?? '');
    if (_disposed) return;
    await _presentCurrent();
  }

  Future<void> _speak(String text) async {
    if (_disposed || text.isEmpty) return;
    state = state.copyWith(phase: LessonPhase.speaking);
    try {
      await speech.speak(text);
    } catch (_) {}
  }

  Future<void> _presentCurrent() async {
    final ex = state.current;
    if (ex == null) {
      await _finish();
      return;
    }

    state = state.copyWith(
      phase: LessonPhase.speaking,
      partial: '',
      heard: '',
      clearEvaluation: true,
      clearBanner: true,
    );

    await _speak(ex.spokenPrompt);
    if (_disposed) return;

    if (!ex.type.needsVoice) {
      state = state.copyWith(phase: LessonPhase.awaiting);
      return;
    }

    if (!voiceEnabled) {
      state = state.copyWith(phase: LessonPhase.awaiting);
      return;
    }

    await listen();
  }

  Future<void> listen() async {
    final ex = state.current;
    if (ex == null || _disposed) return;

    state = state.copyWith(phase: LessonPhase.listening, partial: '');

    final result = await speech.listenOnce(
      onPartial: (p) {
        if (!_disposed) state = state.copyWith(partial: p);
      },
      listenFor: const Duration(seconds: 15),
    );

    if (_disposed) return;
    await submitSpeech(result.text, result.confidence);
  }

  Future<void> submitSpeech(String text, double confidence) async {
    final ex = state.current;
    if (ex == null || _disposed) return;

    state = state.copyWith(
      phase: LessonPhase.evaluating,
      heard: text,
      partial: '',
    );

    final evaluation = evaluator.evaluate(
      exercise: ex,
      heard: text,
      confidence: confidence,
      attempt: state.attempt,
    );

    await _applyEvaluation(ex, evaluation);
  }

  Future<void> submitChoice(int chosen) async {
    final ex = state.current;
    if (ex == null || _disposed) return;

    state = state.copyWith(phase: LessonPhase.evaluating);

    final evaluation = evaluator.evaluateChoice(
      exercise: ex,
      chosen: chosen,
      attempt: state.attempt,
    );

    await _applyEvaluation(ex, evaluation);
  }

  Future<void> _applyEvaluation(Exercise ex, Evaluation evaluation) async {
    if (evaluation.verdict == Verdict.retry) {
      state = state.copyWith(
        phase: LessonPhase.scaffolding,
        evaluation: evaluation,
      );

      await _speak(evaluation.feedback);
      if (_disposed) return;

      final sc = evaluation.scaffold;
      if (sc != null) {
        await _speak(sc.instruction);
        if (_disposed) return;
        if (sc.hint != null && sc.hint!.isNotEmpty) {
          await _speak(sc.hint!);
          if (_disposed) return;
        }
      }

      state = state.copyWith(attempt: state.attempt + 1);

      if (ex.type.needsVoice && voiceEnabled) {
        await listen();
      } else {
        state = state.copyWith(phase: LessonPhase.awaiting);
      }
      return;
    }

    final result = ExerciseResult(
      exercise: ex,
      heardText: state.heard,
      intelligibility: evaluation.intelligibility,
      targetMatch: evaluation.targetMatch,
      semanticMatch: evaluation.semanticMatch,
      verdict: evaluation.verdict,
      attempts: state.attempt,
      feedback: evaluation.feedback,
      phonologicalProcesses: evaluation.processes,
    );

    state = state.copyWith(
      phase: LessonPhase.feedback,
      evaluation: evaluation,
      results: [...state.results, result],
      stars: state.stars + result.stars,
    );

    await _speak(evaluation.feedback);
    if (_disposed) return;

    final sc = evaluation.scaffold;
    if (sc != null && sc.level == ScaffoldLevel.together) {
      await _speak(sc.instruction);
      if (_disposed) return;
      if (sc.hint != null && sc.hint!.isNotEmpty) {
        await _speak(sc.hint!);
        if (_disposed) return;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_disposed) return;
    await next();
  }

  Future<void> next() async {
    if (_disposed) return;

    final nextIndex = state.index + 1;
    if (nextIndex >= state.exercises.length) {
      await _finish();
      return;
    }

    state = state.copyWith(
      index: nextIndex,
      attempt: 1,
      clearEvaluation: true,
    );

    if (nextIndex % 3 == 0) {
      await _speak(engine.transition());
      if (_disposed) return;
    }

    await _presentCurrent();
  }

  Future<void> skip() async {
    final ex = state.current;
    if (ex == null || _disposed) return;

    final result = ExerciseResult(
      exercise: ex,
      heardText: '',
      intelligibility: 0,
      targetMatch: 0,
      semanticMatch: 0,
      verdict: Verdict.partial,
      attempts: state.attempt,
      feedback: 'Bunu sonra deneriz.',
    );

    state = state.copyWith(
      results: [...state.results, result],
      stars: state.stars + result.stars,
    );
    await next();
  }

  Future<LessonResult> _finish() async {
    _ticker?.cancel();
    await speech.cancel();

    final result = buildResult();

    if (!_disposed) {
      state = state.copyWith(
        phase: LessonPhase.complete,
        banner: engine.closer(),
      );
      await _speak(state.banner ?? '');
    }
    return result;
  }

  LessonResult buildResult() => LessonResult(
        lessonId: lesson.id,
        unitId: lesson.unitId,
        results: state.results,
        duration: _startedAt == null
            ? Duration.zero
            : DateTime.now().difference(_startedAt!),
      );

  Future<LessonResult> abandon() async {
    _ticker?.cancel();
    await speech.cancel();
    await speech.silence();
    return buildResult();
  }

  Future<void> repeatPrompt() async {
    final ex = state.current;
    if (ex == null) return;
    await _speak(ex.spokenPrompt);
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    speech.cancel();
    speech.silence();
    super.dispose();
  }
}

final lessonControllerProvider = StateNotifierProvider.autoDispose
    .family<LessonController, LessonState, String>((ref, lessonId) {
  final lesson = ContentLibrary.lessonById(lessonId)!;
  final unit = ContentLibrary.unitById(lesson.unitId)!;
  final seed = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  return LessonController(
    lesson: lesson,
    unit: unit,
    engine: ref.watch(dialogueEngineProvider((lessonId: lessonId, seed: seed))),
    evaluator: ref.watch(evaluatorProvider),
    speech: ref.watch(speechServiceProvider),
  );
});
