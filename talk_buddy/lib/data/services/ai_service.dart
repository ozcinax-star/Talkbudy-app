import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'settings_service.dart';

class AiException implements Exception {
  final String message;
  final int? statusCode;
  const AiException(this.message, {this.statusCode});

  String get userMessage {
    final code = statusCode ?? 0;
    return switch (code) {
      401 || 403 => 'API anahtarı geçersiz veya yetkisiz.',
      429 => 'Kullanım limiti aşıldı. Bir süre sonra tekrar deneyin.',
      >= 500 => 'Servis şu anda yanıt vermiyor.',
      _ => message,
    };
  }

  @override
  String toString() => 'AiException($statusCode): $message';
}

abstract class AiService {
  Future<String> reply({
    required String childUtterance,
    required ChildProfile child,
    required Activity activity,
    required List<ChatTurn> history,
  });

  Future<String> summarize({
    required ChildProfile child,
    required List<ChatTurn> turns,
    required SpeechMetrics metrics,
  });

  Future<String> suggestNextFocus({
    required ChildProfile child,
    required SpeechMetrics metrics,
  });

  Future<ConnectionTest> testConnection();

  factory AiService.from(AppSettings s, {http.Client? client}) {
    if (!s.isConfigured) return OfflineAiService();
    return switch (s.provider) {
      AiProvider.gemini => GeminiAiService(s, client: client),
      AiProvider.claude => ClaudeAiService(s, client: client),
      AiProvider.openai => OpenAiService(s, client: client),
      AiProvider.offline => OfflineAiService(),
    };
  }
}

class ConnectionTest {
  final bool ok;
  final String message;
  final Duration latency;
  const ConnectionTest(this.ok, this.message, this.latency);
}

String buildSystemPrompt(ChildProfile child, Activity activity) => '''
Sen "Buddy" adında, çocuklara arkadaşlık eden sıcak ve neşeli bir karaktersin.
Konuştuğun çocuk: ${child.name}, ${child.ageLabel}.
Bugünkü etkinlik: "${activity.title}" — hedef beceri: ${activity.targetSkill}.
Etkinlik yönergesi: ${activity.promptHint}

KURALLAR (istisnasız uy):
1. SADECE Türkçe konuş. Basit, günlük kelimeler kullan.
2. Yanıtın EN FAZLA 2 cümle ve toplam 25 kelime olsun.
3. Her yanıtın sonunda çocuğu konuşmaya davet eden BİR soru sor.
4. Çocuk yanlış telaffuz ederse ASLA düzeltme veya "yanlış" deme.
   Doğru halini cümle içinde doğal biçimde tekrar et.
5. Övgü somut olsun: "Aferin" yerine "'Kaplumbağa' kelimesini çok güzel söyledin!".
6. Korku, şiddet, ölüm, cinsellik, din, siyaset, para konularına GİRME.
   Çocuk açarsa nazikçe konuyu oyuna çevir.
7. Çocuktan kişisel bilgi (adres, okul adı, telefon) İSTEME.
   Kendisi söylerse tekrar etme.
8. Çocuk üzgün veya korkmuş görünürse önce duygusunu adlandır, sonra teselli et,
   sonra bir yetişkinle konuşmasını öner.
9. Emoji, kısaltma ve parantez kullanma; metin sesli okunacak.
10. Çocuk üç turdur tek kelimeyle cevaplıyorsa seçenekli soru sor.
''';

const _summarySystem = '''
Sen bir dil ve konuşma terapisti asistanısın. Sana bir çocuk-yapay zeka
sohbetinin dökümü ve ölçülen metrikler verilecek.
Ebeveyne yönelik, 2 cümlelik, sade ve umut verici bir özet yaz.
Tanı koyma, teşhis ima etme. Somut bir gözlem ve somut bir öneri ver.
''';

const _focusSystem =
    'Bir dil terapisti asistanı olarak, tek cümlede bir sonraki seans '
    'için hangi becerinin çalışılmasını önerdiğini yaz.';

String _metricsLine(ChildProfile c, SpeechMetrics m) =>
    '${c.name} (${c.ageLabel}) — '
    'telaffuz %${(m.articulation * 100).round()}, '
    'akıcılık %${(m.fluency * 100).round()}, '
    'kelime çeşitliliği %${(m.vocabulary * 100).round()}, '
    'hız ${m.wordsPerMinute.round()} kelime/dk, '
    'ortalama cümle ${m.meanUtteranceLength.toStringAsFixed(1)} kelime, '
    'zorlanılan sesler: ${m.difficultPhonemes.isEmpty ? "yok" : m.difficultPhonemes.join(", ")}';

String _transcript(ChildProfile c, List<ChatTurn> turns) => turns
    .map((t) => '${t.speaker == Speaker.child ? c.name : "Buddy"}: ${t.text}')
    .join('\n');

const _timeout = Duration(seconds: 20);

class GeminiAiService implements AiService {
  final AppSettings _s;
  final http.Client _client;
  GeminiAiService(this._s, {http.Client? client})
      : _client = client ?? http.Client();

  static const _model = 'gemini-2.0-flash';

  Uri get _endpoint => _s.useProxy
      ? Uri.parse('${_s.proxyUrl}/gemini')
      : Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$_model:generateContent?key=${_s.apiKey}');

  Future<String> _generate(
    String system,
    List<Map<String, dynamic>> contents, {
    int maxTokens = 120,
  }) async {
    final res = await _client
        .post(
          _endpoint,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': system},
              ],
            },
            'contents': contents,
            'generationConfig': {
              'temperature': 0.85,
              'maxOutputTokens': maxTokens,
              'topP': 0.95,
            },
            'safetySettings': [
              for (final c in const [
                'HARM_CATEGORY_HARASSMENT',
                'HARM_CATEGORY_HATE_SPEECH',
                'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                'HARM_CATEGORY_DANGEROUS_CONTENT',
              ])
                {'category': c, 'threshold': 'BLOCK_LOW_AND_ABOVE'},
            ],
          }),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw AiException(res.body, statusCode: res.statusCode);
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const AiException('Yanıt güvenlik filtresine takıldı.');
    }
    final parts = candidates.first['content']?['parts'] as List?;
    final text = (parts?.first['text'] as String? ?? '').trim();
    if (text.isEmpty) throw const AiException('Boş yanıt alındı.');
    return text;
  }

  @override
  Future<String> reply({
    required String childUtterance,
    required ChildProfile child,
    required Activity activity,
    required List<ChatTurn> history,
  }) =>
      _generate(buildSystemPrompt(child, activity), [
        for (final t in history.lastN(8))
          {
            'role': t.speaker == Speaker.child ? 'user' : 'model',
            'parts': [
              {'text': t.text},
            ],
          },
        {
          'role': 'user',
          'parts': [
            {'text': childUtterance},
          ],
        },
      ]);

  @override
  Future<String> summarize({
    required ChildProfile child,
    required List<ChatTurn> turns,
    required SpeechMetrics metrics,
  }) =>
      _generate(
        _summarySystem,
        [
          {
            'role': 'user',
            'parts': [
              {
                'text': 'DÖKÜM:\n${_transcript(child, turns)}\n\n'
                    'METRİKLER: ${_metricsLine(child, metrics)}',
              },
            ],
          },
        ],
        maxTokens: 180,
      );

  @override
  Future<String> suggestNextFocus({
    required ChildProfile child,
    required SpeechMetrics metrics,
  }) =>
      _generate(
        _focusSystem,
        [
          {
            'role': 'user',
            'parts': [
              {'text': _metricsLine(child, metrics)},
            ],
          },
        ],
        maxTokens: 90,
      );

  @override
  Future<ConnectionTest> testConnection() => _runTest(
        () => _generate(
          'Yalnızca "tamam" yaz.',
          [
            {
              'role': 'user',
              'parts': [
                {'text': 'test'},
              ],
            },
          ],
          maxTokens: 10,
        ),
      );
}

class ClaudeAiService implements AiService {
  final AppSettings _s;
  final http.Client _client;
  ClaudeAiService(this._s, {http.Client? client})
      : _client = client ?? http.Client();

  static const _model = 'claude-sonnet-5';

  Uri get _endpoint => _s.useProxy
      ? Uri.parse('${_s.proxyUrl}/claude')
      : Uri.parse('https://api.anthropic.com/v1/messages');

  Future<String> _generate(
    String system,
    List<Map<String, String>> messages, {
    int maxTokens = 150,
  }) async {
    final res = await _client
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            if (!_s.useProxy) ...{
              'x-api-key': _s.apiKey,
              'anthropic-version': '2023-06-01',
            },
          },
          body: jsonEncode({
            'model': _model,
            'max_tokens': maxTokens,
            'temperature': 0.85,
            'system': system,
            'messages': messages,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw AiException(res.body, statusCode: res.statusCode);
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final content = data['content'] as List?;
    final text = (content?.first['text'] as String? ?? '').trim();
    if (text.isEmpty) throw const AiException('Boş yanıt alındı.');
    return text;
  }

  @override
  Future<String> reply({
    required String childUtterance,
    required ChildProfile child,
    required Activity activity,
    required List<ChatTurn> history,
  }) =>
      _generate(buildSystemPrompt(child, activity), [
        for (final t in history.lastN(8))
          {
            'role': t.speaker == Speaker.child ? 'user' : 'assistant',
            'content': t.text,
          },
        {'role': 'user', 'content': childUtterance},
      ]);

  @override
  Future<String> summarize({
    required ChildProfile child,
    required List<ChatTurn> turns,
    required SpeechMetrics metrics,
  }) =>
      _generate(
        _summarySystem,
        [
          {
            'role': 'user',
            'content': 'DÖKÜM:\n${_transcript(child, turns)}\n\n'
                'METRİKLER: ${_metricsLine(child, metrics)}',
          },
        ],
        maxTokens: 180,
      );

  @override
  Future<String> suggestNextFocus({
    required ChildProfile child,
    required SpeechMetrics metrics,
  }) =>
      _generate(
        _focusSystem,
        [
          {'role': 'user', 'content': _metricsLine(child, metrics)},
        ],
        maxTokens: 90,
      );

  @override
  Future<ConnectionTest> testConnection() => _runTest(
        () => _generate(
          'Yalnızca "tamam" yaz.',
          [
            {'role': 'user', 'content': 'test'},
          ],
          maxTokens: 10,
        ),
      );
}

class OpenAiService implements AiService {
  final AppSettings _s;
  final http.Client _client;
  OpenAiService(this._s, {http.Client? client})
      : _client = client ?? http.Client();

  static const _model = 'gpt-4o-mini';

  Uri get _endpoint => _s.useProxy
      ? Uri.parse('${_s.proxyUrl}/openai')
      : Uri.parse('https://api.openai.com/v1/chat/completions');

  Future<String> _generate(
    String system,
    List<Map<String, String>> messages, {
    int maxTokens = 150,
  }) async {
    final res = await _client
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            if (!_s.useProxy) 'Authorization': 'Bearer ${_s.apiKey}',
          },
          body: jsonEncode({
            'model': _model,
            'max_tokens': maxTokens,
            'temperature': 0.85,
            'messages': [
              {'role': 'system', 'content': system},
              ...messages,
            ],
          }),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw AiException(res.body, statusCode: res.statusCode);
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final text =
        ((data['choices'] as List).first['message']['content'] as String).trim();
    if (text.isEmpty) throw const AiException('Boş yanıt alındı.');
    return text;
  }

  @override
  Future<String> reply({
    required String childUtterance,
    required ChildProfile child,
    required Activity activity,
    required List<ChatTurn> history,
  }) =>
      _generate(buildSystemPrompt(child, activity), [
        for (final t in history.lastN(8))
          {
            'role': t.speaker == Speaker.child ? 'user' : 'assistant',
            'content': t.text,
          },
        {'role': 'user', 'content': childUtterance},
      ]);

  @override
  Future<String> summarize({
    required ChildProfile child,
    required List<ChatTurn> turns,
    required SpeechMetrics metrics,
  }) =>
      _generate(
        _summarySystem,
        [
          {
            'role': 'user',
            'content': 'DÖKÜM:\n${_transcript(child, turns)}\n\n'
                'METRİKLER: ${_metricsLine(child, metrics)}',
          },
        ],
        maxTokens: 180,
      );

  @override
  Future<String> suggestNextFocus({
    required ChildProfile child,
    required SpeechMetrics metrics,
  }) =>
      _generate(
        _focusSystem,
        [
          {'role': 'user', 'content': _metricsLine(child, metrics)},
        ],
        maxTokens: 90,
      );

  @override
  Future<ConnectionTest> testConnection() => _runTest(
        () => _generate(
          'Yalnızca "tamam" yaz.',
          [
            {'role': 'user', 'content': 'test'},
          ],
          maxTokens: 10,
        ),
      );
}

class OfflineAiService implements AiService {
  int _turn = 0;

  static const _lines = [
    'Vay canına, bunu çok güzel anlattın! Peki sonra ne oldu?',
    'Bu gerçekten heyecanlı. Sence en eğlenceli kısmı hangisiydi?',
    'Anladım! Bana biraz daha anlatır mısın?',
    'Harika bir seçim. Rengi neydi peki?',
    'Bunu duyduğuma sevindim. Yanında kim vardı?',
    'Çok güzel söyledin. En sevdiğin hangisi?',
    'Bunu hiç düşünmemiştim! Başka ne yaptınız?',
  ];

  @override
  Future<String> reply({
    required String childUtterance,
    required ChildProfile child,
    required Activity activity,
    required List<ChatTurn> history,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final line = _lines[_turn % _lines.length];
    _turn++;
    final words =
        childUtterance.split(RegExp(r'\s+')).where((w) => w.length > 3).toList();
    if (words.isNotEmpty && _turn.isEven) {
      return '"${words.first}" kelimesini çok net söyledin ${child.name}! $line';
    }
    return line;
  }

  @override
  Future<String> summarize({
    required ChildProfile child,
    required List<ChatTurn> turns,
    required SpeechMetrics metrics,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final p = metrics.difficultPhonemes;
    final tail = p.isEmpty
        ? 'Belirgin bir zorlanma gözlenmedi.'
        : '"${p.first}" sesinde ara ara zorlandı; bu sesle başlayan kelimeleri '
            'oyun içinde tekrar etmek faydalı olur.';
    return '${child.name} bu seansta ${metrics.totalWords} kelime kullandı ve '
        'cümlelerini geçen haftaya göre daha uzun kurdu. $tail';
  }

  @override
  Future<String> suggestNextFocus({
    required ChildProfile child,
    required SpeechMetrics metrics,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (metrics.difficultPhonemes.isNotEmpty) {
      return 'Sonraki seansta "${metrics.difficultPhonemes.first}" sesi içeren '
          'kelimelerle Hayvanlar Ülkesi etkinliği önerilir.';
    }
    return 'Sonraki seansta cümle uzunluğunu artırmaya yönelik '
        'Hikâye Tamamlama etkinliği önerilir.';
  }

  @override
  Future<ConnectionTest> testConnection() async =>
      const ConnectionTest(true, 'Çevrimdışı mod etkin.', Duration.zero);
}

Future<ConnectionTest> _runTest(Future<String> Function() call) async {
  final sw = Stopwatch()..start();
  try {
    await call();
    sw.stop();
    return ConnectionTest(true, 'Bağlantı başarılı.', sw.elapsed);
  } on AiException catch (e) {
    sw.stop();
    return ConnectionTest(false, e.userMessage, sw.elapsed);
  } catch (e) {
    sw.stop();
    return ConnectionTest(false, 'Bağlantı kurulamadı: $e', sw.elapsed);
  }
}

extension<T> on List<T> {
  List<T> lastN(int n) => length <= n ? this : sublist(length - n);
}
