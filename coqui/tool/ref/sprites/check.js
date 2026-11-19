#!/usr/bin/env node
'use strict';
/* Self-check for coqui/ref/sprites/: every file against index.json (size, SHA-256), then for each group
   (engine, kit): every function's .bin against sprites.json, every sprite's slice (offset, w * h * 4 bytes, SHA-256), no empty sprite,
   ids unique, every mk* function and every bg* function of the old files present, the frog's sizes against its argument,
   every hundredth of the frog's size from .40 to 1 present with both blinks and both mouths, the sheets' size.
   Run from the repo root:  node coqui/tool/ref/sprites/check.js */
const fs = require('fs');
const path = require('path');
const L = require('./lib.js');

const REPO = path.resolve(__dirname, '../../../..');
const ROOT = path.resolve(process.argv[2] || path.join(REPO, 'coqui/ref/sprites'));
const errs = [];
const bad = m => errs.push(m);
errs.push(...L.verifyIndex(ROOT));

const OLD = { engine: 'historia/engine.js', kit: 'historia/escenas/kit.js' };
const counts = {};
for (const group of ['engine', 'kit']) {
  const j = JSON.parse(fs.readFileSync(path.join(ROOT, group, 'sprites.json'), 'utf8'));
  const files = {};
  for (const [fn, f] of Object.entries(j.functions)) {
    const b = fs.readFileSync(path.join(ROOT, group, f.file));
    files[fn] = b;
    if (b.length !== f.bytes) bad(group + '/' + fn + ': ' + b.length + ' bytes, sprites.json says ' + f.bytes);
    if (L.sha256(b) !== f.sha256) bad(group + '/' + fn + ': sha256 differs from sprites.json');
  }
  const ids = new Set();
  const perFn = {};
  const end = {};
  for (const s of j.sprites) {
    if (ids.has(s.id)) bad(group + ': id ' + s.id + ' twice');
    ids.add(s.id);
    perFn[s.fn] = (perFn[s.fn] || 0) + 1;
    const b = files[s.fn];
    if (!b) { bad(s.id + ': no file for ' + s.fn); continue; }
    if (!(s.w > 0 && s.h > 0) || s.bytes !== s.w * s.h * 4) bad(s.id + ': bytes ' + s.bytes + ' for ' + s.w + 'x' + s.h);
    if (s.offset !== (end[s.fn] || 0)) bad(s.id + ': offset ' + s.offset + ' does not follow the one before');
    end[s.fn] = s.offset + s.bytes;
    if (s.offset + s.bytes > b.length) { bad(s.id + ': runs past the end of ' + s.file); continue; }
    const slice = b.subarray(s.offset, s.offset + s.bytes);
    if (L.sha256(slice) !== s.sha256) bad(s.id + ': sha256 differs');
    if (!slice.some((v, i) => i % 4 === 3 && v !== 0)) bad(s.id + ': empty');
    if (!Array.isArray(s.args) || typeof s.call !== 'string') bad(s.id + ': no args or call');
  }
  for (const [fn, f] of Object.entries(j.functions)) {
    if (perFn[fn] !== f.sprites) bad(group + '/' + fn + ': ' + perFn[fn] + ' sprites listed, functions says ' + f.sprites);
    if (end[fn] !== files[fn].length) bad(group + '/' + fn + ': the sprites do not fill the file');
  }
  // every mk* and bg* function of the old file is in the list
  const src = fs.readFileSync(path.join(REPO, OLD[group]), 'utf8');
  for (const m of src.matchAll(/function\s+((?:mk|bg)\w+)\s*\(/g)) if (!j.functions[m[1]]) bad(group + ': ' + m[1] + ' of ' + OLD[group] + ' has no sprites');
  if (group === 'engine') {
    const frogs = j.sprites.filter(s => s.fn === 'mkCoqui');
    for (const s of frogs) {
      const [sz] = s.args;
      if (s.w !== Math.round(30 * sz) + 2 || s.h !== Math.round(25 * sz) + 2) bad(s.id + ': size ' + s.w + 'x' + s.h + ' does not follow from s = ' + sz);
    }
    const have = new Set(frogs.map(s => s.args.join(',')));
    for (let k = 40; k <= 100; k++) for (const bl of [0, 1]) for (const op of [0, 1]) if (!have.has([k / 100, bl, op].join(','))) bad('mkCoqui(' + k / 100 + ',' + bl + ',' + op + ') missing');
    for (const s of j.sprites) if (s.fn === 'mkAbuela' && (s.w !== 48 || s.h !== 51)) bad(s.id + ': not 48 x 51');
  }
  if (group === 'kit') {
    const people = new Set(j.sprites.filter(s => s.fn === 'mkPersona').map(s => s.args[0].fam));
    for (const p of Object.keys(j.FAM)) if (!people.has(p)) bad('mkPersona: no sprite for FAM.' + p);
  }
  const sz = L.pngSize(fs.readFileSync(path.join(ROOT, 'sheet-' + group + '.png')));
  if (!sz || sz.w !== 1500 || sz.h < 200) bad('sheet-' + group + '.png: ' + JSON.stringify(sz));
  counts[group] = j.sprites.length + ' sprites in ' + Object.keys(j.functions).length + ' functions';
}
if (errs.length) { console.error('CHECK FAILED (' + errs.length + ')\n' + errs.map(e => '  ' + e).join('\n')); process.exit(1); }
console.log('ok  engine: ' + counts.engine + '; kit: ' + counts.kit + '; every file against index.json');
