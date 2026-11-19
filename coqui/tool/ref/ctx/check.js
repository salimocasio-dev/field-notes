#!/usr/bin/env node
'use strict';
/* Self-check for coqui/ref/ctx/: every file against index.json (size, SHA-256), then cases.json against the tiles and the old code:
   40 cases numbered 1 to 40, each tile 64 * 64 * 4 bytes with the hash cases.json gives and not blank, each case's ops valid
   (names, argument counts, a source that exists, imageSmoothingEnabled first), each source file the size it says, and each
   `refs` line still the text it was when the data was made. Run from the repo root:  node coqui/tool/ref/ctx/check.js */
const fs = require('fs');
const path = require('path');
const L = require('./lib.js');

const REPO = path.resolve(__dirname, '../../../..');
const ROOT = path.resolve(process.argv[2] || path.join(REPO, 'coqui/ref/ctx'));
const errs = [];
const bad = m => errs.push(m);
errs.push(...L.verifyIndex(ROOT));

const ARGS = { save: 0, restore: 0, translate: 2, scale: 2, rotate: 1, fillRect: 4, clearRect: 4, beginPath: 0, rect: 4, arc: 5, ellipse: 7, moveTo: 2, lineTo: 2, fill: 0, stroke: 0, clip: 0 };
const j = JSON.parse(fs.readFileSync(path.join(ROOT, 'cases.json'), 'utf8'));
const sources = j.sources;
for (const [id, s] of Object.entries(sources)) {
  const b = fs.readFileSync(path.join(ROOT, s.file));
  if (b.length !== s.w * s.h * 4) bad('source ' + id + ': ' + b.length + ' bytes for ' + s.w + 'x' + s.h);
  if (L.sha256(b) !== s.sha256) bad('source ' + id + ': sha256 differs from cases.json');
  if (!b.some((v, i) => i % 4 === 3 && v === 255)) bad('source ' + id + ': no opaque pixel');
}
if (j.cases.length !== 40) bad('cases: ' + j.cases.length + ', expected 40');
const kinds = {};
const fileLines = {};
j.cases.forEach((c, i) => {
  const tag = 'case ' + c.n;
  if (c.n !== i + 1) bad(tag + ': number out of order');
  kinds[c.kind] = (kinds[c.kind] || 0) + 1;
  const b = fs.readFileSync(path.join(ROOT, c.file));
  if (b.length !== 64 * 64 * 4) bad(tag + ': ' + b.length + ' bytes');
  if (L.sha256(b) !== c.sha256) bad(tag + ': sha256 differs from cases.json');
  const first = b.subarray(0, 4);
  let differ = 0;
  for (let p = 0; p < b.length; p += 4) if (b[p] !== first[0] || b[p + 1] !== first[1] || b[p + 2] !== first[2] || b[p + 3] !== first[3]) differ++;
  if (differ < 30) bad(tag + ': blank (' + differ + ' pixels differ from the corner)');
  if (!c.ops.length || c.ops[0][0] !== 'imageSmoothingEnabled' || typeof c.ops[0][1] !== 'boolean') bad(tag + ': does not begin with imageSmoothingEnabled');
  for (const op of c.ops) {
    const [name, ...a] = op;
    if (name === 'fillStyle' || name === 'strokeStyle') { if (op.length !== 3 || op[2].length !== 4 || op[2].some(v => !Number.isInteger(v) || v < 0 || v > 255)) bad(tag + ': bad colour op ' + JSON.stringify(op)); }
    else if (name === 'globalAlpha' || name === 'lineWidth') { if (op.length !== 2 || !Number.isFinite(op[1])) bad(tag + ': bad ' + name); }
    else if (name === 'imageSmoothingEnabled') { if (op.length !== 2 || typeof op[1] !== 'boolean') bad(tag + ': bad ' + name); }
    else if (name === 'drawImage' || name === 'drawImageRect') {
      if (!sources[a[0]]) bad(tag + ': drawImage of unknown source ' + a[0]);
      const n = a.length - 1;
      if (name === 'drawImage' ? n !== 2 && n !== 4 : n !== 8) bad(tag + ': ' + name + ' with ' + n + ' numbers');
      if (a.slice(1).some(v => !Number.isFinite(v))) bad(tag + ': a drawImage number is not finite');
    } else if (name in ARGS) {
      if (a.length !== ARGS[name] || a.some(v => !Number.isFinite(v))) bad(tag + ': bad ' + name + ' ' + JSON.stringify(op));
    } else bad(tag + ': unknown op ' + name);
  }
  if (!c.refs) bad(tag + ': no refs');
  for (const r of c.refs || []) {
    const ls = fileLines[r.file] || (fileLines[r.file] = fs.readFileSync(path.join(REPO, r.file), 'utf8').split('\n'));
    if (!(ls[r.line - 1] || '').trim().startsWith(r.text)) bad(tag + ': ' + r.file + ':' + r.line + ' is no longer "' + r.text.slice(0, 40) + '..."');
  }
});
for (const k of Object.keys(kinds)) if (kinds[k] < 1) bad('kind ' + k);
const need = ['fillRect-whole', 'fillRect-half', 'drawImage-plain', 'drawImage-scale-1.6', 'drawImage-scale-0.86', 'drawImage-flip', 'drawImage-rotate-0.5', 'drawImage-smoothing', 'globalAlpha-0.5', 'arc-fill', 'ellipse-fill', 'clip-rect', 'stroke-1', 'stroke-2'];
for (const k of need) if (!kinds[k]) bad('no case of kind ' + k);
const sz = L.pngSize(fs.readFileSync(path.join(ROOT, 'sheet.png')));
if (!sz || sz.w !== 1644 || sz.h !== 1152) bad('sheet.png: ' + JSON.stringify(sz));

if (errs.length) { console.error('CHECK FAILED (' + errs.length + ')\n' + errs.map(e => '  ' + e).join('\n')); process.exit(1); }
console.log('ok  40 cases, ' + Object.keys(sources).length + ' sources, ' + Object.keys(kinds).length + ' kinds, every file against index.json');
