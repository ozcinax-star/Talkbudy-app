# Talk Buddy

Konuşma ve dil gelişiminde desteğe ihtiyaç duyan çocuklar için sesli, cezasız, oyunlaştırılmış öğrenme uygulaması. Buddy sesli soru sorar, çocuk konuşarak cevaplar, uygulama cevabı çocuk fonolojisine toleranslı biçimde değerlendirir. **Beta 0.9.0.**

- Site ve çalışan demo: https://ozcinax-star.github.io/Talkbudy-app/
- Android APK: [Releases](https://github.com/ozcinax-star/Talkbudy-app/releases/latest) sayfasındaki `TalkBuddy-0.9.0.apk`

## İçerik

| Klasör | Ne |
|---|---|
| `talk_buddy/` | Flutter (Android) uygulaması. Ayrıntılı belge: [talk_buddy/README.md](talk_buddy/README.md) |
| `demo/` | Tarayıcı demosunun kaynakları (`python demo/build.py`). Ders motorunun JS portu |
| `talk_buddy_demo.html` | Derlenmiş tek dosyalık çalışan demo |
| `talk_buddy_onizleme.html` | Ön izleme sayfası |
| `site/` | GitHub Pages sitesi |
| `store_icon_512.png` | Uygulama simgesi |

## Kurulum

**APK:** Releases'tan indirin, telefonda "bilinmeyen kaynaklardan yükleme"ye izin verin. APK debug anahtarıyla imzalıdır (Play Store sürümü değildir).

**Kaynaktan derleme:** Flutter 3.24.x ve JDK 17 ile test edildi.
```
cd talk_buddy
copy android\local.properties.example android\local.properties   # yolları düzenleyin
flutter pub get
flutter build apk --release
```

## API anahtarı

Uygulamada gömülü anahtar yoktur. İlk açılış çevrimdışı moddadır ve tüm ders akışı anahtarsız çalışır. Yapay zekâ sohbeti için Gemini, Claude veya OpenAI anahtarınızı uygulamada Ayarlar > Yapay Zekâ ekranından kendiniz girersiniz. Derleme sırasında isteğe bağlı: `--dart-define=AI_API_KEY=...` (APK'ya gömülür, paylaşmayın).

## Durum

- Beta; tanı aracı değildir, uzman değerlendirmesinin yerini tutmaz.
- Windows .exe yoktur: ürün mobil uygulamadır, masaüstü karşılığı tarayıcı demosudur.
- APK derlendi ve paket bilgisi doğrulandı; gerçek cihazda uçtan uca denenmedi.

## Lisans

Kod: MIT ([LICENSE](LICENSE)).

## English

Talk Buddy is a voice-first, errorless-learning app for children with speech and language delays (Turkish). Flutter/Android app plus a browser demo. Try the demo on the site above; grab the APK from Releases. No API key is bundled; AI providers are optional and configured in-app.
