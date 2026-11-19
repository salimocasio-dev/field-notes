// Order 02: expected values from the old code, for coqui_contracts and its tests.
//
//   cd coqui && TZ=UTC node tool/contracts/make_fixtures.mjs && dart format packages/core/coqui_contracts
//
// It reads the old files under historia/ (never edits them) and writes two Dart files:
//
//   packages/core/coqui_contracts/lib/src/normalize_table.dart
//       What PAL.norm does to each character, per code point: today's
//       toLowerCase().normalize("NFD") with the marks U+0300..U+036F removed and
//       every run that is not a-z0-9 turned into one space. Dart has no NFD, so the
//       port reads this table. Only the code points where the answer differs from
//       "a-z0-9 stays, anything else is a space" are listed.
//
//   packages/core/coqui_contracts/test/fixtures/old_code.dart
//       30 strings and what PAL.norm (historia/palabras.js, run here) gives for each;
//       ten Mulberry32 values for seed 1; a sample store made by running palabras.js;
//       CURSO (curso.js), NV (nivel.js), LLAMADAS (llamada.js), the items of
//       cuentos/cual-frente.json and the book libros/la-lluvia.json, as JSON text.
//
// Run it again whenever one of those old files changes. The output is the same on
// every run (fixed clock, TZ=UTC).

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const coqui = path.resolve(here, '..', '..');
const historia = path.resolve(coqui, '..', 'historia');
const read = (p) => fs.readFileSync(path.join(historia, p), 'utf8');

if (new Date(0).getTimezoneOffset() !== 0) {
  console.error('Run with TZ=UTC: the sample store holds day keys.');
  process.exit(1);
}

// ---------- palabras.js, run as the page runs it ----------
function loadPal(nowRef) {
  const store = {};
  const ctx = {
    localStorage: {
      getItem: (k) => (k in store ? store[k] : null),
      setItem: (k, v) => {
        store[k] = String(v);
      },
    },
    window: {
      get __PAL_NOW() {
        return nowRef.t;
      },
    },
  };
  vm.createContext(ctx);
  const PAL = vm.runInContext(read('palabras.js') + '\n;PAL', ctx);
  return {PAL, store};
}

// ---------- PAL.norm: 30 strings ----------
const {PAL: PALN} = loadPal({t: 0});
const normCases = [
  'Hola',
  '¿Cómo estás?',
  '¡Sí!',
  'Ñandú',
  'mañana',
  '  hola   abuela  ',
  '',
  null,
  'Él está aquí.',
  '¿Qué es esto?',
  'PUERTA',
  'pingüino',
  'Hasta mañana.',
  'adiós, adiós',
  'uno, dos, tres',
  '¡Arriba! ¡Abajo!',
  'señor/señora',
  'Abuela: ¿Quieres jugo?',
  'café con leche',
  'é ã',
  'niño-niña',
  '123 ABC',
  'tab\there\nnewline',
  'ÀÉÎÕÜ àéîõü',
  'Ça va?',
  'Straße',
  'İstanbul',
  '😀 coquí 😀',
  '...?!',
  'ﬁn ǅemal ½',
];
if (normCases.length !== 30) throw new Error('30 strings, not ' + normCases.length);
const normExpected = normCases.map((s) => [s, PALN.norm(s)]);

// ---------- the table for the Dart port of PAL.norm ----------
// The regex of PAL.norm, taken from the file itself.
const src = read('palabras.js');
const m = src.match(/const norm=s=>" "\+String\(s==null\?"":s\)\.toLowerCase\(\)\.normalize\("NFD"\)\.replace\((\/\[[^\]]+\]\/g),""\)\.replace\(\/\[\^a-z0-9\]\+\/g," "\)\.trim\(\)\+" ";/);
if (!m) throw new Error('PAL.norm in palabras.js is not the line this script knows');
const marks = vm.runInNewContext(m[1]);
const fold = (c) => String.fromCodePoint(c).toLowerCase().normalize('NFD').replace(marks, '');
const reduce = (s) => s.replace(/[^a-z0-9]+/g, ' ');
const plain = (c) => (c < 128 && /[a-z0-9]/.test(String.fromCharCode(c)) ? String.fromCharCode(c) : ' ');
const byValue = new Map();
for (let c = 0; c <= 0x10ffff; c++) {
  if (c >= 0xd800 && c <= 0xdfff) continue;
  const r = reduce(fold(c));
  if (r === plain(c)) continue;
  if (!byValue.has(r)) byValue.set(r, []);
  byValue.get(r).push(c);
}
// The table must give PAL.norm's answer for any string: check it on random strings here.
const tableNorm = (s) => {
  let out = '';
  for (const ch of String(s == null ? '' : s)) {
    const c = ch.codePointAt(0);
    let v = null;
    for (const [k, cs] of byValue) if (cs.includes(c)) v = k;
    out += v != null ? v : plain(c);
  }
  return ' ' + out.replace(/[^a-z0-9]+/g, ' ').trim() + ' ';
};
const pool = [...byValue.values()].flat().concat([32, 33, 46, 97, 98, 122, 48, 57, 0x20ac, 0x1f600, 0x4e2d, 0xac00]);
let seed = 7;
const rnd = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
for (let i = 0; i < 2000; i++) {
  let s = '';
  const n = 1 + Math.floor(rnd() * 8);
  for (let j = 0; j < n; j++) s += String.fromCodePoint(pool[Math.floor(rnd() * pool.length)]);
  if (tableNorm(s) !== PALN.norm(s)) throw new Error('the table differs from PAL.norm on ' + JSON.stringify(s));
}
for (const [s, e] of normExpected) if (tableNorm(s) !== e) throw new Error('the table differs on ' + JSON.stringify(s));

// ---------- Mulberry32, seed 1 (the standard generator) ----------
function mulberry32(a) {
  return function () {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const r1 = mulberry32(1);
const mulberry = Array.from({length: 10}, () => r1());

// ---------- a sample store, made by palabras.js ----------
// Fixed clock: 2026-11-10 15:00 UTC, moved on by hand between calls.
const clock = {t: Date.UTC(2026, 10, 10, 15, 0, 0)};
const {PAL, store} = loadPal(clock);
const DAY = 864e5;
const story1 = JSON.parse(read('cuentos/la-lluvia.json'));
PAL.oida('casa');
PAL.cuento(
  Object.assign({}, story1, {_lost: 1}),
  [
    {word: 'casa', asked: 'casa', got: 'casa', ok: true, ms: 900},
    {word: 'puerta', asked: 'puerta', got: 'ventana', ok: false, ms: 2400},
    {word: null, asked: 'libre', got: 'si', ok: true},
  ],
);
clock.t += DAY;
PAL.responde('casa', 'ear', true, 800, false);
PAL.responde('puerta', 'ear', true, 3100, false); // right but slow
PAL.responde('ventana', 'ear', false, 1500, false);
PAL.responde('hola', 'mouth', true, 0, false);
clock.t += 10 * 6e4;
PAL.responde('ventana', 'ear', false, 1200, false);
PAL.responde('ventana', 'ear', false, 1300, false); // the third miss: parked, flagged
PAL.oido('d-toc-toc');
PAL.oido('d-toc-toc');
PAL.minutos(3.25);
clock.t += 2 * DAY;
PAL.presume(['abre', 'cierra'], ['el-bizcocho'], [{i: 0, w: 'abuela', ok: true, ms: 1200}]);
PAL.db.leidos = {'la-lluvia': clock.t}; // app.html, marcaLeido
PAL.db.extra = ['the weather']; // app.html, extra
PAL.db.ajustes.bienvenida = 1;
PAL.save();
const sampleStore = store['coqui.palabras.v1'];

// A store whose `due` is not a whole number (palabras.js line 33: e.due=t+e.gap*DAY). Six rights a day apart
// stretch the gap to 2.5^6 days; five misses ten minutes apart cut it by 3 each time (the third parks the word),
// to 2.5^6/3^5; one more right gives 2.5^7/3^5 = 2.5117... days, and t + that many ms has a fraction.
const clock2 = {t: Date.UTC(2026, 10, 1, 15, 0, 0)};
const {PAL: PAL2, store: store2} = loadPal(clock2);
for (let i = 0; i < 6; i++) {
  PAL2.responde('sol', 'ear', true, 500, false);
  clock2.t += DAY;
}
for (let i = 0; i < 5; i++) {
  PAL2.responde('sol', 'ear', false, 500, false);
  clock2.t += 10 * 6e4;
}
PAL2.responde('sol', 'ear', true, 500, false);
const fractionalStore = store2['coqui.palabras.v1'];
if (Number.isInteger(JSON.parse(fractionalStore).palabras.sol.ear.due)) throw new Error('the due is whole: the sequence no longer makes a fraction');
// Each word record exactly as JSON.stringify writes it, from both stores.
const wordTexts = {};
for (const [name, text] of [['sample', sampleStore], ['fractional', fractionalStore]]) {
  for (const [w, r] of Object.entries(JSON.parse(text).palabras)) wordTexts[name + ':' + w] = JSON.stringify(r);
}

// ---------- data files and the old code's data ----------
const evalConst = (file, name) => {
  const text = read(file);
  const at = text.indexOf('const ' + name + '=');
  if (at < 0) throw new Error(name + ' is not in ' + file);
  let i = text.indexOf('=', at) + 1;
  const open = text[i];
  const close = open === '[' ? ']' : '}';
  let depth = 0;
  let j = i;
  for (; j < text.length; j++) {
    if (text[j] === open) depth++;
    else if (text[j] === close && --depth === 0) break;
  }
  return vm.runInNewContext('(' + text.slice(i, j + 1) + ')');
};
const curso = vm.runInNewContext(read('curso.js') + '\n;CURSO');
const nv = evalConst('nivel.js', 'NV');
const llamadas = evalConst('llamada.js', 'LLAMADAS');
const cualFrente = JSON.parse(read('cuentos/cual-frente.json'));
const libro = JSON.parse(read('libros/la-lluvia.json'));

// ---------- write ----------
const dartString = (s) => {
  if (s == null) return 'null';
  let out = "'";
  for (const ch of s) {
    const c = ch.codePointAt(0);
    if (ch === "'" || ch === '\\' || ch === '$') out += '\\' + ch;
    else if (c < 0x20 || c > 0x7e) out += '\\u{' + c.toString(16) + '}';
    else out += ch;
  }
  return out + "'";
};
const json = (v) => dartString(JSON.stringify(v));

const header = (what) =>
  `// Made by coqui/tool/contracts/make_fixtures.mjs from the old code. Do not edit by hand.\n` +
  `// Re-run: cd coqui && TZ=UTC node tool/contracts/make_fixtures.mjs && dart format packages/core/coqui_contracts\n` +
  `// ${what}\n`;

let table = header('What PAL.norm makes of each character (see normalize.dart).');
table += '\n/// For each result, the code points that give it. A code point not listed\n';
table += '/// stays itself when it is a-z or 0-9 and is a space otherwise.\n';
table += 'const Map<String, String> normalizeTable = {\n';
for (const [v, cs] of [...byValue.entries()].sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0))) {
  table += `  ${dartString(v)}: '${cs.map((c) => '\\u{' + c.toString(16) + '}').join('')}',\n`;
}
table += '};\n';
fs.writeFileSync(path.join(coqui, 'packages/core/coqui_contracts/lib/src/normalize_table.dart'), table);

let fx = header('Expected values for the coqui_contracts tests.');
fx += '\n/// [input, PAL.norm(input)] for 30 strings.\n';
fx += 'const List<List<String?>> normCases = [\n';
for (const [s, e] of normExpected) fx += `  [${dartString(s)}, ${dartString(e)}],\n`;
fx += '];\n';
fx += '\n/// The first ten values of mulberry32(1), from node.\n';
fx += `const List<double> mulberry32Seed1 = [\n${mulberry.map((v) => '  ' + v + ',').join('\n')}\n];\n`;
fx += "\n/// localStorage['coqui.palabras.v1'] after a scripted run of palabras.js.\n";
fx += `const String sampleStoreJson = ${dartString(sampleStore)};\n`;
fx += "\n/// localStorage['coqui.palabras.v1'] after six rights, five misses and a right on one word: its ear `due` has a fraction.\n";
fx += `const String fractionalStoreJson = ${dartString(fractionalStore)};\n`;
fx += '\n/// Every word record of both stores, as JSON.stringify writes it, by "store:word".\n';
fx += 'const Map<String, String> wordRecordTexts = {\n';
for (const [k, v] of Object.entries(wordTexts)) fx += `  ${dartString(k)}: ${dartString(v)},\n`;
fx += '};\n';
fx += '\n/// CURSO, from curso.js.\n';
fx += `const String cursoJson = ${json(curso)};\n`;
fx += '\n/// NV, from nivel.js.\n';
fx += `const String nvJson = ${json(nv)};\n`;
fx += '\n/// LLAMADAS, from llamada.js.\n';
fx += `const String llamadasJson = ${json(llamadas)};\n`;
fx += '\n/// historia/cuentos/cual-frente.json, as it is.\n';
fx += `const String cualFrenteJson = ${json(cualFrente)};\n`;
fx += '\n/// historia/libros/la-lluvia.json, as it is.\n';
fx += `const String bookLaLluviaJson = ${json(libro)};\n`;
fs.mkdirSync(path.join(coqui, 'packages/core/coqui_contracts/test/fixtures'), {recursive: true});
fs.writeFileSync(path.join(coqui, 'packages/core/coqui_contracts/test/fixtures/old_code.dart'), fx);

console.log(
  `normalize table: ${[...byValue.values()].flat().length} code points in ${byValue.size} results; ` +
    `${normExpected.length} norm cases; ${mulberry.length} mulberry32 values; sample store ${sampleStore.length} chars`,
);
