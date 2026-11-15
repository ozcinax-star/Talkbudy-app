import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'settings_service.dart';

enum SpeechStatus { idle, ready, denied, unsupported, error }

@immutable
class SpeechResult {
  final String text;
  final double confidence;
  final Duration duration;
  final String? error;

  const SpeechResult({
    required this.text,
    required this.confidence,
    required this.duration,
    this.error,
  });

  const SpeechResult.failed(this.error)
      : text = '',
        confidence = 0,
        duration = Duration.zero;

  bool get isEmpty => text.trim().isEmpty;
  bool get ok => error == null && !isEmpty;
}

class SpeechService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  AppSettings _settings = const AppSettings();

  bool _ready = false;
  bool _trSupported = false;
  String? _lastError;

  final ValueNotifier<double> level = ValueNotifier(0);

  bool get isListening => _stt.isListening;
  bool get isReady => _ready;
  bool get turkishSupported => _trSupported;
  String? get lastError => _lastError;

  void applySettings(AppSettings s) {
    _settings = s;
    if (_ready) _applyTtsSettings();
  }

  Future<void> _applyTtsSettings() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(_settings.speechRate);
    await _tts.setPitch(_settings.speechPitch);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<SpeechStatus> init() async {
    if (_ready) return SpeechStatus.ready;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _lastError = 'Mikrofon izni verilmedi.';
      return SpeechStatus.denied;
    }

    _ready = await _stt.initialize(
      onError: (e) => _lastError = e.errorMsg,
      onStatus: (s) => debugPrint('stt: $s'),
      debugLogging: false,
    );

    if (!_ready) {
      _lastError ??= 'Konuşma tanıma başlatılamadı.';
      return SpeechStatus.error;
    }

    try {
      final locales = await _stt.locales();
      _trSupported = locales.any((l) => l.localeId.startsWith('tr'));
    } catch (_) {
      _trSupported = false;
    }

    await _applyTtsSettings();

    if (!_trSupported) {
      _lastError = 'Cihazda Türkçe konuşma tanıma paketi bulunamadı.';
      return SpeechStatus.unsupported;
    }
    return SpeechStatus.ready;
  }

  Future<SpeechResult> listenOnce({
    void Function(String partial)? onPartial,
    Duration listenFor = const Duration(seconds: 30),
  }) async {
    if (!_ready) {
      final st = await init();
      if (st != SpeechStatus.ready && st != SpeechStatus.unsupported) {
        return SpeechResult.failed(_lastError ?? 'Mikrofon hazır değil.');
      }
    }

    final completer = Completer<SpeechResult>();
    final started = DateTime.now();
    var lastText = '';
    var lastConfidence = 0.0;

    try {
      await _stt.listen(
        localeId: 'tr_TR',
        listenFor: listenFor,
        pauseFor: _settings.silenceTimeout,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
        onSoundLevelChange: (l) {
          level.value = ((l + 2) / 12).clamp(0.0, 1.0);
        },
        onResult: (SpeechRecognitionResult r) {
          lastText = r.recognizedWords;
          if (r.confidence > 0) lastConfidence = r.confidence;
          if (!r.finalResult) {
            onPartial?.call(lastText);
          } else if (!completer.isCompleted) {
            completer.complete(
              SpeechResult(
                text: lastText,
                confidence: lastConfidence,
                duration: DateTime.now().difference(started),
              ),
            );
          }
        },
      );
    } catch (e) {
      level.value = 0;
      return SpeechResult.failed('$e');
    }

    return completer.future
        .timeout(
          listenFor + const Duration(seconds: 3),
          onTimeout: () => SpeechResult(
            text: lastText,
            confidence: lastConfidence,
            duration: DateTime.now().difference(started),
          ),
        )
        .whenComplete(() => level.value = 0);
  }

  Future<void> stop() async {
    await _stt.stop();
    level.value = 0;
  }

  Future<void> cancel() async {
    await _stt.cancel();
    level.value = 0;
  }

  Future<void> speak(String text) async {
    if (_stt.isListening) await _stt.stop();
    await _tts.speak(text);
  }

  Future<void> silence() => _tts.stop();

  Future<List<String>> availableVoices() async {
    try {
      final voices = await _tts.getVoices as List?;
      return voices
              ?.whereType<Map>()
              .where((v) => '${v["locale"]}'.startsWith('tr'))
              .map((v) => '${v["name"]}')
              .toList() ??
          const [];
    } catch (_) {
      return const [];
    }
  }

  void dispose() {
    level.dispose();
    _tts.stop();
    _stt.cancel();
  }
}
