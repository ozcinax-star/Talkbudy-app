/* ===========================================================================
   Talk Buddy — Müfredat motoru (Dart sürümünün birebir JS portu)
   Kaynak: lib/data/curriculum/{phonology,answer_evaluator,dialogue_engine,
           content_library,progress_store}.dart
   =========================================================================== */
'use strict';

/* ---------------------------------------------------------------------------
   1. TÜRKÇE FONOLOJİ
   --------------------------------------------------------------------------- */
const TurkishPhonology = (() => {
  const acquisitionOrder = {
    p: 24, b: 24, m: 24, n: 24, t: 26, d: 26,
    h: 28, y: 30, k: 32, g: 34, f: 36, v: 38,
    l: 42, 'ç': 44, c: 44, s: 46, z: 48, 'ş': 50,
    j: 54, r: 60,
  };

  const processes = [
    {id:'fronting', label:'Öne alma',
     explanation:'Arka damak sesleri (k, g) dil ucuyla üretiliyor: "kedi" yerine "tedi".',
     resolve:42},
    {id:'stopping', label:'Durdurma',
     explanation:'Sürtünmeli sesler (s, ş, f, v, z) patlamalıya dönüyor: "su" yerine "tu".',
     resolve:48},
    {id:'gliding', label:'Kayma',
     explanation:'Akıcı sesler (r, l) y sesine dönüyor: "araba" yerine "ayaba".',
     resolve:66},
    {id:'liquidSubstitution', label:'Akıcı ses değişimi',
     explanation:'"r" yerine "l" ya da tersi kullanılıyor: "araba" yerine "alaba".',
     resolve:60},
    {id:'clusterReduction', label:'Küme sadeleştirme',
     explanation:'Yan yana iki ünsüzden biri düşüyor: "tren" yerine "ten".',
     resolve:48},
    {id:'finalDeletion', label:'Son ses düşmesi',
     explanation:'Kelimenin son sesi söylenmiyor: "kitap" yerine "kita".',
     resolve:36},
    {id:'syllableDeletion', label:'Hece düşmesi',
     explanation:'Vurgusuz hece atlanıyor: "kelebek" yerine "kebek".',
     resolve:48},
    {id:'devoicing', label:'Ötümsüzleşme',
     explanation:'Ötümlü ses ötümsüze dönüyor: "baba" yerine "papa".',
     resolve:40},
  ];

  const byId = id => processes.find(p => p.id === id) || null;

  const SUBS = {
    fronting: {k:'t', g:'d'},
    stopping: {s:'t','ş':'t', z:'d', f:'p', v:'b', c:'d','ç':'t', j:'d'},
    gliding: {r:'y', l:'y'},
    liquidSubstitution: {r:'l', l:'r'},
    devoicing: {b:'p', d:'t', g:'k', c:'ç', z:'s', v:'f'},
  };

  const VOWELS = 'aeıioöuüâî';
  const CONSONANTS = 'bcçdfgğhjklmnprsştvyz';

  const isVowel = c => VOWELS.includes(c);
  const isConsonant = c => CONSONANTS.includes(c);

  function normalize(s) {
    return String(s || '')
      .toLocaleLowerCase('tr')
      .replace(/â/g, 'a').replace(/î/g, 'i')
      .replace(/[^a-zçğıöşü\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  const tokenize = s => normalize(s).split(' ').filter(Boolean);

  const SUFFIXES = [
    'lerimizi','larımızı','lerimiz','larımız','lerini','larını',
    'lerde','larda','lerin','ların','ecek','acak','iyor','ıyor',
    'uyor','üyor','miş','mış','muş','müş','ler','lar','den',
    'dan','ten','tan','nin','nın','nun','nün','de','da','te',
    'ta','yi','yı','yu','yü','ye','ya','im','ım','um','üm',
    'in','ın','un','ün','si','sı','su','sü','i','ı','u','ü',
    'e','a','m','n','s',
  ];

  function stem(w) {
    let out = w;
    for (let pass = 0; pass < 2; pass++) {
      for (const s of SUFFIXES) {
        if (out.length > s.length + 2 && out.endsWith(s)) {
          out = out.slice(0, out.length - s.length);
          break;
        }
      }
    }
    return out;
  }

  const applyProcess = (word, pid) => {
    const map = SUBS[pid];
    if (!map) return word;
    return word.split('').map(c => map[c] || c).join('');
  };

  function reduceClusters(word) {
    let out = '', prevCons = false;
    for (const ch of word) {
      const isc = isConsonant(ch);
      if (isc && prevCons) continue;
      out += ch;
      prevCons = isc;
    }
    return out;
  }

  const deleteFinal = w =>
    w.length >= 3 && isConsonant(w[w.length - 1]) ? w.slice(0, -1) : w;

  function levenshtein(a, b) {
    if (a === b) return 0;
    if (!a.length) return b.length;
    if (!b.length) return a.length;
    let prev = Array.from({length: b.length + 1}, (_, i) => i);
    for (let i = 0; i < a.length; i++) {
      const curr = [i + 1];
      for (let j = 0; j < b.length; j++) {
        curr[j + 1] = Math.min(
          curr[j] + 1,
          prev[j + 1] + 1,
          prev[j] + (a[i] === b[j] ? 0 : 1)
        );
      }
      prev = curr;
    }
    return prev[b.length];
  }

  function similarity(a, b) {
    const m = Math.max(a.length, b.length);
    return m === 0 ? 1 : 1 - levenshtein(a, b) / m;
  }

  return {acquisitionOrder, processes, byId, normalize, tokenize, stem,
          applyProcess, reduceClusters, deleteFinal, levenshtein, similarity,
          isVowel, isConsonant, VOWELS, CONSONANTS};
})();

/* ---------------------------------------------------------------------------
   Gelişimsel süreçleri tolere eden eşleştirici
   --------------------------------------------------------------------------- */
class PhonologyMatcher {
  constructor(ageMonths) { this.age = ageMonths; }

  matchWord(heard, target) {
    const P = TurkishPhonology;
    const h = P.normalize(heard);
    const t = P.normalize(target);
    if (!h) return {score: 0, processes: [], exact: false};
    if (h === t) return {score: 1, processes: [], exact: true};

    const hs = P.stem(h), ts = P.stem(t);
    if (hs === ts && hs.length >= 3) {
      return {score: 0.97, processes: [], exact: true};
    }

    let found = [];
    let best = P.similarity(h, t);

    for (const id of ['fronting','stopping','gliding','liquidSubstitution','devoicing']) {
      const sim = P.similarity(h, P.applyProcess(t, id));
      if (sim > best + 0.001) { best = sim; found = [id]; }
      else if (sim >= 0.99 && !found.includes(id)) { found.push(id); }
    }

    const reduced = P.reduceClusters(t);
    if (reduced !== t) {
      const sim = P.similarity(h, reduced);
      if (sim > best + 0.001) { best = sim; found = ['clusterReduction']; }
    }

    const noFinal = P.deleteFinal(t);
    if (noFinal !== t) {
      const sim = P.similarity(h, noFinal);
      if (sim > best + 0.001) { best = sim; found = ['finalDeletion']; }
    }

    if (h.length < t.length && t.length >= 6 && P.similarity(h, t) > 0.55) {
      if (!found.includes('syllableDeletion') && t.startsWith(h.slice(0, Math.min(2, h.length)))) {
        best = Math.max(best, 0.72);
        found.push('syllableDeletion');
      }
    }

    return {score: this._ageAdjust(best, found), processes: found, exact: false};
  }

  _ageAdjust(raw, procs) {
    if (!procs.length) return raw;
    let bonus = 0;
    for (const id of procs) {
      const p = TurkishPhonology.byId(id);
      if (!p) continue;
      bonus = Math.max(bonus, this.age <= p.resolve ? 0.12 : 0.05);
    }
    return Math.min(1, raw + bonus);
  }

  matchPhrase(heard, targets) {
    if (!targets || !targets.length) return {score: 0, processes: [], exact: false};
    const words = TurkishPhonology.tokenize(heard);
    if (!words.length) return {score: 0, processes: [], exact: false};

    let best = {score: 0, processes: [], exact: false};
    for (const target of targets) {
      const tw = TurkishPhonology.tokenize(target);
      if (tw.length > 1) {
        const m = this.matchWord(words.join(' '), target);
        if (m.score > best.score) best = m;
      }
      for (const w of words) {
        for (const t of tw) {
          const m = this.matchWord(w, t);
          if (m.score > best.score) best = m;
        }
      }
    }
    return best;
  }
}

/* ---------------------------------------------------------------------------
   2. CEVAP DEĞERLENDİRME — hatasız öğrenme
   --------------------------------------------------------------------------- */
const FEEDBACK = {
  exactPraise: [
    '"{kelime}" kelimesini çok net söyledin!',
    'Tam istediğim gibi: "{kelime}". Harikasın!',
    'Bunu duyunca çok mutlu oldum. "{kelime}" mükemmeldi.',
    'Vay canına, "{kelime}" pırıl pırıl çıktı!',
    'İşte bu! "{kelime}" tam yerinde.',
  ],
  shapingPraise: [
    'Çok yaklaştın! Benim söyleyişim şöyle: "{kelime}". Sen de çok güzel dedin.',
    'Neredeyse aynısı! Kulağıma "{kelime}" gibi geldi, aferin.',
    'Güzel denedin. Ben "{kelime}" diyorum, sen de gittikçe yaklaşıyorsun.',
    'Bunu duydum ve beğendim. "{kelime}" böyle söyleniyor, sen de çok iyisin.',
  ],
  generalPraise: [
    'Bunu çok güzel anlattın!',
    'Harika bir cevap, seni dinlemek keyifli.',
    'Aklına gelenleri söylemen çok hoşuma gitti.',
    'Bravo, tam olması gerektiği gibi.',
    'Çok güzel düşünmüşsün!',
  ],
  partialPraise: [
    'Güzel deneme! "{kelime}" biraz zor, ama sen cesurca söyledin.',
    'Sesini duydum ve bu çok değerli. "{kelime}" böyle söyleniyor.',
    'Denemen bile büyük iş. Beraber tekrar edelim: "{kelime}".',
    'İyi gidiyorsun, "{kelime}" yavaş yavaş oturuyor.',
  ],
  partialOpen: [
    'Söylediklerin güzeldi. Biraz daha anlatmak ister misin?',
    'Seni duydum, teşekkür ederim. Devam edelim.',
    'Güzel başladın. Bir dahakine biraz daha uzun anlat.',
  ],
  retry: [
    'Bir daha deneyelim, acelemiz yok.',
    'Buradayım, seni bekliyorum. Tekrar dener misin?',
    'Hiç sorun değil, birlikte tekrar bakalım.',
    'Dene bakalım, ben yanındayım.',
  ],
  silence: [
    'Seni duyamadım. Biraz daha yüksek sesle söyler misin?',
    'Sessiz kaldın galiba. Hazır olduğunda başlayalım.',
    'Mikrofonuma yakın konuşursan seni daha iyi duyarım.',
  ],
  correctChoice: [
    'Doğru! Kulakların çok keskin.',
    'Evet, tam olarak bu!',
    'Bildin! Çok iyi dinledin.',
    'Harika, doğru olanı seçtin.',
  ],
  wrongChoice: [
    'Bu değildi ama iyi denedin. Bir daha dinleyelim mi?',
    'Yaklaştın. Tekrar dinleyip deneyelim.',
    'Olsun, bir kere daha bakalım.',
  ],
};

class AnswerEvaluator {
  constructor(ageMonths, seed) {
    this.age = ageMonths;
    this.matcher = new PhonologyMatcher(ageMonths);
    this.rnd = mulberry32(seed || Date.now());
  }

  _pick(pool) { return pool[Math.floor(this.rnd() * pool.length)]; }

  evaluate(exercise, heard, confidence, attempt) {
    const text = TurkishPhonology.normalize(heard);

    if (!text) {
      return {
        verdict: 'retry', intelligibility: 0, targetMatch: 0, semanticMatch: 0,
        processes: [], feedback: this._pick(FEEDBACK.silence),
        scaffold: this._scaffold(exercise, attempt),
      };
    }

    const targets = [];
    if (exercise.targetWord) targets.push(exercise.targetWord);
    targets.push(...(exercise.accepted || []));

    const match = targets.length
      ? this.matcher.matchPhrase(text, targets)
      : {score: 0, processes: [], exact: false};

    const semantic = this._semantic(exercise, text);
    const intelligibility = this._intel(confidence, match);
    const wordCount = TurkishPhonology.tokenize(text).length;

    const verdict = this._decide(exercise, match.score, semantic, attempt, wordCount);

    return {
      verdict,
      intelligibility,
      targetMatch: match.score,
      semanticMatch: semantic,
      processes: match.score >= 0.5 ? match.processes : [],
      feedback: this._feedback(exercise, verdict, match),
      // 3. denemede kabul ediyoruz ama çocuk son bir kez doğru modeli
      // duymalı: "Hadi birlikte söyleyelim" adımı burada tetiklenir.
      scaffold: verdict === 'retry'
        ? this._scaffold(exercise, attempt)
        : (attempt >= 3 && exercise.targetWord ? this._scaffold(exercise, 3) : null),
    };
  }

  evaluateChoice(exercise, chosen, attempt) {
    const correct = chosen === exercise.correctOption;
    return {
      verdict: correct ? 'pass' : (attempt >= 2 ? 'partial' : 'retry'),
      intelligibility: 1,
      targetMatch: correct ? 1 : 0,
      semanticMatch: correct ? 1 : 0,
      processes: [],
      feedback: correct
        ? this._pick(FEEDBACK.correctChoice)
        : (attempt >= 2 ? 'Doğrusu bu. Şimdi birlikte bakalım.'
                        : this._pick(FEEDBACK.wrongChoice)),
      scaffold: (correct || attempt >= 2) ? null
        : {level: 'slowModel', instruction: 'Bir daha dinleyelim, kulağını ver.'},
    };
  }

  _decide(exercise, targetMatch, semantic, attempt, wordCount) {
    // Hatasız öğrenme: üçüncü denemede asla başarısız sayılmaz.
    if (attempt >= 3) return 'partial';

    if (isOpenEnded(exercise.type)) {
      if (wordCount >= 2 && semantic >= 0.45) return 'pass';
      if (wordCount >= 1 && semantic >= 0.2) return 'partial';
      if (wordCount >= 3) return 'partial';
      return 'retry';
    }

    if (targetMatch >= 0.7 || semantic >= 0.6) return 'pass';
    if (targetMatch >= 0.45 || semantic >= 0.35) return 'partial';
    return 'retry';
  }

  _intel(confidence, match) {
    if (!confidence || confidence <= 0) {
      return match.exact ? 0.85 : Math.min(0.9, match.score * 0.8);
    }
    return Math.max(0, Math.min(1, confidence * 0.65 + match.score * 0.35));
  }

  _semantic(exercise, text) {
    const words = new Set(TurkishPhonology.tokenize(text).map(TurkishPhonology.stem));
    if (!words.size) return 0;

    if (!(exercise.accepted || []).length && !exercise.targetWord) {
      const n = words.size;
      if (n >= 5) return 0.75;
      if (n >= 3) return 0.6;
      if (n >= 2) return 0.45;
      return 0.25;
    }

    const accepted = new Set();
    if (exercise.targetWord) {
      TurkishPhonology.tokenize(exercise.targetWord)
        .map(TurkishPhonology.stem).forEach(w => accepted.add(w));
    }
    for (const a of (exercise.accepted || [])) {
      TurkishPhonology.tokenize(a).map(TurkishPhonology.stem).forEach(w => accepted.add(w));
    }
    if (!accepted.size) return 0.4;

    let hits = 0;
    for (const w of words) if (accepted.has(w)) hits++;
    if (hits > 0) return Math.min(1, 0.55 + hits * 0.2);

    let fuzzy = 0;
    for (const w of words) {
      for (const a of accepted) {
        fuzzy = Math.max(fuzzy, TurkishPhonology.similarity(w, a));
      }
    }
    if (fuzzy >= 0.75) return 0.5;
    if (fuzzy >= 0.6) return 0.35;
    return words.size >= 3 ? 0.3 : 0.12;
  }

  _scaffold(exercise, attempt) {
    if (attempt <= 1) {
      return {
        level: 'slowModel',
        instruction: exercise.targetWord
          ? 'Yavaşça tekrar söyleyeyim, sonra sen dene.'
          : 'Acele yok, bir daha deneyelim.',
        hint: exercise.targetWord || null,
      };
    }
    if (attempt === 2) {
      if (exercise.targetWord && exercise.targetWord.length >= 3) {
        return {
          level: 'choices',
          instruction: 'İpucu vereyim mi? İlk hecesi şöyle:',
          hint: firstSyllable(exercise.targetWord),
        };
      }
      return {
        level: 'choices',
        instruction: 'Tek kelime bile olur, aklına ilk geleni söyle.',
        hint: null,
      };
    }
    return {
      level: 'together',
      instruction: 'Hadi birlikte söyleyelim!',
      hint: exercise.targetWord || null,
    };
  }

  _feedback(exercise, verdict, match) {
    const w = exercise.targetWord;
    if (verdict === 'pass') {
      if (match.exact && w) return this._pick(FEEDBACK.exactPraise).replace('{kelime}', w);
      if (match.processes.length && w) return this._pick(FEEDBACK.shapingPraise).replace('{kelime}', w);
      return this._pick(FEEDBACK.generalPraise);
    }
    if (verdict === 'partial') {
      return w ? this._pick(FEEDBACK.partialPraise).replace('{kelime}', w)
               : this._pick(FEEDBACK.partialOpen);
    }
    return this._pick(FEEDBACK.retry);
  }
}

function firstSyllable(word) {
  const w = TurkishPhonology.normalize(word);
  let seenVowel = false;
  for (let i = 0; i < w.length; i++) {
    if (TurkishPhonology.isVowel(w[i])) seenVowel = true;
    else if (seenVowel) return w.slice(0, i + 1) + '...';
  }
  return (w[0] || '') + '...';
}

const isOpenEnded = t =>
  t === 'answerQuestion' || t === 'retellStory' || t === 'emotionMatch';

const needsVoice = t => t !== 'choosePicture' && t !== 'minimalPair';

/* ---------------------------------------------------------------------------
   3. DİYALOG ÜRETİM MOTORU
   --------------------------------------------------------------------------- */
function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

class DialogueEngine {
  constructor(ctx) {
    this.ctx = ctx;
    this.rnd = mulberry32(ctx.seed || 1);
    this.usedPrompts = new Set();
    this.usedSlots = new Set();
  }

  buildLesson(lesson) {
    const templates = lesson.templateIds
      .map(id => TEMPLATES.find(t => t.id === id))
      .filter(Boolean);
    if (!templates.length) return [];

    return this._interleave(templates, lesson.exerciseCount)
      .map(t => this._materialize(t));
  }

  _templateWeight(t) {
    let w = 3;
    for (const p of (t.targetPhonemes || [])) {
      const m = this.ctx.mastery[p];
      if (!m) { w += 2; continue; }
      if (m.score < 0.4) w += 3;
      else if (m.score < 0.7) w += 1;
      else if (isMastered(m)) w -= 1;
      if (isDue(m)) w += 2;
    }
    const ageGap = t.difficulty * 12 + 24 - this.ctx.ageMonths;
    if (ageGap > 18) w -= 2;
    return Math.max(1, Math.min(12, w));
  }

  _interleave(templates, count) {
    const weighted = [];
    for (const t of templates) {
      const w = this._templateWeight(t);
      for (let i = 0; i < w; i++) weighted.push(t);
    }
    const out = [];
    let last = null;
    for (let i = 0; i < count; i++) {
      const pool = weighted.filter(t => !last || t.id !== last.id);
      const src = pool.length ? pool : weighted;
      const pick = src[Math.floor(this.rnd() * src.length)];
      out.push(pick);
      last = pick;
    }
    out.sort((a, b) => a.difficulty - b.difficulty);
    if (out.length > 2) {
      const mid = out.pop();
      out.splice(Math.floor(out.length / 2) + 1, 0, mid);
    }
    return out;
  }

  _pickPrompt(t) {
    const fresh = t.prompts.filter(p =>
      !this.usedPrompts.has(t.id + '|' + p) &&
      !this.ctx.recentPrompts.has(t.id + '|' + p));
    const fallback = t.prompts.filter(p => !this.usedPrompts.has(t.id + '|' + p));
    const pool = fresh.length ? fresh : (fallback.length ? fallback : t.prompts);
    const chosen = pool[Math.floor(this.rnd() * pool.length)];
    this.usedPrompts.add(t.id + '|' + chosen);
    return chosen;
  }

  _pickSlot(templateId, key, values) {
    const k = templateId + '|' + key;
    const fresh = values.filter(v =>
      !this.usedSlots.has(k + '|' + v) &&
      !this.ctx.recentWords.has(String(v).split('|')[0]));
    const fallback = values.filter(v => !this.usedSlots.has(k + '|' + v));
    const pool = fresh.length ? fresh : (fallback.length ? fallback : values);
    const chosen = pool[Math.floor(this.rnd() * pool.length)];
    this.usedSlots.add(k + '|' + chosen);
    return chosen;
  }

  _apply(prompt, fills) {
    let out = prompt;
    for (const [k, v] of Object.entries(fills)) {
      out = out.split('{' + k + '}').join(String(v).split('|')[0]);
    }
    return out.split('{ad}').join(this.ctx.childName).replace(/\s+/g, ' ').trim();
  }

  _materialize(t) {
    const prompt = this._pickPrompt(t);
    const fills = {};
    for (const s of (t.slots || [])) {
      fills[s.key] = this._pickSlot(t.id, s.key, s.values);
    }

    const base = {
      templateId: t.id, type: t.type, domain: t.domain,
      emoji: t.emoji || '', targetPhonemes: t.targetPhonemes || [],
      difficulty: t.difficulty, options: [], correctOption: 0,
      targetWord: null, accepted: [],
    };

    switch (t.type) {
      case 'listenRepeat': {
        const word = fills['kelime'] || '';
        return {...base, prompt: this._apply(prompt, fills),
                targetWord: word, accepted: [word]};
      }
      case 'namePicture': {
        const [emoji, word] = String(fills['görsel'] || '❓|şey').split('|');
        return {...base, prompt: this._apply(prompt, {}),
                targetWord: word, accepted: [word], emoji};
      }
      case 'choosePicture': {
        const parts = String(fills['set'] || 'kedi|🐱🐶🐦|0').split('|');
        const options = Array.from(parts[1] || '');
        const correct = Math.max(0, Math.min(options.length - 1, parseInt(parts[2] || '0', 10)));
        return {...base, prompt: this._apply(prompt, {'hedef': parts[0]}),
                targetWord: parts[0], accepted: [parts[0]],
                options, correctOption: correct, emoji: ''};
      }
      case 'minimalPair': {
        const parts = String(fills['çift'] || 'tam|dam|0').split('|');
        const correct = parseInt(parts[2] || '0', 10);
        const flip = this.rnd() < 0.5;
        const options = flip ? [parts[1], parts[0]] : [parts[0], parts[1]];
        const ci = flip ? (1 - correct) : correct;
        return {...base, prompt: this._apply(prompt, {}) + ' ' + options[ci],
                targetWord: options[ci], accepted: [options[ci]],
                options, correctOption: ci};
      }
      case 'completeSentence': {
        const parts = String(fills['cümle'] || '').split('|');
        const answer = (parts[1] || '').trim();
        return {...base, prompt: this._apply(prompt, {'cümle': parts[0].trim()}),
                targetWord: answer || null, accepted: answer ? [answer] : []};
      }
      case 'emotionMatch': {
        const parts = String(fills['durum'] || '').split('|');
        return {...base, prompt: this._apply(prompt, {'durum': parts[0].trim()}),
                accepted: parts.slice(1).map(s => s.trim()), emoji: '💛'};
      }
      case 'retellStory':
        return {...base, prompt: this._apply(prompt, {'hikâye': fills['hikâye'] || ''}),
                emoji: '📖'};
      case 'tongueTwister': {
        const line = fills['tekerleme'] || '';
        return {...base, prompt: this._apply(prompt, {'tekerleme': line}),
                targetWord: line, accepted: [line], emoji: '🎵'};
      }
      default:
        return {...base, prompt: this._apply(prompt, fills)};
    }
  }

  opener(unitTitle) {
    const l = OPENERS[Math.floor(this.rnd() * OPENERS.length)];
    return l.split('{ad}').join(this.ctx.childName).split('{ünite}').join(unitTitle);
  }
  closer() {
    const l = CLOSERS[Math.floor(this.rnd() * CLOSERS.length)];
    return l.split('{ad}').join(this.ctx.childName);
  }
  transition() {
    return TRANSITIONS[Math.floor(this.rnd() * TRANSITIONS.length)];
  }

  static combinationCount() {
    let total = 0;
    for (const t of TEMPLATES) {
      let prod = 1;
      for (const s of (t.slots || [])) prod *= s.values.length;
      total += t.prompts.length * prod;
    }
    return total;
  }
}

/* ---------------------------------------------------------------------------
   4. USTALIK VE İLERLEME
   --------------------------------------------------------------------------- */
const BOX_INTERVAL_DAYS = [0, 1, 3, 7, 16];

const isMastered = m => m.score >= 0.8 && m.box >= 3;

function isDue(m) {
  const days = BOX_INTERVAL_DAYS[Math.max(0, Math.min(4, m.box))];
  return (Date.now() - m.lastSeen) / 86400000 >= days;
}

function emptyProgress() {
  return {
    lessons: {}, mastery: {}, processes: {},
    recentPrompts: [], recentWords: [],
    totalStars: 0, streakDays: 0, lastActiveDay: null,
  };
}

const ProgressStore = {
  key: id => 'tb_progress_' + id,

  load(profileId) {
    try {
      const raw = localStorage.getItem(this.key(profileId));
      if (!raw) return emptyProgress();
      return Object.assign(emptyProgress(), JSON.parse(raw));
    } catch (e) { return emptyProgress(); }
  },

  save(profileId, p) {
    try { localStorage.setItem(this.key(profileId), JSON.stringify(p)); } catch (e) {}
  },

  clear(profileId) {
    try { localStorage.removeItem(this.key(profileId)); } catch (e) {}
  },

  applyResult(current, result) {
    const p = JSON.parse(JSON.stringify(current));

    const prev = p.lessons[result.lessonId];
    const passed = successRate(result) >= 0.6;
    const stars = totalStars(result);

    if (passed) {
      p.lessons[result.lessonId] = {
        lessonId: result.lessonId,
        bestStars: Math.max(prev ? prev.bestStars : 0, stars),
        completions: (prev ? prev.completions : 0) + 1,
        lastCompletedAt: Date.now(),
      };
    } else if (!prev) {
      p.lessons[result.lessonId] = {
        lessonId: result.lessonId, bestStars: stars,
        completions: 0, lastCompletedAt: Date.now(),
      };
    }

    // Ses başına ders başına TEK kutu adımı — aksi hâlde ustalık tek
    // derste tavana vurur ve aralıklı tekrar anlamsızlaşır.
    const byPhoneme = {};
    for (const r of result.results) {
      for (const ph of (r.exercise.targetPhonemes || [])) {
        (byPhoneme[ph] = byPhoneme[ph] || []).push(r);
      }
    }

    for (const [ph, rs] of Object.entries(byPhoneme)) {
      const passes = rs.filter(r => r.verdict === 'pass').length;
      const partials = rs.filter(r => r.verdict === 'partial').length;
      const rate = (passes + partials * 0.5) / rs.length;
      const success = rate >= 0.6;
      const delta = (rate - 0.45) * 0.32;

      const m = p.mastery[ph];
      if (!m) {
        p.mastery[ph] = {
          phoneme: ph, score: Math.max(0, Math.min(1, 0.4 + delta)),
          box: success ? 1 : 0, lastSeen: Date.now(),
          attempts: rs.length, successes: passes,
        };
      } else {
        p.mastery[ph] = {
          phoneme: ph,
          score: Math.max(0, Math.min(1, m.score + delta)),
          box: success ? Math.min(4, m.box + 1) : Math.max(0, m.box - 1),
          lastSeen: Date.now(),
          attempts: m.attempts + rs.length,
          successes: m.successes + passes,
        };
      }
    }

    // Gözlenen fonolojik süreçler kalıcı tutulur; uzman paneli bunları okur.
    p.processes = p.processes || {};
    for (const [id, n] of Object.entries(processCounts(result))) {
      const prev = p.processes[id] || {count: 0, lessons: 0};
      p.processes[id] = {
        count: prev.count + n,
        lessons: prev.lessons + 1,
        lastSeen: Date.now(),
      };
    }

    const prompts = new Set(p.recentPrompts);
    const words = new Set(p.recentWords);
    for (const r of result.results) {
      prompts.add(r.exercise.templateId + '|' + r.exercise.prompt);
      if (r.exercise.targetWord) words.add(r.exercise.targetWord);
    }
    p.recentPrompts = [...prompts].slice(-40);
    p.recentWords = [...words].slice(-40);

    const today = new Date(); today.setHours(0, 0, 0, 0);
    if (!p.lastActiveDay) {
      p.streakDays = 1;
    } else {
      const last = new Date(p.lastActiveDay); last.setHours(0, 0, 0, 0);
      const diff = Math.round((today - last) / 86400000);
      if (diff === 1) p.streakDays += 1;
      else if (diff > 1) p.streakDays = 1;
    }
    p.lastActiveDay = today.getTime();
    p.totalStars += stars;
    return p;
  },
};

const totalStars = result => result.results.reduce((a, r) => a + starsFor(r), 0);
const maxStars = result => result.results.length * 3;

function starsFor(r) {
  if (r.verdict === 'pass') return r.attempts <= 1 ? 3 : 2;
  if (r.verdict === 'partial') return 1;
  return 0;
}

const successRate = result => result.results.length
  ? result.results.filter(r => r.verdict !== 'retry').length / result.results.length
  : 0;

function strugglingPhonemes(result) {
  const counts = {};
  for (const r of result.results.filter(r => r.verdict !== 'pass')) {
    for (const p of (r.exercise.targetPhonemes || [])) counts[p] = (counts[p] || 0) + 1;
  }
  return Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 3).map(e => e[0]);
}

function processCounts(result) {
  const m = {};
  for (const r of result.results) {
    for (const p of (r.processes || [])) m[p] = (m[p] || 0) + 1;
  }
  return m;
}

function meanIntelligibility(result) {
  const v = result.results.filter(r => needsVoice(r.exercise.type));
  if (!v.length) return 0;
  return v.reduce((a, r) => a + r.intelligibility, 0) / v.length;
}

/* --- İlerleme sorguları --- */
const isLessonComplete = (p, id) => !!(p.lessons[id] && p.lessons[id].completions > 0);
const starsOfLesson = (p, id) => (p.lessons[id] || {}).bestStars || 0;

function isUnitUnlocked(p, unit) {
  const i = UNITS.findIndex(u => u.id === unit.id);
  if (i <= 0) return true;
  return UNITS[i - 1].lessons.every(l => isLessonComplete(p, l.id));
}

function isLessonUnlocked(p, unit, lesson) {
  if (!isUnitUnlocked(p, unit)) return false;
  if (lesson.index === 0) return true;
  return isLessonComplete(p, unit.lessons[lesson.index - 1].id);
}

function nextLesson(p) {
  for (const u of UNITS) {
    if (!isUnitUnlocked(p, u)) continue;
    for (const l of u.lessons) if (!isLessonComplete(p, l.id)) return l;
  }
  return null;
}

function overallCompletion(p) {
  const all = UNITS.flatMap(u => u.lessons);
  if (!all.length) return 0;
  return all.filter(l => isLessonComplete(p, l.id)).length / all.length;
}

function weakestPhonemes(p) {
  return Object.values(p.mastery).filter(m => m.attempts >= 2)
    .sort((a, b) => a.score - b.score).slice(0, 5);
}

function topProcesses(p, limit) {
  return Object.entries(p.processes || {})
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, limit || 3)
    .map(([id, v]) => ({id, ...v, meta: TurkishPhonology.byId(id)}))
    .filter(x => x.meta);
}

function lateProcesses(p, ageMonths) {
  return topProcesses(p, 8).filter(x => ageMonths > x.meta.resolve + 6);
}

function averageMastery(p) {
  const v = Object.values(p.mastery);
  return v.length ? v.reduce((a, m) => a + m.score, 0) / v.length : 0;
}
