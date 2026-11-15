/* ===========================================================================
   Talk Buddy - Icerik kutuphanesi
   OTOMATIK URETILDI: lib/data/curriculum/content_library.dart dosyasindan.
   Elle duzenlemeyin; Dart tarafini degistirip 'python3 demo/gen_content.py' calistirin.
   =========================================================================== */
'use strict';

const TEMPLATES = [
  {
    "id": "lr_pbm",
    "type": "listenRepeat",
    "domain": "articulation",
    "targetPhonemes": [
      "p",
      "b",
      "m"
    ],
    "difficulty": 1,
    "emoji": "👄",
    "prompts": [
      "Dudaklarını birleştir ve benimle söyle: {kelime}",
      "Şimdi sıra sende. {kelime} diyebilir misin?",
      "Ben söyleyeyim, sen tekrar et: {kelime}",
      "Bu kelime çok eğlenceli: {kelime}. Sen de dene!",
      "Hazır mısın? {kelime}"
    ],
    "slots": [
      {
        "key": "kelime",
        "values": [
          "baba",
          "maymun",
          "para",
          "burun",
          "masa",
          "balon",
          "muz",
          "pasta",
          "bebek",
          "memnun",
          "pencere",
          "bardak",
          "mum",
          "patates"
        ]
      }
    ]
  },
  {
    "id": "np_pbm",
    "type": "namePicture",
    "domain": "vocabulary",
    "targetPhonemes": [
      "p",
      "b",
      "m"
    ],
    "difficulty": 1,
    "emoji": "",
    "prompts": [
      "Bak bakalım, bu ne?",
      "Bunu tanıdın mı? Adı ne?",
      "Bunun adını söyleyebilir misin?",
      "Şunu bir gör! Bu nedir?"
    ],
    "slots": [
      {
        "key": "görsel",
        "values": [
          "🍌|muz",
          "🎈|balon",
          "🐵|maymun",
          "🎂|pasta",
          "👶|bebek",
          "🥔|patates"
        ]
      }
    ]
  },
  {
    "id": "lr_tdn",
    "type": "listenRepeat",
    "domain": "articulation",
    "targetPhonemes": [
      "t",
      "d",
      "n"
    ],
    "difficulty": 1,
    "emoji": "👅",
    "prompts": [
      "Dilinin ucunu dişlerinin arkasına koy ve söyle: {kelime}",
      "Şimdi bunu deneyelim: {kelime}",
      "Kulağını ver, sonra sen söyle: {kelime}",
      "Bu kelimeyi çok seviyorum: {kelime}. Sen de söyler misin?"
    ],
    "slots": [
      {
        "key": "kelime",
        "values": [
          "top",
          "tavuk",
          "dede",
          "defter",
          "nine",
          "nar",
          "tabak",
          "davul",
          "nokta",
          "tren",
          "dondurma",
          "nane",
          "telefon",
          "domates"
        ]
      }
    ]
  },
  {
    "id": "mp_td",
    "type": "minimalPair",
    "domain": "auditory",
    "targetPhonemes": [
      "t",
      "d"
    ],
    "difficulty": 2,
    "emoji": "",
    "prompts": [
      "Dikkatli dinle. Hangisini söyledim?",
      "Kulaklarını aç bakalım, hangisiydi?",
      "İki kelime çok benziyor. Hangisini duydun?"
    ],
    "slots": [
      {
        "key": "çift",
        "values": [
          "tam|dam|0",
          "tas|das|0",
          "dal|tal|0",
          "top|dop|0",
          "diş|tiş|0"
        ]
      }
    ]
  },
  {
    "id": "lr_kg",
    "type": "listenRepeat",
    "domain": "articulation",
    "targetPhonemes": [
      "k",
      "g"
    ],
    "difficulty": 2,
    "emoji": "🗣️",
    "prompts": [
      "Bu ses boğazının arkasından gelir. Dene: {kelime}",
      "Şimdi biraz zor bir tane: {kelime}",
      "Ben söyleyeyim, sen tekrar et: {kelime}",
      "Bunu söyleyebilir misin? {kelime}",
      "Hadi bakalım: {kelime}"
    ],
    "slots": [
      {
        "key": "kelime",
        "values": [
          "kedi",
          "kapı",
          "kuş",
          "kalem",
          "köpek",
          "kitap",
          "kaşık",
          "gül",
          "göz",
          "gemi",
          "gözlük",
          "güneş",
          "kelebek",
          "karpuz",
          "gitar"
        ]
      }
    ]
  },
  {
    "id": "cp_kg",
    "type": "choosePicture",
    "domain": "auditory",
    "targetPhonemes": [
      "k",
      "g"
    ],
    "difficulty": 2,
    "emoji": "",
    "prompts": [
      "Söylediğim şeyi bul: {hedef}",
      "Hangisi {hedef}? Dokun bakalım.",
      "{hedef} nerede? Bulabilir misin?"
    ],
    "slots": [
      {
        "key": "set",
        "values": [
          "kedi|🐱🐶🐦|0",
          "kuş|🐟🐦🐰|1",
          "gemi|🚗🚲🚢|2",
          "güneş|🌙⭐☀️|2",
          "kitap|📕🎒✏️|0"
        ]
      }
    ]
  },
  {
    "id": "lr_fvsz",
    "type": "listenRepeat",
    "domain": "articulation",
    "targetPhonemes": [
      "f",
      "v",
      "s",
      "z"
    ],
    "difficulty": 3,
    "emoji": "💨",
    "prompts": [
      "Bu ses yılan gibi uzun: {kelime}. Dene bakalım.",
      "Havayı yavaşça bırak ve söyle: {kelime}",
      "Şimdi sıra sende: {kelime}",
      "Bu kelime biraz uzun soluklu: {kelime}"
    ],
    "slots": [
      {
        "key": "kelime",
        "values": [
          "fil",
          "fener",
          "fırça",
          "vazo",
          "vapur",
          "su",
          "saat",
          "sepet",
          "zebra",
          "zil",
          "zeytin",
          "salıncak",
          "fındık",
          "volkan"
        ]
      }
    ]
  },
  {
    "id": "mp_sz",
    "type": "minimalPair",
    "domain": "auditory",
    "targetPhonemes": [
      "s",
      "z"
    ],
    "difficulty": 3,
    "emoji": "",
    "prompts": [
      "İyi dinle, hangisiydi?",
      "Bu ikisi çok benziyor. Hangisini söyledim?",
      "Kulağını aç: hangisi?"
    ],
    "slots": [
      {
        "key": "çift",
        "values": [
          "sar|zar|0",
          "sil|zil|0",
          "buz|bus|0",
          "kaz|kas|0",
          "saman|zaman|0"
        ]
      }
    ]
  },
  {
    "id": "lr_scj",
    "type": "listenRepeat",
    "domain": "articulation",
    "targetPhonemes": [
      "ş",
      "ç",
      "c"
    ],
    "difficulty": 4,
    "emoji": "🤫",
    "prompts": [
      "Dudaklarını hafif büz ve söyle: {kelime}",
      "Bu ses \"şşş\" gibi başlar: {kelime}",
      "Zor ama sen yaparsın: {kelime}",
      "Ben söyleyeyim, sen dene: {kelime}"
    ],
    "slots": [
      {
        "key": "kelime",
        "values": [
          "şeker",
          "şapka",
          "şemsiye",
          "çiçek",
          "çorap",
          "çanta",
          "ceket",
          "cam",
          "ceviz",
          "şarkı",
          "çilek",
          "cüzdan",
          "şeftali"
        ]
      }
    ]
  },
  {
    "id": "lr_r",
    "type": "listenRepeat",
    "domain": "articulation",
    "targetPhonemes": [
      "r"
    ],
    "difficulty": 5,
    "emoji": "🐯",
    "prompts": [
      "Dilini titret bakalım: {kelime}",
      "Bu en zor ses ama sen deneyeceksin: {kelime}",
      "Kaplan gibi: {kelime}",
      "Ben söyleyeyim, sen istediğin kadar dene: {kelime}",
      "Acele yok, yavaşça: {kelime}"
    ],
    "slots": [
      {
        "key": "kelime",
        "values": [
          "araba",
          "radyo",
          "resim",
          "ruh",
          "ördek",
          "kırmızı",
          "portakal",
          "tren",
          "kraliçe",
          "arı",
          "orman",
          "merdiven",
          "kartal"
        ]
      }
    ]
  },
  {
    "id": "cs_r",
    "type": "completeSentence",
    "domain": "syntax",
    "targetPhonemes": [
      "r"
    ],
    "difficulty": 4,
    "emoji": "",
    "prompts": [
      "Cümleyi tamamla: {cümle}",
      "Devamını sen söyle: {cümle}",
      "Şunu bitirebilir misin? {cümle}"
    ],
    "slots": [
      {
        "key": "cümle",
        "values": [
          "Yolda giden şeyin adı... |araba",
          "Kırmızı ve yuvarlak meyve... |elma",
          "Ağaçların çok olduğu yer... |orman",
          "Bal yapan küçük böcek... |arı",
          "Rayların üzerinde giden... |tren"
        ]
      }
    ]
  },
  {
    "id": "lr_l",
    "type": "listenRepeat",
    "domain": "articulation",
    "targetPhonemes": [
      "l"
    ],
    "difficulty": 3,
    "emoji": "🍋",
    "prompts": [
      "Dilinin ucunu yukarı kaldır: {kelime}",
      "Şimdi bunu söyleyelim: {kelime}",
      "Sen de dener misin? {kelime}",
      "Kulağını ver: {kelime}"
    ],
    "slots": [
      {
        "key": "kelime",
        "values": [
          "limon",
          "lale",
          "lamba",
          "balık",
          "kalem",
          "elma",
          "salatalık",
          "kelebek",
          "gölge",
          "yelken",
          "lokum",
          "çilek"
        ]
      }
    ]
  },
  {
    "id": "np_kategori",
    "type": "namePicture",
    "domain": "vocabulary",
    "targetPhonemes": [],
    "difficulty": 2,
    "emoji": "",
    "prompts": [
      "Bu ne? Adını söyler misin?",
      "Bunu biliyor musun? Nedir?",
      "Bak bakalım, karşımızda ne var?",
      "Bunun adı ne acaba?"
    ],
    "slots": [
      {
        "key": "görsel",
        "values": [
          "🦁|aslan",
          "🐘|fil",
          "🚌|otobüs",
          "🏠|ev",
          "🌳|ağaç",
          "☂️|şemsiye",
          "🧦|çorap",
          "🍇|üzüm",
          "🐢|kaplumbağa",
          "🚲|bisiklet",
          "🪑|sandalye",
          "🕰️|saat",
          "🧸|oyuncak ayı",
          "🍉|karpuz"
        ]
      }
    ]
  },
  {
    "id": "aq_kategori",
    "type": "answerQuestion",
    "domain": "vocabulary",
    "targetPhonemes": [],
    "difficulty": 3,
    "emoji": "",
    "prompts": [
      "Bana üç tane {kategori} sayabilir misin?",
      "{kategori} deyince aklına neler geliyor?",
      "Hangi {kategori} isimlerini biliyorsun?",
      "En sevdiğin {kategori} hangisi? Neden?"
    ],
    "slots": [
      {
        "key": "kategori",
        "values": [
          "hayvan",
          "meyve",
          "sebze",
          "renk",
          "oyuncak",
          "araç",
          "giysi",
          "mutfak eşyası",
          "okul eşyası"
        ]
      }
    ]
  },
  {
    "id": "cs_syntax",
    "type": "completeSentence",
    "domain": "syntax",
    "targetPhonemes": [],
    "difficulty": 3,
    "emoji": "",
    "prompts": [
      "Cümleyi tamamla: {cümle}",
      "Şunun devamını söyle: {cümle}",
      "Nasıl biter bu cümle? {cümle}"
    ],
    "slots": [
      {
        "key": "cümle",
        "values": [
          "Ben acıkınca... |yemek yerim",
          "Yağmur yağınca... |şemsiye açarım",
          "Uykum gelince... |yatarım",
          "Üşüyünce... |mont giyerim",
          "Parka gidince... |oynarım",
          "Anneme sarılınca... |mutlu olurum",
          "Karnım doyunca... |oyun oynarım"
        ]
      }
    ]
  },
  {
    "id": "aq_syntax",
    "type": "answerQuestion",
    "domain": "syntax",
    "targetPhonemes": [],
    "difficulty": 4,
    "emoji": "",
    "prompts": [
      "{karakter} {yer} ne yapıyor olabilir? Uzun bir cümleyle anlat.",
      "{zaman} {yer} neler oldu, anlatır mısın?",
      "{karakter} hakkında bana iki cümle söyler misin?"
    ],
    "slots": [
      {
        "key": "karakter",
        "values": [
          "tavşan Pamuk",
          "kedi Minnoş",
          "ayı Koca",
          "kuş Cıvıl",
          "fil Koko",
          "köpek Karabaş",
          "kaplumbağa Ağır",
          "sincap Fındık",
          "kurbağa Vırak"
        ]
      },
      {
        "key": "yer",
        "values": [
          "parkta",
          "bahçede",
          "ormanda",
          "deniz kenarında",
          "evde",
          "okulda",
          "markette",
          "kütüphanede",
          "oyun alanında"
        ]
      },
      {
        "key": "zaman",
        "values": [
          "bu sabah",
          "dün akşam",
          "öğleden sonra",
          "hafta sonu",
          "geçen gün"
        ]
      }
    ]
  },
  {
    "id": "rs_story",
    "type": "retellStory",
    "domain": "narrative",
    "targetPhonemes": [],
    "difficulty": 4,
    "emoji": "",
    "prompts": [
      "{hikâye} Şimdi sen anlat bakalım, ne oldu?",
      "{hikâye} Sonra ne olmuş olabilir?",
      "{hikâye} Bu hikâyeyi bana kendi cümlelerinle anlatır mısın?"
    ],
    "slots": [
      {
        "key": "hikâye",
        "values": [
          "Küçük tavşan bahçede bir havuç bulmuş, ama havuç çok büyükmüş.",
          "Kedi Minnoş ağaca çıkmış, sonra inemeyince miyavlamaya başlamış.",
          "Bir çocuk parkta topunu kaybetmiş, sonra bir arkadaşı bulmuş.",
          "Kuş Cıvıl yuvasını yapmak için dal toplamış, ama rüzgâr çıkmış.",
          "Fil Koko su içmeye gitmiş, hortumuyla herkese su sıçratmış.",
          "Kaplumbağa yarışa katılmış, çok yavaşmış ama hiç durmamış."
        ]
      }
    ]
  },
  {
    "id": "em_emotion",
    "type": "emotionMatch",
    "domain": "pragmatics",
    "targetPhonemes": [],
    "difficulty": 3,
    "emoji": "",
    "prompts": [
      "{durum} Sence ne hissetti?",
      "{durum} O an nasıl hissetmiş olabilir?",
      "{durum} Sen olsan ne hissederdin?"
    ],
    "slots": [
      {
        "key": "durum",
        "values": [
          "Ali'nin balonu patladı.|üzgün|üzüldü|kötü|ağladı",
          "Zeynep doğum günü hediyesi aldı.|mutlu|sevindi|heyecanlı|güzel",
          "Karanlıkta bir ses duyuldu.|korktu|korkmuş|ürktü",
          "Deniz oyuncağını arkadaşıyla paylaştı.|mutlu|iyi|güzel|sevindi",
          "Kerem yaptığı resmi öğretmenine gösterdi.|gururlu|mutlu|sevindi|heyecanlı",
          "Elif en sevdiği oyuncağını kaybetti.|üzgün|üzüldü|ağladı"
        ]
      }
    ]
  },
  {
    "id": "aq_pragmatics",
    "type": "answerQuestion",
    "domain": "pragmatics",
    "targetPhonemes": [],
    "difficulty": 3,
    "emoji": "",
    "prompts": [
      "Bugün seni ne mutlu etti?",
      "Bir arkadaşın üzgün olsa ona ne söylerdin?",
      "Bir şey isteyeceğin zaman nasıl söylersin?",
      "En sevdiğin oyunu bana anlatır mısın?",
      "Bugün sana iyi gelen bir şey oldu mu?"
    ],
    "slots": []
  },
  {
    "id": "tt_fluency",
    "type": "tongueTwister",
    "domain": "articulation",
    "targetPhonemes": [],
    "difficulty": 4,
    "emoji": "🎵",
    "prompts": [
      "Benimle söyle: {tekerleme}",
      "Şimdi eğlenceli kısım! {tekerleme}",
      "Yavaş başlayalım: {tekerleme}",
      "Hazır mısın? {tekerleme}"
    ],
    "slots": [
      {
        "key": "tekerleme",
        "values": [
          "Bir berber bir berbere gel beraber berber dükkânı açalım demiş.",
          "Şu köşe yaz köşesi, şu köşe kış köşesi.",
          "Al bu takatukaları takatukacıya götür.",
          "Dal sarkar kartal kalkar, kartal kalkar dal sarkar.",
          "Kırk küp, kırkının da kulpu kırık küp.",
          "Bu yoğurdu sarımsaklasak da mı saklasak?"
        ]
      }
    ]
  }
];

const UNITS = [
  {
    "id": "u1",
    "title": "İlk Sesler",
    "subtitle": "Dudak sesleri: p, b, m",
    "emoji": "👄",
    "color": "#5B6CFF",
    "domain": "articulation",
    "targetPhonemes": [
      "p",
      "b",
      "m"
    ],
    "minAgeMonths": 24,
    "lessons": [
      {
        "id": "u1l1",
        "unitId": "u1",
        "title": "Tanışalım",
        "index": 0,
        "templateIds": [
          "lr_pbm",
          "np_pbm"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u1l2",
        "unitId": "u1",
        "title": "Kelime Avı",
        "index": 1,
        "templateIds": [
          "np_pbm",
          "lr_pbm",
          "np_kategori"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u1l3",
        "unitId": "u1",
        "title": "Sohbet Vakti",
        "index": 2,
        "templateIds": [
          "lr_pbm",
          "aq_pragmatics"
        ],
        "exerciseCount": 6
      }
    ]
  },
  {
    "id": "u2",
    "title": "Dil Ucu",
    "subtitle": "Dil sesleri: t, d, n",
    "emoji": "👅",
    "color": "#2ED3A5",
    "domain": "articulation",
    "targetPhonemes": [
      "t",
      "d",
      "n"
    ],
    "minAgeMonths": 26,
    "lessons": [
      {
        "id": "u2l1",
        "unitId": "u2",
        "title": "Yeni Sesler",
        "index": 0,
        "templateIds": [
          "lr_tdn"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u2l2",
        "unitId": "u2",
        "title": "Kulak Kesil",
        "index": 1,
        "templateIds": [
          "mp_td",
          "lr_tdn"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u2l3",
        "unitId": "u2",
        "title": "Birlikte Kuralım",
        "index": 2,
        "templateIds": [
          "lr_tdn",
          "cs_syntax"
        ],
        "exerciseCount": 6
      }
    ]
  },
  {
    "id": "u3",
    "title": "Arka Sesler",
    "subtitle": "Boğaz sesleri: k, g",
    "emoji": "🎯",
    "color": "#FFC53D",
    "domain": "articulation",
    "targetPhonemes": [
      "k",
      "g"
    ],
    "minAgeMonths": 32,
    "lessons": [
      {
        "id": "u3l1",
        "unitId": "u3",
        "title": "Derinden Gelen",
        "index": 0,
        "templateIds": [
          "lr_kg"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u3l2",
        "unitId": "u3",
        "title": "Bul Bakalım",
        "index": 1,
        "templateIds": [
          "cp_kg",
          "lr_kg"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u3l3",
        "unitId": "u3",
        "title": "Kelime Bahçesi",
        "index": 2,
        "templateIds": [
          "lr_kg",
          "np_kategori",
          "aq_kategori"
        ],
        "exerciseCount": 7
      }
    ]
  },
  {
    "id": "u4",
    "title": "Uzun Sesler",
    "subtitle": "Sürtünmeli: f, v, s, z",
    "emoji": "💨",
    "color": "#41C9FF",
    "domain": "articulation",
    "targetPhonemes": [
      "f",
      "v",
      "s",
      "z"
    ],
    "minAgeMonths": 36,
    "lessons": [
      {
        "id": "u4l1",
        "unitId": "u4",
        "title": "Yılan Sesi",
        "index": 0,
        "templateIds": [
          "lr_fvsz"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u4l2",
        "unitId": "u4",
        "title": "Hangisi?",
        "index": 1,
        "templateIds": [
          "mp_sz",
          "lr_fvsz"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u4l3",
        "unitId": "u4",
        "title": "Cümle Kur",
        "index": 2,
        "templateIds": [
          "lr_fvsz",
          "cs_syntax"
        ],
        "exerciseCount": 6
      }
    ]
  },
  {
    "id": "u5",
    "title": "L Yolculuğu",
    "subtitle": "l sesi",
    "emoji": "🍋",
    "color": "#22C55E",
    "domain": "articulation",
    "targetPhonemes": [
      "l"
    ],
    "minAgeMonths": 42,
    "lessons": [
      {
        "id": "u5l1",
        "unitId": "u5",
        "title": "Dil Yukarı",
        "index": 0,
        "templateIds": [
          "lr_l"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u5l2",
        "unitId": "u5",
        "title": "Kelimelerle",
        "index": 1,
        "templateIds": [
          "lr_l",
          "np_kategori"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u5l3",
        "unitId": "u5",
        "title": "Tekerleme",
        "index": 2,
        "templateIds": [
          "lr_l",
          "tt_fluency"
        ],
        "exerciseCount": 5
      }
    ]
  },
  {
    "id": "u6",
    "title": "Zor Sesler",
    "subtitle": "ş, ç, c sesleri",
    "emoji": "🤫",
    "color": "#A678FF",
    "domain": "articulation",
    "targetPhonemes": [
      "ş",
      "ç",
      "c"
    ],
    "minAgeMonths": 46,
    "lessons": [
      {
        "id": "u6l1",
        "unitId": "u6",
        "title": "Fısıltı Sesleri",
        "index": 0,
        "templateIds": [
          "lr_scj"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u6l2",
        "unitId": "u6",
        "title": "Kelime Ustası",
        "index": 1,
        "templateIds": [
          "lr_scj",
          "np_kategori"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u6l3",
        "unitId": "u6",
        "title": "Anlat Bakalım",
        "index": 2,
        "templateIds": [
          "lr_scj",
          "aq_kategori"
        ],
        "exerciseCount": 6
      }
    ]
  },
  {
    "id": "u7",
    "title": "R Macerası",
    "subtitle": "En zor ses: r",
    "emoji": "🐯",
    "color": "#FF7A6B",
    "domain": "articulation",
    "targetPhonemes": [
      "r"
    ],
    "minAgeMonths": 54,
    "lessons": [
      {
        "id": "u7l1",
        "unitId": "u7",
        "title": "İlk Adım",
        "index": 0,
        "templateIds": [
          "lr_r"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u7l2",
        "unitId": "u7",
        "title": "Cümlede R",
        "index": 1,
        "templateIds": [
          "lr_r",
          "cs_r"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u7l3",
        "unitId": "u7",
        "title": "Tekerleme Ustası",
        "index": 2,
        "templateIds": [
          "lr_r",
          "tt_fluency"
        ],
        "exerciseCount": 6
      }
    ]
  },
  {
    "id": "u8",
    "title": "Kelime Bahçesi",
    "subtitle": "Kelime dağarcığı",
    "emoji": "📚",
    "color": "#3B82F6",
    "domain": "vocabulary",
    "targetPhonemes": [],
    "minAgeMonths": 36,
    "lessons": [
      {
        "id": "u8l1",
        "unitId": "u8",
        "title": "Bu Ne?",
        "index": 0,
        "templateIds": [
          "np_kategori"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u8l2",
        "unitId": "u8",
        "title": "Kategoriler",
        "index": 1,
        "templateIds": [
          "aq_kategori",
          "np_kategori"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u8l3",
        "unitId": "u8",
        "title": "Anlat Bana",
        "index": 2,
        "templateIds": [
          "aq_kategori",
          "aq_syntax"
        ],
        "exerciseCount": 5
      }
    ]
  },
  {
    "id": "u9",
    "title": "Cümle Kurma",
    "subtitle": "Uzun cümleler",
    "emoji": "🧩",
    "color": "#F59E0B",
    "domain": "syntax",
    "targetPhonemes": [],
    "minAgeMonths": 42,
    "lessons": [
      {
        "id": "u9l1",
        "unitId": "u9",
        "title": "Tamamla",
        "index": 0,
        "templateIds": [
          "cs_syntax"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u9l2",
        "unitId": "u9",
        "title": "Uzat Bakalım",
        "index": 1,
        "templateIds": [
          "cs_syntax",
          "aq_syntax"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u9l3",
        "unitId": "u9",
        "title": "Serbest Anlatım",
        "index": 2,
        "templateIds": [
          "aq_syntax"
        ],
        "exerciseCount": 5
      }
    ]
  },
  {
    "id": "u10",
    "title": "Hikâye Zamanı",
    "subtitle": "Anlatı becerisi",
    "emoji": "📖",
    "color": "#8B5CF6",
    "domain": "narrative",
    "targetPhonemes": [],
    "minAgeMonths": 48,
    "lessons": [
      {
        "id": "u10l1",
        "unitId": "u10",
        "title": "Dinle ve Anlat",
        "index": 0,
        "templateIds": [
          "rs_story"
        ],
        "exerciseCount": 4
      },
      {
        "id": "u10l2",
        "unitId": "u10",
        "title": "Sonunu Sen Yaz",
        "index": 1,
        "templateIds": [
          "rs_story",
          "aq_syntax"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u10l3",
        "unitId": "u10",
        "title": "Hikâye Ustası",
        "index": 2,
        "templateIds": [
          "rs_story"
        ],
        "exerciseCount": 5
      }
    ]
  },
  {
    "id": "u11",
    "title": "Duygu Dünyası",
    "subtitle": "Sosyal iletişim",
    "emoji": "💛",
    "color": "#EC4899",
    "domain": "pragmatics",
    "targetPhonemes": [],
    "minAgeMonths": 42,
    "lessons": [
      {
        "id": "u11l1",
        "unitId": "u11",
        "title": "Ne Hissetti?",
        "index": 0,
        "templateIds": [
          "em_emotion"
        ],
        "exerciseCount": 5
      },
      {
        "id": "u11l2",
        "unitId": "u11",
        "title": "Ben Nasılım?",
        "index": 1,
        "templateIds": [
          "em_emotion",
          "aq_pragmatics"
        ],
        "exerciseCount": 6
      },
      {
        "id": "u11l3",
        "unitId": "u11",
        "title": "Arkadaşlık",
        "index": 2,
        "templateIds": [
          "aq_pragmatics"
        ],
        "exerciseCount": 5
      }
    ]
  }
];

const OPENERS = [
  "Merhaba {ad}! Bugün {ünite} üzerinde çalışacağız. Hazır mısın?",
  "Selam {ad}! Seni görmek çok güzel. Bugün {ünite} var.",
  "Hoş geldin {ad}! Bugün birlikte {ünite} çalışalım mı?",
  "Merhaba {ad}! Bugünkü macera: {ünite}. Başlayalım!",
  "Seni bekliyordum {ad}! {ünite} bizi çağırıyor."
];

const CLOSERS = [
  "Bugün çok iyi çalıştın {ad}. Seninle konuşmak harikaydı!",
  "Ne güzel bir ders oldu! Yarın yine bekliyorum seni {ad}.",
  "{ad}, bugün sesin çok güzel çıktı. Kendinle gurur duy!",
  "Harika iş çıkardın {ad}. Görüşmek üzere!",
  "Bugünkü çalışman için teşekkürler {ad}. Çok eğlendim."
];

const TRANSITIONS = [
  "Şimdi sıradakine geçelim.",
  "Hadi devam edelim!",
  "Bir sonraki geliyor.",
  "Şimdi başka bir şey deneyelim.",
  "Sırada güzel bir tane var.",
  "Devam ediyoruz!"
];

const ALL_LESSONS = UNITS.flatMap(u => u.lessons);
const lessonById = id => ALL_LESSONS.find(l => l.id === id) || null;
const unitById = id => UNITS.find(u => u.id === id) || null;
