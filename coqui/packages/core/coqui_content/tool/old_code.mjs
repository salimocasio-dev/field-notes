// Order 17: the old code that reads the course, run in node. Used by make_expected.mjs and make_fixture.mjs.
//
// It takes the old functions out of the old files as text and runs them as the page runs them:
//   cual.js    cualCarga()            builds CU.items from the review sets (app.html line 496: CU=await cualCarga())
//   app.html   pares(), oidoEn()      the word -> pair index and "Heard in"
//   app.html   veces()                what "played" means (line 185)
//   palabras.js PAL.norm              the normaliser they call
//   curso.js   CURSO                  the course
// The globals those functions read are given the values the page has when it calls them: fetch reads a file of the
// tree it is given, cargaEscena does nothing (scenes are drawing code), STOV holds every story file of the course
// (cuentoJ, line 309), HAVE is the set of clips in audio/ready.json (audioListo, line 312).
//
// Nothing here edits a file under historia/.

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
export const historia = path.resolve(here, '..', '..', '..', '..', '..', 'historia');
const readOld = (p) => fs.readFileSync(path.join(historia, p), 'utf8');

/** The text of the function [name] in [src], from its `function` keyword to its closing brace. */
export function extractFunction(src, name) {
  const m = new RegExp(`(?:async\\s+)?function\\s+${name}\\s*\\(`).exec(src);
  if (!m) throw new Error(`function ${name} not found`);
  let i = src.indexOf('{', m.index);
  const start = m.index;
  let depth = 0;
  for (; i < src.length; i++) {
    const c = src[i];
    if (c === '"' || c === "'" || c === '`') {
      // a string: skip to its end (the functions taken here have no template placeholders)
      for (i++; src[i] !== c; i++) if (src[i] === '\\') i++;
    } else if (c === '/' && src[i + 1] === '/') {
      while (src[i] !== '\n') i++;
    } else if (c === '/' && src[i + 1] === '*') {
      i = src.indexOf('*/', i) + 1;
    } else if (c === '{') {
      depth++;
    } else if (c === '}') {
      depth--;
      if (depth === 0) return src.slice(start, i + 1);
    }
  }
  throw new Error(`function ${name} is not closed`);
}

/** The text of the one-line declaration that starts with [head] in [src], up to the `;` that ends the line. */
function extractLine(src, head) {
  const i = src.indexOf(head);
  if (i < 0) throw new Error(`"${head}" not found`);
  const end = src.indexOf('\n', i);
  const line = src.slice(i, end);
  if (!line.trimEnd().endsWith(';')) throw new Error(`"${head}": the line does not end with ;`);
  return line;
}

/** PAL.norm, from palabras.js run as the page runs it. */
function oldNorm() {
  const ctx = {localStorage: {getItem: () => null, setItem: () => {}}, window: {}};
  vm.createContext(ctx);
  return vm.runInContext(readOld('palabras.js') + '\n;PAL.norm', ctx);
}

/** CURSO, from curso.js. */
export function oldCurso() {
  const ctx = {};
  vm.createContext(ctx);
  return JSON.parse(JSON.stringify(vm.runInContext(readOld('curso.js') + '\n;CURSO', ctx)));
}

/**
 * The old code over a tree of files. [files] maps a path under historia/ (for example "cuentos/la-lluvia.json")
 * to its text; [curso] is CURSO.
 * Returns {CU, pares(), oidoEn(w, played)} where played is the list of story ids with veces(id) > 0.
 */
export async function runOld(files, curso) {
  const norm = oldNorm();
  const app = readOld('app.html');
  const cual = readOld('cual.js');
  const readJson = (p) => {
    if (!(p in files)) throw new Error(`the tree has no ${p}`);
    return JSON.parse(files[p]);
  };

  const PAL = {norm, db: {ajustes: {}, cuentos: {}}};
  const ctx = {
    CURSO: curso,
    PAL,
    fetch: async (url) => ({ok: true, json: async () => readJson(url)}),
    cargaEscena: async () => {},
    STOV: {},
    HAVE: null,
  };
  vm.createContext(ctx);
  const run = (code) => vm.runInContext(code, ctx);

  // cual.js, cualCarga: CU
  run(extractFunction(cual, 'cualCarga'));
  run('var CU;');
  await run('(async()=>{CU=await cualCarga();})()');

  // app.html: the played test, pares(), oidoEn()
  run(extractLine(app, 'const db=()=>PAL.db,'));
  run('let PW=null;');
  run(extractFunction(app, 'pares'));
  run(extractFunction(app, 'oidoEn'));

  // cuentoJ: every story file of the course that exists; audioListo: the clips that have a recording
  for (const c of Object.keys(curso.cuentos)) {
    const p = `cuentos/${c}.json`;
    if (p in files) ctx.STOV[c] = readJson(p);
  }
  if ('audio/ready.json' in files) {
    ctx.HAVE = new Set(readJson('audio/ready.json').clips || []);
  }

  return {
    CU: JSON.parse(JSON.stringify(ctx.CU)),
    pares() {
      const P = run('pares()');
      return {words: [...P.m.keys()], items: [...P.m.values()].map((it) => JSON.parse(JSON.stringify(it)))};
    },
    /** oidoEn(w) with exactly the stories in [played] played once. [[story, clip id, text], ...] */
    oidoEn(w, played) {
      PAL.db.cuentos = Object.fromEntries(played.map((c) => [c, {n: 1}]));
      ctx.__w = w;
      return run('oidoEn(__w)').map((x) => [x.c, x.id, x.cl.text]);
    },
    /** juego.js line 104: the url of a clip, exactly as the page writes it (j is ready.json) */
    clipUrl(id) {
      const j = readJson('audio/ready.json');
      const src = readOld('juego.js');
      const m = /fetch\((\"audio\/\"\+id\+\"\.mp3\?v=\"\+\(j\.v\|\|0\))\)/.exec(src);
      if (!m) throw new Error('the clip url expression of juego.js is not where it was');
      return vm.runInNewContext(m[1], {id, j});
    },
  };
}

/** Both cases of oidoEn the order names, for [words]: every course story played, and only the first place's. */
export function playedCases(curso) {
  const all = curso.lugares.flatMap((l) => l.cuentos || []);
  const place1 = [...(curso.lugares[0].cuentos || [])];
  return {all, place1};
}

/** The words the store can hold that oidoEn is asked about: the pair words, then every focus and back_again word. */
export function wordList(old, files, curso) {
  const out = [];
  const seen = new Set();
  const add = (w) => {
    if (!seen.has(w)) {
      seen.add(w);
      out.push(w);
    }
  };
  old.pares().words.forEach(add);
  for (const c of Object.keys(curso.cuentos)) {
    const p = `cuentos/${c}.json`;
    if (!(p in files)) continue;
    const j = JSON.parse(files[p]);
    for (const w of [...(j.focus_words || []), ...(j.back_again || [])]) add(w);
  }
  return out;
}

/** A tree of the real files the catalog reads: every file under the folders it reads, as text. */
export function realTree() {
  const files = {};
  for (const dir of ['datos', 'cuentos', 'libros']) {
    for (const f of fs.readdirSync(path.join(historia, dir)).sort()) {
      if (f.endsWith('.json')) files[`${dir}/${f}`] = readOld(`${dir}/${f}`);
    }
  }
  files['audio/ready.json'] = readOld('audio/ready.json');
  files['audio/marcas.json'] = readOld('audio/marcas.json');
  return files;
}
