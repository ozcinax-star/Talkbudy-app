# Talk Buddy — Demo kaynakları

`talk_buddy_demo.html` bu klasördeki parçalardan üretilir. Dosyayı elle
düzenlemeyin; parçaları değiştirip yeniden derleyin:

```bash
python3 demo/build.py
```

| Dosya | İçerik |
|---|---|
| `shell.html` | HTML iskeleti ve tüm CSS |
| `content.js` | **Otomatik üretilir** — Dart içerik kütüphanesinden |
| `engine.js` | Fonoloji, değerlendirici, diyalog motoru, ilerleme deposu |
| `speech.js` | Web Speech API (seslendirme + tanıma) |
| `app.js` | Ders oturumu ve çocuk ekranları |
| `panels.js` | Veli, öğretmen, uzman panelleri ve ayarlar |
| `nav.js` | Navigasyon, kabuk, modal/sheet/toast |

## İçeriği yeniden üretme

`content.js` doğrudan `talk_buddy/lib/data/curriculum/content_library.dart`
dosyasından üretilir; böylece uygulama ile demo asla ayrışmaz. Dart tarafındaki
üniteleri veya şablonları değiştirdikten sonra:

```bash
python3 demo/gen_content.py    # content.js'i yeniden üret
python3 demo/build.py          # demoyu derle
```

## Motor eşitliği

`engine.js`, `lib/data/curriculum/` altındaki Dart dosyalarının birebir
portudur. Bir tarafta algoritma değişirse diğerinde de değişmelidir. Eşitliği
doğrulayan testler:

- Dart: `flutter test test/curriculum_test.dart`
- JS  : `node demo/test.js`
