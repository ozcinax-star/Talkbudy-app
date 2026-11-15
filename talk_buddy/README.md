# Talk Buddy — Beta 0.9.0

Konuşma ve dil gelişiminde desteğe ihtiyaç duyan çocuklar için sesli, oyunlaştırılmış bir öğrenme uygulaması. Buddy sesli soru sorar, çocuk konuşarak cevaplar, uygulama cevabı değerlendirip bölümü geçirir.

Flutter · Android · Cihaz üstü ses tanıma · Gemini / Claude / OpenAI

---

## Hızlı başlangıç

```powershell
cd talk_buddy

copy android\local.properties.example android\local.properties
#    Dosyayı açıp sdk.dir ve flutter.sdk satırlarını kendi yollarınızla değiştirin

flutter pub get
flutter run
```

`android/` klasörü hazırdır — `flutter create` gerekmez. İlk açılışta uygulama **çevrimdışı moddadır**; API anahtarı ve internet olmadan tüm ders akışı çalışır.

**Build:** `flutter build apk --release` · Ayrıntılı imzalama adımları bölüm 7'de.

---

## 1. Öğrenme sistemi

Uygulamanın çekirdeği bir müfredat motorudur. Duolingo'ya benzeyen bir yol haritası vardır ama **öğrenme modeli kasıtlı olarak farklıdır.**

### 1.1 Neden "can" sistemi yok

Duolingo modeli 3 hata sonrası dersi kilitler. Konuşma geriliği olan bir çocuk için bu **aktif olarak zararlıdır**: çocuk zaten günde onlarca kez anlaşılamıyor; uygulamada da cezalandırılırsa konuşma kaçınması (speech avoidance) gelişir — yani konuşmaktan kaçınmayı öğrenir.

Bunun yerine **hatasız öğrenme (errorless learning)** ilkesi kuruldu:

| Kural | Uygulaması |
|---|---|
| Can/kalp yok | Yanlış cevap hiçbir şey kaybettirmez |
| Her denemede kazanım var | Kısmi cevap 1, iyi cevap 2, ilk seferde doğru 3 yıldız |
| Üçüncü denemede asla başarısız olunmaz | `attempt >= 3` ise sonuç en kötü ihtimalle `partial` |
| Telaffuz bölüm geçmeyi **engellemez** | Sadece ölçülür ve uzmana raporlanır |
| Ders %60 başarıyla geçilir | Kalan %40 zaten öğrenmenin normal parçası |

### 1.2 Kademeli ipucu (scaffolding)

Çocuk zorlandığında uygulama zorluğu **kendisi düşürür**:

```
1. deneme başarısız → Buddy yavaşça tekrar modeller
2. deneme başarısız → İlk hece ipucu verilir ("kal...")
3. deneme          → "Hadi birlikte söyleyelim" — kabul edilir, ilerlenir
```

### 1.3 Çocuk fonolojisini tolere eden değerlendirme

Bu, sistemin klinik olarak en kritik parçası. Konuşma tanıma motoru çocuğun söylediğini "tedi" olarak döndürür; hedef kelime "kedi"dir. Standart metin eşleştirme bunu başarısız sayar — ve çocuk hiç ilerleyemez.

`PhonologyMatcher`, Türkçedeki **gelişimsel ses süreçlerini** bilir ve bunları yakın eşleşme olarak kabul eder:

| Süreç | Örnek | Tipik düzelme yaşı |
|---|---|---|
| Öne alma (fronting) | kedi → tedi | 42 ay |
| Durdurma (stopping) | su → tu | 48 ay |
| Kayma (gliding) | araba → ayaba | 66 ay |
| Akıcı ses değişimi | araba → alaba | 60 ay |
| Küme sadeleştirme | tren → ten | 48 ay |
| Son ses düşmesi | kitap → kita | 36 ay |
| Hece düşmesi | kelebek → kebek | 48 ay |
| Ötümsüzleşme | baba → papa | 40 ay |

Doğrulanmış davranış:

```
Çocuk dedi   Hedef     Yaş   Skor   Tespit               Karar
tedi         kedi      40    1.00   fronting             GEÇTİ
ayaba        araba     48    1.00   gliding              GEÇTİ
ten          tren      40    1.00   clusterReduction     GEÇTİ
kebek        kelebek   44    0.84   syllableDeletion     GEÇTİ
köpek        kedi      48    0.20   —                    tekrar
```

Çocuk ilerler, **süreç uzmanın paneline yazılır.** Yaş süreci geçmişse (örneğin 60 aylık çocukta hâlâ öne alma varsa) skor bonusu düşürülür ve klinik uyarı üretilir.

### 1.4 Diyalog üretimi — her seferinde farklı

Üç katmanlı:

1. **Elle yazılmış çekirdek** — terapötik dil kurallarına göre yazılmış istem ve geri bildirim havuzları
2. **Yuvalı şablonlar** — `{kelime}`, `{karakter}`, `{yer}`, `{durum}` yuvaları kombinatoryal çeşitlilik üretir
3. **Ağırlıklı seçim** — tekrar önleme (recency), ustalığa göre hedef ağırlıklandırma, aralıklı tekrar (Leitner)

**1.899 benzersiz alıştırma** kombinasyonu. Aynı ders iki kez oynandığında farklı içerik gelir; aynı ders içinde kelime tekrarı olmaz.

Seçim ağırlığı `_templateWeight()` ile hesaplanır: ustalığı düşük ses `+3`, tekrar zamanı gelmiş ses `+2`, ustalaşmış ses `−1`.

### 1.5 Müfredat — Türkçe fonolojik edinim sırasına göre

```
İlk Sesler (24 ay)  p, b, m        →  Dil Ucu (26 ay)    t, d, n
Arka Sesler (32 ay) k, g           →  Uzun Sesler (36 ay) f, v, s, z
L Yolculuğu (42 ay) l              →  Zor Sesler (46 ay)  ş, ç, c
R Macerası (54 ay)  r
Kelime Bahçesi · Cümle Kurma · Hikâye Zamanı · Duygu Dünyası
```

11 ünite · 33 ders · 9 alıştırma türü:

`listenRepeat` · `namePicture` · `choosePicture` · `minimalPair` · `answerQuestion` · `completeSentence` · `retellStory` · `emotionMatch` · `tongueTwister`

`choosePicture` ve `minimalPair` ses gerektirmez — mikrofon çalışmadığında veya çocuk konuşmak istemediğinde de ilerleme mümkündür.

### 1.6 Ustalık ve aralıklı tekrar

Her ses için `PhonemeMastery` tutulur: skor (0–1), Leitner kutusu (0–4), son görülme tarihi. Kutu aralıkları `[0, 1, 3, 7, 16]` gün. Doğru cevap kutuyu yükseltir, yanlış düşürür. Ders üretilirken vadesi gelmiş sesler öne çıkarılır.

---

## 2. Roller ve giriş

| Rol | Giriş | Sekmeler |
|---|---|---|
| Çocuk | Doğrudan | Öğren · Sohbet · Rozetler |
| Veli | 4 haneli PIN | Panel · Seanslar · Ayarlar |
| Öğretmen | 4 haneli PIN | Sınıfım · Raporlar · Ayarlar |
| Uzman | — | Danışanlar · Uyarılar · Ayarlar |

PIN ilk girişte oluşturulur, `sha256` + cihaza özel tuz ile saklanır. Çocuk ekranındaki kilit simgesi rastgele çarpım sorusu sorar (küçük çocuğun geçemeyeceği, yetişkinin anında geçeceği eşik).

Öğretmen paneli sınıf bazlı çalışır: her sınıfın öğrenci listesi, müfredat ilerlemesi, ses ustalık haritası ve pasiflik uyarısı. Öğrenci detayında 20 Türkçe ünsüzün renk kodlu ustalık ızgarası vardır.

> **Not:** Bu yerel bir profil sistemidir; gerçek kimlik doğrulama sunucu gerektirir (bölüm 8).

---

## 3. Yapay zeka servisi

Uygulama içinden: **Ayarlar → Yapay Zeka → sağlayıcı seç → anahtar gir → bağlantıyı test et**

| Sağlayıcı | Anahtar | Not |
|---|---|---|
| Çevrimdışı Demo | — | Varsayılan. İnternet gerekmez, ders akışı tam çalışır |
| Google Gemini | aistudio.google.com/apikey | Ücretsiz kotası var |
| Anthropic Claude | console.anthropic.com | Tutarlı Türkçe |
| OpenAI | platform.openai.com/api-keys | Yaygın alternatif |

**Ders motoru yapay zekadan bağımsızdır.** 1.899 alıştırmanın tamamı çevrimdışı üretilir. Yapay zeka yalnızca serbest sohbet modunda ve seans özetlerinde devreye girer — internet kesilse bile dersler çalışmaya devam eder.

### Yayında anahtar güvenliği

APK içindeki anahtar okunabilir. **Ayarlar → "Kendi sunucum üzerinden bağlan"** açılıp sunucu adresi girilir:

```
Telefon → sizin sunucunuz (anahtar burada) → sağlayıcı
```

Beklenen uç noktalar: `POST {taban}/gemini` · `/claude` · `/openai`

---

## 4. Ses akışı

```
Çocuk konuşur
   → [CİHAZ] Android SpeechRecognizer → metin + güven skoru
   → [CİHAZ] PhonologyMatcher → gelişimsel süreç tespiti
   → [CİHAZ] AnswerEvaluator → verdict + kademeli ipucu
   → [CİHAZ] Redactor → telefon/adres/kimlik maskeleme
   → [BULUT] yalnızca arındırılmış METİN (opsiyonel)
   → Buddy'nin yanıtı → cihazda seslendirme
```

Ham ses kaydı cihazdan çıkmaz. Değerlendirme tamamen cihaz üstündedir — gecikme yok, maliyet yok, KVKK riski minimum.

---

## 5. Yapı

```
lib/
├── main.dart
├── core/{theme,router}/
├── data/
│   ├── curriculum/
│   │   ├── curriculum_models.dart   Ünite, ders, alıştırma, sonuç modelleri
│   │   ├── content_library.dart     11 ünite, 20 şablon, elle yazılmış içerik
│   │   ├── phonology.dart           Türkçe edinim sırası, gelişimsel süreçler, eşleştirici
│   │   ├── dialogue_engine.dart     Yuva doldurma, ağırlıklı seçim, tekrar önleme
│   │   ├── answer_evaluator.dart    Değerlendirme, kademeli ipucu, geri bildirim
│   │   └── progress_store.dart      Ustalık, Leitner kutuları, kilit durumu
│   ├── models/ · services/ · repositories/
└── features/
    ├── learn/       Öğrenme yolu, ders akışı, ders sonu
    ├── auth/        Rol seçimi, PIN
    ├── teacher/     Sınıf paneli, öğrenci detayı
    ├── child/ · parent/ · specialist/ · settings/ · shell/ · shared/
```

---

## 6. Tarayıcı demosu

`talk_buddy_demo.html` — çift tıklayın, kurulum gerekmez. Bu bir mockup değil:
müfredat motoru, fonolojik değerlendirici ve ilerleme sistemi JavaScript'e
birebir portlanmıştır ve gerçekten çalışır.

| Özellik | Durum |
|---|---|
| 1.899 alıştırma, 11 ünite, 33 ders | Gerçek |
| Sesli soru (konuşma sentezi) | Her tarayıcıda |
| Sesli cevap (konuşma tanıma) | Chrome / Edge |
| Yazılı cevap yedeği | Diğer tarayıcılarda otomatik |
| Fonolojik tolerans ve süreç tespiti | Gerçek |
| Kilitli ilerleme, yıldız, ustalık | `localStorage`'da kalıcı |
| Veli / öğretmen PIN | Gerçek |

Deneyin: **Çocuk → ilk ders → "kedi" yerine kasten "tedi" deyin.** Ders geçer,
"öne alma" süreci tespit edilir, veli ve uzman panellerine düşer.

Demo kaynakları `demo/` klasöründedir ve tek dosyaya derlenir:

```bash
python3 demo/gen_content.py   # Dart içerik kütüphanesinden content.js üret
python3 demo/build.py         # tek HTML dosyasına derle
node demo/test.js             # 43 test
```

`content.js` doğrudan `content_library.dart` dosyasından üretilir; uygulama ile
demo asla ayrışmaz. `engine.js` ise `lib/data/curriculum/` altındaki Dart
dosyalarının portudur — bir tarafta algoritma değişirse diğerinde de değişmelidir.

---

## 7. Test

```powershell
flutter test
flutter analyze
```

- `test/curriculum_test.dart` — fonolojik eşleştirme, değerlendirme kuralları, diyalog üretimi, müfredat tutarlılığı, ilerleme mantığı
- `test/smoke_test.dart` — ayar kalıcılığı, metrik hesaplama, kişisel veri maskeleme

Kritik testler: telaffuz hatasının bölümü engellemediği, üçüncü denemede asla başarısız olunmadığı, aynı ders içinde kelime tekrarı olmadığı, ünite sırasının edinim sırasıyla uyumlu olduğu.

---

## 8. Yayına çıkmadan önce

1. **Proxy sunucusu** — anahtar güvenliği. Zorunlu.
2. **Gerçek kimlik doğrulama** — mevcut PIN sistemi yereldir; veli/öğretmen hesapları sunucu gerektirir.
3. **Bulut senkronizasyonu** — ilerleme şu an yalnızca cihazda. Öğretmenin öğrenci verisini görmesi için sunucu şart.
4. **KVKK belgeleri** — açık rıza, aydınlatma metni, veri saklama politikası, VERBİS kaydı. Çocuk verisi işlendiği için veli rızası ayrı ve açık alınmalıdır.
5. **Mağaza metni** — "tanı", "tedavi", "terapi", "iyileştirir" kullanılmamalı. Yerine "destekler", "takip eder", "pratik imkânı sunar".

### İmzalama

```powershell
keytool -genkey -v -keystore android\app\talkbuddy.jks -keyalg RSA -keysize 2048 -validity 10000 -alias talkbuddy
copy android\key.properties.example android\key.properties
flutter build appbundle --release
```

---

## 9. Bilinen sınırlar

- **İçerik sonlu.** 1.899 kombinasyon yoğun kullanımda birkaç ay yeter. Genişletme `content_library.dart` içine şablon eklemekle olur — kod değişikliği gerekmez.
- **Konuşma tanıma çocuk sesinde zayıftır.** Bu yüzden fonolojik tolerans katmanı var; yine de gürültülü ortamda doğruluk düşer.
- **Anlamsal değerlendirme sözlük tabanlıdır.** Açık uçlu sorularda "uygun cevap" ölçütü kabaca kelime örtüşmesine dayanır. Yapay zeka bağlıyken bu katman iyileştirilebilir.
- **google_fonts** yazı tiplerini ilk açılışta indirir; internet yoksa sistem yazı tipine düşer.
- Emülatörde mikrofon çalışmayabilir — **gerçek cihazda test edin.**

---

Talk Buddy bir tıbbi cihaz veya tanı aracı değildir. Uzman değerlendirmesinin yerini almaz.
