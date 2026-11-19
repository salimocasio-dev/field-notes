// Order 17: what the old code answers over the real files under historia/, for the vm tests of coqui_content.
//
//   cd coqui/packages/core/coqui_content && bash tool/make_fixtures.sh
//
// (this script alone: node tool/make_expected.mjs). It runs cual.js's cualCarga(), app.html's pares() and oidoEn()
// (see old_code.mjs) over the real tree and writes test/fixture/real_expected.json:
//   pairs     CU.items, in order, as the old code has them (each with its `esc`, the file's scene)
//   words     the keys of pares().m, in order (one per distinct item word)
//   played    the two cases: every story of every place played, and only the first place's
//   wordList  the words oidoEn is asked about: the pair words, then every focus and back_again word
//   lines     for each word and case, what oidoEn(word) returns: [story id, clip id, text]
//   titles    CURSO.cuentos[id].t for every story of the course
//   urls      the url juego.js builds for a few clips (every 100th of ready.json, and the last)
//   curso     curso.js's CURSO, to check that datos/curso.json is the same
// The output is the same on every run: no dates, no random numbers, sorted keys where a tree is read.

import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {oldCurso, playedCases, realTree, runOld, wordList} from './old_code.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const out = path.resolve(here, '..', 'test', 'fixture', 'real_expected.json');

const files = realTree();
const curso = oldCurso();
const old = await runOld(files, curso);
const played = playedCases(curso);
const words = wordList(old, files, curso);

const lines = {};
for (const w of words) {
  lines[w] = {all: old.oidoEn(w, played.all), place1: old.oidoEn(w, played.place1)};
}

const ready = JSON.parse(files['audio/ready.json']);
const urls = {};
ready.clips.forEach((id, i) => {
  if (i % 100 === 0 || i === ready.clips.length - 1) urls[id] = old.clipUrl(id);
});

const pares = old.pares();
const expected = {
  note: 'Made by tool/make_expected.mjs from the old code. Do not edit.',
  curso,
  words: pares.words,
  pairs: old.CU.items,
  played,
  wordList: words,
  lines,
  titles: Object.fromEntries(Object.entries(curso.cuentos).map(([c, m]) => [c, m.t])),
  urls,
};

// one entry per line, so a change shows as a short diff
const entries = Object.entries(expected).map(([k, v]) => {
  if (k === 'lines') {
    return `${JSON.stringify(k)}:{\n${Object.entries(v)
      .map(([w, c]) => `${JSON.stringify(w)}:${JSON.stringify(c)}`)
      .join(',\n')}\n}`;
  }
  if (k === 'pairs') {
    return `${JSON.stringify(k)}:[\n${v.map((x) => JSON.stringify(x)).join(',\n')}\n]`;
  }
  return `${JSON.stringify(k)}:${JSON.stringify(v)}`;
});
fs.writeFileSync(out, `{\n${entries.join(',\n')}\n}\n`);
console.log(`${path.relative(process.cwd(), out)}: ${words.length} words, ${old.CU.items.length} pairs, ${pares.words.length} in pares().m`);
