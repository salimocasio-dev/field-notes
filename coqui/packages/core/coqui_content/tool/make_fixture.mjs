// Order 17: a small course for the tests that run on chrome as well as on the vm, made from a few real files.
//
//   cd coqui/packages/core/coqui_content && bash tool/make_fixtures.sh
//
// (this script alone: node tool/make_fixture.mjs, then dart format test/fixture). It writes, under test/fixture/:
//   small_tree.dart      `smallTree`: path -> file text, as Dart strings. The files the catalog reads, cut down:
//                          datos/curso.json    places 1, 2 and 4 of curso.js; places 1 and 2 keep the stories named
//                                              below (no pictures or routines); the four review sets named below
//                          datos/nivel.json    the first 3 items
//                          datos/llamadas.json, datos/fijos.json   as they are
//                          cuentos/            la-lluvia, el-bizcocho, donde-esta-el-pajaro (place 1), uno-dos-tres,
//                                              la-bola (place 2): the real files without `beats`, `final`, `also_heard`
//                          cuentos/cual-*.json four review sets cut to the items below, with the clips those items say
//                          libros/              la-lluvia and uno-dos-tres (el-bizcocho has no book in the tree)
//                          audio/ready.json    every clip of those files except every 7th (in sorted order), so some
//                                              lines have no recording; a clip fijos.json holds a line for (`lineas`)
//                                              always keeps its recording
//                          audio/marcas.json   the real marks of the clips in ready.json
//   small_expected.dart  `smallExpectedJson`: what the old code (old_code.mjs) answers over exactly this tree:
//                          pairs, words, played cases, lines for each word, titles, urls
// The output is the same on every run.

import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {historia, oldCurso, playedCases, runOld, wordList} from './old_code.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.resolve(here, '..', 'test', 'fixture');
const real = (p) => JSON.parse(fs.readFileSync(path.join(historia, p), 'utf8'));

// ---- the rule that picks the files ----
const PLACES = {casa: ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro'], parque: ['uno-dos-tres', 'la-bola'], colmado: []};
const CUAL_ITEMS = {
  'cual-frente': ['casa', 'puerta', 'abuela'],
  'cual-sala': ['bebé', 'tú'],
  'cual-campo': ['tu', 'bola'],
  'cual-banco': ['bebe', 'hombre'],
};
const BOOKS = ['la-lluvia', 'uno-dos-tres'];
const DROP_STORY_KEYS = ['beats', 'final', 'also_heard'];

const curso = oldCurso();
const files = {};
const put = (p, obj) => {
  files[p] = JSON.stringify(obj);
};

// curso
const lugares = curso.lugares
  .filter((l) => l.id in PLACES)
  .map((l) => {
    const o = {...l};
    delete o.dibujos;
    delete o.haz;
    if (PLACES[l.id].length) o.cuentos = [...PLACES[l.id]];
    else delete o.cuentos;
    return o;
  });
const storyIds = Object.values(PLACES).flat();
put('datos/curso.json', {
  lugares,
  cuentos: Object.fromEntries(storyIds.map((c) => [c, curso.cuentos[c]])),
  cual: Object.keys(CUAL_ITEMS),
});

// stories
const clipIds = new Set();
for (const c of storyIds) {
  const j = real(`cuentos/${c}.json`);
  for (const k of DROP_STORY_KEYS) delete j[k];
  put(`cuentos/${c}.json`, j);
  Object.keys(j.clips).forEach((id) => clipIds.add(id));
}

// review sets
for (const [f, words] of Object.entries(CUAL_ITEMS)) {
  const j = real(`cuentos/${f}.json`);
  j.items = words.map((w) => {
    const it = j.items.find((x) => x.w === w);
    if (!it) throw new Error(`${f} has no item ${w}`);
    return it;
  });
  const say = new Set(j.items.map((x) => x.say));
  j.clips = Object.fromEntries(Object.entries(j.clips).filter(([id]) => say.has(id)));
  put(`cuentos/${f}.json`, j);
  Object.keys(j.clips).forEach((id) => clipIds.add(id));
}

// the other data
put('datos/nivel.json', real('datos/nivel.json').slice(0, 3));
put('datos/llamadas.json', real('datos/llamadas.json'));
put('datos/fijos.json', real('datos/fijos.json'));
for (const b of BOOKS) put(`libros/${b}.json`, real(`libros/${b}.json`));

// audio: every 7th clip (sorted) has no recording, except the clips fijos.json writes a line for (`lineas`)
const keep = new Set(Object.keys(real('datos/fijos.json').lineas ?? {}));
keep.forEach((id) => clipIds.add(id));
const sorted = [...clipIds].sort();
const have = sorted.filter((id, i) => i % 7 !== 6 || keep.has(id));
const realReady = real('audio/ready.json');
const realMarks = real('audio/marcas.json');
put('audio/ready.json', {voces: realReady.voces, rate: realReady.rate, v: realReady.v, clips: have});
put('audio/marcas.json', Object.fromEntries(have.map((id) => [id, realMarks[id]])));

// ---- what the old code answers over this tree ----
const smallCurso = JSON.parse(files['datos/curso.json']);
const old = await runOld(files, smallCurso);
const played = playedCases(smallCurso);
const words = wordList(old, files, smallCurso);
const lines = {};
for (const w of words) lines[w] = {all: old.oidoEn(w, played.all), place1: old.oidoEn(w, played.place1)};
const urls = {};
for (const id of [have[0], have[have.length - 1]]) urls[id] = old.clipUrl(id);
const pares = old.pares();
const expected = {
  words: pares.words,
  pairs: old.CU.items,
  played,
  wordList: words,
  lines,
  titles: Object.fromEntries(Object.entries(smallCurso.cuentos).map(([c, m]) => [c, m.t])),
  urls,
  withoutRecording: sorted.filter((id, i) => i % 7 === 6 && !keep.has(id)),
};

// ---- Dart ----
const dartString = (s) =>
  "'" +
  [...s]
    .map((ch) => {
      const c = ch.codePointAt(0);
      if (ch === '\\') return '\\\\';
      if (ch === "'") return "\\'";
      if (ch === '$') return '\\$';
      if (c < 0x20 || c === 0x7f || c === 0x2028 || c === 0x2029) return `\\u{${c.toString(16)}}`;
      return ch;
    })
    .join('') +
  "'";
const header = '// Made by tool/make_fixture.mjs from real files under historia/. Do not edit.\n\n';
fs.writeFileSync(
  path.join(outDir, 'small_tree.dart'),
  `${header}/// The small course: path under historia/ -> file text.\nconst smallTree = <String, String>{\n${Object.entries(files)
    .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
    .map(([p, t]) => `${dartString(p)}: ${dartString(t)},`)
    .join('\n')}\n};\n`,
);
fs.writeFileSync(
  path.join(outDir, 'small_expected.dart'),
  `${header}/// What the old code (pares, oidoEn, cualCarga) gives over [smallTree], as JSON.\nconst smallExpectedJson = ${dartString(JSON.stringify(expected))};\n`,
);
console.log(`small tree: ${Object.keys(files).length} files, ${clipIds.size} clips (${have.length} with a recording), ${old.CU.items.length} pairs, ${words.length} words`);
