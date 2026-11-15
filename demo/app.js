/* ===========================================================================
   Talk Buddy — Demo uygulaması (ekranlar, durum, navigasyon)
   =========================================================================== */
'use strict';

/* ---------------------------------------------------------------------------
   Durum
   --------------------------------------------------------------------------- */
const S = {
  screen: 'login',
  shell: null,
  tab: 0,
  role: 'child',
  activeChildId: 'c1',
  detailTab: 0,
  studentId: 'c1',
  range: 30,
  showKey: false,
  settings: {
    provider: 'offline', apiKey: '', useProxy: false, proxyUrl: '',
    rate: 0.44, pitch: 1.18, limit: 12, silence: 6,
    redact: true, store: true, voiceMode: 'auto',
  },
  pins: {parent: null, teacher: null},
  lesson: null,
};

const CHILDREN = [
  {id:'c1', name:'Elif',   ageMonths:52, avatar:'🐰', classroomId:'k1'},
  {id:'c2', name:'Kerem',  ageMonths:41, avatar:'🦊', classroomId:'k1'},
  {id:'c3', name:'Deniz',  ageMonths:67, avatar:'🐢', classroomId:'k1'},
  {id:'c4', name:'Zeynep', ageMonths:35, avatar:'🐥', classroomId:'k2'},
  {id:'c5', name:'Mert',   ageMonths:58, avatar:'🦕', classroomId:'k2'},
];

const CLASSROOMS = [
  {id:'k1', name:'Papatya Sınıfı', teacherName:'Aynur Yörük'},
  {id:'k2', name:'Menekşe Sınıfı', teacherName:'Aynur Yörük'},
];

const PROVIDERS = {
  offline: {label:'Çevrimdışı Demo', icon:'📴', color:'#5A6079', key:false,
    desc:'API anahtarı gerekmez. Tüm dersler çevrimdışı çalışır.'},
  gemini:  {label:'Google Gemini', icon:'✨', color:'#41C9FF', key:true,
    desc:'Ücretsiz kullanım kotası vardır. Düşük gecikme.',
    hint:'AIza ile başlar', url:'aistudio.google.com/apikey'},
  claude:  {label:'Anthropic Claude', icon:'✨', color:'#FF7A6B', key:true,
    desc:'Uzun bağlam ve tutarlı Türkçe.',
    hint:'sk-ant- ile başlar', url:'console.anthropic.com'},
  openai:  {label:'OpenAI', icon:'✨', color:'#2ED3A5', key:true,
    desc:'Yaygın kullanılan alternatif.',
    hint:'sk- ile başlar', url:'platform.openai.com/api-keys'},
};

/* --- Kalıcılık ------------------------------------------------------------ */
function loadPrefs() {
  try {
    const raw = localStorage.getItem('tb_prefs');
    if (raw) Object.assign(S.settings, JSON.parse(raw));
    const pins = localStorage.getItem('tb_pins');
    if (pins) Object.assign(S.pins, JSON.parse(pins));
    const ac = localStorage.getItem('tb_active_child');
    if (ac) S.activeChildId = ac;
  } catch (e) {}
}
function savePrefs() {
  try {
    localStorage.setItem('tb_prefs', JSON.stringify(S.settings));
    localStorage.setItem('tb_pins', JSON.stringify(S.pins));
    localStorage.setItem('tb_active_child', S.activeChildId);
  } catch (e) {}
}

const activeChild = () =>
  CHILDREN.find(c => c.id === S.activeChildId) || CHILDREN[0];

const progressOf = id => ProgressStore.load(id);
const activeProgress = () => progressOf(S.activeChildId);

function ageLabel(months) {
  const y = Math.floor(months / 12), m = months % 12;
  if (y === 0) return m + ' aylık';
  return m === 0 ? y + ' yaş' : y + ' yaş ' + m + ' ay';
}

/* --- Yardımcılar ---------------------------------------------------------- */
const esc = t => String(t == null ? '' : t)
  .replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));

const scoreHex = v => v >= .75 ? '#22C55E' : v >= .5 ? '#FFC53D'
                    : v >= .3 ? '#F59E0B' : '#EF4444';

function buddy(mood, size) {
  const C = {idle:['#8D99FF','#5B6CFF'], listening:['#6FE3C2','#2ED3A5'],
             talking:['#8D99FF','#5B6CFF'], thinking:['#C4A5FF','#A678FF'],
             happy:['#FFD97A','#FFC53D']}[mood] || ['#8D99FF','#5B6CFF'];
  const eye = size * .15, pup = size * .08;
  let mouth;
  if (mood === 'talking')        mouth = `<div class="m-talk" style="width:${size*.22}px;margin-top:${size*.08}px"></div>`;
  else if (mood === 'listening') mouth = `<div class="m-o" style="width:${size*.11}px;height:${size*.11}px;margin-top:${size*.08}px"></div>`;
  else if (mood === 'thinking')  mouth = `<div style="width:${size*.2}px;height:${size*.035}px;background:var(--ink);border-radius:3px;margin-top:${size*.1}px;transform:rotate(-6deg)"></div>`;
  else                           mouth = `<div class="m-smile" style="width:${size*.3}px;height:${size*.14}px;margin-top:${size*.07}px"></div>`;
  const rings = mood === 'listening'
    ? [0,.53,1.06].map(d => `<div class="ring" style="width:${size}px;height:${size}px;border-color:${C[1]};animation-delay:${d}s"></div>`).join('') : '';
  const cheeks = (mood === 'happy' || mood === 'talking')
    ? `<div class="cheek" style="width:${size*.13}px;height:${size*.13}px;left:${size*.1}px;top:${size*.52}px"></div>
       <div class="cheek" style="width:${size*.13}px;height:${size*.13}px;right:${size*.1}px;top:${size*.52}px"></div>` : '';
  return `<div class="buddy" style="width:${size*1.5}px;height:${size*1.5}px">${rings}
    <div class="face" style="width:${size}px;height:${size}px;
      background:linear-gradient(135deg,${C[0]},${C[1]});box-shadow:0 14px 40px ${C[1]}59">${cheeks}
      <div class="row" style="gap:${size*.14}px;margin-top:${size*.05}px">
        <div class="eye" style="width:${eye}px;height:${eye}px"><div class="pupil" style="width:${pup}px;height:${pup}px"></div></div>
        <div class="eye" style="width:${eye}px;height:${eye}px"><div class="pupil" style="width:${pup}px;height:${pup}px"></div></div>
      </div>${mouth}</div></div>`;
}

function ring(v, size) {
  const st = size * .11, r = (size - st) / 2, c = 2 * Math.PI * r, col = scoreHex(v);
  return `<svg width="${size}" height="${size}" style="flex-shrink:0">
    <circle cx="${size/2}" cy="${size/2}" r="${r}" fill="none" stroke="#E6E8F0" stroke-width="${st}"/>
    <circle cx="${size/2}" cy="${size/2}" r="${r}" fill="none" stroke="${col}" stroke-width="${st}"
      stroke-linecap="round" stroke-dasharray="${c*v} ${c}" transform="rotate(-90 ${size/2} ${size/2})"/>
    <text x="50%" y="50%" text-anchor="middle" dy=".35em" font-size="${size*.26}" font-weight="800"
      fill="${col}" font-family="system-ui,sans-serif">%${Math.round(v*100)}</text></svg>`;
}

function bars(data, w, h, threshold) {
  w = w || 320; h = h || 120; threshold = threshold || 5;
  const pad = 4, iw = w - pad * 2, ih = h - pad * 2;
  const max = Math.max.apply(null, data.concat([1]));
  const gap = iw / data.length, bw = gap * .6;
  return `<svg viewBox="0 0 ${w} ${h}" style="width:100%;height:${h}px;display:block">
    ${data.map((v, i) => {
      const bh = Math.max(3, v / max * ih);
      return `<rect x="${pad+i*gap+(gap-bw)/2}" y="${pad+ih-bh}" width="${bw}" height="${bh}" rx="3"
        fill="${v >= threshold ? '#5B6CFF' : '#E6E8F0'}"/>`;
    }).join('')}</svg>`;
}

function stat(icon, label, val, unit, color) {
  return `<div class="card" style="padding:12px">
    <div style="font-size:15px;color:${color}">${icon}</div>
    <div style="font-size:20px;font-weight:800;margin-top:8px;line-height:1">${val}</div>
    <div class="sub" style="font-size:10px">${unit}</div>
    <div class="sub" style="font-size:11.5px;font-weight:600;margin-top:4px">${label}</div></div>`;
}

const maskKey = k => k.length <= 10 ? '•'.repeat(k.length)
  : k.slice(0, 6) + '••••••••••••' + k.slice(-4);
const rateLabel = v => v <= .33 ? 'Çok yavaş' : v <= .42 ? 'Yavaş'
  : v <= .52 ? 'Normal' : v <= .63 ? 'Hızlı' : 'Çok hızlı';
const pitchLabel = v => v <= .95 ? 'Kalın' : v <= 1.15 ? 'Doğal'
  : v <= 1.35 ? 'Neşeli' : 'Çok ince';

/* ===========================================================================
   DERS OTURUMU — Dart'taki LessonController'ın karşılığı
   =========================================================================== */
class LessonSession {
  constructor(lessonId) {
    this.lesson = lessonById(lessonId);
    this.unit = unitById(this.lesson.unitId);
    const child = activeChild();
    const p = activeProgress();

    this.engine = new DialogueEngine({
      childName: child.name,
      ageMonths: child.ageMonths,
      mastery: p.mastery,
      recentPrompts: new Set(p.recentPrompts),
      recentWords: new Set(p.recentWords),
      seed: Math.floor(Date.now() / 1000),
    });
    this.evaluator = new AnswerEvaluator(child.ageMonths, Date.now());

    this.exercises = this.engine.buildLesson(this.lesson);
    this.index = 0;
    this.attempt = 1;
    this.results = [];
    this.stars = 0;
    this.phase = 'intro';
    this.partial = '';
    this.heard = '';
    this.evaluation = null;
    this.banner = this.engine.opener(this.unit.title);
    this.startedAt = Date.now();
    this.busy = false;
    this.voiceMode = Speech.supportsRecognition() ? 'voice' : 'text';
  }

  get current() { return this.exercises[this.index] || null; }
  get total() { return this.exercises.length; }
  get progress() { return this.total ? this.index / this.total : 0; }

  async start() {
    await this._say(this.banner);
    this.banner = null;
    await this._present();
  }

  async _say(text) {
    if (!text) return;
    this.phase = 'speaking';
    render();
    await Speech.speak(text);
  }

  async _present() {
    const ex = this.current;
    if (!ex) { await this._finish(); return; }
    this.partial = ''; this.heard = ''; this.evaluation = null;
    await this._say(ex.prompt);
    this.phase = 'awaiting';
    render();
    if (needsVoice(ex.type) && this.voiceMode === 'voice') {
      await this.listen();
    }
  }

  async listen() {
    const ex = this.current;
    if (!ex || this.busy) return;
    this.busy = true;
    this.phase = 'listening';
    this.partial = '';
    render();

    const res = await Speech.listen(p => { this.partial = p; render(); }, 12000);

    if (res.unsupported) {
      this.voiceMode = 'text';
      this.phase = 'awaiting';
      this.busy = false;
      render();
      return;
    }
    if (res.denied) {
      this.voiceMode = 'text';
      this.phase = 'micDenied';
      this.busy = false;
      render();
      return;
    }
    this.busy = false;
    await this.submitSpeech(res.text, res.confidence);
  }

  async submitSpeech(text, confidence) {
    const ex = this.current;
    if (!ex) return;
    this.heard = text;
    this.partial = '';
    this.phase = 'evaluating';
    render();
    await sleep(320);
    const evaluation = this.evaluator.evaluate(ex, text, confidence || 0, this.attempt);
    await this._apply(ex, evaluation);
  }

  async submitChoice(chosen) {
    const ex = this.current;
    if (!ex || this.busy) return;
    this.busy = true;
    this.phase = 'evaluating';
    render();
    await sleep(260);
    const evaluation = this.evaluator.evaluateChoice(ex, chosen, this.attempt);
    this.busy = false;
    await this._apply(ex, evaluation);
  }

  async _apply(ex, evaluation) {
    this.evaluation = evaluation;

    if (evaluation.verdict === 'retry') {
      this.phase = 'scaffolding';
      render();
      await this._say(evaluation.feedback);
      const sc = evaluation.scaffold;
      if (sc) {
        await this._say(sc.instruction);
        if (sc.hint) await this._say(sc.hint);
      }
      this.attempt += 1;
      this.phase = 'awaiting';
      render();
      if (needsVoice(ex.type) && this.voiceMode === 'voice') await this.listen();
      return;
    }

    this.results.push({
      exercise: ex,
      heardText: this.heard,
      intelligibility: evaluation.intelligibility,
      targetMatch: evaluation.targetMatch,
      semanticMatch: evaluation.semanticMatch,
      verdict: evaluation.verdict,
      attempts: this.attempt,
      processes: evaluation.processes,
      feedback: evaluation.feedback,
    });
    this.stars += starsFor(this.results[this.results.length - 1]);

    this.phase = 'feedback';
    render();
    await this._say(evaluation.feedback);

    // Üçüncü denemede kabul ediyoruz ama çocuk doğru modeli son bir kez
    // duymalı — "Hadi birlikte söyleyelim: portakal".
    const sc = evaluation.scaffold;
    if (sc && sc.level === 'together') {
      await this._say(sc.instruction);
      if (sc.hint) await this._say(sc.hint);
    }

    await sleep(420);
    await this.next();
  }

  async next() {
    this.index += 1;
    this.attempt = 1;
    this.evaluation = null;
    if (this.index >= this.exercises.length) { await this._finish(); return; }
    if (this.index % 3 === 0) await this._say(this.engine.transition());
    await this._present();
  }

  async skip() {
    const ex = this.current;
    if (!ex) return;
    this.results.push({
      exercise: ex, heardText: '', intelligibility: 0, targetMatch: 0,
      semanticMatch: 0, verdict: 'partial', attempts: this.attempt,
      processes: [], feedback: 'Bunu sonra deneriz.',
    });
    this.stars += 1;
    await this.next();
  }

  buildResult() {
    return {
      lessonId: this.lesson.id,
      unitId: this.lesson.unitId,
      results: this.results,
      duration: Math.round((Date.now() - this.startedAt) / 1000),
    };
  }

  async _finish() {
    Speech.cancel();
    const result = this.buildResult();
    const p = ProgressStore.applyResult(activeProgress(), result);
    ProgressStore.save(S.activeChildId, p);
    S.lessonResult = result;
    this.phase = 'complete';
    const closer = this.engine.closer();
    S.lesson = null;
    go('lessonDone');
    Speech.speak(closer);
  }

  abandon() {
    Speech.cancel();
    if (this.results.length) {
      const result = this.buildResult();
      const p = ProgressStore.applyResult(activeProgress(), result);
      ProgressStore.save(S.activeChildId, p);
    }
    S.lesson = null;
  }
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

/* ===========================================================================
   EKRANLAR
   =========================================================================== */
const SCREENS = {};

/* --- Giriş ---------------------------------------------------------------- */
SCREENS.login = () => {
  const p = PROVIDERS[S.settings.provider];
  const needsSetup = p.key && !S.settings.apiKey && !S.settings.useProxy;
  const child = activeChild();
  return `<div class="pad" style="background:linear-gradient(180deg,#EEF0FF,#F7F8FC);min-height:100%;
    padding-top:calc(var(--safe-top) + 20px)">
    <div style="text-align:center">
      ${buddy('happy', 96)}
      <h1 style="font-size:30px;font-weight:800;letter-spacing:-.5px;margin-top:-8px">Talk Buddy</h1>
      <p class="sub" style="font-size:13.5px;margin-top:5px">Çünkü her çocuk anlaşılmayı hak eder.</p>
    </div>
    <div style="margin-top:24px">
      ${needsSetup ? `<button class="pcard" style="background:rgba(245,158,11,.1);border-color:rgba(245,158,11,.3);align-items:center"
        onclick="go('aiset')"><span style="font-size:18px">⚙️</span>
        <span class="grow" style="font-size:12.5px;line-height:1.4">Yapay zeka servisi ayarlanmadı. Dersler çevrimdışı çalışıyor.</span>
        <span style="color:var(--warning)">›</span></button>` : ''}
      ${roleTile('child','🧸','Çocuk', child.avatar+'  '+esc(child.name)+' olarak devam et','#5B6CFF',false)}
      ${roleTile('parent','👨‍👩‍👧','Veli','Gelişimi takip et, raporları gör','#2ED3A5',!!S.pins.parent)}
      ${roleTile('teacher','🎓','Öğretmen','Sınıfını yönet, öğrencileri izle','#A678FF',!!S.pins.teacher)}
      ${roleTile('specialist','🩺','Uzman','Danışan analizleri ve uyarılar','#41C9FF',false)}
    </div>
    <div style="text-align:center;margin-top:16px">
      <button class="ibtn" style="width:auto;padding:0 14px;height:38px;font-size:13px;gap:6px;display:inline-flex"
        onclick="pickChild()">👥 Profil değiştir</button>
      <button class="ibtn" style="width:auto;padding:0 14px;height:38px;font-size:13px;gap:6px;display:inline-flex"
        onclick="go('settings')">⚙️ Ayarlar</button>
      <p class="sub" style="font-size:11px;line-height:1.5;margin-top:8px">
        Beta 0.9.0 · Talk Buddy bir tanı aracı değildir.</p>
    </div></div>`;
};

function roleTile(role, emoji, title, sub, color, locked) {
  return `<button class="soft" style="width:100%;display:flex;align-items:center;gap:13px;
    padding:15px;margin-bottom:9px;cursor:pointer;font-family:inherit;text-align:left"
    onclick="enterRole('${role}')">
    <span style="width:48px;height:48px;border-radius:var(--r-md);background:${color}24;
      display:grid;place-items:center;font-size:24px;flex-shrink:0">${emoji}</span>
    <span class="grow"><span style="font-size:16.5px;font-weight:800;display:block">${title}
      ${locked ? '<span style="font-size:12px;color:var(--ink-soft)"> 🔒</span>' : ''}</span>
      <span class="sub" style="display:block;margin-top:2px;font-size:12.5px">${sub}</span></span>
    <span style="color:var(--ink-soft);font-size:16px">→</span></button>`;
}

/* --- Öğrenme yolu --------------------------------------------------------- */
SCREENS.path = () => {
  const child = activeChild();
  const p = activeProgress();
  const next = nextLesson(p);
  const comp = overallCompletion(p);

  return `<div class="pad-c" style="padding-top:calc(var(--safe-top) + 12px)">
    <div class="row" style="gap:10px">
      <div style="width:44px;height:44px;background:#fff;border-radius:50%;display:grid;
        place-items:center;font-size:22px;box-shadow:0 4px 12px rgba(15,21,51,.06)">${child.avatar}</div>
      <div class="grow" style="min-width:0">
        <div style="font-size:19px;font-weight:800;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">Merhaba ${esc(child.name)}!</div>
        <div class="sub" style="font-size:12px">Yolculuğun %${Math.round(comp*100)} tamamlandı</div>
      </div>
      <span class="pill">⭐ ${p.totalStars}</span>
      <span class="pill">🔥 ${p.streakDays}</span>
      <button class="pill" style="padding:0 11px" onclick="gate('parent')">🔒</button>
    </div>
    <div class="bar" style="height:9px;margin-top:12px"><i style="width:${comp*100}%;background:var(--brand)"></i></div>

    ${next ? `<button class="continue" onclick="startLesson('${next.id}')">
      ${buddy('happy',48)}
      <span class="grow" style="text-align:left">
        <span style="display:block;font-size:10.5px;font-weight:800;letter-spacing:.9px;color:rgba(255,255,255,.7)">KALDIĞIN YERDEN</span>
        <span style="display:block;font-size:18px;font-weight:800;color:#fff;margin-top:2px">${esc(next.title)}</span></span>
      <span style="width:42px;height:42px;border-radius:50%;background:rgba(255,255,255,.2);
        display:grid;place-items:center;font-size:20px;color:#fff">▶</span></button>`
      : `<div class="soft" style="padding:18px;margin-top:14px;text-align:center">
         <div style="font-size:30px">🏆</div>
         <div style="font-size:17px;font-weight:800;margin-top:6px">Tüm dersleri bitirdin!</div>
         <div class="sub" style="margin-top:4px">Tekrar oynayarak yıldızlarını artırabilirsin.</div></div>`}

    ${UNITS.map((u,ui) => unitBlock(u, p, ui === 0)).join('')}
  </div>`;
};

function unitBlock(u, p, isFirst) {
  const unlocked = isUnitUnlocked(p, u);
  const done = u.lessons.filter(l => isLessonComplete(p, l.id)).length;
  return `<div style="margin-top:${isFirst ? 22 : 26}px">
    <div class="row" style="gap:11px;opacity:${unlocked ? 1 : .45}">
      <span style="width:42px;height:42px;border-radius:var(--r-md);background:${u.color}28;
        display:grid;place-items:center;font-size:21px">${u.emoji}</span>
      <span class="grow">
        <span style="display:block;font-size:17px;font-weight:800">${esc(u.title)}</span>
        <span class="sub" style="display:block;font-size:12px">${esc(u.subtitle)}</span></span>
      ${unlocked ? `<span style="font-size:13px;font-weight:800;color:${u.color}">${done}/${u.lessons.length}</span>`
                 : '<span style="color:var(--ink-soft)">🔒</span>'}
    </div>
    <div style="margin-top:12px">
      ${u.lessons.map((l,i) => lessonNode(u, l, p, i % 2 === 1)).join('')}
    </div></div>`;
}

function lessonNode(u, l, p, right) {
  const unlocked = isLessonUnlocked(p, u, l);
  const complete = isLessonComplete(p, l.id);
  const stars = starsOfLesson(p, l.id);
  const filled = complete ? Math.max(1, Math.round(stars / (l.exerciseCount * 3) * 3)) : 0;
  return `<button class="lnode" style="opacity:${unlocked ? 1 : .42};
      margin-left:${right ? 44 : 0}px;margin-right:${right ? 0 : 44}px"
      onclick="${unlocked ? `startLesson('${l.id}')` : `toast('Önce bir önceki dersi tamamla')`}">
    <span style="width:40px;height:40px;border-radius:50%;flex-shrink:0;
      background:${complete ? u.color : (unlocked ? u.color + '24' : 'var(--canvas)')};
      display:grid;place-items:center;font-size:${complete ? 19 : 17}px;
      color:${complete ? '#fff' : u.color}">${complete ? '✓' : (unlocked ? '▶' : '🔒')}</span>
    <span class="grow" style="text-align:left;min-width:0">
      <span style="display:block;font-size:15px;font-weight:800">${esc(l.title)}</span>
      <span class="sub" style="display:block;font-size:11.5px">${l.exerciseCount} alıştırma</span></span>
    ${complete ? `<span style="flex-shrink:0">${[0,1,2].map(i =>
        `<span style="font-size:14px;color:${i < filled ? 'var(--lemon)' : 'var(--line)'}">★</span>`).join('')}</span>` : ''}
  </button>`;
}

/* --- Ders ----------------------------------------------------------------- */
SCREENS.lesson = () => {
  const s = S.lesson;
  if (!s) return '<div class="pad">Ders bulunamadı</div>';
  const u = s.unit, ex = s.current;
  const color = u.color;

  const mood = s.phase === 'listening' ? 'listening'
    : (s.phase === 'speaking' || s.phase === 'intro') ? 'talking'
    : s.phase === 'evaluating' ? 'thinking'
    : (s.phase === 'feedback' && s.evaluation && s.evaluation.verdict !== 'retry') ? 'happy'
    : 'idle';

  const label = {intro:'Buddy konuşuyor', speaking:'Buddy konuşuyor',
    awaiting:'Sıra sende', listening:'Seni dinliyorum...', evaluating:'Düşünüyorum...',
    feedback:'', scaffolding:'Birlikte deneyelim', micDenied:''}[s.phase] || '';

  if (s.phase === 'micDenied') return lessonChrome(s, color, `
    <div style="text-align:center;padding:40px 20px">
      <div style="font-size:46px">🎤</div>
      <h3 style="font-size:19px;font-weight:800;margin-top:14px">Mikrofona ihtiyacım var</h3>
      <p class="sub" style="font-size:14px;line-height:1.5;margin-top:10px">
        Tarayıcı mikrofon iznini vermezsen sesini duyamıyorum.
        İzin verip tekrar deneyebilir ya da yazarak devam edebilirsin.</p>
      <button class="btn" style="margin-top:20px" onclick="retryMic()">İzin ver ve tekrar dene</button>
      <button class="btn ghost" style="margin-top:10px" onclick="useTextMode()">Yazarak devam et</button>
    </div>`);

  return lessonChrome(s, color, `
    <div style="text-align:center">
      ${buddy(mood, 104)}
      ${label ? `<p style="font-size:14.5px;font-weight:700;color:${color};margin-top:-10px">${label}</p>`
              : '<div style="height:20px"></div>'}
    </div>

    ${s.banner ? `<div class="bubble" style="text-align:center;margin-top:8px">
        <div class="tx" style="font-size:17px">${esc(s.banner)}</div></div>`
      : ex ? promptCard(ex, color) : ''}

    ${ex && ex.emoji && !ex.options.length
      ? `<div style="text-align:center;font-size:72px;margin-top:12px">${ex.emoji}</div>` : ''}

    ${ex && ex.options.length ? optionsBlock(s, ex, color) : ''}

    ${s.partial ? `<div class="heard" style="border-color:${color}59;background:${color}1A">
        <div style="font-size:11px;font-weight:800;letter-spacing:.7px;color:${color}">SEN</div>
        <div style="font-size:16px;font-weight:600;margin-top:4px">${esc(s.partial)}</div></div>` : ''}

    ${s.evaluation ? feedbackCard(s.evaluation, s.heard) : ''}
  `);
};

function lessonChrome(s, color, body) {
  const ex = s.current;
  const showMic = ex && needsVoice(ex.type) &&
    (s.phase === 'awaiting' || s.phase === 'listening');
  const textMode = s.voiceMode === 'text';

  return `<div style="background:linear-gradient(180deg,${color}1F,#F7F8FC);min-height:100%;
    display:flex;flex-direction:column;padding-top:calc(var(--safe-top) + 8px)">
    <div class="row" style="gap:10px;padding:0 14px">
      <button class="ibtn" onclick="quitLesson()">✕</button>
      <span class="bar grow" style="height:12px"><i style="width:${s.progress*100}%;background:${color}"></i></span>
      <span class="pill" style="height:32px;font-size:13px;padding:0 10px">⭐ ${s.stars}</span>
    </div>

    <div style="flex:1;overflow-y:auto;padding:8px 18px 12px;-webkit-overflow-scrolling:touch">${body}</div>

    ${s.phase === 'micDenied' ? '' : `
    <div class="lbar">
      ${showMic ? micWave(s.phase === 'listening', color) : ''}
      ${textMode && ex && needsVoice(ex.type) && s.phase === 'awaiting' ? `
        <div class="row" style="gap:8px;margin-bottom:8px">
          <input class="inp" id="answerin" placeholder="Cevabını yaz..." style="font-family:inherit;padding:12px"
            onkeydown="if(event.key==='Enter')submitTyped()">
          <button class="btn" style="width:auto;padding:0 18px" onclick="submitTyped()">✓</button>
        </div>` : ''}
      <div class="row" style="gap:9px">
        <button class="sbtn" onclick="repeatPrompt()"><span>🔁</span><span>Tekrar dinle</span></button>
        ${!textMode && ex && needsVoice(ex.type) && s.phase === 'awaiting'
          ? `<button class="btn grow" style="background:${color}" onclick="startListen()">🎤 Konuş</button>`
          : '<span class="grow"></span>'}
        <button class="sbtn" onclick="skipExercise()"><span>⏭</span><span>Atla</span></button>
      </div>
    </div>`}
  </div>`;
}

function promptCard(ex, color) {
  const typeLabel = {listenRepeat:'Dinle ve Tekrarla', namePicture:'Bu Ne?',
    choosePicture:'Doğrusunu Seç', minimalPair:'Hangisi?', answerQuestion:'Sohbet',
    completeSentence:'Cümleyi Tamamla', retellStory:'Hikâyeyi Anlat',
    emotionMatch:'Ne Hissetti?', tongueTwister:'Tekerleme'}[ex.type] || '';
  const domainEmoji = {articulation:'🗣️', auditory:'👂', vocabulary:'📚',
    syntax:'🧩', narrative:'📖', pragmatics:'💛'}[ex.domain] || '';

  return `<div class="bubble" style="margin-top:8px">
    <div class="row between" style="margin-bottom:10px">
      <span class="tag" style="background:${color}21;color:${color}">${typeLabel}</span>
      <span style="font-size:14px">${domainEmoji}</span>
    </div>
    <div style="font-size:17.5px;line-height:1.35;font-weight:700">${esc(ex.prompt)}</div>
    ${ex.targetWord && ex.type === 'listenRepeat' ? `
      <div style="text-align:center;margin-top:12px">
        <span style="display:inline-block;padding:11px 20px;border-radius:var(--r-lg);
          background:${color}1A;font-size:27px;font-weight:800;color:${color};letter-spacing:1.4px">${esc(ex.targetWord)}</span>
      </div>` : ''}
  </div>`;
}

function optionsBlock(s, ex, color) {
  const isEmoji = ex.type === 'choosePicture';
  const enabled = s.phase === 'awaiting';
  return `<div class="row center" style="gap:12px;flex-wrap:wrap;margin-top:16px">
    ${ex.options.map((o, i) => `<button class="opt" ${enabled ? '' : 'disabled'}
      style="width:${isEmoji ? 88 : 128}px;height:${isEmoji ? 88 : 62}px;
        font-size:${isEmoji ? 40 : 20}px;border-color:${enabled ? color + '59' : 'var(--line)'}"
      onclick="pickOption(${i})">${o}</button>`).join('')}
  </div>`;
}

function feedbackCard(ev, heard) {
  const map = {pass:['#22C55E','✓'], partial:['#FFC53D','👍'], retry:['#5B6CFF','🔁']};
  const [c, icon] = map[ev.verdict];
  const procNames = (ev.processes || []).map(p => {
    const o = TurkishPhonology.byId(p);
    return o ? o.label : p;
  });
  return `<div style="margin-top:14px;background:${c}1A;border:1px solid ${c}4D;
    border-radius:var(--r-lg);padding:14px">
    <div class="row" style="gap:10px;align-items:flex-start">
      <span style="font-size:17px;color:${c}">${icon}</span>
      <span class="grow" style="font-size:15px;line-height:1.4;font-weight:600">${esc(ev.feedback)}</span>
    </div>
    ${ev.scaffold && ev.scaffold.hint ? `
      <div class="row" style="gap:8px;background:#fff;border-radius:var(--r-md);
        padding:9px 13px;margin-top:10px">
        <span style="color:var(--warning)">💡</span>
        <span style="font-size:17px;font-weight:800;letter-spacing:1px">${esc(ev.scaffold.hint)}</span>
      </div>` : ''}
    ${procNames.length ? `<div class="sub" style="font-size:11px;margin-top:8px">
      Gözlenen: ${procNames.join(', ')} · uzmana iletildi</div>` : ''}
  </div>`;
}

function micWave(active, color) {
  const bars = [.3,.45,.6,.75,.9,1,.9,.75,.6,.45,.3];
  return `<div class="wave" id="micwave" style="height:34px">
    ${bars.map((m, i) => `<i data-m="${m}" style="height:${active ? 6 + m * 24 : 6}px;
      background:${active ? color : 'var(--line)'};transition:height .09s"></i>`).join('')}
  </div>`;
}

/* --- Ders sonu ------------------------------------------------------------ */
SCREENS.lessonDone = () => {
  const r = S.lessonResult;
  if (!r) return '<div class="pad">Sonuç yok</div>';
  const u = unitById(r.unitId), l = lessonById(r.lessonId);
  const stars = totalStars(r), max = maxStars(r);
  const passed = successRate(r) >= 0.6;
  const filled = max ? Math.round(stars / max * 3) : 0;
  const advanced = r.results.filter(x => x.verdict !== 'retry').length;
  const struggling = strugglingPhonemes(r);
  const intel = meanIntelligibility(r);
  const procs = Object.entries(processCounts(r)).sort((a, b) => b[1] - a[1]);

  let note = `${r.results.length} alıştırmanın ${advanced} tanesinde hedefe ulaştı. `;
  if (intel > 0) note += `Konuşma netliği ortalama %${Math.round(intel*100)}. `;
  note += struggling.length
    ? `En çok zorlandığı sesler: ${struggling.map(p => '"'+p+'"').join(', ')}.`
    : 'Belirgin bir zorlanma gözlenmedi.';

  return `<div class="pad-c" style="padding-top:calc(var(--safe-top) + 14px)">
    <div style="text-align:center">
      ${buddy(passed ? 'happy' : 'idle', 92)}
      <h2 style="font-size:28px;font-weight:800;margin-top:-8px">${passed ? 'Tebrikler!' : 'İyi çalıştın!'}</h2>
      <p class="sub" style="font-size:15px;margin-top:3px">${u.emoji} ${esc(l.title)}</p>
    </div>

    <div class="row center" style="gap:8px;margin-top:18px">
      ${[0,1,2].map(i => `<span class="bigstar" style="animation-delay:${i*.15}s;
        color:${i < filled ? 'var(--lemon)' : 'var(--line)'}">★</span>`).join('')}
    </div>
    <p class="sub" style="text-align:center;font-size:13px;margin-top:4px">${stars} / ${max} puan</p>

    <div class="grid3" style="margin-top:18px">
      ${[['⭐',stars,'yıldız'],['✅',advanced+'/'+r.results.length,'alıştırma'],
         ['⏱️',Math.max(1,Math.round(r.duration/60)),'dakika']].map(t =>
        `<div class="soft" style="text-align:center;padding:14px 6px">
          <div style="font-size:22px">${t[0]}</div>
          <div style="font-size:18px;font-weight:800;margin-top:4px">${t[1]}</div>
          <div class="sub" style="font-size:11.5px">${t[2]}</div></div>`).join('')}
    </div>

    ${!passed ? `<div style="margin-top:16px;background:var(--brand-soft);border-radius:var(--r-lg);
      padding:14px;display:flex;gap:10px">
      <span>💙</span><p style="font-size:13.5px;line-height:1.45">Bu ders biraz zorlayıcıydı ama sen pes etmedin.
      Tekrar denediğinde çok daha kolay gelecek.</p></div>` : ''}

    <div style="height:1px;background:var(--line);margin:22px 0 12px"></div>
    <p style="font-size:11.5px;font-weight:800;letter-spacing:.7px;color:var(--ink-soft);margin-bottom:10px">
      👨‍👩‍👧 AİLEYE NOT</p>
    <div class="soft" style="padding:15px"><p style="font-size:14px;line-height:1.5">${esc(note)}</p></div>

    ${procs.length ? `<div style="margin-top:14px;background:rgba(245,158,11,.07);
      border:1px solid rgba(245,158,11,.25);border-radius:var(--r-lg);padding:14px">
      <div style="font-size:13.5px;font-weight:800">Gözlenen ses süreçleri</div>
      <div class="sub" style="font-size:11.5px;margin-top:3px">Gelişimsel olarak normal olabilir; uzman paneline iletildi.</div>
      ${procs.slice(0,3).map(([id,n]) => {
        const p = TurkishPhonology.byId(id);
        if (!p) return '';
        return `<div style="margin-top:11px">
          <div class="row" style="gap:8px">
            <span style="font-size:13px;font-weight:800">${p.label}</span>
            <span class="tag" style="background:rgba(245,158,11,.18);color:var(--warning)">${n} kez</span></div>
          <p style="font-size:12.5px;line-height:1.4;margin-top:3px">${p.explanation}</p>
          <p class="sub" style="font-size:11px;font-style:italic;margin-top:2px">
            Genellikle ${Math.round(p.resolve/12)} yaş civarında kendiliğinden düzelir.</p></div>`;
      }).join('')}</div>` : ''}

    <button class="btn" style="margin-top:22px" onclick="go('path')">Öğrenme yoluna dön</button>
    <button class="ibtn" style="width:100%;height:46px;color:var(--brand);font-weight:700;font-size:14px;margin-top:6px"
      onclick="enterRole('parent')">Detaylı raporu gör</button>
  </div>`;
};

/* --- Rozetler ------------------------------------------------------------- */
SCREENS.rewards = () => {
  const p = activeProgress();
  const badges = [
    ['🔥','7 Gün Seri','Yedi gün üst üste çalış', p.streakDays >= 7],
    ['⭐','Yıldız Avcısı','100 yıldız topla', p.totalStars >= 100],
    ['🎯','İlk Adım','İlk dersini tamamla', Object.keys(p.lessons).length > 0],
    ['👄','Dudak Ustası','İlk Sesler ünitesini bitir', UNITS[0].lessons.every(l => isLessonComplete(p,l.id))],
    ['📚','Kelime Dostu','20 ses üzerinde çalış', Object.keys(p.mastery).length >= 8],
    ['🏆','Yarı Yol','Müfredatın yarısını bitir', overallCompletion(p) >= 0.5],
    ['🐯','R Kahramanı','R Macerası ünitesini aç', isUnitUnlocked(p, unitById('u7'))],
    ['🚀','Buddy Efsanesi','Tüm dersleri tamamla', overallCompletion(p) >= 1],
  ];
  const earned = badges.filter(b => b[3]).length;
  const nextStreak = Math.max(0, 7 - p.streakDays);

  return `<div class="appbar"><h2>Rozetlerim</h2></div>
  <div style="padding:0 16px 20px">
    <div style="background:linear-gradient(135deg,#FFC53D,#FF9F1C);border-radius:var(--r-xl);
      padding:20px;display:flex;align-items:center;gap:15px;box-shadow:0 12px 30px rgba(255,159,28,.3)">
      <span style="font-size:42px">⭐</span>
      <div><div style="font-size:34px;font-weight:800;color:#fff;line-height:1">${p.totalStars}</div>
        <div style="font-size:14.5px;color:#fff;font-weight:600">yıldız topladın!</div></div></div>

    <div class="soft" style="margin-top:16px;padding:15px">
      <div class="row" style="gap:10px">
        <span style="font-size:21px">🔥</span>
        <span class="grow" style="font-size:14.5px;font-weight:800">Günlük seri</span>
        <span style="font-size:14.5px;font-weight:800;color:var(--coral)">${p.streakDays}/7</span></div>
      <div class="bar" style="height:11px;margin-top:11px"><i style="width:${Math.min(100,p.streakDays/7*100)}%;background:var(--coral)"></i></div>
      <p class="sub" style="margin-top:7px;font-size:13px">${nextStreak > 0
        ? nextStreak + ' gün daha çalışırsan rozeti kazanacaksın!' : 'Rozeti kazandın, harikasın!'}</p></div>

    <div class="row between" style="margin:20px 0 12px">
      <span style="font-size:18px;font-weight:800">Tüm Rozetler</span>
      <span class="sub">${earned} / ${badges.length}</span></div>
    <div class="grid2">
      ${badges.map(b => `<div class="badge-tile ${b[3] ? '' : 'lock'}">
        <div class="row between"><span style="font-size:26px">${b[0]}</span>
          ${b[3] ? '' : '<span style="font-size:12px;color:var(--ink-soft)">🔒</span>'}</div>
        <div style="margin-top:auto">
          <div style="font-size:13.5px;font-weight:800;line-height:1.2">${b[1]}</div>
          <div class="sub" style="font-size:11px;line-height:1.25;margin-top:3px">${b[2]}</div></div>
      </div>`).join('')}
    </div>
  </div>`;
};

/* --- Ses haritası (çocuk) -------------------------------------------------- */
SCREENS.sounds = () => {
  const p = activeProgress();
  const order = Object.entries(TurkishPhonology.acquisitionOrder)
    .sort((a, b) => a[1] - b[1]);
  const child = activeChild();

  return `<div class="appbar"><h2>Ses Haritam</h2></div>
  <div style="padding:0 16px 20px">
    <p class="sub" style="font-size:13px;line-height:1.5;margin-bottom:14px">
      Her sesin ne kadar oturduğunu buradan görebilirsin. Sesler, Türkçede
      genellikle öğrenildikleri sıraya göre dizili.</p>

    <div class="card">
      <div style="display:grid;grid-template-columns:repeat(5,1fr);gap:8px">
        ${order.map(([ph, age]) => {
          const m = p.mastery[ph];
          const col = m ? scoreHex(m.score) : '#E6E8F0';
          const tooYoung = child.ageMonths < age - 6;
          return `<div style="aspect-ratio:1;border-radius:var(--r-md);display:grid;place-items:center;
            background:${m ? col + '2E' : 'var(--canvas)'};
            border:${m && isMastered(m) ? '2px solid ' + col : 'none'};
            opacity:${tooYoung ? .45 : 1}">
            <span style="font-size:17px;font-weight:800;color:${m ? col : 'var(--ink-soft)'}">${ph}</span>
            <span style="font-size:8.5px;color:var(--ink-soft);margin-top:-2px">${Math.round(age/12*10)/10} yaş</span>
          </div>`;
        }).join('')}
      </div>
      <div class="row" style="gap:13px;margin-top:14px;flex-wrap:wrap">
        ${[['#E6E8F0','Çalışılmadı'],['#EF4444','Zayıf'],['#FFC53D','Gelişiyor'],['#22C55E','Kazanıldı']]
          .map(l => `<span class="row" style="gap:5px">
            <i style="width:9px;height:9px;background:${l[0]};border-radius:50%;display:block"></i>
            <span class="sub" style="font-size:10.5px">${l[1]}</span></span>`).join('')}
      </div>
    </div>

    ${weakestPhonemes(p).length ? `
      <p class="h2" style="margin:20px 0 10px">Üzerinde çalıştıkların</p>
      ${weakestPhonemes(p).map(m => `<div class="card" style="margin-bottom:9px;padding:13px">
        <div class="row" style="gap:11px">
          <span style="width:36px;height:36px;border-radius:var(--r-sm);background:${scoreHex(m.score)}2E;
            display:grid;place-items:center;font-size:16px;font-weight:800;color:${scoreHex(m.score)}">${m.phoneme}</span>
          <span class="grow">
            <span style="display:block;font-size:13.5px;font-weight:700">${m.successes}/${m.attempts} başarılı</span>
            <span class="bar" style="height:5px;margin-top:5px;display:block"><i style="width:${m.score*100}%;background:${scoreHex(m.score)}"></i></span></span>
          <span class="sub" style="font-size:11px">${isDue(m) ? 'tekrar zamanı' : BOX_INTERVAL_DAYS[m.box] + ' gün'}</span>
        </div></div>`).join('')}` : ''}
  </div>`;
};
