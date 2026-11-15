import 'dart:math';

import '../models/models.dart';

class DemoData {
  DemoData._();

  static const activities = <Activity>[
    Activity(
      id: 'free',
      title: 'Serbest Sohbet',
      subtitle: 'Buddy ile canın ne isterse konuş',
      emoji: '💬',
      colorValue: 0xFF5B6CFF,
      targetSkill: 'Kendiliğinden konuşma',
      promptHint:
          'Çocuğun ilgisini takip et. Açık uçlu sorular sor, konuyu o seçsin.',
      estimatedMinutes: 6,
    ),
    Activity(
      id: 'animals',
      title: 'Hayvanlar Ülkesi',
      subtitle: 'Sesleri taklit et, hayvanları tanı',
      emoji: '🦁',
      colorValue: 0xFFFFC53D,
      targetSkill: 'Sesletim: k, g, r',
      promptHint:
          'Hayvan isimleri ve sesleri üzerinden ilerle. Çocuktan hayvan sesini '
          'taklit etmesini iste. Kaplan, kurbağa, karga gibi k/g/r içeren '
          'kelimeleri öne çıkar.',
      estimatedMinutes: 5,
    ),
    Activity(
      id: 'story',
      title: 'Hikâye Tamamlama',
      subtitle: 'Sen anlat, Buddy devam etsin',
      emoji: '📖',
      colorValue: 0xFFA678FF,
      targetSkill: 'Cümle uzunluğu (MLU)',
      promptHint:
          'Kısa bir hikâye başlat ve yarıda kes. Çocuktan devamını istemek '
          'için "sonra ne oldu?" tarzı sorular sor. Uzun cümle kurmasını teşvik et.',
      estimatedMinutes: 7,
    ),
    Activity(
      id: 'colors',
      title: 'Renkler ve Şekiller',
      subtitle: 'Gördüğünü anlat',
      emoji: '🎨',
      colorValue: 0xFF2ED3A5,
      targetSkill: 'Kelime dağarcığı',
      promptHint:
          'Renk ve şekil isimleri sor. Çocuğun etrafındaki nesneleri tarif '
          'etmesini iste. Sıfat kullanımını teşvik et.',
      estimatedMinutes: 5,
    ),
    Activity(
      id: 'rhyme',
      title: 'Tekerleme Zamanı',
      subtitle: 'Hızlı söyle, dilini şaşırma',
      emoji: '🎵',
      colorValue: 0xFFFF7A6B,
      targetSkill: 'Akıcılık ve ritim',
      promptHint:
          'Basit Türkçe tekerlemeler söyle ve çocuktan tekrar etmesini iste. '
          'Yavaştan hızlıya doğru ilerle. Hata olursa gülüp devam et.',
      estimatedMinutes: 4,
    ),
    Activity(
      id: 'feelings',
      title: 'Duygu Kartları',
      subtitle: 'Bugün nasıl hissediyorsun?',
      emoji: '💛',
      colorValue: 0xFF41C9FF,
      targetSkill: 'Duygu ifadesi',
      promptHint:
          'Duyguları adlandırmasına yardım et. "Ne hissettin?" ve "neden?" '
          'sorularıyla ilerle. Yargılama, yalnızca yansıt.',
      estimatedMinutes: 5,
    ),
  ];

  static final children = <ChildProfile>[
    ChildProfile(
      id: 'c1',
      name: 'Elif',
      ageMonths: 52,
      avatar: '🐰',
      createdAt: DateTime(2026, 4, 12),
      specialistId: 's1',
      stars: 148,
      streakDays: 9,
    ),
    ChildProfile(
      id: 'c2',
      name: 'Kerem',
      ageMonths: 41,
      avatar: '🦊',
      createdAt: DateTime(2026, 5, 3),
      specialistId: 's1',
      stars: 76,
      streakDays: 3,
    ),
    ChildProfile(
      id: 'c3',
      name: 'Deniz',
      ageMonths: 67,
      avatar: '🐢',
      createdAt: DateTime(2026, 3, 21),
      specialistId: 's1',
      stars: 233,
      streakDays: 21,
    ),
    ChildProfile(
      id: 'c4',
      name: 'Zeynep',
      ageMonths: 35,
      avatar: '🐥',
      createdAt: DateTime(2026, 6, 9),
      specialistId: 's1',
      stars: 41,
      streakDays: 1,
    ),
    ChildProfile(
      id: 'c5',
      name: 'Mert',
      ageMonths: 58,
      avatar: '🦕',
      createdAt: DateTime(2026, 2, 14),
      specialistId: 's1',
      stars: 190,
      streakDays: 0,
    ),
  ];

  static ChildProfile get activeChild => children.first;

  static List<DailyPoint> trend(String childId, {int days = 30}) {
    final seed = childId.codeUnits.fold<int>(0, (a, b) => a + b);
    final rnd = Random(seed);
    final base = 0.42 + rnd.nextDouble() * 0.12;
    final slope = 0.004 + rnd.nextDouble() * 0.004;
    final today = DateTime.now();

    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));

      final weekend = day.weekday >= 6;
      final noise = (rnd.nextDouble() - 0.5) * 0.09;
      final overall = (base + slope * i + noise).clamp(0.0, 1.0);
      final minutes = weekend
          ? (rnd.nextInt(6))
          : (4 + rnd.nextInt(11));
      return DailyPoint(
        day: DateTime(day.year, day.month, day.day),
        overall: overall.toDouble(),
        minutes: minutes,
        words: minutes * (18 + rnd.nextInt(22)),
      );
    });
  }

  static SpeechMetrics latestMetrics(String childId) {
    final t = trend(childId, days: 7);
    final last = t.last.overall;
    final seed = childId.codeUnits.fold<int>(0, (a, b) => a + b);
    final rnd = Random(seed + 7);

    return SpeechMetrics(
      articulation: (last + (rnd.nextDouble() - 0.4) * 0.15).clamp(0.05, 0.98),
      fluency: (last + (rnd.nextDouble() - 0.5) * 0.18).clamp(0.05, 0.98),
      vocabulary: (last + (rnd.nextDouble() - 0.35) * 0.2).clamp(0.05, 0.98),
      wordsPerMinute: 55 + rnd.nextDouble() * 55,
      meanUtteranceLength: 2.4 + rnd.nextDouble() * 2.6,
      sentiment: (rnd.nextDouble() * 1.4 - 0.35).clamp(-1.0, 1.0),
      totalWords: 120 + rnd.nextInt(280),
      difficultPhonemes: switch (childId) {
        'c1' => const ['r', 'ş'],
        'c2' => const ['k', 'g', 'r'],
        'c3' => const ['s'],
        'c4' => const ['r', 'l', 'ş'],
        _ => const ['j'],
      },
    );
  }

  static List<Session> sessions(String childId, {int count = 12}) {
    final rnd = Random(childId.hashCode);
    final now = DateTime.now();
    return List.generate(count, (i) {
      final at = now.subtract(Duration(days: i, hours: rnd.nextInt(8)));
      final act = activities[rnd.nextInt(activities.length)];
      final m = latestMetrics(childId);
      return Session(
        id: '$childId-s$i',
        childId: childId,
        startedAt: at,
        duration: Duration(minutes: 3 + rnd.nextInt(9)),
        activity: act.title,
        metrics: m,
        summary: _summaries[rnd.nextInt(_summaries.length)],
        turns: _sampleTurns,
      );
    });
  }

  static const _summaries = [
    'Cümlelerini geçen haftaya göre daha uzun kurdu; "r" sesinde ara ara takıldı.',
    'Bugün çok konuşkandı. Yeni 6 kelime kullandı, duygu durumu belirgin olumluydu.',
    'Seansın ilk yarısında sessizdi, hikâye başlayınca açıldı. Akıcılık iyi.',
    'Telaffuz netliği düne göre yükseldi. Tekrarlı takılmalar azaldı.',
    'Kısa cevaplar verdi. Seçenekli sorularla desteklemek faydalı olabilir.',
  ];

  static final _sampleTurns = <ChatTurn>[
    ChatTurn(
      speaker: Speaker.buddy,
      text: 'Merhaba Elif! Bugün nasılsın? Bana günün nasıl geçtiğini anlatır mısın?',
      at: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    ChatTurn(
      speaker: Speaker.child,
      text: 'İyiyim. Bugün parka gittik',
      at: DateTime.now().subtract(const Duration(minutes: 7, seconds: 40)),
      confidence: 0.88,
    ),
    ChatTurn(
      speaker: Speaker.buddy,
      text: 'Parka gitmek çok eğlenceli! Parkta en çok neyle oynadın?',
      at: DateTime.now().subtract(const Duration(minutes: 7, seconds: 20)),
    ),
    ChatTurn(
      speaker: Speaker.child,
      text: 'Kaydaak. Sonra salıncakla',
      at: DateTime.now().subtract(const Duration(minutes: 7)),
      confidence: 0.61,
      flaggedPhonemes: ['k', 'r'],
    ),
    ChatTurn(
      speaker: Speaker.buddy,
      text: 'Kaydırak ve salıncak, ne güzel! Kaydıraktan kayarken ne hissettin?',
      at: DateTime.now().subtract(const Duration(minutes: 6, seconds: 40)),
    ),
    ChatTurn(
      speaker: Speaker.child,
      text: 'Çok mutlu oldum uçuyorum gibiydi',
      at: DateTime.now().subtract(const Duration(minutes: 6, seconds: 10)),
      confidence: 0.91,
    ),
    ChatTurn(
      speaker: Speaker.buddy,
      text: '"Uçuyorum gibiydi" demen harikaydı! Peki yanında kim vardı?',
      at: DateTime.now().subtract(const Duration(minutes: 5, seconds: 50)),
    ),
  ];

  static List<SpecialistAlert> alerts() {
    final now = DateTime.now();
    return [
      SpecialistAlert(
        id: 'a1',
        childId: 'c5',
        childName: 'Mert',
        level: AlertLevel.urgent,
        message: '6 gündür hiç seans yapılmadı. Aile ile iletişime geçilmesi önerilir.',
        at: now.subtract(const Duration(hours: 3)),
      ),
      SpecialistAlert(
        id: 'a2',
        childId: 'c4',
        childName: 'Zeynep',
        level: AlertLevel.watch,
        message: 'Telaffuz netliği son 5 seansta %14 düştü. "r" ve "l" seslerinde artan zorlanma.',
        at: now.subtract(const Duration(hours: 9)),
      ),
      SpecialistAlert(
        id: 'a3',
        childId: 'c2',
        childName: 'Kerem',
        level: AlertLevel.watch,
        message: 'Ortalama cümle uzunluğu yaş beklentisinin altında (2.6 / beklenen 3.6).',
        at: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      SpecialistAlert(
        id: 'a4',
        childId: 'c3',
        childName: 'Deniz',
        level: AlertLevel.info,
        message: '21 günlük seri! Kelime çeşitliliği hedefin üzerinde seyrediyor.',
        at: now.subtract(const Duration(days: 1, hours: 6)),
      ),
    ];
  }

  static const badges = <(String emoji, String title, String desc, bool earned)>[
    ('🔥', '7 Gün Seri', 'Yedi gün üst üste konuştun', true),
    ('🗣️', 'Konuşkan', 'Tek seansta 100 kelime', true),
    ('🦁', 'Hayvan Dostu', 'Hayvanlar Ülkesi 5 kez', true),
    ('📖', 'Hikâyeci', 'Bir hikâyeyi sonuna kadar anlat', true),
    ('⭐', 'Yıldız Avcısı', '100 yıldız topla', true),
    ('🎵', 'Tekerleme Ustası', 'Tekerlemeyi hatasız söyle', false),
    ('🏆', '30 Gün Seri', 'Otuz gün üst üste konuş', false),
    ('🚀', 'Uzay Kaşifi', 'Tüm etkinlikleri dene', false),
  ];
}
