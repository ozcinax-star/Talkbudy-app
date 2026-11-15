/* ===========================================================================
   Talk Buddy — Navigasyon, kabuk, eylemler
   =========================================================================== */
'use strict';

const SHELLS = {
  child: {screens:['path','sounds','rewards'],
    tabs:[['🗺️','Öğren'],['🔤','Sesler'],['⭐','Rozetler']], bg:'#F2F4FF'},
  parent: {screens:['parent','history','settings'],
    tabs:[['📊','Panel'],['📄','Dersler'],['⚙️','Ayarlar']], bg:'var(--canvas)'},
  teacher: {screens:['teacher','specialist','settings'],
    tabs:[['👥','Sınıfım'],['📈','Analiz'],['⚙️','Ayarlar']], bg:'var(--canvas)'},
  specialist: {screens:['specialist','alerts','settings'],
    tabs:[['🩺','Danışanlar'],['🔔','Uyarılar'],['⚙️','Ayarlar']], bg:'var(--canvas)'},
};

const FULLSCREEN = ['login','lesson','lessonDone','aiset','speechset','student'];
const history = [];

function shellOf(screen) {
  for (const k in SHELLS) if (SHELLS[k].screens[0] === screen) return k;
  return null;
}

function go(screen, noPush) {
  if (!SCREENS[screen]) return;
  if (!noPush && S.screen !== screen) {
    history.push({s: S.screen, sh: S.shell, tab: S.tab});
    if (history.length > 30) history.shift();
  }

  const owner = shellOf(screen);
  if (owner) { S.shell = owner; S.tab = 0; }
  else if (S.shell && SHELLS[S.shell].screens.includes(screen)) {
    S.tab = SHELLS[S.shell].screens.indexOf(screen);
  } else if (FULLSCREEN.includes(screen)) {
    if (screen === 'login') S.shell = null;
  }

  S.screen = screen;
  render();
}

function back() {
  const h = history.pop();
  if (h && SCREENS[h.s]) { S.screen = h.s; S.shell = h.sh; S.tab = h.tab; render(); }
  else go('login', true);
}

function tabTo(i) {
  if (!S.shell) return;
  S.tab = i;
  S.screen = SHELLS[S.shell].screens[i];
  render();
}

/* --- Rol geçişleri --------------------------------------------------------- */
function enterRole(role) {
  S.role = role;
  if (role === 'child') { S.shell = 'child'; go('path'); return; }
  if (role === 'specialist') { S.shell = 'specialist'; go('specialist'); return; }

  const target = role === 'teacher' ? 'teacher' : 'parent';
  if (!S.pins[role]) {
    setPin(role, () => { S.shell = role; go(target); });
    return;
  }
  gate(role, () => { S.shell = role; go(target); });
}

function gate(role, onOk) {
  if (!S.pins[role]) {
    if (role === 'parent' || role === 'teacher') {
      setPin(role, onOk || (() => { S.shell = role; go(role === 'teacher' ? 'teacher' : 'parent'); }));
      return;
    }
  }
  const a = 6 + Math.floor(Math.random() * 7), b = 6 + Math.floor(Math.random() * 7);
  showModal({
    title: (role === 'teacher' ? 'Öğretmen' : 'Veli') + ' Girişi',
    body: `<p style="font-size:13.5px;line-height:1.45">4 haneli PIN'inizi girin.</p>
      <input class="inp pin" id="pinin" type="password" inputmode="numeric" maxlength="4"
        placeholder="••••" autofocus>
      <p class="sub" style="font-size:11.5px;margin-top:10px">
        PIN'i unuttuysanız Ayarlar → Güvenlik bölümünden sıfırlayabilirsiniz.</p>
      <p id="pinerr" style="color:var(--danger);font-size:12.5px;font-weight:600;margin-top:8px"></p>`,
    okLabel: 'Giriş',
    onOk: () => {
      const v = (document.getElementById('pinin') || {}).value || '';
      if (v === S.pins[role]) {
        closeModal();
        (onOk || (() => { S.shell = role; go(role === 'teacher' ? 'teacher' : 'parent'); }))();
      } else {
        const e = document.getElementById('pinerr');
        if (e) e.textContent = 'PIN yanlış, tekrar deneyin';
        const i = document.getElementById('pinin');
        if (i) { i.value = ''; i.focus(); }
      }
      return false;
    },
  });
}

function setPin(role, onDone) {
  showModal({
    title: (role === 'teacher' ? 'Öğretmen' : 'Veli') + ' PIN oluştur',
    body: `<p style="font-size:13.5px;line-height:1.45">4 haneli bir PIN belirleyin.
        Bu PIN yalnızca bu tarayıcıda saklanır ve çocuğun panele girmesini engeller.</p>
      <input class="inp pin" id="pin1" type="password" inputmode="numeric" maxlength="4"
        placeholder="Yeni PIN" autofocus>
      <input class="inp pin" id="pin2" type="password" inputmode="numeric" maxlength="4"
        placeholder="PIN tekrar" style="margin-top:10px">
      <p id="pinerr" style="color:var(--danger);font-size:12.5px;font-weight:600;margin-top:8px"></p>`,
    okLabel: 'Kaydet',
    onOk: () => {
      const a = (document.getElementById('pin1') || {}).value || '';
      const b = (document.getElementById('pin2') || {}).value || '';
      const err = document.getElementById('pinerr');
      if (a.length !== 4) { if (err) err.textContent = 'PIN 4 haneli olmalı'; return false; }
      if (a !== b) { if (err) err.textContent = 'İki PIN aynı değil'; return false; }
      S.pins[role] = a;
      savePrefs();
      closeModal();
      toast('PIN kaydedildi');
      if (onDone) onDone(); else render();
      return false;
    },
  });
}

function pickChild() {
  showSheet('Kim çalışacak?', CHILDREN.map(c => {
    const p = progressOf(c.id);
    return {
      html: `<span style="font-size:24px">${c.avatar}</span>
        <span class="grow" style="text-align:left">
          <span style="display:block;font-size:15px;font-weight:700">${esc(c.name)}</span>
          <span class="sub" style="display:block;font-size:12px">${ageLabel(c.ageMonths)} ·
            %${Math.round(overallCompletion(p)*100)} · ⭐ ${p.totalStars}</span></span>
        ${c.id === S.activeChildId ? '<span style="color:var(--brand)">✓</span>' : ''}`,
      action: () => { S.activeChildId = c.id; savePrefs(); closeSheet(); render(); toast(c.name + ' seçildi'); },
    };
  }));
}

function switchToStudent(id) {
  S.activeChildId = id;
  savePrefs();
  S.shell = 'child';
  go('path');
  toast(activeChild().name + ' olarak giriş yapıldı');
}

const openStudent = id => { S.studentId = id; go('student'); };

/* --- Ders eylemleri -------------------------------------------------------- */
async function startLesson(id) {
  S.lesson = new LessonSession(id);
  go('lesson');
  await S.lesson.start();
}

function quitLesson() {
  const s = S.lesson;
  if (!s) { go('path'); return; }
  if (!s.results.length) { s.abandon(); go('path'); return; }
  showModal({
    title: 'Dersten çıkalım mı?',
    body: `<p style="font-size:13.5px;line-height:1.5">Şimdiye kadarki çalışman kaydedilecek.
      İstediğin zaman kaldığın yerden devam edebilirsin.</p>`,
    okLabel: 'Çık',
    cancelLabel: 'Devam et',
    onOk: () => {
      const result = s.buildResult();
      s.abandon();
      S.lessonResult = result;
      closeModal();
      go('lessonDone');
      return false;
    },
  });
}

const startListen = () => S.lesson && S.lesson.listen();
const pickOption = i => S.lesson && S.lesson.submitChoice(i);
const skipExercise = () => S.lesson && S.lesson.skip();

function repeatPrompt() {
  const s = S.lesson;
  if (!s) return;
  const ex = s.current;
  Speech.speak(ex ? ex.prompt : (s.banner || ''));
}

function submitTyped() {
  const el = document.getElementById('answerin');
  if (!el || !S.lesson) return;
  const v = el.value.trim();
  if (!v) return;
  el.value = '';
  S.lesson.submitSpeech(v, 0.92);
}

async function retryMic() {
  const ok = await Speech.requestMic();
  if (ok && S.lesson) {
    S.lesson.voiceMode = 'voice';
    S.lesson.phase = 'awaiting';
    render();
    S.lesson.listen();
  } else {
    toast('Mikrofon izni verilmedi');
  }
}

function useTextMode() {
  if (!S.lesson) return;
  S.lesson.voiceMode = 'text';
  S.lesson.phase = 'awaiting';
  render();
}

/* --- Ayar eylemleri -------------------------------------------------------- */
function setField(f, v) { S.settings[f] = v; savePrefs(); }
function setNum(f, v) {
  S.settings[f] = parseFloat(v);
  Speech.applySettings(S.settings);
  savePrefs();
  scheduleRender();
}
function toggleField(f) { S.settings[f] = !S.settings[f]; savePrefs(); render(); }
function setProvider(id) { S.settings.provider = id; savePrefs(); render(); }
function toggleKey() { S.showKey = !S.showKey; render(); }

let renderTimer = null;
function scheduleRender() {
  clearTimeout(renderTimer);
  renderTimer = setTimeout(() => render(true), 350);
}

function clearKey() {
  S.settings.apiKey = '';
  S.settings.provider = 'offline';
  savePrefs(); render(); toast('Anahtar silindi');
}

function resetProgress() {
  const c = activeChild();
  showModal({
    title: 'İlerlemeyi sıfırla',
    body: `<p style="font-size:13.5px;line-height:1.5">${esc(c.name)} için tüm ders kayıtları,
      yıldızlar ve ses ustalıkları silinecek. Bu işlem geri alınamaz.</p>`,
    okLabel: 'Sıfırla', danger: true,
    onOk: () => { ProgressStore.clear(c.id); closeModal(); render(); toast('İlerleme sıfırlandı'); return false; },
  });
}

function resetAll() {
  showModal({
    title: 'Her şeyi sıfırla',
    body: `<p style="font-size:13.5px;line-height:1.5">Tüm profillerin ilerlemesi, ayarlar
      ve PIN'ler silinecek. Bu işlem geri alınamaz.</p>`,
    okLabel: 'Sıfırla', danger: true,
    onOk: () => {
      CHILDREN.forEach(c => ProgressStore.clear(c.id));
      try { localStorage.removeItem('tb_prefs'); localStorage.removeItem('tb_pins');
            localStorage.removeItem('tb_active_child'); } catch (e) {}
      S.pins = {parent: null, teacher: null};
      S.settings = {provider:'offline', apiKey:'', useProxy:false, proxyUrl:'',
        rate:0.44, pitch:1.18, limit:12, silence:6, redact:true, store:true, voiceMode:'auto'};
      S.activeChildId = 'c1';
      closeModal(); go('login'); toast('Her şey sıfırlandı');
      return false;
    },
  });
}

function testConn() {
  const s = S.settings;
  const btn = document.getElementById('testbtn');
  const out = document.getElementById('testout');
  if (!btn || !out) return;
  btn.textContent = '⏳ Deneniyor...'; btn.disabled = true;
  setTimeout(() => {
    const ok = s.useProxy ? !!s.proxyUrl.trim() : s.apiKey.trim().length > 12;
    const msg = ok ? 'Bağlantı başarılı.'
      : (s.useProxy ? 'Sunucu adresi girilmemiş.' : 'API anahtarı geçersiz veya eksik.');
    const c = ok ? '#22C55E' : '#EF4444';
    out.innerHTML = `<div style="margin-top:14px;background:${c}14;border:1px solid ${c}4D;
      border-radius:var(--r-md);padding:14px;display:flex;gap:10px">
      <span style="color:${c}">${ok ? '✓' : '⛔'}</span>
      <div><div style="font-size:14px;font-weight:800;color:${c}">${ok ? 'Başarılı' : 'Başarısız'}</div>
        <p style="font-size:12.5px;line-height:1.45;margin-top:3px">${msg}</p>
        ${ok ? '<p class="sub" style="font-size:11.5px;margin-top:4px">Yanıt süresi: 412 ms (demo)</p>' : ''}</div></div>`;
    btn.textContent = '📡 Bağlantıyı test et'; btn.disabled = false;
  }, 850);
}

function previewVoice() {
  Speech.applySettings(S.settings);
  Speech.speak('Merhaba! Ben Buddy. Sesim böyle çıkıyor, beğendin mi?');
  toast('Buddy konuşuyor...');
}

async function checkMic() {
  if (!Speech.supportsRecognition()) {
    toast('Bu tarayıcı konuşma tanımayı desteklemiyor');
    return;
  }
  const ok = await Speech.requestMic();
  toast(ok ? '✓ Mikrofon hazır' : '⛔ Mikrofon izni verilmedi');
  render();
}

function copyText(t) {
  if (navigator.clipboard) navigator.clipboard.writeText(t).then(() => toast('Kopyalandı'));
  else toast(t);
}

/* --- Modal / sheet / toast -------------------------------------------------- */
let modalState = null;

function showModal(cfg) {
  modalState = cfg;
  const el = document.getElementById('modal');
  el.innerHTML = `<div class="mbox">
    <h3>${cfg.title}</h3>
    <div class="mbody">${cfg.body}</div>
    <div class="mact">
      <button class="mbtn" onclick="closeModal()">${cfg.cancelLabel || 'Vazgeç'}</button>
      <button class="mbtn primary ${cfg.danger ? 'danger' : ''}" onclick="modalOk()">${cfg.okLabel || 'Tamam'}</button>
    </div></div>`;
  el.classList.add('show');
  setTimeout(() => {
    const f = el.querySelector('input[autofocus], input');
    if (f) f.focus();
  }, 60);
}

function modalOk() {
  if (modalState && modalState.onOk) {
    const close = modalState.onOk();
    if (close !== false) closeModal();
  } else closeModal();
}

function closeModal() {
  modalState = null;
  const el = document.getElementById('modal');
  el.classList.remove('show');
  el.innerHTML = '';
}

let sheetActions = [];

function showSheet(title, items) {
  sheetActions = items.map(i => i.action);
  const el = document.getElementById('sheet');
  el.innerHTML = `<div class="sbox">
    <div class="shandle"></div>
    <h3>${title}</h3>
    ${items.map((it, i) => `<button class="sitem" onclick="sheetAct(${i})">${it.html}</button>`).join('')}
    <button class="mbtn" style="width:100%;margin-top:10px" onclick="closeSheet()">Kapat</button>
  </div>`;
  el.classList.add('show');
}

const sheetAct = i => sheetActions[i] && sheetActions[i]();

function closeSheet() {
  const el = document.getElementById('sheet');
  el.classList.remove('show');
  el.innerHTML = '';
}

let toastTimer = null;
function toast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 1900);
}

/* --- Render ---------------------------------------------------------------- */
const CAPTIONS = {
  login:'Giriş — rol seçimi, PIN korumalı veli ve öğretmen',
  path:'Öğrenme yolu — 11 ünite, 33 ders, kilitli ilerleme',
  lesson:'Ders akışı — sesli soru, sesli cevap, canlı değerlendirme',
  lessonDone:'Ders sonu — yıldızlar, aileye not, ses süreçleri',
  sounds:'Ses haritası — edinim sırasına göre ustalık',
  rewards:'Rozetler — gerçek ilerlemeye bağlı',
  parent:'Veli paneli — ünite ilerlemesi ve ses ustalığı',
  history:'Ders geçmişi — tamamlanan dersler',
  teacher:'Öğretmen paneli — sınıf bazlı öğrenci listesi',
  student:'Öğrenci detayı — ustalık haritası, ünite durumu',
  specialist:'Uzman paneli — risk sıralı danışan listesi',
  alerts:'Uyarılar — ilerlemeden otomatik üretilir',
  settings:'Ayarlar — servis, profil, güvenlik, gizlilik',
  aiset:'Yapay zeka servisi — sağlayıcı ve API anahtarı',
  speechset:'Ses ve ders ayarları',
};

const NOTES = {
  login:[['PIN koruması','Veli ve öğretmen ilk girişte 4 haneli PIN oluşturur. Çocuk doğrudan girer.']],
  path:[['Kilitli ilerleme','Ünite ve dersler sırayla açılır. Sıra Türkçe fonolojik edinim sırasına göre: p,b,m → t,d,n → k,g → f,v,s,z → l → ş,ç,c → r.'],
        ['Gerçek veri','Yıldız, seri ve yüzde localStorage\'da tutulur; ders bitirdikçe artar.']],
  lesson:[['Gerçek ses','Chrome/Edge\'de mikrofonla konuşabilirsiniz. Desteklenmeyen tarayıcıda yazılı kutu çıkar.'],
          ['Hatasız öğrenme','Can yok. 1. hatada yavaş model, 2. hatada ilk hece ipucu, 3. denemede kabul edip ilerler.'],
          ['Fonolojik tolerans','"kedi" yerine "tedi" derseniz GEÇER — gelişimsel öne alma olarak tanınır ve uzmana raporlanır.']],
  lessonDone:[['Ses süreçleri','Tespit edilen gelişimsel süreçler ve tipik düzelme yaşları listelenir.']],
  sounds:[['Edinim sırası','20 ses Türkçede öğrenilme yaşına göre dizili. Yaşa göre erken olanlar soluk gösterilir.']],
  parent:[['Canlı veri','Panel çocuğun gerçek ders kayıtlarından beslenir. Ders yapmadan boş görünür.']],
  teacher:[['Sınıf bazlı','İki sınıf, beş öğrenci. Her öğrencinin ilerlemesi ayrı saklanır.'],
           ['Rol geçişi','Öğrenci detayında "bu öğrenci olarak derse gir" ile profil değişir.']],
  specialist:[['Otomatik uyarı','Uyarılar sabit değil — ustalık skorları ve yaş normlarından üretilir.']],
  settings:[['Sıfırlama','Demoyu baştan denemek için "Her şeyi sıfırla" kullanın.']],
};

function render(keepScroll) {
  const view = document.getElementById('view');
  const nav = document.getElementById('nav');
  const app = document.getElementById('app');
  const scroll = keepScroll ? view.scrollTop : 0;

  const active = document.activeElement;
  const activeId = active && active.id;
  const caret = active && active.selectionStart;

  view.innerHTML = SCREENS[S.screen] ? SCREENS[S.screen]() : '';

  const inShell = S.shell && SHELLS[S.shell].screens.includes(S.screen)
                  && !FULLSCREEN.includes(S.screen);

  if (inShell) {
    const sh = SHELLS[S.shell];
    app.style.background = sh.bg;
    nav.className = '';
    nav.innerHTML = sh.tabs.map((t, i) => `<button class="${i === S.tab ? 'on' : ''}"
      onclick="tabTo(${i})"><span class="ni">${t[0]}</span><span class="nl">${t[1]}</span></button>`).join('');
  } else {
    nav.className = 'hide';
    nav.innerHTML = '';
    app.style.background = ['path','sounds','rewards','lesson','lessonDone','login']
      .includes(S.screen) ? '#F2F4FF' : 'var(--canvas)';
  }

  view.scrollTop = scroll;

  if (activeId) {
    const el = document.getElementById(activeId);
    if (el) { el.focus(); try { el.setSelectionRange(caret, caret); } catch (e) {} }
  }

  const cap = document.getElementById('caption');
  if (cap) cap.textContent = CAPTIONS[S.screen] || '';
  const notes = document.getElementById('notes');
  if (notes) {
    notes.innerHTML = (NOTES[S.screen] || [])
      .map(n => `<div class="note"><h4>${n[0]}</h4><p>${n[1]}</p></div>`).join('');
  }
  document.querySelectorAll('#navlist button').forEach(b =>
    b.classList.toggle('on', b.dataset.s === S.screen));

  bindMicWave();
}

/* Mikrofon dalgasını canlı seviyeye bağla (render'dan bağımsız, akıcı) */
function bindMicWave() {
  Speech.onLevel = (lvl) => {
    const wave = document.getElementById('micwave');
    if (!wave) return;
    const active = S.lesson && S.lesson.phase === 'listening';
    wave.querySelectorAll('i').forEach(bar => {
      const m = parseFloat(bar.dataset.m || '0.5');
      bar.style.height = (active ? 6 + lvl * 28 * m : 6) + 'px';
    });
  };
}

/* --- Masaüstü menüsü ------------------------------------------------------- */
const MENU = [
  ['Giriş', [['login','🚪','Rol Seçimi']]],
  ['Çocuk', [['path','🗺️','Öğrenme Yolu'],['sounds','🔤','Ses Haritam'],['rewards','⭐','Rozetler']]],
  ['Veli', [['parent','📊','Panel'],['history','📄','Ders Geçmişi']]],
  ['Öğretmen', [['teacher','👥','Sınıfım'],['student','🔬','Öğrenci Detayı']]],
  ['Uzman', [['specialist','🩺','Danışanlar'],['alerts','🔔','Uyarılar']]],
  ['Ayarlar', [['settings','⚙️','Genel'],['aiset','🔑','Yapay Zeka'],['speechset','🔊','Ses ve Ders']]],
];

function buildMenu() {
  const el = document.getElementById('navlist');
  if (!el) return;
  el.innerHTML = MENU.map(g => `<p class="nav-title">${g[0]}</p>` +
    g[1].map(i => `<button data-s="${i[0]}"><span class="ico">${i[1]}</span>${i[2]}</button>`).join('')
  ).join('');
  el.querySelectorAll('button').forEach(b =>
    b.addEventListener('click', () => {
      if (b.dataset.s === 'lesson') { startLesson(nextLesson(activeProgress()) ? nextLesson(activeProgress()).id : 'u1l1'); return; }
      go(b.dataset.s);
    }));
}

/* --- Yerleşim -------------------------------------------------------------- */
function isMobile() {
  const touch = ('ontouchstart' in window) || navigator.maxTouchPoints > 0;
  const narrow = Math.min(window.innerWidth, window.innerHeight) < 560;
  const ua = /Android|iPhone|iPad|iPod|Mobile|Windows Phone/i.test(navigator.userAgent);
  return (touch && narrow) || (ua && narrow) || window.innerWidth < 560;
}

function applyLayout() {
  const mobile = isMobile();
  document.body.classList.toggle('mobile', mobile);
  const host = document.getElementById('phone-host');
  const slot = document.getElementById('phone-host-desk');
  if (mobile) {
    if (host.parentNode !== document.body) document.body.appendChild(host);
    host.style.cssText = '';
  } else {
    if (host.parentNode !== slot) slot.appendChild(host);
    host.style.cssText = 'width:100%;height:100%';
  }
}

let rzTimer = null;
window.addEventListener('resize', () => {
  clearTimeout(rzTimer);
  rzTimer = setTimeout(() => { applyLayout(); render(true); }, 150);
});

let lastTouch = 0;
document.addEventListener('touchend', e => {
  const now = Date.now();
  if (now - lastTouch < 320) e.preventDefault();
  lastTouch = now;
}, {passive: false});

/* --- Başlat ---------------------------------------------------------------- */
loadPrefs();
Speech.applySettings(S.settings);
buildMenu();
applyLayout();
go('login', true);
