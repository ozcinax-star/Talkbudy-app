/* Talk Buddy demo testleri:  node demo/test.js  */
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.dirname(__dirname);

const els = {};
const mkEl = id => ({id, innerHTML:'', textContent:'', value:'', scrollTop:0, disabled:false,
  className:'', dataset:{}, style:{cssText:'', background:''},
  classList:{_s:new Set(), toggle(c,v){v?this._s.add(c):this._s.delete(c)},
    add(c){this._s.add(c)}, remove(c){this._s.delete(c)}, contains(c){return this._s.has(c)}},
  querySelectorAll:()=>[], querySelector:()=>null, addEventListener(){}, appendChild(){},
  focus(){}, setSelectionRange(){}, parentNode:null});
global.document = {getElementById:id=>els[id]||(els[id]=mkEl(id)), querySelectorAll:()=>[],
  addEventListener(){}, activeElement:null, body:{classList:{toggle(){}}, appendChild(){}}};
global.window = {innerWidth:1400, innerHeight:900, addEventListener(){}, maxTouchPoints:0};
Object.defineProperty(global, 'navigator', {
  value: {userAgent:'node', maxTouchPoints:0}, configurable: true, writable: true,
});
global.localStorage = {_d:{}, getItem(k){return this._d[k]||null},
  setItem(k,v){this._d[k]=v}, removeItem(k){delete this._d[k]}};
global.requestAnimationFrame = () => 0;
global.cancelAnimationFrame = () => {};

const html = fs.readFileSync(path.join(ROOT, 'talk_buddy_demo.html'), 'utf8');
const bundle = html.split('<script>')[1].split('</' + 'script>')[0];
// Betiği global bağlamda çalıştır: top-level const/class global sözcüksel
// kapsama girer ve modül kodundan erişilebilir olur.
vm.runInThisContext(bundle);

let fail = 0, pass = 0;
const t = (n, c) => { if (!c) { fail++; console.log('  ✗ ' + n); } else { pass++; console.log('  ✓ ' + n); } };
const head = s => console.log('\n' + s + '\n' + '-'.repeat(68));

(async () => {

head('FONOLOJİK EŞLEŞTİRİCİ');
const cases = [['tedi','kedi',40,'fronting'], ['ayaba','araba',48,'gliding'],
  ['alaba','araba',48,'liquidSubstitution'], ['tu','su',42,'stopping'],
  ['ten','tren',40,'clusterReduction'], ['kita','kitap',34,'finalDeletion'],
  ['kebek','kelebek',44,'syllableDeletion'], ['papa','baba',36,'devoicing']];
for (const [h, tg, age, exp] of cases) {
  const m = new PhonologyMatcher(age).matchWord(h, tg);
  t(`"${h}" → "${tg}" (${age}ay) = ${m.score.toFixed(2)} [${m.processes.join(',')}]`,
    m.score >= 0.7 && m.processes.includes(exp));
}
t('alakasız kelime eşleşmiyor', new PhonologyMatcher(48).matchWord('köpek','kedi').score < 0.45);
t('ek almış hâl köke iner', new PhonologyMatcher(48).matchWord('arabayı','araba').score > 0.8);

head('DEĞERLENDİRME — hatasız öğrenme');
const ex = {templateId:'x', type:'listenRepeat', domain:'articulation', prompt:'',
  targetWord:'kalem', accepted:['kalem'], targetPhonemes:['k'], options:[], correctOption:0};
const ev = new AnswerEvaluator(40, 1);
t('telaffuz hatası bölümü engellemiyor',
  ev.evaluate({...ex, targetWord:'kedi', accepted:['kedi']}, 'tedi', 0.55, 1).verdict === 'pass');
t('sessizlik tekrar istiyor', ev.evaluate(ex, '', 0, 1).verdict === 'retry');
const ladder = [1,2,3].map(a => ev.evaluate(ex, 'zzz', 0.1, a).scaffold.level);
t('ipucu merdiveni: ' + ladder.join(' → '),
  ladder[0]==='slowModel' && ladder[1]==='choices' && ladder[2]==='together');
t('2. denemede ilk hece ipucu', ev.evaluate(ex,'zzz',0.1,2).scaffold.hint.startsWith('kal'));
t('3. denemede ASLA başarısız olunmuyor', ev.evaluate(ex,'zzz',0.1,3).verdict !== 'retry');
t('3. denemede doğru model veriliyor', ev.evaluate(ex,'zzz',0.1,3).scaffold.hint === 'kalem');
const open = {templateId:'a', type:'answerQuestion', domain:'pragmatics', prompt:'',
  targetWord:null, accepted:[], targetPhonemes:[], options:[]};
t('açık uçlu uzun cevap geçiyor',
  ev.evaluate(open, 'bugün parka gittim çok eğlendim', 0.9, 1).verdict === 'pass');
const em = {...open, type:'emotionMatch', accepted:['üzgün','üzüldü','kötü']};
t('duygu eş anlamlısı kabul ediliyor', ev.evaluate(em, 'çok üzüldü', 0.85, 1).verdict === 'pass');
const cp = {...ex, type:'choosePicture', options:['🐱','🐶'], correctOption:0};
t('çoktan seçmeli doğru', ev.evaluateChoice(cp, 0, 1).verdict === 'pass');
t('çoktan seçmeli 2. hatada ilerliyor', ev.evaluateChoice(cp, 1, 2).verdict === 'partial');

head('DİYALOG MOTORU');
const ctx = (seed, m) => ({childName:'Elif', ageMonths:52, seed, mastery:m||{},
  recentPrompts:new Set(), recentWords:new Set()});
let allOk = true, totalEx = 0;
for (const l of ALL_LESSONS) {
  const exs = new DialogueEngine(ctx(3)).buildLesson(l);
  totalEx += exs.length;
  if (exs.length !== l.exerciseCount) { allOk = false; console.log('    ' + l.id + ' sayı hatalı'); }
  for (const e of exs) {
    if (!e.prompt || e.prompt.includes('{')) { allOk = false; console.log('    ' + l.id + ' yuva: ' + e.prompt); }
    if (!needsVoice(e.type) && (e.options.length < 2 || e.correctOption >= e.options.length)) {
      allOk = false; console.log('    ' + l.id + '/' + e.templateId + ' seçenek hatalı');
    }
  }
}
t(`33 dersin tamamı geçerli (${totalEx} alıştırma)`, allOk);
const a = new DialogueEngine(ctx(1)).buildLesson(lessonById('u3l1'));
const b = new DialogueEngine(ctx(999)).buildLesson(lessonById('u3l1'));
t('farklı seed farklı içerik', a.filter((x,i) => x.prompt === b[i].prompt).length < a.length);
const w = new DialogueEngine(ctx(42)).buildLesson(lessonById('u1l1')).map(e => e.targetWord).filter(Boolean);
t('aynı derste kelime tekrarı yok', new Set(w).size === w.length);
t('kombinasyon havuzu = 1899', DialogueEngine.combinationCount() === 1899);
t('11 ünite / 33 ders', UNITS.length === 11 && ALL_LESSONS.length === 33);

head('İLERLEME VE USTALIK');
localStorage._d = {};
let p = emptyProgress();
t('ilk ünite açık', isUnitUnlocked(p, UNITS[0]));
t('ikinci ünite kilitli', !isUnitUnlocked(p, UNITS[1]));
const mk = v => ({lessonId:'u1l1', unitId:'u1', duration:200, results:Array.from({length:5}, () => ({
  exercise:{templateId:'x', type:'listenRepeat', targetPhonemes:['p'], targetWord:'baba', accepted:['baba']},
  heardText:'baba', intelligibility:.9, targetMatch:1, semanticMatch:1,
  verdict:v, attempts:1, processes:v === 'pass' ? ['fronting'] : []}))});
p = ProgressStore.applyResult(p, mk('pass'));
t('ustalık TEK derste kazanılmıyor', !isMastered(p.mastery.p));
p = ProgressStore.applyResult(p, mk('pass'));
p = ProgressStore.applyResult(p, mk('pass'));
t(`ustalık ÜÇ derste kazanılıyor (${p.mastery.p.score.toFixed(2)}, kutu ${p.mastery.p.box})`,
  isMastered(p.mastery.p));
t(`fonolojik süreç kalıcı (${p.processes.fronting.count} kez, ${p.processes.fronting.lessons} derste)`,
  p.processes.fronting && p.processes.fronting.count === 15);
t('sonraki ders açıldı', isLessonUnlocked(p, UNITS[0], UNITS[0].lessons[1]));
ProgressStore.save('t1', p);
t('localStorage kalıcılığı', ProgressStore.load('t1').totalStars === p.totalStars);

head('TAM DERS AKIŞI');
localStorage._d = {}; S.activeChildId = 'c2';
const s = new LessonSession('u3l1'); S.lesson = s;
for (let i = 0; i < s.total; i++) {
  const e = s.current; if (!e) break;
  if (!needsVoice(e.type)) await s.submitChoice(e.correctOption);
  else await s.submitSpeech(TurkishPhonology.applyProcess(e.targetWord || 'evet', 'fronting'), 0.52);
}
const r = S.lessonResult;
t(`ders tamamlandı (${r.results.length}/${s.total} alıştırma)`, r.results.length === s.total);
t(`telaffuz hatalarına rağmen geçti (%${Math.round(successRate(r)*100)})`, successRate(r) >= 0.6);
t('sonuç ekranına geçildi', S.screen === 'lessonDone');
const p2 = ProgressStore.load('c2');
t('ilerleme kaydedildi', isLessonComplete(p2, 'u1l1') || isLessonComplete(p2, 'u3l1'));
t('süreç uzmana raporlandı', Object.keys(p2.processes).length > 0);
const alerts = buildAlerts().filter(x => x.childId === 'c2');
t(`uzman paneline uyarı düştü (${alerts.length})`, alerts.length > 0);

head('EKRAN RENDER');
S.lesson = null;
let renderOk = true;
for (const n of Object.keys(SCREENS)) {
  try {
    if (n === 'lesson') S.lesson = new LessonSession('u1l1');
    const o = SCREENS[n]();
    if (/undefined|NaN|\[object [A-Z]/.test(o)) throw new Error('şüpheli çıktı');
    if (o.length < 200) throw new Error('çok kısa');
  } catch (e) { renderOk = false; console.log('    ✗ ' + n + ': ' + e.message); }
}
S.lesson = null;
t(`${Object.keys(SCREENS).length} ekran hatasız render ediliyor`, renderOk);

head('NAVİGASYON BÜTÜNLÜĞÜ');
const screens = Object.keys(SCREENS);
const goT = [...new Set([...bundle.matchAll(/go\('(\w+)'/g)].map(m => m[1]))];
t(`go() hedefleri geçerli (${goT.length})`, goT.every(x => screens.includes(x)));
t('kabuk sekmeleri geçerli',
  [...new Set(Object.values(SHELLS).flatMap(x => x.screens))].every(x => screens.includes(x)));
t('menü hedefleri geçerli', MENU.flatMap(g => g[1].map(i => i[0])).every(x => screens.includes(x)));
t('açıklama kapsamı tam', Object.keys(CAPTIONS).length >= screens.length);

console.log('\n' + '='.repeat(68));
console.log(fail ? `>>> ${fail} HATA, ${pass} geçti` : `>>> ${pass} testin tamamı geçti`);
console.log('='.repeat(68));
process.exit(fail ? 1 : 0);
})();
