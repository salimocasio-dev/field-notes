#!/usr/bin/env node
// Order 04: the old site's course data, written as JSON for the Flutter app.
//
//   node coqui/tool/export_datos.mjs            (from anywhere; no dependencies)
//
// Writes, in historia/datos/ (2-space indent, key order as in the old source, one final newline,
// so a second run is byte-identical):
//   curso.json     CURSO     (historia/curso.js)
//   nivel.json     NV        (historia/nivel.js)
//   llamadas.json  LLAMADAS  (historia/llamada.js; it lives inside the Llamada closure, see below)
//   fijos.json     { clips: { <role>: <clip id> }, despedidas: [goodbye words] }
//
// The data is never copied by hand. curso.js, nivel.js and llamada.js are evaluated as they are in a vm
// context with the few browser globals they touch stubbed. Every file is then checked: the JSON that was
// written, read back, must equal the old object (plain data only, same keys in the same order).
//
// ---- How the fixed clip ids are found ---------------------------------------------------------------
// In juego.js, cual.js and llamada.js, with comments blanked out (so a word in a comment never counts):
//   1. CALL.   For each call of say( playClip( bien( habLinea( turnoLinea( take the FIRST ARGUMENT
//              (the text up to the top-level comma or the closing parenthesis) and collect every string
//              literal in it. That finds say("ahora_tu",200), playClip("ahora_tu"), bien("si_muy_bien") and
//              the default in say(id||S.bien||"muy_bien",350). An id that comes from a story file reaches
//              these calls as a variable (say(line), say(said[t]), say(it.say)): no literal, so it is not found.
//   2. LIST.   have.has("<id>"): a membership test on ready.json's list of clips (juego.js, loadVoice).
//   3. LINES.  LINES.<id> or LINES["<id>"]: the code looks up a clip's line by its name.
// Each id found is checked against historia/audio/ready.json; one that is not there stops the script.
// The ROLES table below gives each (file, id) its role; a found pair without a role, or a role whose
// pair was not found, also stops the script, so nothing is added or lost without a decision.
// As a second net, every other string literal in those three files that is equal to a clip id of
// ready.json is listed in NOT_CLIPS with the reason it is not a clip; an unexplained one stops the script.
// A name built at run time ("hz_no_"+thing) is printed as a dynamic family and not exported.
//
// The goodbye words: the string literals in the second argument of dice(n,"...") inside llamada.js's
// `adios` function (the learner's or Danny's goodbye, either one ends the call).
//
// LLAMADAS is a const inside the Llamada closure, so no script can reach it. Its text, from `const LLAMADAS=`
// to the matching `}`, is cut out of llamada.js by a bracket scanner and evaluated; the whole file is also
// evaluated, and Llamada.tiene / Llamada.minutos must agree with the cut-out object.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const HIS = path.join(ROOT, 'historia');
const OUT = path.join(HIS, 'datos');
const read = (p) => fs.readFileSync(p, 'utf8');
const fail = (msg) => { console.error('export_datos: ' + msg); process.exit(1); };

// ---- roles ---------------------------------------------------------------------------------------------
// [file, clip id, role]. The role is what the code uses the clip for, prefixed by its file.
const ROLES = [
  ['juego.js', 'ahora_tu',    'story_your_turn'],           // "Ahora tú.": said before and between his speaking attempts
  ['juego.js', 'muy_bien',    'story_praise'],              // the default of bien(): after a right move when the story names no S.bien
  ['cual.js',  'si_muy_bien', 'review_praise_right'],       // "¡Sí! ¡Muy bien!" after a right touch
  ['cual.js',  'muy_bien',    'review_praise_after_miss'],  // "¡Muy bien!" after he touches the shown answer to a miss
];
// literals equal to a clip id that are not clips
const NOT_CLIPS = [
  ['juego.js', 'puerta',  'the name of a thing on the stage (pn.loose: before the door has a name, the door is the house)'],
  ['juego.js', 'ventana', 'the name of a thing on the stage (same line)'],
  ['juego.js', 'casa',    'the name of a thing on the stage (same line)'],
  ['juego.js', 'abuela',  'the grandmother as a person on the stage (W.ab, E.box("abuela")), not her clip'],
  ['llamada.js', 'casa',  'the place id of the call and the picture it shows (LLAMADAS.casa.foto)'],
];
const FILES = ['juego.js', 'cual.js', 'llamada.js'];
const SAY_FUNCTIONS = ['say', 'playClip', 'bien', 'habLinea', 'turnoLinea'];

// ---- a small JavaScript scanner (strings, comments, regex literals) --------------------------------------
// Returns the source with every comment replaced by spaces (newlines kept, so offsets and line numbers stay).
function blankComments(src, name) {
  let out = '';
  let i = 0;
  let prev = '';   // the last significant character: decides whether a "/" starts a regex
  const n = src.length;
  const regexAllowed = () => prev === '' || '(,=:[!&|?{};+-*%<>~^'.includes(prev);
  while (i < n) {
    const c = src[i], d = src[i + 1];
    if (c === '/' && d === '/') {
      while (i < n && src[i] !== '\n') { out += ' '; i++; }
    } else if (c === '/' && d === '*') {
      const e = src.indexOf('*/', i + 2);
      if (e < 0) fail(`${name}: a comment is not closed`);
      for (; i < e + 2; i++) out += src[i] === '\n' ? '\n' : ' ';
    } else if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < n && src[j] !== c) { if (src[j] === '\\') j++; if (src[j] === '\n') fail(`${name}: a string breaks a line`); j++; }
      out += src.slice(i, j + 1); i = j + 1; prev = c;
    } else if (c === '`') {
      let j = i + 1, depth = 0;
      for (; j < n; j++) {
        if (src[j] === '\\') { j++; continue; }
        if (depth === 0 && src[j] === '`') break;
        if (src[j] === '$' && src[j + 1] === '{') { depth++; j++; } else if (depth > 0 && src[j] === '}') depth--;
      }
      out += src.slice(i, j + 1); i = j + 1; prev = c;
    } else if (c === '/' && regexAllowed()) {
      let j = i + 1, cls = false;
      while (j < n && (cls || src[j] !== '/')) { if (src[j] === '\\') j++; else if (src[j] === '[') cls = true; else if (src[j] === ']') cls = false; else if (src[j] === '\n') fail(`${name}: a regex breaks a line`); j++; }
      j++; while (/[a-z]/i.test(src[j] || '')) j++;
      out += src.slice(i, j); i = j; prev = ')';
    } else {
      out += c; if (!/\s/.test(c)) prev = c; i++;
    }
  }
  return out;
}

// The text of a balanced region starting at src[open] (one of ( [ {), up to and excluding the matching closer,
// or, with stopAtComma, up to the first top-level comma. Strings are skipped.
function balanced(src, open, stopAtComma = false) {
  const pairs = { '(': ')', '[': ']', '{': '}' };
  let depth = 0;
  for (let i = open; i < src.length; i++) {
    const c = src[i];
    if (c === '"' || c === "'" || c === '`') { i++; while (i < src.length && src[i] !== c) { if (src[i] === '\\') i++; i++; } continue; }
    if (pairs[c]) { depth++; continue; }
    if (')]}'.includes(c)) { depth--; if (depth === 0) return src.slice(open + 1, i); continue; }
    if (stopAtComma && c === ',' && depth === 1) return src.slice(open + 1, i);
  }
  fail('an opening bracket is never closed');
}

const lineOf = (src, at) => src.slice(0, at).split('\n').length;
const literalsIn = (text) => [...text.matchAll(/"([^"\\\n]*)"|'([^'\\\n]*)'/g)].map((m) => m[1] ?? m[2]);

// ---- the old code, evaluated ------------------------------------------------------------------------------
function sandbox() {
  const none = () => {};
  const el = () => ({ appendChild: none, setAttribute: none, style: {}, classList: { add: none, remove: none, toggle: none }, addEventListener: none, querySelector: () => null, querySelectorAll: () => [] });
  const sb = {
    console, URLSearchParams, Math, JSON, Date,
    location: { search: '', href: 'http://localhost/', pathname: '/', origin: 'http://localhost' },
    document: { getElementById: () => null, querySelector: () => null, querySelectorAll: () => [], createElement: el, head: el(), body: el(), documentElement: { clientWidth: 0 } },
    navigator: {}, performance: { now: () => 0 }, localStorage: { getItem: () => null, setItem: none }, sessionStorage: { getItem: () => null, setItem: none },
    addEventListener: none, removeEventListener: none, dispatchEvent: none, matchMedia: () => ({ matches: false }),
    setTimeout: none, clearTimeout: none, setInterval: none, clearInterval: none, innerWidth: 0, innerHeight: 0, devicePixelRatio: 1,
    Event: function Event() {},
  };
  sb.window = sb;
  sb.Q = new URLSearchParams('');   // juego.js defines Q; nivel.js reads it at load
  return vm.createContext(sb);
}
const ctx = sandbox();
function load(file) {
  const src = read(path.join(HIS, file));
  try { new vm.Script(src, { filename: file }).runInContext(ctx); }
  catch (e) { fail(`${file} did not load in the stub context (${e.message}); a browser global it touches needs a stub`); }
  return src;
}
const get = (expr) => vm.runInContext(expr, ctx);

// ---- the check: written JSON equals the old object ------------------------------------------------------------
function same(a, b, at) {
  if (a === null || typeof a !== 'object') {
    if (typeof b === 'number' && !Number.isFinite(b)) fail(`${at}: not a finite number`);
    if (typeof b === 'function' || b === undefined) fail(`${at}: ${typeof b} cannot be JSON`);
    if (!Object.is(a, b)) fail(`${at}: ${JSON.stringify(a)} is not ${JSON.stringify(b)}`);
    return;
  }
  if (b === null || typeof b !== 'object') fail(`${at}: expected ${JSON.stringify(b)}`);
  if (Array.isArray(a) !== Array.isArray(b)) fail(`${at}: array against object`);
  if (Array.isArray(a)) {
    if (a.length !== b.length) fail(`${at}: length ${a.length} against ${b.length}`);
    a.forEach((x, i) => same(x, b[i], `${at}[${i}]`));
    return;
  }
  const ka = Object.keys(a), kb = Object.keys(b);
  if (ka.join('\u0000') !== kb.join('\u0000')) fail(`${at}: keys differ`);
  ka.forEach((k) => same(a[k], b[k], `${at}.${k}`));
}
function writeJson(name, old) {
  const text = JSON.stringify(old, null, 2) + '\n';
  same(JSON.parse(text), old, name);
  fs.mkdirSync(OUT, { recursive: true });
  fs.writeFileSync(path.join(OUT, name), text);
  console.log(`wrote historia/datos/${name} (${text.length} bytes)`);
}

// ---- curso.json, nivel.json -----------------------------------------------------------------------------------
load('curso.js');
load('nivel.js');
writeJson('curso.json', get('CURSO'));
writeJson('nivel.json', get('NV'));

// ---- llamadas.json ---------------------------------------------------------------------------------------------
const llamadaSrc = load('llamada.js');
const code = blankComments(llamadaSrc, 'llamada.js');
const decl = code.match(/\bconst\s+LLAMADAS\s*=\s*/);
if (!decl || code.indexOf('const LLAMADAS', decl.index + 1) >= 0) fail('llamada.js: expected exactly one "const LLAMADAS="');
const braceAt = decl.index + decl[0].length;
if (code[braceAt] !== '{') fail('llamada.js: LLAMADAS is not an object literal');
const LLAMADAS = vm.runInContext('(' + '{' + balanced(code, braceAt) + '}' + ')', ctx);
for (const id of Object.keys(LLAMADAS)) {
  if (get(`Llamada.tiene(${JSON.stringify(id)})`) !== true) fail(`Llamada.tiene("${id}") disagrees with the cut-out LLAMADAS`);
  if (get(`Llamada.minutos(${JSON.stringify(id)})`) !== LLAMADAS[id].minutos) fail(`Llamada.minutos("${id}") disagrees with the cut-out LLAMADAS`);
}
if (get('Llamada.tiene("__none__")') !== false) fail('Llamada.tiene accepts an id that is not there');
writeJson('llamadas.json', LLAMADAS);

// ---- fijos.json: the clip ids named in code ----------------------------------------------------------------------
const ready = JSON.parse(read(path.join(HIS, 'audio', 'ready.json')));
const inReady = new Set(ready.clips);
const found = new Map();   // "file\0id" -> [line, ...]
const add = (file, id, line) => { const k = file + '\0' + id; if (!found.has(k)) found.set(k, []); found.get(k).push(line); };
const dynamic = [];
const naive = new Map();   // the second net: every literal of the raw text that is a clip id
for (const file of FILES) {
  const raw = read(path.join(HIS, file));
  const src = blankComments(raw, file);
  if (src.length !== raw.length) fail(`${file}: comment blanking changed the length`);
  new vm.Script(src, { filename: file + ' (comments blanked)' });   // still valid JavaScript
  // 1. CALL
  const call = new RegExp(`(?<![\\w$.])(${SAY_FUNCTIONS.join('|')})\\(`, 'g');
  for (let m; (m = call.exec(src));) {
    const arg = balanced(src, m.index + m[0].length - 1, true);
    if (arg.includes('`')) fail(`${file}:${lineOf(src, m.index)}: a template literal in the first argument of ${m[1]}(): decide by hand`);
    for (const id of literalsIn(arg)) add(file, id, lineOf(src, m.index));
  }
  // 2. LIST and 3. LINES
  for (const m of src.matchAll(/\bhave\.has\(\s*(?:"([^"]*)"|'([^']*)')\s*\)/g)) add(file, m[1] ?? m[2], lineOf(src, m.index));
  for (const m of src.matchAll(/\bLINES\.([A-Za-z_$][\w$]*)/g)) add(file, m[1], lineOf(src, m.index));
  for (const m of src.matchAll(/\bLINES\[\s*(?:"([^"]*)"|'([^']*)')\s*\]/g)) add(file, m[1] ?? m[2], lineOf(src, m.index));
  // names built at run time
  for (const m of src.matchAll(/(?:"|')([a-z][a-z0-9_]*_)(?:"|')\s*\+/g)) dynamic.push([file, lineOf(src, m.index), m[1]]);
  // the second net
  for (const m of src.matchAll(/"([^"\\\n]+)"|'([^'\\\n]+)'/g)) { const s = m[1] ?? m[2]; if (inReady.has(s)) { const k = file + '\0' + s; if (!naive.has(k)) naive.set(k, []); naive.get(k).push(lineOf(src, m.index)); } }
}
for (const k of found.keys()) {
  const [file, id] = k.split('\0');
  if (!inReady.has(id)) fail(`${file}:${found.get(k)[0]} names the clip "${id}", which is not in audio/ready.json`);
  if (!ROLES.some((r) => r[0] === file && r[1] === id)) fail(`${file}:${found.get(k)[0]} names the clip "${id}": it needs a role in ROLES`);
}
for (const [file, id, role] of ROLES) if (!found.has(file + '\0' + id)) fail(`role ${role}: ${file} no longer names "${id}"`);
const dismissed = new Set(NOT_CLIPS.map((r) => r[0] + '\0' + r[1]));
for (const [k, lines] of naive) {
  if (found.has(k)) continue;
  if (!dismissed.has(k)) fail(`${k.split('\0').join(' "')}" (line ${lines[0]}) is a string equal to a clip id, but is neither found as a clip nor in NOT_CLIPS: decide by hand`);
}
for (const [file, id] of NOT_CLIPS) if (!naive.has(file + '\0' + id)) fail(`NOT_CLIPS lists ${file} "${id}", which is no longer there`);
const clips = {};
for (const [file, id, role] of ROLES) {
  if (role in clips) fail(`role ${role} is given twice`);
  clips[role] = id;
}
// the goodbye words
const adios = code.match(/\bconst\s+adios\s*=\s*/);
if (!adios) fail('llamada.js: no `const adios=`');
const adiosEnd = code.indexOf('\n', adios.index);
const despedidas = [...code.slice(adios.index, adiosEnd).matchAll(/\bdice\(\s*\w+\s*,\s*(?:"([^"]*)"|'([^']*)')\s*\)/g)].map((m) => m[1] ?? m[2]);
if (!despedidas.length) fail('llamada.js: no goodbye words found in `adios`');
writeJson('fijos.json', { clips, despedidas });

// ---- what was found, for the report --------------------------------------------------------------------------------
console.log('\nrole -> clip id -> where the code names it');
for (const [file, id, role] of ROLES) console.log(`  ${role.padEnd(26)} ${id.padEnd(12)} ${[...new Set(found.get(file + '\0' + id))].sort((x, y) => x - y).map((l) => `${file}:${l}`).join(' ')}`);
console.log('goodbye words: ' + JSON.stringify(despedidas));
for (const [file, line, prefix] of dynamic) console.log(`dynamic, not exported: ${file}:${line} builds "${prefix}" + a name at run time (${ready.clips.filter((c) => c.startsWith(prefix)).length} such ids are in ready.json)`);
for (const [file, id, why] of NOT_CLIPS) console.log(`not a clip: ${file} "${id}" (lines ${naive.get(file + '\0' + id).join(', ')}): ${why}`);
