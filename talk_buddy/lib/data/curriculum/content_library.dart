import 'curriculum_models.dart';

class ContentLibrary {
  ContentLibrary._();

  static const _characters = SlotFill('karakter', [
    'tavşan Pamuk', 'kedi Minnoş', 'ayı Koca', 'kuş Cıvıl', 'fil Koko',
    'köpek Karabaş', 'kaplumbağa Ağır', 'sincap Fındık', 'kurbağa Vırak',
  ]);

  static const _places = SlotFill('yer', [
    'parkta', 'bahçede', 'ormanda', 'deniz kenarında', 'evde',
    'okulda', 'markette', 'kütüphanede', 'oyun alanında',
  ]);

  static const _times = SlotFill('zaman', [
    'bu sabah', 'dün akşam', 'öğleden sonra', 'hafta sonu', 'geçen gün',
  ]);

  static const templates = <ExerciseTemplate>[
    // ---------- Ünite 1: İlk Sesler (p, b, m) ----------
    ExerciseTemplate(
      id: 'lr_pbm',
      type: ExerciseType.listenRepeat,
      domain: SkillDomain.articulation,
      targetPhonemes: ['p', 'b', 'm'],
      difficulty: 1,
      emoji: '👄',
      prompts: [
        'Dudaklarını birleştir ve benimle söyle: {kelime}',
        'Şimdi sıra sende. {kelime} diyebilir misin?',
        'Ben söyleyeyim, sen tekrar et: {kelime}',
        'Bu kelime çok eğlenceli: {kelime}. Sen de dene!',
        'Hazır mısın? {kelime}',
      ],
      slots: [
        SlotFill('kelime', [
          'baba', 'maymun', 'para', 'burun', 'masa', 'balon', 'muz',
          'pasta', 'bebek', 'memnun', 'pencere', 'bardak', 'mum', 'patates',
        ]),
      ],
      encouragements: [
        'Dudakların tam yerinde!',
        'Bu sesi çok iyi çıkarıyorsun.',
      ],
    ),
    ExerciseTemplate(
      id: 'np_pbm',
      type: ExerciseType.namePicture,
      domain: SkillDomain.vocabulary,
      targetPhonemes: ['p', 'b', 'm'],
      difficulty: 1,
      prompts: [
        'Bak bakalım, bu ne?',
        'Bunu tanıdın mı? Adı ne?',
        'Bunun adını söyleyebilir misin?',
        'Şunu bir gör! Bu nedir?',
      ],
      slots: [
        SlotFill('görsel', ['🍌|muz', '🎈|balon', '🐵|maymun', '🎂|pasta', '👶|bebek', '🥔|patates']),
      ],
    ),

    // ---------- Ünite 2: Dil Ucu Sesleri (t, d, n) ----------
    ExerciseTemplate(
      id: 'lr_tdn',
      type: ExerciseType.listenRepeat,
      domain: SkillDomain.articulation,
      targetPhonemes: ['t', 'd', 'n'],
      difficulty: 1,
      emoji: '👅',
      prompts: [
        'Dilinin ucunu dişlerinin arkasına koy ve söyle: {kelime}',
        'Şimdi bunu deneyelim: {kelime}',
        'Kulağını ver, sonra sen söyle: {kelime}',
        'Bu kelimeyi çok seviyorum: {kelime}. Sen de söyler misin?',
      ],
      slots: [
        SlotFill('kelime', [
          'top', 'tavuk', 'dede', 'defter', 'nine', 'nar', 'tabak',
          'davul', 'nokta', 'tren', 'dondurma', 'nane', 'telefon', 'domates',
        ]),
      ],
    ),
    ExerciseTemplate(
      id: 'mp_td',
      type: ExerciseType.minimalPair,
      domain: SkillDomain.auditory,
      targetPhonemes: ['t', 'd'],
      difficulty: 2,
      prompts: [
        'Dikkatli dinle. Hangisini söyledim?',
        'Kulaklarını aç bakalım, hangisiydi?',
        'İki kelime çok benziyor. Hangisini duydun?',
      ],
      slots: [
        SlotFill('çift', ['tam|dam|0', 'tas|das|0', 'dal|tal|0', 'top|dop|0', 'diş|tiş|0']),
      ],
    ),

    // ---------- Ünite 3: Arka Sesler (k, g) ----------
    ExerciseTemplate(
      id: 'lr_kg',
      type: ExerciseType.listenRepeat,
      domain: SkillDomain.articulation,
      targetPhonemes: ['k', 'g'],
      difficulty: 2,
      emoji: '🗣️',
      prompts: [
        'Bu ses boğazının arkasından gelir. Dene: {kelime}',
        'Şimdi biraz zor bir tane: {kelime}',
        'Ben söyleyeyim, sen tekrar et: {kelime}',
        'Bunu söyleyebilir misin? {kelime}',
        'Hadi bakalım: {kelime}',
      ],
      slots: [
        SlotFill('kelime', [
          'kedi', 'kapı', 'kuş', 'kalem', 'köpek', 'kitap', 'kaşık',
          'gül', 'göz', 'gemi', 'gözlük', 'güneş', 'kelebek', 'karpuz', 'gitar',
        ]),
      ],
      encouragements: [
        'Bu ses gerçekten zor, sen çok iyi yapıyorsun.',
        'Arka sesler ustası oluyorsun!',
      ],
    ),
    ExerciseTemplate(
      id: 'cp_kg',
      type: ExerciseType.choosePicture,
      domain: SkillDomain.auditory,
      targetPhonemes: ['k', 'g'],
      difficulty: 2,
      prompts: [
        'Söylediğim şeyi bul: {hedef}',
        'Hangisi {hedef}? Dokun bakalım.',
        '{hedef} nerede? Bulabilir misin?',
      ],
      slots: [
        SlotFill('set', ['kedi|🐱🐶🐦|0', 'kuş|🐟🐦🐰|1', 'gemi|🚗🚲🚢|2', 'güneş|🌙⭐☀️|2', 'kitap|📕🎒✏️|0']),
      ],
    ),

    // ---------- Ünite 4: Sürtünmeli Sesler (f, v, s, z) ----------
    ExerciseTemplate(
      id: 'lr_fvsz',
      type: ExerciseType.listenRepeat,
      domain: SkillDomain.articulation,
      targetPhonemes: ['f', 'v', 's', 'z'],
      difficulty: 3,
      emoji: '💨',
      prompts: [
        'Bu ses yılan gibi uzun: {kelime}. Dene bakalım.',
        'Havayı yavaşça bırak ve söyle: {kelime}',
        'Şimdi sıra sende: {kelime}',
        'Bu kelime biraz uzun soluklu: {kelime}',
      ],
      slots: [
        SlotFill('kelime', [
          'fil', 'fener', 'fırça', 'vazo', 'vapur', 'su', 'saat',
          'sepet', 'zebra', 'zil', 'zeytin', 'salıncak', 'fındık', 'volkan',
        ]),
      ],
    ),
    ExerciseTemplate(
      id: 'mp_sz',
      type: ExerciseType.minimalPair,
      domain: SkillDomain.auditory,
      targetPhonemes: ['s', 'z'],
      difficulty: 3,
      prompts: [
        'İyi dinle, hangisiydi?',
        'Bu ikisi çok benziyor. Hangisini söyledim?',
        'Kulağını aç: hangisi?',
      ],
      slots: [
        SlotFill('çift', ['sar|zar|0', 'sil|zil|0', 'buz|bus|0', 'kaz|kas|0', 'saman|zaman|0']),
      ],
    ),

    // ---------- Ünite 5: Zor Sesler (ş, ç, c, j) ----------
    ExerciseTemplate(
      id: 'lr_scj',
      type: ExerciseType.listenRepeat,
      domain: SkillDomain.articulation,
      targetPhonemes: ['ş', 'ç', 'c'],
      difficulty: 4,
      emoji: '🤫',
      prompts: [
        'Dudaklarını hafif büz ve söyle: {kelime}',
        'Bu ses "şşş" gibi başlar: {kelime}',
        'Zor ama sen yaparsın: {kelime}',
        'Ben söyleyeyim, sen dene: {kelime}',
      ],
      slots: [
        SlotFill('kelime', [
          'şeker', 'şapka', 'şemsiye', 'çiçek', 'çorap', 'çanta',
          'ceket', 'cam', 'ceviz', 'şarkı', 'çilek', 'cüzdan', 'şeftali',
        ]),
      ],
      encouragements: [
        'Bu ses beş yaşında bile zordur, sen çok iyisin.',
      ],
    ),

    // ---------- Ünite 6: R Macerası ----------
    ExerciseTemplate(
      id: 'lr_r',
      type: ExerciseType.listenRepeat,
      domain: SkillDomain.articulation,
      targetPhonemes: ['r'],
      difficulty: 5,
      emoji: '🐯',
      prompts: [
        'Dilini titret bakalım: {kelime}',
        'Bu en zor ses ama sen deneyeceksin: {kelime}',
        'Kaplan gibi: {kelime}',
        'Ben söyleyeyim, sen istediğin kadar dene: {kelime}',
        'Acele yok, yavaşça: {kelime}',
      ],
      slots: [
        SlotFill('kelime', [
          'araba', 'radyo', 'resim', 'ruh', 'ördek', 'kırmızı',
          'portakal', 'tren', 'kraliçe', 'arı', 'orman', 'merdiven', 'kartal',
        ]),
      ],
      encouragements: [
        '"r" sesi altı yaşına kadar oturmayabilir, denemen bile harika.',
        'Bu sesi denediğin için gurur duyuyorum.',
      ],
    ),
    ExerciseTemplate(
      id: 'cs_r',
      type: ExerciseType.completeSentence,
      domain: SkillDomain.syntax,
      targetPhonemes: ['r'],
      difficulty: 4,
      prompts: [
        'Cümleyi tamamla: {cümle}',
        'Devamını sen söyle: {cümle}',
        'Şunu bitirebilir misin? {cümle}',
      ],
      slots: [
        SlotFill('cümle', [
          'Yolda giden şeyin adı... |araba',
          'Kırmızı ve yuvarlak meyve... |elma',
          'Ağaçların çok olduğu yer... |orman',
          'Bal yapan küçük böcek... |arı',
          'Rayların üzerinde giden... |tren',
        ]),
      ],
    ),

    // ---------- Ünite 7: L Yolculuğu ----------
    ExerciseTemplate(
      id: 'lr_l',
      type: ExerciseType.listenRepeat,
      domain: SkillDomain.articulation,
      targetPhonemes: ['l'],
      difficulty: 3,
      emoji: '🍋',
      prompts: [
        'Dilinin ucunu yukarı kaldır: {kelime}',
        'Şimdi bunu söyleyelim: {kelime}',
        'Sen de dener misin? {kelime}',
        'Kulağını ver: {kelime}',
      ],
      slots: [
        SlotFill('kelime', [
          'limon', 'lale', 'lamba', 'balık', 'kalem', 'elma',
          'salatalık', 'kelebek', 'gölge', 'yelken', 'lokum', 'çilek',
        ]),
      ],
    ),

    // ---------- Ünite 8: Kelime Bahçesi ----------
    ExerciseTemplate(
      id: 'np_kategori',
      type: ExerciseType.namePicture,
      domain: SkillDomain.vocabulary,
      difficulty: 2,
      prompts: [
        'Bu ne? Adını söyler misin?',
        'Bunu biliyor musun? Nedir?',
        'Bak bakalım, karşımızda ne var?',
        'Bunun adı ne acaba?',
      ],
      slots: [
        SlotFill('görsel', [
          '🦁|aslan', '🐘|fil', '🚌|otobüs', '🏠|ev', '🌳|ağaç',
          '☂️|şemsiye', '🧦|çorap', '🍇|üzüm', '🐢|kaplumbağa', '🚲|bisiklet',
          '🪑|sandalye', '🕰️|saat', '🧸|oyuncak ayı', '🍉|karpuz',
        ]),
      ],
    ),
    ExerciseTemplate(
      id: 'aq_kategori',
      type: ExerciseType.answerQuestion,
      domain: SkillDomain.vocabulary,
      difficulty: 3,
      prompts: [
        'Bana üç tane {kategori} sayabilir misin?',
        '{kategori} deyince aklına neler geliyor?',
        'Hangi {kategori} isimlerini biliyorsun?',
        'En sevdiğin {kategori} hangisi? Neden?',
      ],
      slots: [
        SlotFill('kategori', [
          'hayvan', 'meyve', 'sebze', 'renk', 'oyuncak',
          'araç', 'giysi', 'mutfak eşyası', 'okul eşyası',
        ]),
      ],
    ),

    // ---------- Ünite 9: Cümle Kurma ----------
    ExerciseTemplate(
      id: 'cs_syntax',
      type: ExerciseType.completeSentence,
      domain: SkillDomain.syntax,
      difficulty: 3,
      prompts: [
        'Cümleyi tamamla: {cümle}',
        'Şunun devamını söyle: {cümle}',
        'Nasıl biter bu cümle? {cümle}',
      ],
      slots: [
        SlotFill('cümle', [
          'Ben acıkınca... |yemek yerim',
          'Yağmur yağınca... |şemsiye açarım',
          'Uykum gelince... |yatarım',
          'Üşüyünce... |mont giyerim',
          'Parka gidince... |oynarım',
          'Anneme sarılınca... |mutlu olurum',
          'Karnım doyunca... |oyun oynarım',
        ]),
      ],
    ),
    ExerciseTemplate(
      id: 'aq_syntax',
      type: ExerciseType.answerQuestion,
      domain: SkillDomain.syntax,
      difficulty: 4,
      prompts: [
        '{karakter} {yer} ne yapıyor olabilir? Uzun bir cümleyle anlat.',
        '{zaman} {yer} neler oldu, anlatır mısın?',
        '{karakter} hakkında bana iki cümle söyler misin?',
      ],
      slots: [_characters, _places, _times],
    ),

    // ---------- Ünite 10: Hikâye Zamanı ----------
    ExerciseTemplate(
      id: 'rs_story',
      type: ExerciseType.retellStory,
      domain: SkillDomain.narrative,
      difficulty: 4,
      prompts: [
        '{hikâye} Şimdi sen anlat bakalım, ne oldu?',
        '{hikâye} Sonra ne olmuş olabilir?',
        '{hikâye} Bu hikâyeyi bana kendi cümlelerinle anlatır mısın?',
      ],
      slots: [
        SlotFill('hikâye', [
          'Küçük tavşan bahçede bir havuç bulmuş, ama havuç çok büyükmüş.',
          'Kedi Minnoş ağaca çıkmış, sonra inemeyince miyavlamaya başlamış.',
          'Bir çocuk parkta topunu kaybetmiş, sonra bir arkadaşı bulmuş.',
          'Kuş Cıvıl yuvasını yapmak için dal toplamış, ama rüzgâr çıkmış.',
          'Fil Koko su içmeye gitmiş, hortumuyla herkese su sıçratmış.',
          'Kaplumbağa yarışa katılmış, çok yavaşmış ama hiç durmamış.',
        ]),
      ],
    ),

    // ---------- Ünite 11: Duygu Dünyası ----------
    ExerciseTemplate(
      id: 'em_emotion',
      type: ExerciseType.emotionMatch,
      domain: SkillDomain.pragmatics,
      difficulty: 3,
      prompts: [
        '{durum} Sence ne hissetti?',
        '{durum} O an nasıl hissetmiş olabilir?',
        '{durum} Sen olsan ne hissederdin?',
      ],
      slots: [
        SlotFill('durum', [
          'Ali\'nin balonu patladı.|üzgün|üzüldü|kötü|ağladı',
          'Zeynep doğum günü hediyesi aldı.|mutlu|sevindi|heyecanlı|güzel',
          'Karanlıkta bir ses duyuldu.|korktu|korkmuş|ürktü',
          'Deniz oyuncağını arkadaşıyla paylaştı.|mutlu|iyi|güzel|sevindi',
          'Kerem yaptığı resmi öğretmenine gösterdi.|gururlu|mutlu|sevindi|heyecanlı',
          'Elif en sevdiği oyuncağını kaybetti.|üzgün|üzüldü|ağladı',
        ]),
      ],
    ),
    ExerciseTemplate(
      id: 'aq_pragmatics',
      type: ExerciseType.answerQuestion,
      domain: SkillDomain.pragmatics,
      difficulty: 3,
      prompts: [
        'Bugün seni ne mutlu etti?',
        'Bir arkadaşın üzgün olsa ona ne söylerdin?',
        'Bir şey isteyeceğin zaman nasıl söylersin?',
        'En sevdiğin oyunu bana anlatır mısın?',
        'Bugün sana iyi gelen bir şey oldu mu?',
      ],
      slots: [],
    ),

    // ---------- Tekerlemeler ----------
    ExerciseTemplate(
      id: 'tt_fluency',
      type: ExerciseType.tongueTwister,
      domain: SkillDomain.articulation,
      difficulty: 4,
      emoji: '🎵',
      prompts: [
        'Benimle söyle: {tekerleme}',
        'Şimdi eğlenceli kısım! {tekerleme}',
        'Yavaş başlayalım: {tekerleme}',
        'Hazır mısın? {tekerleme}',
      ],
      slots: [
        SlotFill('tekerleme', [
          'Bir berber bir berbere gel beraber berber dükkânı açalım demiş.',
          'Şu köşe yaz köşesi, şu köşe kış köşesi.',
          'Al bu takatukaları takatukacıya götür.',
          'Dal sarkar kartal kalkar, kartal kalkar dal sarkar.',
          'Kırk küp, kırkının da kulpu kırık küp.',
          'Bu yoğurdu sarımsaklasak da mı saklasak?',
        ]),
      ],
    ),
  ];

  static ExerciseTemplate? byId(String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  static const units = <Unit>[
    Unit(
      id: 'u1',
      title: 'İlk Sesler',
      subtitle: 'Dudak sesleri: p, b, m',
      emoji: '👄',
      colorValue: 0xFF5B6CFF,
      domain: SkillDomain.articulation,
      targetPhonemes: ['p', 'b', 'm'],
      minAgeMonths: 24,
      lessons: [
        Lesson(id: 'u1l1', unitId: 'u1', title: 'Tanışalım', index: 0,
            templateIds: ['lr_pbm', 'np_pbm'], exerciseCount: 5),
        Lesson(id: 'u1l2', unitId: 'u1', title: 'Kelime Avı', index: 1,
            templateIds: ['np_pbm', 'lr_pbm', 'np_kategori'], exerciseCount: 6),
        Lesson(id: 'u1l3', unitId: 'u1', title: 'Sohbet Vakti', index: 2,
            templateIds: ['lr_pbm', 'aq_pragmatics'], exerciseCount: 6),
      ],
    ),
    Unit(
      id: 'u2',
      title: 'Dil Ucu',
      subtitle: 'Dil sesleri: t, d, n',
      emoji: '👅',
      colorValue: 0xFF2ED3A5,
      domain: SkillDomain.articulation,
      targetPhonemes: ['t', 'd', 'n'],
      minAgeMonths: 26,
      lessons: [
        Lesson(id: 'u2l1', unitId: 'u2', title: 'Yeni Sesler', index: 0,
            templateIds: ['lr_tdn'], exerciseCount: 5),
        Lesson(id: 'u2l2', unitId: 'u2', title: 'Kulak Kesil', index: 1,
            templateIds: ['mp_td', 'lr_tdn'], exerciseCount: 6),
        Lesson(id: 'u2l3', unitId: 'u2', title: 'Birlikte Kuralım', index: 2,
            templateIds: ['lr_tdn', 'cs_syntax'], exerciseCount: 6),
      ],
    ),
    Unit(
      id: 'u3',
      title: 'Arka Sesler',
      subtitle: 'Boğaz sesleri: k, g',
      emoji: '🎯',
      colorValue: 0xFFFFC53D,
      domain: SkillDomain.articulation,
      targetPhonemes: ['k', 'g'],
      minAgeMonths: 32,
      lessons: [
        Lesson(id: 'u3l1', unitId: 'u3', title: 'Derinden Gelen', index: 0,
            templateIds: ['lr_kg'], exerciseCount: 5),
        Lesson(id: 'u3l2', unitId: 'u3', title: 'Bul Bakalım', index: 1,
            templateIds: ['cp_kg', 'lr_kg'], exerciseCount: 6),
        Lesson(id: 'u3l3', unitId: 'u3', title: 'Kelime Bahçesi', index: 2,
            templateIds: ['lr_kg', 'np_kategori', 'aq_kategori'], exerciseCount: 7),
      ],
    ),
    Unit(
      id: 'u4',
      title: 'Uzun Sesler',
      subtitle: 'Sürtünmeli: f, v, s, z',
      emoji: '💨',
      colorValue: 0xFF41C9FF,
      domain: SkillDomain.articulation,
      targetPhonemes: ['f', 'v', 's', 'z'],
      minAgeMonths: 36,
      lessons: [
        Lesson(id: 'u4l1', unitId: 'u4', title: 'Yılan Sesi', index: 0,
            templateIds: ['lr_fvsz'], exerciseCount: 5),
        Lesson(id: 'u4l2', unitId: 'u4', title: 'Hangisi?', index: 1,
            templateIds: ['mp_sz', 'lr_fvsz'], exerciseCount: 6),
        Lesson(id: 'u4l3', unitId: 'u4', title: 'Cümle Kur', index: 2,
            templateIds: ['lr_fvsz', 'cs_syntax'], exerciseCount: 6),
      ],
    ),
    Unit(
      id: 'u5',
      title: 'L Yolculuğu',
      subtitle: 'l sesi',
      emoji: '🍋',
      colorValue: 0xFF22C55E,
      domain: SkillDomain.articulation,
      targetPhonemes: ['l'],
      minAgeMonths: 42,
      lessons: [
        Lesson(id: 'u5l1', unitId: 'u5', title: 'Dil Yukarı', index: 0,
            templateIds: ['lr_l'], exerciseCount: 5),
        Lesson(id: 'u5l2', unitId: 'u5', title: 'Kelimelerle', index: 1,
            templateIds: ['lr_l', 'np_kategori'], exerciseCount: 6),
        Lesson(id: 'u5l3', unitId: 'u5', title: 'Tekerleme', index: 2,
            templateIds: ['lr_l', 'tt_fluency'], exerciseCount: 5),
      ],
    ),
    Unit(
      id: 'u6',
      title: 'Zor Sesler',
      subtitle: 'ş, ç, c sesleri',
      emoji: '🤫',
      colorValue: 0xFFA678FF,
      domain: SkillDomain.articulation,
      targetPhonemes: ['ş', 'ç', 'c'],
      minAgeMonths: 46,
      lessons: [
        Lesson(id: 'u6l1', unitId: 'u6', title: 'Fısıltı Sesleri', index: 0,
            templateIds: ['lr_scj'], exerciseCount: 5),
        Lesson(id: 'u6l2', unitId: 'u6', title: 'Kelime Ustası', index: 1,
            templateIds: ['lr_scj', 'np_kategori'], exerciseCount: 6),
        Lesson(id: 'u6l3', unitId: 'u6', title: 'Anlat Bakalım', index: 2,
            templateIds: ['lr_scj', 'aq_kategori'], exerciseCount: 6),
      ],
    ),
    Unit(
      id: 'u7',
      title: 'R Macerası',
      subtitle: 'En zor ses: r',
      emoji: '🐯',
      colorValue: 0xFFFF7A6B,
      domain: SkillDomain.articulation,
      targetPhonemes: ['r'],
      minAgeMonths: 54,
      lessons: [
        Lesson(id: 'u7l1', unitId: 'u7', title: 'İlk Adım', index: 0,
            templateIds: ['lr_r'], exerciseCount: 5),
        Lesson(id: 'u7l2', unitId: 'u7', title: 'Cümlede R', index: 1,
            templateIds: ['lr_r', 'cs_r'], exerciseCount: 6),
        Lesson(id: 'u7l3', unitId: 'u7', title: 'Tekerleme Ustası', index: 2,
            templateIds: ['lr_r', 'tt_fluency'], exerciseCount: 6),
      ],
    ),
    Unit(
      id: 'u8',
      title: 'Kelime Bahçesi',
      subtitle: 'Kelime dağarcığı',
      emoji: '📚',
      colorValue: 0xFF3B82F6,
      domain: SkillDomain.vocabulary,
      minAgeMonths: 36,
      lessons: [
        Lesson(id: 'u8l1', unitId: 'u8', title: 'Bu Ne?', index: 0,
            templateIds: ['np_kategori'], exerciseCount: 6),
        Lesson(id: 'u8l2', unitId: 'u8', title: 'Kategoriler', index: 1,
            templateIds: ['aq_kategori', 'np_kategori'], exerciseCount: 6),
        Lesson(id: 'u8l3', unitId: 'u8', title: 'Anlat Bana', index: 2,
            templateIds: ['aq_kategori', 'aq_syntax'], exerciseCount: 5),
      ],
    ),
    Unit(
      id: 'u9',
      title: 'Cümle Kurma',
      subtitle: 'Uzun cümleler',
      emoji: '🧩',
      colorValue: 0xFFF59E0B,
      domain: SkillDomain.syntax,
      minAgeMonths: 42,
      lessons: [
        Lesson(id: 'u9l1', unitId: 'u9', title: 'Tamamla', index: 0,
            templateIds: ['cs_syntax'], exerciseCount: 6),
        Lesson(id: 'u9l2', unitId: 'u9', title: 'Uzat Bakalım', index: 1,
            templateIds: ['cs_syntax', 'aq_syntax'], exerciseCount: 6),
        Lesson(id: 'u9l3', unitId: 'u9', title: 'Serbest Anlatım', index: 2,
            templateIds: ['aq_syntax'], exerciseCount: 5),
      ],
    ),
    Unit(
      id: 'u10',
      title: 'Hikâye Zamanı',
      subtitle: 'Anlatı becerisi',
      emoji: '📖',
      colorValue: 0xFF8B5CF6,
      domain: SkillDomain.narrative,
      minAgeMonths: 48,
      lessons: [
        Lesson(id: 'u10l1', unitId: 'u10', title: 'Dinle ve Anlat', index: 0,
            templateIds: ['rs_story'], exerciseCount: 4),
        Lesson(id: 'u10l2', unitId: 'u10', title: 'Sonunu Sen Yaz', index: 1,
            templateIds: ['rs_story', 'aq_syntax'], exerciseCount: 5),
        Lesson(id: 'u10l3', unitId: 'u10', title: 'Hikâye Ustası', index: 2,
            templateIds: ['rs_story'], exerciseCount: 5),
      ],
    ),
    Unit(
      id: 'u11',
      title: 'Duygu Dünyası',
      subtitle: 'Sosyal iletişim',
      emoji: '💛',
      colorValue: 0xFFEC4899,
      domain: SkillDomain.pragmatics,
      minAgeMonths: 42,
      lessons: [
        Lesson(id: 'u11l1', unitId: 'u11', title: 'Ne Hissetti?', index: 0,
            templateIds: ['em_emotion'], exerciseCount: 5),
        Lesson(id: 'u11l2', unitId: 'u11', title: 'Ben Nasılım?', index: 1,
            templateIds: ['em_emotion', 'aq_pragmatics'], exerciseCount: 6),
        Lesson(id: 'u11l3', unitId: 'u11', title: 'Arkadaşlık', index: 2,
            templateIds: ['aq_pragmatics'], exerciseCount: 5),
      ],
    ),
  ];

  static Unit? unitById(String id) {
    for (final u in units) {
      if (u.id == id) return u;
    }
    return null;
  }

  static Lesson? lessonById(String id) {
    for (final u in units) {
      for (final l in u.lessons) {
        if (l.id == id) return l;
      }
    }
    return null;
  }

  static List<Lesson> get allLessons =>
      [for (final u in units) ...u.lessons];

  static const openers = [
    'Merhaba {ad}! Bugün {ünite} üzerinde çalışacağız. Hazır mısın?',
    'Selam {ad}! Seni görmek çok güzel. Bugün {ünite} var.',
    'Hoş geldin {ad}! Bugün birlikte {ünite} çalışalım mı?',
    'Merhaba {ad}! Bugünkü macera: {ünite}. Başlayalım!',
    'Seni bekliyordum {ad}! {ünite} bizi çağırıyor.',
  ];

  static const closers = [
    'Bugün çok iyi çalıştın {ad}. Seninle konuşmak harikaydı!',
    'Ne güzel bir ders oldu! Yarın yine bekliyorum seni {ad}.',
    '{ad}, bugün sesin çok güzel çıktı. Kendinle gurur duy!',
    'Harika iş çıkardın {ad}. Görüşmek üzere!',
    'Bugünkü çalışman için teşekkürler {ad}. Çok eğlendim.',
  ];

  static const transitions = [
    'Şimdi sıradakine geçelim.',
    'Hadi devam edelim!',
    'Bir sonraki geliyor.',
    'Şimdi başka bir şey deneyelim.',
    'Sırada güzel bir tane var.',
    'Devam ediyoruz!',
  ];
}
