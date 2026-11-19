// The 30 scripted sequences for ref/progress (order 05, scheduler).
// Each sequence is a script: it receives `T` (local wall-clock time -> epoch ms in the run's time zone)
// and `call(nowMs, fn, ...args)` which runs PAL[fn](...args) with the clock at nowMs and returns
// what PAL returned. A script may look at returns (vence) to decide its next calls; the recorded
// file lists the calls actually made, so a replay needs no logic.
//
// Story data below is frozen here on purpose (copied from historia/cuentos on Nov 19 2026), so the
// progress references do not change when a story file changes.

const LLUVIA = { id: "la-lluvia", focus_words: ["casa", "puerta", "ventana", "abuela", "hola", "toca", "abre"] };
const BIZCOCHO = { id: "el-bizcocho", focus_words: ["cierra", "sí", "no", "abre"], back_again: ["puerta", "ventana", "abuela", "hola", "casa"] };
const PAJARO = { id: "donde-esta-el-pajaro", focus_words: ["grande", "pequeña", "adiós"], back_again: ["casa", "puerta", "abuela", "sí", "cierra"] };
const JUGO = { id: "el-jugo", focus_words: ["silla", "se sienta", "vaso", "jugo", "agua", "toma"], back_again: ["abuela", "hola", "grande", "pequeña", "no"] };
const CALOR = { id: "que-calor", focus_words: ["quiero", "gracias", "¿cómo estás?", "bien"], back_again: ["agua", "jugo", "toma", "no"] };
const D = (w, asked, got, ok, ms) => (ms === undefined ? { word: w, asked, got, ok } : { word: w, asked, got, ok, ms });
const S = (base, lost) => Object.assign({}, base, { _lost: lost });

// a fixed, readable outcome rule for the 20-day run: from the word and the day
const outcome = (w, day) => {
  let h = 0;
  for (const ch of w) h += ch.codePointAt(0);
  const k = (h + day) % 7;
  return k === 0 ? "miss" : k === 1 ? "slow" : "fast";
};

export const SEQUENCES = [
  {
    id: "01-veinte-dias",
    title: "The 20-day run (page 08): stories on some evenings, every due word answered each morning, a miss brings the word back 10 minutes later, two days skipped",
    run(T, call) {
      const day = n => `2026-03-${String(1 + n).padStart(2, "0")}`; // day 1 = Mon Mar 2 2026 (crosses the US DST start on Mar 8)
      const stories = {
        1: [S(LLUVIA, 1), [D("casa", "casa", "casa", true, 0), D("puerta", "puerta", "ventana", false, 1800), D("ventana", "ventana", "ventana", true, 2400), D("abre", "abre", "abre", true, 900)]],
        3: [S(BIZCOCHO, 0), [D("sí", "si", "si", true, 700), D("no", "no", "si", false, 1500), D("puerta", "puerta", "puerta", true, 600), D("cierra", "cierra", "cierra", true, 1200)]],
        6: [S(PAJARO, 2), [D("grande", "grande", "pequena", false, 3000), D("pequeña", "pequena", "pequena", true, 800), D("casa", "casa", "casa", true, 500), D("adiós", "adios", "adios", true, 2100)]],
        10: [S(LLUVIA, 0), [D("casa", "casa", "casa", true, 400), D("puerta", "puerta", "puerta", true, 700), D("ventana", "ventana", "puerta", false, 900), D("abre", "abre", "abre", true, 1000)]],
        15: [S(JUGO, 1), [D("silla", "vaso_silla", "vaso_mesa", false, 1300), D("vaso", "vaso", "vaso", true, 600), D("grande", "vaso_grande", "vaso_grande", true, 500), D(null, "libre", "agua", true)]],
      };
      for (let n = 1; n <= 20; n++) {
        if (n === 8 || n === 12) continue; // he did not open the app: the streak breaks
        if (n > 1) {
          const due = call(T(`${day(n)} 08:30`), "vence", "ear");
          due.forEach((w, i) => {
            const o = outcome(w, n);
            call(T(`${day(n)} 08:31`) + i * 7000, "responde", w, "ear", o !== "miss", o === "slow" ? 2600 : 900, false);
          });
          const again = call(T(`${day(n)} 08:45`), "vence", "ear");
          again.forEach((w, i) => call(T(`${day(n)} 08:46`) + i * 7000, "responde", w, "ear", true, 2600, false));
          call(T(`${day(n)} 08:50`), "minutos", 3.25);
        }
        if (stories[n]) {
          call(T(`${day(n)} 18:00`), "cuento", ...stories[n]);
          call(T(`${day(n)} 18:05`), "minutos", 5.5);
        }
        call(T(`${day(n)} 21:00`), "racha");
      }
      for (const w of ["casa", "puerta", "ventana", "sí", "grande", "silla"]) call(T("2026-03-21 21:05"), "abiertaHabla", w);
      call(T("2026-03-21 21:06"), "vence", "ear", T("2026-04-30 12:00"));
    },
  },
  {
    id: "02-un-fallo",
    title: "One miss on a return: step down, gap divided by 3, back in 10 minutes",
    run(T, call) {
      call(T("2026-03-02 17:00"), "oida", "casa");
      call(T("2026-03-03 09:00"), "responde", "casa", "ear", true, 800, false);
      call(T("2026-03-03 09:01"), "responde", "casa", "ear", true, 800, false);
      call(T("2026-03-06 09:00"), "vence", "ear");
      call(T("2026-03-06 09:00"), "responde", "casa", "ear", false, 1200, false);
      call(T("2026-03-06 09:05"), "vence", "ear");
      call(T("2026-03-06 09:10"), "vence", "ear");
      call(T("2026-03-06 09:11"), "responde", "casa", "ear", true, 700, false);
    },
  },
  {
    id: "03-tres-fallos",
    title: "Three misses in a row on returns: parked a week, flagged, stage back to found, aciertos cleared",
    run(T, call) {
      call(T("2026-03-02 17:00"), "oida", "ventana");
      call(T("2026-03-03 09:00"), "responde", "ventana", "ear", true, 800, false);
      call(T("2026-03-03 09:10"), "responde", "ventana", "ear", false, 900, false);
      call(T("2026-03-03 09:20"), "responde", "ventana", "ear", false, 900, false);
      call(T("2026-03-03 09:30"), "responde", "ventana", "ear", false, 900, false);
      call(T("2026-03-03 09:40"), "vence", "ear");
      call(T("2026-03-09 09:00"), "vence", "ear");
      call(T("2026-03-10 09:31"), "vence", "ear");
      call(T("2026-03-10 09:32"), "responde", "ventana", "ear", true, 800, false);
    },
  },
  {
    id: "04-lento",
    title: "Right but slow keeps the gap: ms 2600 (slow), 2000 (not slow, the limit), 2001 (slow), null and absent (not slow)",
    run(T, call) {
      call(T("2026-03-02 17:00"), "oida", "puerta");
      call(T("2026-03-03 09:00"), "responde", "puerta", "ear", true, 900, false);
      call(T("2026-03-05 09:00"), "responde", "puerta", "ear", true, 2600, false);
      call(T("2026-03-07 09:00"), "responde", "puerta", "ear", true, 2000, false);
      call(T("2026-03-12 09:00"), "responde", "puerta", "ear", true, 2001, false);
      call(T("2026-03-20 09:00"), "responde", "puerta", "ear", true, null, false);
      call(T("2026-04-02 09:00"), "responde", "puerta", "ear", true);
    },
  },
  {
    id: "05-presume",
    title: "The level check: presume words (one already holding), stories (one already played), with and without a log; then the cold check the next morning",
    run(T, call) {
      call(T("2026-03-02 10:00"), "cuento", S(LLUVIA, 0), [D("casa", "casa", "casa", true, 500)]);
      call(T("2026-03-03 09:00"), "responde", "casa", "ear", true, 500, false);
      call(T("2026-03-03 11:00"), "presume", ["casa", "agua", "jugo", "gracias"], ["la-lluvia", "el-jugo", "que-calor"], [{ w: "agua", s: 1, ok: true }, { w: "jugo", s: 2, ok: false }]);
      call(T("2026-03-03 11:01"), "abiertaHabla", "agua");
      call(T("2026-03-04 04:30"), "vence", "ear");
      call(T("2026-03-04 04:31"), "responde", "agua", "ear", true, 800, false);
      call(T("2026-03-04 04:32"), "responde", "jugo", "ear", false, 800, false);
      call(T("2026-03-05 10:00"), "presume", ["tú"], null);
      call(T("2026-03-05 10:01"), "presume");
    },
  },
  {
    id: "06-cuento-dos-veces",
    title: "A story finished twice: the second play is the return for the words that were due, an intro for the others",
    run(T, call) {
      const log1 = [D("puerta", "puerta", "puerta", true, 800), D("ventana", "ventana", "puerta", false, 1400), D("abre", "abre", "abre", true, 600)];
      call(T("2026-03-02 17:00"), "cuento", S(LLUVIA, 1), log1);
      call(T("2026-03-02 17:30"), "cuento", S(LLUVIA, 0), log1);
      call(T("2026-03-03 18:00"), "cuento", S(LLUVIA, 2), [D("puerta", "puerta", "puerta", true, 2500), D("ventana", "ventana", "ventana", true, 700), D("toca", "toca", "casa", false, 900)]);
      call(T("2026-03-03 18:01"), "vence", "ear");
    },
  },
  {
    id: "07-a-las-3-59",
    title: "First meeting and an intro answer at 3:59 local: next morning is 4:00 of the next day, not one minute later",
    run(T, call) {
      call(T("2026-03-03 03:59"), "oida", "hola");
      call(T("2026-03-03 03:59") + 30000, "responde", "abuela", "ear", true, 900, true);
      call(T("2026-03-03 04:00"), "vence", "ear");
      call(T("2026-03-04 03:59"), "vence", "ear");
      call(T("2026-03-04 04:00"), "vence", "ear");
      call(T("2026-03-04 04:00"), "racha");
    },
  },
  {
    id: "08-a-las-4-01",
    title: "First meeting and an intro answer at 4:01 local: due 4:00 the next day; the same day key as 3:59 in UTC",
    run(T, call) {
      call(T("2026-03-03 04:01"), "oida", "hola");
      call(T("2026-03-03 04:01") + 30000, "responde", "abuela", "ear", false, 900, true);
      call(T("2026-03-04 03:59"), "vence", "ear");
      call(T("2026-03-04 04:00"), "vence", "ear");
      call(T("2026-03-04 04:01"), "responde", "hola", "ear", true, 1000, false);
    },
  },
  {
    id: "09-intro",
    title: "Answers while a word is introduced (intro=true): found on a right one, heard on a wrong one, the schedule set once and not moved",
    run(T, call) {
      call(T("2026-03-02 17:00"), "responde", "sí", "ear", false, 900, true);
      call(T("2026-03-02 17:01"), "responde", "sí", "ear", true, 900, true);
      call(T("2026-03-02 17:02"), "responde", "sí", "ear", true, 900, true);
      call(T("2026-03-03 09:00"), "responde", "sí", "ear", true, 900, false);
      call(T("2026-03-03 09:01"), "responde", "sí", "ear", false, 900, true);
      call(T("2026-03-03 09:02"), "responde", "no", "mouth", true, 500, true);
    },
  },
  {
    id: "10-bien",
    title: "Good: right on three returns spread over 14 days or more (and not before); a miss drops good back to holding",
    run(T, call) {
      call(T("2026-03-02 17:00"), "oida", "abuela");
      call(T("2026-03-03 09:00"), "responde", "abuela", "ear", true, 800, false);
      call(T("2026-03-06 09:00"), "responde", "abuela", "ear", true, 800, false);
      call(T("2026-03-16 08:59"), "responde", "abuela", "ear", true, 800, false);
      call(T("2026-03-17 09:00"), "responde", "abuela", "ear", true, 800, false);
      call(T("2026-03-30 09:00"), "responde", "abuela", "ear", false, 800, false);
      call(T("2026-03-30 09:00"), "abiertaHabla", "abuela");
    },
  },
  {
    id: "11-pasos",
    title: "Steps 1 to 4: two right in a row moves up (capped at 4), a miss moves down (never below 1)",
    run(T, call) {
      call(T("2026-03-02 17:00"), "oida", "toca");
      call(T("2026-03-03 09:00"), "responde", "toca", "ear", false, 800, false);
      call(T("2026-03-03 09:10"), "responde", "toca", "ear", false, 800, false);
      for (let i = 0; i < 9; i++) call(T("2026-03-04 09:00") + i * 864e5, "responde", "toca", "ear", true, 800, false);
      call(T("2026-03-14 09:00"), "responde", "toca", "ear", false, 800, false);
    },
  },
  {
    id: "12-boca-y-oido",
    title: "Mouth and ear are separate records; open for speaking by ear stage 3 or a mouth answer; unknown words",
    run(T, call) {
      call(T("2026-03-02 17:00"), "abiertaHabla", "gracias");
      call(T("2026-03-02 17:00"), "oida", "gracias");
      call(T("2026-03-02 17:01"), "abiertaHabla", "gracias");
      call(T("2026-03-02 17:02"), "responde", "gracias", "mouth", false, 0, false);
      call(T("2026-03-02 17:03"), "abiertaHabla", "gracias");
      call(T("2026-03-02 17:04"), "responde", "bien", "mouth", true, 300, false);
      call(T("2026-03-02 17:05"), "vence", "mouth", T("2026-03-02 17:20"));
      call(T("2026-03-03 09:00"), "responde", "gracias", "ear", true, 300, false);
      call(T("2026-03-03 09:01"), "abiertaHabla", "gracias");
      call(T("2026-03-03 09:02"), "vence", "ear");
      call(T("2026-03-03 09:03"), "vence", "mouth");
    },
  },
  {
    id: "13-vence-orden",
    title: "vence: most overdue first, parked words left out, stage 0 and no-due records left out, with and without an explicit time",
    run(T, call) {
      call(T("2026-03-02 10:00"), "oida", "uno");
      call(T("2026-03-02 11:00"), "oida", "dos");
      call(T("2026-03-02 12:00"), "responde", "tres", "mouth", false, 800, false);
      call(T("2026-03-03 09:00"), "responde", "dos", "ear", false, 800, false);
      call(T("2026-03-03 09:05"), "responde", "uno", "ear", false, 800, false);
      call(T("2026-03-03 09:06"), "vence", "ear");
      call(T("2026-03-03 09:20"), "vence", "ear");
      call(T("2026-03-03 09:21"), "vence", "ear", T("2026-03-03 09:14"));
      call(T("2026-03-03 09:22"), "vence", "ear", T("2026-03-03 09:16"));
      call(T("2026-03-03 09:23"), "vence", "ear", 0);
      call(T("2026-03-03 09:24"), "vence", "mouth");
    },
  },
  {
    id: "14-racha",
    title: "The streak: consecutive day keys (UTC dates of local times), broken by a missing day; minutos marks a day",
    run(T, call) {
      call(T("2026-03-02 12:00"), "racha");
      call(T("2026-03-02 12:00"), "minutos", 2);
      call(T("2026-03-03 12:00"), "minutos", 0.5);
      call(T("2026-03-03 12:01"), "racha");
      call(T("2026-03-04 12:00"), "racha");
      call(T("2026-03-05 12:00"), "minutos", 1);
      call(T("2026-03-05 12:01"), "racha");
      call(T("2026-03-06 12:00"), "minutos", 0);
      call(T("2026-03-06 12:01"), "racha");
      call(T("2026-03-08 12:00"), "racha");
    },
  },
  {
    id: "15-oido-minutos",
    title: "Escuchar: oido counts a piece heard to the end (twice, two pieces); minutos adds fractions; neither touches a word",
    run(T, call) {
      call(T("2026-03-02 12:00"), "oido", "d-toc-toc");
      call(T("2026-03-02 12:03"), "oido", "d-toc-toc");
      call(T("2026-03-02 12:06"), "oido", "h-frente");
      call(T("2026-03-02 12:07"), "minutos", 1.7333333333333334);
      call(T("2026-03-02 12:08"), "minutos", 0.1);
      call(T("2026-03-02 12:09"), "minutos", 0.2);
    },
  },
  {
    id: "16-norm",
    title: "norm: accents, ñ, case, punctuation, numbers, null and undefined, non-strings",
    run(T, call) {
      const t = T("2026-03-02 12:00");
      for (const s of ["¡Hola, abuela!", "Sí", "  ¿Cómo   estás?  ", "PEQUEÑA", "adiós", "pingüino", "", null, undefined, 42, "1, 2, 3", "Él-y-ella", "café́", "ÁÉÍÓÚ áéíóú ü", "😀 sol", "a\tb\nc", "NÃO ção", true, ["a", "b"]]) call(t, "norm", s);
    },
  },
  {
    id: "17-reset",
    title: "reset: everything back to the empty store and saved; then a word again",
    run(T, call) {
      call(T("2026-03-02 12:00"), "oida", "casa");
      call(T("2026-03-02 12:01"), "minutos", 3);
      call(T("2026-03-02 12:02"), "oido", "d-la-bola");
      call(T("2026-03-02 12:03"), "reset");
      call(T("2026-03-02 12:04"), "db");
      call(T("2026-03-02 12:05"), "oida", "casa");
      call(T("2026-03-02 12:06"), "STAGES");
      call(T("2026-03-02 12:07"), "save");
    },
  },
  {
    id: "18-carga-guardada",
    title: "Loading a stored store: unknown keys kept, no cuentos, partial ajustes merged, records missing ear or mouth",
    setup: {
      stored: JSON.stringify({
        palabras: {
          casa: { w: "casa", primera: 1772400000000, oida: 2, ear: { etapa: 3, paso: 2, seguidas: 1, fallos: 0, gap: 2.5, due: 1772600000000, aciertos: [1772450000000], ultima: 1772450000000, aparcada: 0, marca: 0, n: 2, bien: 2 }, mouth: { etapa: 0, paso: 1, seguidas: 0, fallos: 0, gap: 0, due: 0, aciertos: [], ultima: 0, aparcada: 0, marca: 0, n: 0, bien: 0 } },
          solooreja: { w: "solooreja", primera: 1772400000000, oida: 1, ear: { etapa: 1, paso: 1, seguidas: 0, fallos: 0, gap: 1, due: 1772500000000, aciertos: [], ultima: 0, aparcada: 0, marca: 0, n: 0, bien: 0 } },
          soloboca: { w: "soloboca", primera: 1772400000000, oida: 0, mouth: { etapa: 0, paso: 1, seguidas: 0, fallos: 0, gap: 0, due: 0, aciertos: [], ultima: 0, aparcada: 0, marca: 0, n: 1, bien: 1 } },
        },
        dias: { "2026-03-01": 2 },
        ajustes: { min: 15, habla: 0 },
        minutos: 12.5,
        v: 1,
        extra: ["la playa"],
        leidos: { "la-lluvia": 1 },
        futuro: { x: 1 },
      }),
    },
    run(T, call) {
      call(T("2026-03-02 12:00"), "db");
      call(T("2026-03-02 12:01"), "abiertaHabla", "casa");
      call(T("2026-03-02 12:02"), "abiertaHabla", "solooreja");
      call(T("2026-03-02 12:03"), "abiertaHabla", "soloboca");
      call(T("2026-03-02 12:04"), "racha");
      call(T("2026-03-02 12:05"), "vence", "ear");
      call(T("2026-03-02 12:06"), "minutos", 1);
      call(T("2026-03-02 12:07"), "cuento", S(LLUVIA, 0), [D("casa", "casa", "casa", true, 400)]);
    },
  },
  {
    id: "19-carga-rota",
    title: "Loading a store that is not JSON: the empty store is used and the bad text is overwritten on the first save",
    setup: { stored: "{palabras: not json" },
    run(T, call) {
      call(T("2026-03-02 12:00"), "db");
      call(T("2026-03-02 12:01"), "oida", "agua");
    },
  },
  {
    id: "20-sin-almacen",
    title: "Storage that throws on every read and write (a private window): the store lives in memory, nothing is saved",
    setup: { storage: "throws" },
    run(T, call) {
      call(T("2026-03-02 12:00"), "oida", "agua");
      call(T("2026-03-02 12:01"), "responde", "agua", "ear", true, 500, true);
      call(T("2026-03-02 12:02"), "minutos", 1);
    },
  },
  {
    id: "21-sin-window",
    title: "No window object (the clock is Date.now, given the same scripted times); no localStorage at all",
    setup: { window: "none", storage: "absent" },
    run(T, call) {
      call(T("2026-03-02 12:00"), "oida", "agua");
      call(T("2026-03-03 09:00"), "vence", "ear");
      call(T("2026-03-03 09:01"), "responde", "agua", "ear", true, 500, false);
    },
  },
  {
    id: "22-reloj-cero",
    title: "window.__PAL_NOW = 0 is falsy: palabras.js falls back to Date.now (here given the scripted times)",
    setup: { window: "zero" },
    run(T, call) {
      call(T("2026-03-02 12:00"), "oida", "agua");
      call(T("2026-03-02 12:01"), "racha");
    },
  },
  {
    id: "23-cambio-de-hora-marzo",
    title: "Across the US clock change on Mar 8 2026: nextMorning adds 24 hours to 4:00, so in New York the word is due at 5:00",
    run(T, call) {
      call(T("2026-03-07 20:00"), "oida", "jugo");
      call(T("2026-03-08 04:30"), "vence", "ear");
      call(T("2026-03-08 05:00"), "vence", "ear");
      call(T("2026-03-08 05:01"), "responde", "jugo", "ear", true, 700, false);
      call(T("2026-03-08 22:00"), "minutos", 1);
      call(T("2026-03-09 22:00"), "minutos", 1);
      call(T("2026-03-09 22:01"), "racha");
    },
  },
  {
    id: "24-cambio-de-hora-noviembre",
    title: "Across the US clock change on Nov 1 2026: in New York the word is due at 3:00",
    run(T, call) {
      call(T("2026-10-31 20:00"), "oida", "vaso");
      call(T("2026-11-01 03:00"), "vence", "ear");
      call(T("2026-11-01 03:59"), "vence", "ear");
      call(T("2026-11-01 04:00"), "vence", "ear");
      call(T("2026-11-01 04:01"), "responde", "vaso", "ear", false, 700, false);
      call(T("2026-11-01 23:30"), "minutos", 1);
      call(T("2026-11-02 00:30"), "racha");
    },
  },
  {
    id: "25-cuento-casos",
    title: "cuento edge cases: a log entry with no word (elige), entries with no ms, a due word and a new word in one play, no back_again, no log, no focus words",
    run(T, call) {
      call(T("2026-03-02 17:00"), "oida", "agua");
      call(T("2026-03-03 18:00"), "cuento", S(CALOR, 1), [D(null, "libre", "agua", true), D("agua", "agua", "agua", true), D("quiero", "quiero", "no", false), D("agua", "agua", "jugo", false, 300)]);
      call(T("2026-03-03 18:10"), "cuento", { id: "d-agua-pajaro" }, null);
      call(T("2026-03-03 18:20"), "cuento", { id: "sin-palabras", _lost: 3 }, []);
      call(T("2026-03-03 18:30"), "cuento", { id: "el-jugo", focus_words: ["vaso"], back_again: ["agua"] });
    },
  },
  {
    id: "26-noche",
    title: "Late evening local time: in New York 23:30 is already the next UTC day, so the day key and the streak move",
    run(T, call) {
      call(T("2026-03-02 19:30"), "cuento", S(LLUVIA, 0), [D("casa", "casa", "casa", true, 600)]);
      call(T("2026-03-02 23:30"), "minutos", 2);
      call(T("2026-03-03 00:30"), "racha");
      call(T("2026-03-03 20:30"), "racha");
      call(T("2026-03-03 23:59"), "cuento", S(BIZCOCHO, 0), [D("casa", "casa", "casa", true, 600)]);
      call(T("2026-03-04 07:00"), "racha");
    },
  },
  {
    id: "27-rec-y-oida",
    title: "rec creates a record without saving; oida on it sets the first due; a second oida does not move it",
    run(T, call) {
      call(T("2026-03-02 12:00"), "rec", "mesa");
      call(T("2026-03-02 12:01"), "rec", "mesa");
      call(T("2026-03-02 12:02"), "oida", "mesa");
      call(T("2026-03-04 12:00"), "oida", "mesa");
      call(T("2026-03-04 12:01"), "save");
    },
  },
  {
    id: "28-palabra-nueva",
    title: "An answer on a word never met (the record is made by the answer): right fast from gap 0 gives 2.5 days; a miss from gap 0 gives 1",
    run(T, call) {
      call(T("2026-03-02 12:00"), "responde", "plato", "ear", true, 900, false);
      call(T("2026-03-02 12:01"), "responde", "taza", "ear", false, 900, false);
      call(T("2026-03-02 12:02"), "responde", "taza", "mouth", true, 2500, false);
      call(T("2026-03-02 12:03"), "vence", "ear", T("2026-03-05 12:00"));
    },
  },
  {
    id: "29-gap",
    title: "The gap: x2.5 per fast right, kept on a slow right, /3 on a miss (fractions kept), never under 1",
    run(T, call) {
      call(T("2026-03-02 12:00"), "oida", "pan");
      let t = T("2026-03-03 09:00");
      const plan = ["fast", "fast", "fast", "slow", "miss", "miss", "fast", "miss", "slow", "fast", "fast"];
      for (const o of plan) {
        const e = call(t, "responde", "pan", "ear", o !== "miss", o === "slow" ? 3000 : 500, false);
        t = e.due;
      }
    },
  },
  {
    id: "30-aparcada",
    title: "A parked word: left out of vence for a week, flagged; due again after; right answers afterwards keep the flag",
    run(T, call) {
      call(T("2026-03-02 12:00"), "oida", "leche");
      for (let i = 0; i < 3; i++) call(T("2026-03-03 09:00") + i * 6e5, "responde", "leche", "ear", false, 900, false);
      call(T("2026-03-04 09:00"), "vence", "ear");
      call(T("2026-03-10 09:19"), "vence", "ear");
      call(T("2026-03-10 09:20"), "vence", "ear");
      call(T("2026-03-10 09:21"), "responde", "leche", "ear", true, 800, false);
      call(T("2026-03-10 09:22"), "responde", "leche", "ear", false, 800, false);
      call(T("2026-03-10 09:23"), "vence", "ear", T("2026-03-10 09:40"));
    },
  },
  {
    id: "31-carga-nulos",
    title: "Added after measuring coverage: a stored store whose cuentos and ajustes are null (load puts {} and the default ajustes back)",
    setup: { stored: JSON.stringify({ palabras: {}, dias: {}, cuentos: null, ajustes: null, minutos: 0, v: 1 }) },
    run(T, call) {
      call(T("2026-03-02 12:00"), "db");
      call(T("2026-03-02 12:01"), "cuento", S(LLUVIA, 0), []);
    },
  },
];
