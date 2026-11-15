/* ===========================================================================
   Talk Buddy — Tarayıcı ses katmanı
   Seslendirme: Web Speech Synthesis (her yerde çalışır)
   Tanıma     : Web Speech Recognition (Chrome/Edge; yoksa yazılı yedek)
   =========================================================================== */
'use strict';

const Speech = (() => {
  const SR = window.SpeechRecognition || window.webkitSpeechRecognition || null;

  const state = {
    rate: 0.44,
    pitch: 1.18,
    level: 0,
    listening: false,
    voice: null,
    micGranted: null,
    onLevel: null,
  };

  let recognition = null;
  let audioCtx = null;
  let analyser = null;
  let micStream = null;
  let levelRaf = null;

  const supportsRecognition = () => SR !== null;
  const supportsSynthesis = () => 'speechSynthesis' in window;

  function pickTurkishVoice() {
    if (!supportsSynthesis()) return null;
    const voices = speechSynthesis.getVoices();
    if (!voices.length) return null;
    return voices.find(v => v.lang === 'tr-TR')
        || voices.find(v => v.lang && v.lang.startsWith('tr'))
        || null;
  }

  if (supportsSynthesis()) {
    const load = () => { state.voice = pickTurkishVoice(); };
    load();
    speechSynthesis.addEventListener('voiceschanged', load);
  }

  function applySettings(s) {
    if (typeof s.rate === 'number') state.rate = s.rate;
    if (typeof s.pitch === 'number') state.pitch = s.pitch;
  }

  /* --- Seslendirme -------------------------------------------------------- */
  function speak(text) {
    return new Promise(resolve => {
      if (!text || !supportsSynthesis()) { resolve(); return; }
      try {
        speechSynthesis.cancel();
        const u = new SpeechSynthesisUtterance(text);
        u.lang = 'tr-TR';
        if (state.voice) u.voice = state.voice;
        // Web Speech hız aralığı 0.1–10; uygulamadaki 0.25–0.75 aralığını eşle.
        u.rate = Math.max(0.5, Math.min(2, state.rate * 2.1));
        u.pitch = Math.max(0, Math.min(2, state.pitch));
        u.volume = 1;
        let done = false;
        const finish = () => { if (!done) { done = true; resolve(); } };
        u.onend = finish;
        u.onerror = finish;
        // Emniyet supabı: bazı tarayıcılarda onend tetiklenmiyor.
        setTimeout(finish, Math.max(1800, text.length * 90));
        speechSynthesis.speak(u);
      } catch (e) { resolve(); }
    });
  }

  const silence = () => { try { speechSynthesis.cancel(); } catch (e) {} };

  /* --- Mikrofon seviyesi (dalga animasyonu) -------------------------------- */
  async function startLevelMeter() {
    if (analyser) return;
    try {
      micStream = await navigator.mediaDevices.getUserMedia({audio: true});
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const src = audioCtx.createMediaStreamSource(micStream);
      analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      src.connect(analyser);

      const data = new Uint8Array(analyser.frequencyBinCount);
      const tick = () => {
        if (!analyser) return;
        analyser.getByteTimeDomainData(data);
        let sum = 0;
        for (let i = 0; i < data.length; i++) {
          const v = (data[i] - 128) / 128;
          sum += v * v;
        }
        const rms = Math.sqrt(sum / data.length);
        state.level = Math.min(1, rms * 4);
        if (state.onLevel) state.onLevel(state.level);
        levelRaf = requestAnimationFrame(tick);
      };
      tick();
    } catch (e) {
      analyser = null;
    }
  }

  function stopLevelMeter() {
    if (levelRaf) cancelAnimationFrame(levelRaf);
    levelRaf = null;
    if (micStream) micStream.getTracks().forEach(t => t.stop());
    micStream = null;
    if (audioCtx) { try { audioCtx.close(); } catch (e) {} }
    audioCtx = null;
    analyser = null;
    state.level = 0;
    if (state.onLevel) state.onLevel(0);
  }

  /* --- İzin --------------------------------------------------------------- */
  async function requestMic() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      state.micGranted = false;
      return false;
    }
    try {
      const s = await navigator.mediaDevices.getUserMedia({audio: true});
      s.getTracks().forEach(t => t.stop());
      state.micGranted = true;
      return true;
    } catch (e) {
      state.micGranted = false;
      return false;
    }
  }

  /* --- Tanıma ------------------------------------------------------------- */
  function listen(onPartial, timeoutMs) {
    return new Promise(resolve => {
      if (!supportsRecognition()) {
        resolve({text: '', confidence: 0, unsupported: true});
        return;
      }

      let settled = false;
      let lastText = '';
      let lastConfidence = 0;

      const done = (payload) => {
        if (settled) return;
        settled = true;
        state.listening = false;
        stopLevelMeter();
        clearTimeout(guard);
        try { recognition && recognition.stop(); } catch (e) {}
        recognition = null;
        resolve(payload);
      };

      try {
        recognition = new SR();
      } catch (e) {
        resolve({text: '', confidence: 0, unsupported: true});
        return;
      }

      recognition.lang = 'tr-TR';
      recognition.interimResults = true;
      recognition.continuous = false;
      recognition.maxAlternatives = 3;

      recognition.onresult = (ev) => {
        let interim = '';
        for (let i = ev.resultIndex; i < ev.results.length; i++) {
          const res = ev.results[i];
          const alt = res[0];
          if (res.isFinal) {
            lastText = alt.transcript.trim();
            lastConfidence = alt.confidence || 0;
          } else {
            interim += alt.transcript;
          }
        }
        if (interim && onPartial) onPartial(interim.trim());
        if (lastText) {
          if (onPartial) onPartial(lastText);
          done({text: lastText, confidence: lastConfidence});
        }
      };

      recognition.onerror = (ev) => {
        const denied = ev.error === 'not-allowed' || ev.error === 'service-not-allowed';
        if (denied) state.micGranted = false;
        done({text: lastText, confidence: lastConfidence, denied});
      };

      recognition.onend = () => done({text: lastText, confidence: lastConfidence});

      const guard = setTimeout(
        () => done({text: lastText, confidence: lastConfidence, timedOut: true}),
        timeoutMs || 12000
      );

      state.listening = true;
      startLevelMeter();
      try {
        recognition.start();
      } catch (e) {
        done({text: '', confidence: 0});
      }
    });
  }

  function cancel() {
    try { recognition && recognition.abort(); } catch (e) {}
    recognition = null;
    state.listening = false;
    stopLevelMeter();
  }

  return {
    state, applySettings, speak, silence, listen, cancel, requestMic,
    supportsRecognition, supportsSynthesis,
    get level() { return state.level; },
    set onLevel(fn) { state.onLevel = fn; },
  };
})();
