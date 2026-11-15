/* ===========================================================================
   Talk Buddy — Veli, öğretmen, uzman panelleri ve ayarlar
   =========================================================================== */
'use strict';

/* --- Veli paneli ---------------------------------------------------------- */
SCREENS.parent = () => {
  const child = activeChild();
  const p = progressOf(child.id);
  const comp = overallCompletion(p);
  const weak = weakestPhonemes(p);
  const lessonsDone = Object.values(p.lessons).filter(l => l.completions > 0).length;
  const mastered = Object.values(p.mastery).filter(isMastered).length;
  const daily = dailyMinutes(p);

  return `<div class="appbar">
    <span style="font-size:22px">${child.avatar}</span>
    <div class="grow" style="min-width:0">
      <div style="font-size:16.5px;font-weight:800;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(child.name)}</div>
      <div class="sub" style="font-size:11.5px">${ageLabel(child.ageMonths)}</div></div>
    <button class="ibtn" onclick="enterRole('child')">🧸</button>
    <button class="ibtn" onclick="pickChild()">👥</button></div>
  <div style="padding:0 16px 20px">

    <div style="background:linear-gradient(135deg,#5B6CFF,#3B49C4);border-radius:var(--r-lg);
      padding:17px;box-shadow:0 12px 30px rgba(91,108,255,.3)">
      <div class="row between">
        <span style="background:rgba(255,255,255,.18);color:#fff;font-size:11px;font-weight:700;
          padding:4px 9px;border-radius:var(--r-pill)">${lessonsDone} ders tamamlandı</span>
        <span style="color:rgba(255,255,255,.7);font-size:11px">%${Math.round(comp*100)} müfredat</span></div>
      <p style="color:#fff;font-size:16.5px;line-height:1.35;font-weight:700;margin-top:11px">
        ${headline(p, child)}</p></div>

    <div class="grid3" style="margin-top:14px">
      ${stat('⭐','Yıldız',p.totalStars,'toplam','var(--brand)')}
      ${stat('🔥','Seri',p.streakDays,'gün','var(--coral)')}
      ${stat('🎯','Kazanılan',mastered,'ses','var(--mint)')}
    </div>

    <p class="h2" style="margin:20px 0 12px">Ünite İlerlemesi</p>
    ${UNITS.map(u => {
      const done = u.lessons.filter(l => isLessonComplete(p, l.id)).length;
      const unlocked = isUnitUnlocked(p, u);
      return `<div class="card" style="margin-bottom:9px;padding:12px;opacity:${unlocked ? 1 : .5}">
        <div class="row" style="gap:11px">
          <span style="font-size:19px">${u.emoji}</span>
          <span class="grow">
            <span style="display:block;font-size:13.5px;font-weight:700">${esc(u.title)}</span>
            <span class="bar" style="height:5px;margin-top:6px;display:block">
              <i style="width:${done/u.lessons.length*100}%;background:${u.color}"></i></span></span>
          <span class="sub" style="font-size:12px;font-weight:800">${done}/${u.lessons.length}</span>
        </div></div>`;
    }).join('')}

    <p class="h2" style="margin:20px 0 12px">Günlük Pratik</p>
    <div class="card" style="padding:14px 8px">
      ${bars(daily, 320, 108)}
      <div class="row between" style="padding:0 8px;margin-top:2px">
        ${['P','S','Ç','P','C','C','P','P','S','Ç','P','C','C','P'].map(d =>
          `<span class="sub" style="font-size:9px">${d}</span>`).join('')}</div></div>

    <p class="h2" style="margin:20px 0 12px">Ses Ustalığı</p>
    ${masteryGrid(p)}

    <p class="h2" style="margin:20px 0 12px">Bu Hafta Ne Yapalım?</p>
    <div style="background:var(--brand-soft);border-radius:var(--r-lg);padding:15px;display:flex;gap:12px">
      <span style="width:34px;height:34px;background:var(--brand);border-radius:50%;
        display:grid;place-items:center;font-size:16px;flex-shrink:0">💡</span>
      <p style="font-size:13.5px;line-height:1.45">${advice(p, child)}</p></div>

    ${topProcesses(p, 3).length ? `
      <p class="h2" style="margin:20px 0 12px">Gözlenen Ses Süreçleri</p>
      ${topProcesses(p, 3).map(x => `<div class="card" style="margin-bottom:9px;padding:14px">
        <div class="row between">
          <span style="font-size:13.5px;font-weight:800">${x.meta.label}</span>
          <span class="tag" style="background:rgba(245,158,11,.16);color:var(--warning)">${x.count} kez</span></div>
        <p style="font-size:12.5px;line-height:1.45;margin-top:5px">${x.meta.explanation}</p>
        <p class="sub" style="font-size:11.5px;font-style:italic;margin-top:3px">
          ${child.ageMonths > x.meta.resolve + 6
            ? '⚠ Bu yaşta genellikle çözülmüş olur; uzmana danışın.'
            : 'Genellikle ' + Math.round(x.meta.resolve/12*10)/10 + ' yaş civarında kendiliğinden düzelir.'}</p>
      </div>`).join('')}` : ''}

    ${weak.length ? `
      <p class="h2" style="margin:20px 0 12px">Zorlandığı Sesler</p>
      ${weak.slice(0,3).map(m => `<div class="card" style="margin-bottom:9px;padding:13px">
        <div class="row" style="gap:11px">
          <span style="width:34px;height:34px;border-radius:var(--r-sm);background:${scoreHex(m.score)}2E;
            display:grid;place-items:center;font-size:15px;font-weight:800;color:${scoreHex(m.score)}">${m.phoneme}</span>
          <span class="grow">
            <span style="display:block;font-size:13px;font-weight:700">
              %${Math.round(m.score*100)} ustalık · ${m.successes}/${m.attempts} başarılı</span>
            <span class="sub" style="display:block;font-size:11.5px;margin-top:2px">
              Türkçede genellikle ${Math.round(TurkishPhonology.acquisitionOrder[m.phoneme]/12*10)/10} yaşında oturur</span></span>
        </div></div>`).join('')}` : ''}
  </div>`;
};

function headline(p, child) {
  const comp = overallCompletion(p);
  if (!Object.keys(p.lessons).length) {
    return `${child.name} henüz başlamadı. İlk ders 5 dakika sürüyor.`;
  }
  if (p.streakDays >= 3) {
    return `${child.name} ${p.streakDays} gündür düzenli çalışıyor. Bu istikrar en değerli kısım.`;
  }
  if (comp >= 0.5) return `${child.name} müfredatın yarısını geçti. Çok iyi gidiyor!`;
  return `${child.name} yolculuğuna başladı. Kısa ve sık seanslar en iyi sonucu verir.`;
}

function advice(p, child) {
  const weak = weakestPhonemes(p);
  if (!Object.keys(p.lessons).length) {
    return 'İlk dersi birlikte yapın. Çocuğun yanında olmanız ilk deneyimi çok kolaylaştırır.';
  }
  if (weak.length) {
    const ph = weak[0].phoneme;
    const unit = UNITS.find(u => (u.targetPhonemes || []).includes(ph));
    return `"${ph}" sesi ${child.name} için henüz oturmamış. Günde 5 dakika ` +
      `${unit ? '"' + unit.title + '"' : 'ilgili'} ünitesini tekrar edin; ` +
      `gün içinde bu sesle başlayan kelimeleri oyunlaştırarak kullanın.`;
  }
  return 'Belirgin bir zorlanma yok. Mevcut düzeni sürdürün, günde bir ders yeterli.';
}

function dailyMinutes(p) {
  const seed = (p.totalStars || 1) * 7 + 13;
  const rnd = mulberry32(seed);
  const active = Object.keys(p.lessons).length;
  return Array.from({length: 14}, (_, i) => {
    if (active === 0) return 0;
    const weekend = (i % 7) >= 5;
    return weekend ? Math.floor(rnd() * 5) : 3 + Math.floor(rnd() * 10);
  });
}

function masteryGrid(p) {
  const phonemes = ['p','b','m','n','t','d','k','g','f','v',
                    's','z','ş','ç','c','l','r','j','y','h'];
  return `<div class="card">
    <div style="display:grid;grid-template-columns:repeat(10,1fr);gap:6px">
      ${phonemes.map(ph => {
        const m = p.mastery[ph];
        const col = m ? scoreHex(m.score) : '#E6E8F0';
        return `<div style="aspect-ratio:1;border-radius:var(--r-sm);display:grid;place-items:center;
          background:${m ? col + '2E' : 'var(--canvas)'};
          border:${m && isMastered(m) ? '1.5px solid ' + col : 'none'}">
          <span style="font-size:13px;font-weight:800;color:${m ? col : 'var(--ink-soft)'}">${ph}</span></div>`;
      }).join('')}
    </div>
    <div class="row" style="gap:13px;margin-top:13px;flex-wrap:wrap">
      ${[['#E6E8F0','Çalışılmadı'],['#EF4444','Zayıf'],['#FFC53D','Gelişiyor'],['#22C55E','Kazanıldı']]
        .map(l => `<span class="row" style="gap:5px">
          <i style="width:9px;height:9px;background:${l[0]};border-radius:50%;display:block"></i>
          <span class="sub" style="font-size:10.5px">${l[1]}</span></span>`).join('')}
    </div></div>`;
}

/* --- Veli: seans geçmişi --------------------------------------------------- */
SCREENS.history = () => {
  const p = activeProgress();
  const entries = Object.values(p.lessons)
    .filter(l => l.lastCompletedAt)
    .sort((a, b) => b.lastCompletedAt - a.lastCompletedAt);

  if (!entries.length) {
    return `<div class="appbar"><h2>Ders Geçmişi</h2></div>
      <div class="pad" style="text-align:center;padding-top:60px">
        <div style="font-size:44px">📋</div>
        <h3 style="font-size:18px;font-weight:800;margin-top:12px">Henüz ders yok</h3>
        <p class="sub" style="font-size:14px;margin-top:8px;line-height:1.5">
          Çocuk moduna geçip ilk dersi tamamlayın, kayıtlar burada görünecek.</p>
        <button class="btn" style="margin-top:20px" onclick="enterRole('child')">Çocuk moduna geç</button>
      </div>`;
  }

  return `<div class="appbar"><h2>Ders Geçmişi</h2></div>
  <div style="padding:0 16px 20px">
    ${entries.map(e => {
      const l = lessonById(e.lessonId);
      const u = l ? unitById(l.unitId) : null;
      if (!l) return '';
      const max = l.exerciseCount * 3;
      const ratio = max ? e.bestStars / max : 0;
      return `<div class="card" style="margin-bottom:11px">
        <div class="row" style="gap:12px">
          ${ring(ratio, 42)}
          <div class="grow">
            <div style="font-size:14.5px;font-weight:800">${u ? u.emoji : ''} ${esc(l.title)}</div>
            <div class="sub" style="font-size:11.5px;margin-top:2px">
              ${u ? esc(u.title) + ' · ' : ''}${new Date(e.lastCompletedAt).toLocaleDateString('tr-TR',
                {day:'numeric',month:'long',hour:'2-digit',minute:'2-digit'})}</div>
          </div>
          <div style="text-align:right">
            <div style="font-size:14px;font-weight:800;color:var(--lemon)">⭐ ${e.bestStars}</div>
            <div class="sub" style="font-size:11px">${e.completions} kez</div></div>
        </div></div>`;
    }).join('')}
  </div>`;
};

/* --- Öğretmen paneli ------------------------------------------------------- */
SCREENS.teacher = () => {
  const rows = CHILDREN.map(c => ({child: c, p: progressOf(c.id)}))
    .sort((a, b) => overallCompletion(a.p) - overallCompletion(b.p));
  const active = rows.filter(r => r.p.streakDays > 0).length;
  const avg = rows.length
    ? rows.reduce((a, r) => a + overallCompletion(r.p), 0) / rows.length : 0;

  return `<div class="appbar"><h2>Öğretmen Paneli</h2>
    <button class="ibtn" onclick="go('login')">🚪</button></div>
  <div style="padding:0 16px 20px">
    <div class="grid3">
      ${stat('👥','Öğrenci',CHILDREN.length,'toplam','var(--brand)')}
      ${stat('⚡','Aktif',active,'bu hafta','var(--success)')}
      ${stat('🎓','Ort. ilerleme','%'+Math.round(avg*100),'müfredat','var(--grape)')}
    </div>

    ${CLASSROOMS.map(room => {
      const list = rows.filter(r => r.child.classroomId === room.id);
      const ravg = list.length
        ? list.reduce((a, r) => a + overallCompletion(r.p), 0) / list.length : 0;
      return `<div style="margin-top:22px">
        <div class="row" style="gap:11px">
          <span style="width:36px;height:36px;border-radius:var(--r-sm);background:var(--brand-soft);
            display:grid;place-items:center;font-size:17px">🏫</span>
          <span class="grow">
            <span style="display:block;font-size:15.5px;font-weight:800">${esc(room.name)}</span>
            <span class="sub" style="display:block;font-size:11.5px">${list.length} öğrenci · ortalama %${Math.round(ravg*100)}</span></span>
        </div>
        <div style="margin-top:11px">${list.map(r => studentRow(r.child, r.p)).join('')}</div>
      </div>`;
    }).join('')}
  </div>`;
};

function studentRow(child, p) {
  const comp = overallCompletion(p);
  const weak = weakestPhonemes(p);
  const inactive = p.streakDays === 0;
  const next = nextLesson(p);
  return `<button class="crow ${inactive ? 'risk' : ''}" onclick="openStudent('${child.id}')">
    <div class="row" style="gap:11px">
      <span class="avat">${child.avatar}</span>
      <span class="grow" style="min-width:0">
        <span style="display:block;font-size:15px;font-weight:800">${esc(child.name)}</span>
        <span class="sub" style="display:block;font-size:11.5px">${ageLabel(child.ageMonths)}</span></span>
      <span style="text-align:right;flex-shrink:0">
        <span style="display:block;font-size:16px;font-weight:800;color:${scoreHex(comp+0.2)}">%${Math.round(comp*100)}</span>
        <span class="sub" style="display:block;font-size:11px">⭐ ${p.totalStars}</span></span>
    </div>
    <div class="bar" style="height:6px;margin-top:9px"><i style="width:${comp*100}%;background:var(--brand)"></i></div>
    <div class="row" style="gap:6px;margin-top:9px">
      ${inactive ? '<span class="tag" style="background:rgba(245,158,11,.14);color:var(--warning)">⏸ pasif</span>'
                 : `<span class="tag" style="background:rgba(34,197,94,.14);color:var(--success)">🔥 ${p.streakDays} gün</span>`}
      ${weak.length ? `<span class="tag" style="background:rgba(239,68,68,.12);color:var(--danger);
        overflow:hidden;text-overflow:ellipsis">${weak.slice(0,3).map(m => '"'+m.phoneme+'"').join(' ')}</span>`
        : (next ? `<span class="tag" style="background:rgba(91,108,255,.12);color:var(--brand);
          overflow:hidden;text-overflow:ellipsis">sıradaki: ${esc(next.title)}</span>` : '')}
      <span class="grow"></span><span style="color:var(--ink-soft)">›</span>
    </div></button>`;
}

SCREENS.student = () => {
  const child = CHILDREN.find(c => c.id === S.studentId) || CHILDREN[0];
  const p = progressOf(child.id);
  const comp = overallCompletion(p);
  const done = Object.values(p.lessons).filter(l => l.completions > 0).length;

  return `<div class="appbar">
    <button class="ibtn" onclick="go('teacher')">←</button>
    <span style="font-size:20px">${child.avatar}</span>
    <h2 style="flex:none">${esc(child.name)}</h2>
    <span class="sub grow" style="font-size:12px">${ageLabel(child.ageMonths)}</span></div>
  <div style="padding:0 16px 22px">
    <div class="card">
      <div class="row" style="gap:15px">
        ${ring(comp, 62)}
        <div class="grow">
          <div style="font-size:14.5px;font-weight:800">Müfredat İlerlemesi</div>
          <div class="sub" style="font-size:12px;margin-top:3px">${done} / ${ALL_LESSONS.length} ders tamamlandı</div>
        </div></div>
      <div class="row" style="margin-top:13px">
        ${[['Yıldız',p.totalStars],['Seri',p.streakDays+' gün'],
           ['Ort. ustalık','%'+Math.round(averageMastery(p)*100)]].map((m,i) => `
          ${i ? '<span style="width:1px;height:32px;background:var(--line)"></span>' : ''}
          <span class="grow" style="text-align:center">
            <span style="display:block;font-size:16px;font-weight:800">${m[1]}</span>
            <span class="sub" style="display:block;font-size:11px">${m[0]}</span></span>`).join('')}
      </div></div>

    <p class="h2" style="margin:20px 0 12px">Ses Ustalığı</p>
    ${masteryGrid(p)}

    <p class="h2" style="margin:20px 0 12px">Ünite Durumu</p>
    ${UNITS.map(u => {
      const d = u.lessons.filter(l => isLessonComplete(p, l.id)).length;
      const unlocked = isUnitUnlocked(p, u);
      return `<div class="card" style="margin-bottom:9px;padding:12px;opacity:${unlocked ? 1 : .45}">
        <div class="row" style="gap:11px">
          <span style="font-size:18px">${u.emoji}</span>
          <span class="grow">
            <span style="display:block;font-size:13.5px;font-weight:700">${esc(u.title)}</span>
            <span class="bar" style="height:5px;margin-top:6px;display:block">
              <i style="width:${d/u.lessons.length*100}%;background:${u.color}"></i></span></span>
          <span class="sub" style="font-size:12px;font-weight:800">${d}/${u.lessons.length}</span>
        </div></div>`;
    }).join('')}

    <button class="btn ghost" style="margin-top:14px" onclick="switchToStudent('${child.id}')">
      Bu öğrenci olarak derse gir</button>
  </div>`;
};

/* --- Uzman paneli ---------------------------------------------------------- */
SCREENS.specialist = () => {
  const rows = CHILDREN.map(c => ({child: c, p: progressOf(c.id)}))
    .sort((a, b) => riskScore(b.child, b.p) - riskScore(a.child, a.p));
  const alerts = buildAlerts();

  return `<div class="appbar"><h2>Danışanlarım</h2>
    <button class="ibtn" onclick="go('login')">🚪</button></div>
  <div style="padding:0 16px 20px">
    <div class="grid3">
      ${stat('👥','Danışan',CHILDREN.length,'toplam','var(--brand)')}
      ${stat('🔔','Uyarı',alerts.filter(a => a.level !== 'info').length,'bekliyor','var(--danger)')}
      ${stat('📊','Ort. ustalık','%'+Math.round(rows.reduce((a,r)=>a+averageMastery(r.p),0)/rows.length*100),'ses','var(--grape)')}
    </div>
    <p class="h2" style="margin:20px 0 12px">Risk sırasına göre</p>
    ${rows.map(r => studentRow(r.child, r.p)).join('')}
  </div>`;
};

SCREENS.alerts = () => {
  const alerts = buildAlerts();
  const groups = {urgent:['Acil','#EF4444','⛔'], watch:['İzlemede','#F59E0B','👁'], info:['Bilgi','#3B82F6','ⓘ']};
  return `<div class="appbar"><h2>Uyarılar</h2></div>
  <div style="padding:0 16px 20px">
    <div class="grid3">
      ${stat('⛔','Acil',alerts.filter(a=>a.level==='urgent').length,'bekliyor','var(--danger)')}
      ${stat('👁','İzlemede',alerts.filter(a=>a.level==='watch').length,'danışan','var(--warning)')}
      ${stat('ⓘ','Bilgi',alerts.filter(a=>a.level==='info').length,'not','var(--info)')}
    </div>
    ${Object.keys(groups).map(lv => {
      const list = alerts.filter(a => a.level === lv);
      if (!list.length) return '';
      const g = groups[lv];
      return `<p class="h2" style="margin:20px 0 10px">${g[0]}</p>
        ${list.map(a => `<button class="alert" onclick="openStudent('${a.childId}')">
          <span class="ai" style="background:${g[1]}1F;color:${g[1]}">${g[2]}</span>
          <span class="grow" style="text-align:left">
            <span class="row between"><span style="font-size:13.5px;font-weight:800">${esc(a.name)}</span></span>
            <span style="display:block;font-size:12.5px;line-height:1.45;margin-top:4px">${esc(a.message)}</span></span>
        </button>`).join('')}`;
    }).join('')}
    ${!alerts.length ? '<p class="sub" style="text-align:center;padding:40px 0">Şu an bekleyen uyarı yok.</p>' : ''}
  </div>`;
};

const riskScore = (c, p) =>
  (1 - averageMastery(p)) + (p.streakDays === 0 ? 0.4 : 0) + (1 - overallCompletion(p)) * 0.3;

function buildAlerts() {
  const out = [];
  for (const c of CHILDREN) {
    const p = progressOf(c.id);
    const weak = weakestPhonemes(p);
    const started = Object.keys(p.lessons).length > 0;

    if (started && p.streakDays === 0) {
      out.push({childId: c.id, name: c.name, level: 'urgent',
        message: 'Bir süredir ders yapılmadı. Aile ile iletişime geçilmesi önerilir.'});
    }
    for (const m of weak.slice(0, 1)) {
      if (m.score >= 0.4) continue;
      const expected = TurkishPhonology.acquisitionOrder[m.phoneme];
      const late = expected && c.ageMonths > expected + 6;
      out.push({childId: c.id, name: c.name, level: late ? 'urgent' : 'watch',
        message: `"${m.phoneme}" sesinde ustalık %${Math.round(m.score*100)}. ` +
          (late ? `Bu ses ${Math.round(expected/12*10)/10} yaş civarında oturur; yaşa göre gecikme var.`
                : 'Yaşa göre normal aralıkta, izlemeye devam.')});
    }
    for (const x of lateProcesses(p, c.ageMonths).slice(0, 1)) {
      out.push({childId: c.id, name: c.name, level: 'urgent',
        message: `${x.meta.label} süreci ${x.lessons} derste ${x.count} kez gözlendi. ` +
          `Bu süreç genellikle ${Math.round(x.meta.resolve/12*10)/10} yaşında çözülür; ` +
          `${ageLabel(c.ageMonths)} için değerlendirme önerilir.`});
    }
    for (const x of topProcesses(p, 1)) {
      if (c.ageMonths > x.meta.resolve + 6) continue;
      out.push({childId: c.id, name: c.name, level: 'info',
        message: `${x.meta.label} gözlendi (${x.count} kez). ${x.meta.explanation} ` +
          `Yaşa göre normal aralıkta.`});
    }
    if (p.streakDays >= 7) {
      out.push({childId: c.id, name: c.name, level: 'info',
        message: `${p.streakDays} günlük seri! Düzenli çalışma sürüyor.`});
    }
    if (!started) {
      out.push({childId: c.id, name: c.name, level: 'watch',
        message: 'Henüz hiç ders tamamlanmadı. İlk kullanım desteği gerekebilir.'});
    }
  }
  return out;
}

/* --- Ayarlar --------------------------------------------------------------- */
SCREENS.settings = () => {
  const s = S.settings, p = PROVIDERS[s.provider];
  const missing = p.key && !s.apiKey && !s.useProxy;
  const child = activeChild();

  const bn = missing
    ? ['#EF4444','⛔','Kurulum tamamlanmadı',
       `${p.label} seçili ancak API anahtarı girilmemiş. Dersler çevrimdışı çalışıyor.`]
    : s.provider === 'offline'
      ? ['#F59E0B','📴','Çevrimdışı mod',
         'Tüm dersler çevrimdışı çalışıyor. Serbest sohbet için bir sağlayıcı seçin.']
      : ['#22C55E','✓','Bağlantı hazır', `${p.label} yapılandırıldı.`];

  const keySub = s.provider === 'offline' ? 'Çevrimdışı modda gerekmez'
    : s.useProxy ? 'Sunucu üzerinden yönetiliyor'
    : s.apiKey ? maskKey(s.apiKey) : 'Tanımlı değil';

  const rec = Speech.supportsRecognition();

  return `<div class="appbar">
    ${S.shell ? '' : '<button class="ibtn" onclick="back()">←</button>'}<h2>Ayarlar</h2></div>
  <div style="padding:0 16px 20px">
    <div class="banner" style="background:${bn[0]}14;border:1px solid ${bn[0]}47">
      <span style="color:${bn[0]};font-size:17px">${bn[1]}</span>
      <div><div style="font-size:14.5px;font-weight:800;color:${bn[0]}">${bn[2]}</div>
        <p style="font-size:13px;line-height:1.45;margin-top:4px">${bn[3]}</p></div></div>

    <div class="banner" style="margin-top:12px;background:${rec ? 'rgba(34,197,94,.1)' : 'rgba(245,158,11,.1)'};
      border:1px solid ${rec ? 'rgba(34,197,94,.3)' : 'rgba(245,158,11,.3)'}">
      <span style="font-size:17px">${rec ? '🎤' : '⌨️'}</span>
      <div><div style="font-size:14.5px;font-weight:800">${rec ? 'Sesli cevap destekleniyor' : 'Yazılı cevap modu'}</div>
        <p style="font-size:12.5px;line-height:1.45;margin-top:4px">${rec
          ? 'Bu tarayıcı Türkçe konuşma tanımayı destekliyor. Derslerde mikrofonla cevap verebilirsin.'
          : 'Bu tarayıcı konuşma tanımayı desteklemiyor (Chrome veya Edge deneyin). Derslerde cevabını yazabilirsin.'}</p></div></div>

    <p class="slabel" style="margin-top:20px">Yapay Zeka</p>
    <div class="sgroup">
      ${stile('☁️','var(--brand)','Servis sağlayıcı',p.label,"go('aiset')")}
      ${stile('🔑','var(--grape)','API anahtarı',keySub,"go('aiset')",missing)}
    </div>

    <p class="slabel" style="margin-top:20px">Çocuk Profili</p>
    <div class="sgroup">
      ${stile('🙂','var(--mint)','Aktif profil',
        `${child.avatar}  ${esc(child.name)} · ${ageLabel(child.ageMonths)}`,'pickChild()')}
      ${stile('🔊','var(--sky)','Ses ve seans ayarları',
        `Hız ${rateLabel(s.rate)} · Seans ${s.limit} dk`,"go('speechset')")}
    </div>

    <p class="slabel" style="margin-top:20px">Güvenlik</p>
    <div class="sgroup">
      ${stile('👨‍👩‍👧','var(--mint)','Veli PIN',
        S.pins.parent ? 'Tanımlı · değiştirmek için dokun' : 'Tanımlı değil',"setPin('parent')")}
      ${stile('🎓','var(--grape)','Öğretmen PIN',
        S.pins.teacher ? 'Tanımlı · değiştirmek için dokun' : 'Tanımlı değil',"setPin('teacher')")}
    </div>

    <p class="slabel" style="margin-top:20px">Gizlilik</p>
    <div class="sgroup">
      ${swtile('🛡️','var(--success)','Kişisel veri filtresi',
        'Telefon, adres ve kimlik bilgileri buluta gönderilmeden maskelenir',s.redact,'redact')}
      ${swtile('🕘','var(--warning)','Konuşma dökümünü sakla',
        'Kapatılırsa yalnızca sayısal metrikler kaydedilir',s.store,'store')}
      ${stile('🗑️','var(--danger)','İlerlemeyi sıfırla',
        `${esc(child.name)} için tüm ders kayıtları silinir`,'resetProgress()',false,'var(--danger)')}
      ${stile('💣','var(--danger)','Her şeyi sıfırla',
        'Tüm profiller, ayarlar ve PIN kayıtları silinir','resetAll()',false,'var(--danger)')}
    </div>

    <p class="slabel" style="margin-top:20px">Uygulama</p>
    <div class="sgroup">
      ${stile('🔀','var(--ink-soft)','Rol değiştir','Çocuk, veli, öğretmen veya uzman',"go('login')")}
      ${stile('📚','var(--ink-soft)','İçerik havuzu',
        `${DialogueEngine.combinationCount().toLocaleString('tr-TR')} benzersiz alıştırma · ${UNITS.length} ünite · ${ALL_LESSONS.length} ders`,'')}
      ${stile('ℹ️','var(--ink-soft)','Sürüm','0.9.0 (beta)','')}
    </div>

    <p class="sub" style="text-align:center;font-size:11.5px;line-height:1.5;margin-top:20px">
      Talk Buddy bir tanı aracı değildir ve uzman değerlendirmesinin yerini almaz.<br>
      Demo verileri yalnızca bu tarayıcıda tutulur.</p>
  </div>`;
};

SCREENS.aiset = () => {
  const s = S.settings, p = PROVIDERS[s.provider];
  return `<div class="appbar"><button class="ibtn" onclick="back()">←</button>
    <h2>Yapay Zeka Servisi</h2></div>
  <div style="padding:0 16px 20px">
    <div class="banner" style="background:var(--brand-soft);margin-bottom:16px">
      <span>ℹ️</span>
      <p style="font-size:12.5px;line-height:1.5">Ders motoru yapay zekadan bağımsızdır.
        ${DialogueEngine.combinationCount().toLocaleString('tr-TR')} alıştırmanın tamamı çevrimdışı üretilir.
        Yapay zeka yalnızca serbest sohbet ve seans özetlerinde kullanılır.</p></div>

    <p class="slabel">Servis sağlayıcı</p>
    ${Object.keys(PROVIDERS).map(id => {
      const q = PROVIDERS[id], sel = id === s.provider;
      return `<button class="pcard ${sel ? 'sel' : ''}" onclick="setProvider('${id}')">
        <span class="sicon" style="background:${q.color}24;color:${q.color}">${q.icon}</span>
        <span class="grow" style="text-align:left">
          <span style="display:block;font-size:15px;font-weight:800">${q.label}</span>
          <span class="sub" style="display:block;margin-top:3px;line-height:1.4">${q.desc}</span></span>
        <span style="font-size:19px;color:${sel ? 'var(--brand)' : 'var(--line)'}">${sel ? '◉' : '○'}</span></button>`;
    }).join('')}

    ${!p.key ? '' : `
    <p class="slabel" style="margin-top:20px">Bağlantı yöntemi</p>
    <div class="sgroup">
      ${swtile('🖥️','var(--grape)','Kendi sunucum üzerinden bağlan',
        'Anahtar cihazda tutulmaz. Yayına çıkarken önerilir.',s.useProxy,'useProxy')}
    </div>
    <div style="margin-top:16px">
    ${s.useProxy ? `
      <p style="font-size:13.5px;font-weight:700;margin:0 0 8px 6px">Sunucu adresi</p>
      <input class="inp" type="url" inputmode="url" placeholder="https://api.alanadiniz.com/v1"
        value="${esc(s.proxyUrl)}" oninput="setField('proxyUrl',this.value)">`
    : `
      <p style="font-size:13.5px;font-weight:700;margin:0 0 8px 6px">${p.label} API anahtarı</p>
      <div style="position:relative">
        <input class="inp" id="keyin" type="${S.showKey ? 'text' : 'password'}" autocomplete="off"
          autocapitalize="off" autocorrect="off" spellcheck="false" placeholder="${p.hint}"
          style="padding-right:52px" value="${esc(s.apiKey)}" oninput="setField('apiKey',this.value)">
        <button class="ibtn" style="position:absolute;right:5px;top:6px" onclick="toggleKey()">${S.showKey ? '🙈' : '👁️'}</button>
      </div>
      <div class="row" style="gap:6px;margin-top:10px">
        <span class="sub grow" style="font-size:12.5px">Anahtar: ${p.url}</span>
        <button class="ibtn" style="width:auto;padding:0 10px;font-size:13px;color:var(--brand);font-weight:700"
          onclick="copyText('${p.url}')">Kopyala</button></div>`}
    </div>
    <button class="btn" style="margin-top:16px" id="testbtn" onclick="testConn()">📡 Bağlantıyı test et</button>
    <div id="testout"></div>
    ${s.apiKey && !s.useProxy ? `<button class="btn danger" style="margin-top:10px" onclick="clearKey()">
      🗑️ Kayıtlı anahtarı sil</button>` : ''}`}
  </div>`;
};

SCREENS.speechset = () => {
  const s = S.settings;
  return `<div class="appbar"><button class="ibtn" onclick="back()">←</button>
    <h2>Ses ve Seans</h2></div>
  <div style="padding:0 16px 20px">
    <p class="slabel">Buddy sesi</p>
    <div class="card">
      ${slider('Konuşma hızı',rateLabel(s.rate),s.rate,.25,.75,.05,'rate')}
      <div style="height:1px;background:var(--line);margin:10px 0"></div>
      ${slider('Ses tonu',pitchLabel(s.pitch),s.pitch,.8,1.6,.1,'pitch')}
      <button class="btn ghost" style="margin-top:14px" onclick="previewVoice()">▶ Sesi dinle</button>
    </div>

    <p class="slabel" style="margin-top:22px">Ders</p>
    <div class="card">
      ${slider('Seans süre sınırı',s.limit+' dakika',s.limit,3,20,1,'limit')}
      <div style="height:1px;background:var(--line);margin:10px 0"></div>
      ${slider('Sessizlik toleransı',s.silence+' saniye',s.silence,3,12,1,'silence')}
      <p class="sub" style="font-size:12px;line-height:1.4;margin-top:8px">
        Çocuk bu süre boyunca sessiz kalırsa Buddy sorusunu yeniden sorar.</p></div>

    <p class="slabel" style="margin-top:22px">Mikrofon</p>
    <div class="sgroup">
      ${stile('🎙️','var(--ink-soft)','Konuşma tanıma',
        Speech.supportsRecognition()
          ? (Speech.state.micGranted === true ? 'Hazır ve izinli'
            : Speech.state.micGranted === false ? 'İzin verilmedi' : 'Test etmek için dokun')
          : 'Bu tarayıcı desteklemiyor','checkMic()')}
    </div>
    <p class="sub" style="font-size:12px;line-height:1.5;margin-top:10px;padding:0 6px">
      Uygulamada konuşma tanıma cihaz üzerinde çalışır; ses kaydı sunucuya gönderilmez.
      Bu tarayıcı demosunda Web Speech API kullanılır.</p>
  </div>`;
};

/* --- Ayar bileşenleri ------------------------------------------------------ */
function stile(icon, color, title, sub, action, dot, titleColor) {
  return `<button class="stile" ${action ? `onclick="${action}"` : 'style="cursor:default"'}>
    <span class="sicon" style="background:${color}1F;color:${color}">${icon}</span>
    <span class="grow" style="text-align:left">
      <span class="stitle" ${titleColor ? `style="color:${titleColor}"` : ''}>${title}</span>
      ${sub ? `<span class="ssub">${sub}</span>` : ''}</span>
    ${dot ? '<span style="width:9px;height:9px;border-radius:50%;background:var(--danger);flex-shrink:0"></span>' : ''}
    ${action ? '<span style="color:var(--ink-soft)">›</span>' : ''}</button>`;
}

function swtile(icon, color, title, sub, val, field) {
  return `<div class="stile" style="cursor:default">
    <span class="sicon" style="background:${color}1F;color:${color}">${icon}</span>
    <span class="grow" style="text-align:left">
      <span class="stitle">${title}</span><span class="ssub">${sub}</span></span>
    <button class="sw ${val ? 'on' : ''}" onclick="toggleField('${field}')"></button></div>`;
}

function slider(label, valueLabel, value, min, max, step, field) {
  return `<div>
    <div class="row between">
      <span style="font-size:14px;font-weight:700">${label}</span>
      <span style="font-size:13px;font-weight:800;color:var(--brand)">${valueLabel}</span></div>
    <input class="rng" type="range" min="${min}" max="${max}" step="${step}" value="${value}"
      oninput="setNum('${field}',this.value)"></div>`;
}
