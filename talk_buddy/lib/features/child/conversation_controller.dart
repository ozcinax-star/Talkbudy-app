import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/settings_service.dart';
import '../../data/services/speech_analyzer.dart';
import '../../data/services/speech_service.dart';

enum TurnPhase { idle, buddySpeaking, listening, thinking, finished, error }

@immutable
class ConversationState {
  final Activity activity;
  final TurnPhase phase;
  final List<ChatTurn> turns;
  final String partial;
  final int starsEarned;
  final Duration elapsed;
  final String? errorMessage;

  const ConversationState({
    required this.activity,
    this.phase = TurnPhase.idle,
    this.turns = const [],
    this.partial = '',
    this.starsEarned = 0,
    this.elapsed = Duration.zero,
    this.errorMessage,
  });

  ConversationState copyWith({
    TurnPhase? phase,
    List<ChatTurn>? turns,
    String? partial,
    int? starsEarned,
    Duration? elapsed,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ConversationState(
        activity: activity,
        phase: phase ?? this.phase,
        turns: turns ?? this.turns,
        partial: partial ?? this.partial,
        starsEarned: starsEarned ?? this.starsEarned,
        elapsed: elapsed ?? this.elapsed,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  ChatTurn? get lastBuddyTurn {
    for (var i = turns.length - 1; i >= 0; i--) {
      if (turns[i].speaker == Speaker.buddy) return turns[i];
    }
    return null;
  }
}

@immutable
class SessionResult {
  final SpeechMetrics metrics;
  final String summary;
  final Duration duration;
  final int stars;
  final List<ChatTurn> turns;

  const SessionResult({
    required this.metrics,
    required this.summary,
    required this.duration,
    required this.stars,
    required this.turns,
  });
}

class ConversationController extends StateNotifier<ConversationState> {
  final AiService _ai;
  final SpeechService _speech;
  final SpeechAnalyzer _analyzer;
  final ChildProfile _child;
  final AppSettings _settings;

  Timer? _ticker;
  DateTime? _startedAt;
  bool _stopped = false;
  SessionResult? _result;

  ConversationController({
    required AiService ai,
    required SpeechService speech,
    required SpeechAnalyzer analyzer,
    required ChildProfile child,
    required AppSettings settings,
    required Activity activity,
  })  : _ai = ai,
        _speech = speech,
        _analyzer = analyzer,
        _child = child,
        _settings = settings,
        super(ConversationState(activity: activity));

  SpeechService get speech => _speech;

  Future<void> start() async {
    if (_startedAt != null) return;
    _stopped = false;
    _startedAt = DateTime.now();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt == null || !mounted) return;
      final e = DateTime.now().difference(_startedAt!);
      state = state.copyWith(elapsed: e);
      if (e >= _settings.sessionLimit) finish();
    });

    final status = await _speech.init();
    if (status == SpeechStatus.denied) {
      if (mounted) {
        state = state.copyWith(
          phase: TurnPhase.error,
          errorMessage:
              'Mikrofon izni verilmedi. Ayarlardan izin vererek tekrar deneyin.',
        );
      }
      return;
    }

    await _say(_greeting());
    unawaited(_loop());
  }

  String _greeting() => switch (state.activity.id) {
        'animals' => 'Merhaba ${_child.name}! Bugün hayvanlar ülkesine '
            'gidiyoruz. En sevdiğin hayvan hangisi?',
        'story' => 'Selam ${_child.name}! Bir hikâye anlatacağım ama sonunu '
            'sen tamamlayacaksın. Hazır mısın?',
        'colors' => 'Merhaba ${_child.name}! Etrafına bak bakalım, gördüğün '
            'en güzel renk hangisi?',
        'rhyme' => 'Merhaba ${_child.name}! Tekerleme söyleyeceğiz. '
            'Benimle beraber söyler misin?',
        'feelings' =>
          'Merhaba ${_child.name}! Bugün kendini nasıl hissediyorsun?',
        _ => 'Merhaba ${_child.name}! Seni görmek ne güzel. Bugün ne yaptın?',
      };

  Future<void> _say(String text) async {
    if (!mounted) return;
    state = state.copyWith(
      phase: TurnPhase.buddySpeaking,
      clearError: true,
      turns: [
        ...state.turns,
        ChatTurn(speaker: Speaker.buddy, text: text, at: DateTime.now()),
      ],
    );
    await _speech.speak(text);
  }

  Future<void> _loop() async {
    var silentTurns = 0;

    while (!_stopped && mounted) {
      state = state.copyWith(phase: TurnPhase.listening, partial: '');

      final result = await _speech.listenOnce(
        onPartial: (p) {
          if (mounted) state = state.copyWith(partial: p);
        },
      );

      if (_stopped || !mounted) break;

      if (!result.ok) {
        silentTurns++;
        if (silentTurns >= 3) {
          await _say(
            'Sanırım biraz yoruldun. İstersen sonra devam ederiz. '
            'Bugün benimle konuştuğun için teşekkürler!',
          );
          await finish();
          return;
        }
        await _say(_nudge(silentTurns));
        continue;
      }
      silentTurns = 0;

      state = state.copyWith(
        turns: [
          ...state.turns,
          ChatTurn(
            speaker: Speaker.child,
            text: result.text,
            at: DateTime.now(),
            confidence: result.confidence,
          ),
        ],
        partial: '',
        phase: TurnPhase.thinking,
        starsEarned:
            state.starsEarned + (result.text.split(' ').length >= 5 ? 2 : 1),
      );

      try {
        final outgoing = _settings.redactPii
            ? Redactor.scrub(result.text)
            : result.text;

        final reply = await _ai.reply(
          childUtterance: outgoing,
          child: _child,
          activity: state.activity,
          history: state.turns,
        );

        if (_stopped || !mounted) break;
        await _say(reply);
      } catch (e) {
        if (_stopped || !mounted) break;
        await _say(
          'Şu an biraz dalgın olabilirim ama seni dinliyorum. '
          'Bir daha anlatır mısın?',
        );
      }
    }
  }

  String _nudge(int n) => switch (n) {
        1 => 'Seni duyamadım. Biraz daha yüksek sesle söyler misin?',
        2 => 'Buradayım, acele etme. Hazır olduğunda anlat.',
        _ => 'Beraber sayalım mı? Bir, iki, üç, şimdi sen söyle!',
      };

  Future<SessionResult> finish() async {
    if (_result != null) return _result!;

    _stopped = true;
    _ticker?.cancel();
    await _speech.cancel();
    await _speech.silence();

    final duration = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);

    final metrics = _analyzer.analyze(
      turns: state.turns,
      duration: duration,
      ageMonths: _child.ageMonths,
    );

    String summary;
    try {
      summary = await _ai.summarize(
        child: _child,
        turns: state.turns,
        metrics: metrics,
      );
    } catch (_) {
      summary =
          '${_child.name} bu seansta ${metrics.totalWords} kelime kullandı.';
    }

    if (mounted) state = state.copyWith(phase: TurnPhase.finished);

    _result = SessionResult(
      metrics: metrics,
      summary: summary,
      duration: duration,
      stars: state.starsEarned,
      turns: _settings.storeTranscripts ? state.turns : const [],
    );
    return _result!;
  }

  @override
  void dispose() {
    _stopped = true;
    _ticker?.cancel();
    _speech.cancel();
    _speech.silence();
    super.dispose();
  }
}

final conversationProvider = StateNotifierProvider.autoDispose
    .family<ConversationController, ConversationState, Activity>(
  (ref, activity) => ConversationController(
    ai: ref.watch(aiServiceProvider),
    speech: ref.watch(speechServiceProvider),
    analyzer: ref.watch(analyzerProvider),
    child: ref.watch(activeChildProvider),
    settings: ref.watch(settingsProvider),
    activity: activity,
  ),
);
