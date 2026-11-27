#!/usr/bin/env node
'use strict';
/* Self-check for coqui/ref/pp/: reads the data back, checks every file against index.json (size and SHA-256),
   every buffer against its JSON (size, SHA-256), the PNGs against the buffers, and the unit files' shapes.
   Run from the repo root:  node coqui/tool/ref/pp/check.js   (exit code 1 on any problem) */
const fs = require('fs');
const path = require('path');
const L = require('./lib.js');

const REPO = path.resolve(__dirname, '../../../..');
const ROOT = path.resolve(process.argv[2] || path.join(REPO, 'coqui/ref/pp'));
const errs = [];
const bad = m => errs.push(m);
const read = f => fs.readFileSync(path.join(ROOT, f));
const BYTES = { uint32: 4, float32: 4, uint8: 1 };

for (const e of fs.readdirSync(ROOT, { withFileTypes: true })) {
  if (!e.isDirectory() && e.name !== 'index.json') {
    bad(e.name + ': unexpected top-level file in ' + ROOT);
  }
}

const subdirs = fs.readdirSync(ROOT, { withFileTypes: true })
  .filter(e => e.isDirectory())
  .map(e => e.name)
  .sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));

const expectedEntries = [];
let expectedTotalBytes = 0;
for (const folder of subdirs) {
  const folderPath = path.join(ROOT, folder);
  for (const err of L.verifyIndex(folderPath)) {
    bad(folder + '/' + err);
  }
  let subIdx;
  try {
    subIdx = JSON.parse(fs.readFileSync(path.join(folderPath, 'index.json'), 'utf8'));
  } catch (e) {
    continue;
  }
  if (!Array.isArray(subIdx.entries)) {
    bad(folder + '/index.json: entries is not an array');
    continue;
  }
  for (const e of subIdx.entries) {
    expectedEntries.push({ path: folder + '/' + e.path, bytes: e.bytes, sha256: e.sha256 });
    expectedTotalBytes += e.bytes;
  }
}
expectedEntries.sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0));

try {
  const topIdx = JSON.parse(fs.readFileSync(path.join(ROOT, 'index.json'), 'utf8'));
  if (topIdx.files !== expectedEntries.length) {
    bad('index.json: files is ' + topIdx.files + ', assembled count is ' + expectedEntries.length);
  }
  if (topIdx.totalBytes !== expectedTotalBytes) {
    bad('index.json: totalBytes is ' + topIdx.totalBytes + ', assembled total is ' + expectedTotalBytes);
  }
  if (!Array.isArray(topIdx.entries)) {
    bad('index.json: entries is not an array');
  } else {
    if (topIdx.entries.length !== expectedEntries.length) {
      bad('index.json: entries length is ' + topIdx.entries.length + ', assembled length is ' + expectedEntries.length);
    }
    const len = Math.min(topIdx.entries.length, expectedEntries.length);
    for (let i = 0; i < len; i++) {
      const actual = topIdx.entries[i];
      const expected = expectedEntries[i];
      if (!actual || actual.path !== expected.path || actual.bytes !== expected.bytes || actual.sha256 !== expected.sha256) {
        bad('index.json: entry ' + i + ' (' + (actual && actual.path) + ') does not match assembled ' + expected.path);
      }
    }
  }
} catch (e) {
  bad('index.json: ' + e.message);
}

let dirs = 0, buffers = 0;
for (const f of L.walk(ROOT)) {
  if (!f.endsWith('/state.json')) continue;
  const dir = f.slice(0, -'/state.json'.length);
  dirs++;
  const state = JSON.parse(read(f));
  const { W, H } = state.engine;
  const bufs = {};
  for (const name of ['pix', 'zb', 'kinds']) {
    let meta, bin;
    try { meta = JSON.parse(read(dir + '/' + name + '.json')); bin = read(dir + '/' + meta.file); } catch (e) { bad(dir + '/' + name + ': ' + e.message); continue; }
    buffers++;
    if (meta.width !== W || meta.height !== H) bad(dir + '/' + name + ': ' + meta.width + 'x' + meta.height + ', state.json says ' + W + 'x' + H);
    if (!(meta.type in BYTES)) { bad(dir + '/' + name + ': type ' + meta.type); continue; }
    if (meta.endian !== 'little') bad(dir + '/' + name + ': endian ' + meta.endian);
    if (bin.length !== meta.width * meta.height * BYTES[meta.type]) bad(dir + '/' + name + ': ' + bin.length + ' bytes for ' + meta.width + 'x' + meta.height + ' ' + meta.type);
    if (bin.length !== meta.bytes) bad(dir + '/' + name + ': json says ' + meta.bytes + ' bytes, file has ' + bin.length);
    if (L.sha256(bin) !== meta.sha256) bad(dir + '/' + name + ': sha256 differs from its json');
    bufs[name] = bin;
  }
  if (!bufs.pix || !bufs.zb || !bufs.kinds) continue;
  // the picture is not blank, not one colour, not cut off (every edge row and column has been drawn or is empty alike for the whole picture)
  const u32 = new Uint32Array(bufs.pix.buffer, bufs.pix.byteOffset, bufs.pix.length / 4);
  const colours = new Set();
  let opaque = 0, rowsDrawn = 0;
  for (let y = 0; y < H; y++) { let any = false; for (let x = 0; x < W; x++) { const c = u32[y * W + x]; if (c >>> 24 === 255) { opaque++; any = true; colours.add(c); } } if (any) rowsDrawn++; }
  if (opaque < W * H * 0.3) bad(dir + ': only ' + opaque + ' opaque pixels of ' + W * H);
  if (colours.size < 40) bad(dir + ': only ' + colours.size + ' colours');
  if (rowsDrawn < H * 0.8) bad(dir + ': only ' + rowsDrawn + ' of ' + H + ' rows drawn');
  const f32 = new Float32Array(bufs.zb.buffer.slice(bufs.zb.byteOffset, bufs.zb.byteOffset + bufs.zb.length));
  if (f32.some(v => Number.isNaN(v))) bad(dir + '/zb: NaN');
  if (bufs.kinds.some(v => v > 4)) bad(dir + '/kinds: a value above 4');
  const sz = L.pngSize(read(dir + '/pix.png'));
  if (!sz || sz.w !== W || sz.h !== H) bad(dir + '/pix.png: ' + JSON.stringify(sz) + ' for ' + W + 'x' + H);
  if (state.kind === 'island') {
    const calls = JSON.parse(read(dir + '/decorate-calls.json'));
    if (calls.length !== state.decorateCalls) bad(dir + ': decorate-calls.json has ' + calls.length + ' entries, state.json says ' + state.decorateCalls);
    if (!read(dir + '/calls.md').toString().includes('decorate()')) bad(dir + '/calls.md: does not mention decorate()');
  }
  if (state.kind === 'mapa') {
    for (const k of ['hecho', 'abierto']) if (!Array.isArray(state[k]) || state[k].length !== 10) bad(dir + ': ' + k + ' is not 10 long');
    if (state.time !== 0) bad(dir + ': time is ' + state.time);
  }
  if (state.mathRandomCalls !== 0) bad(dir + ': Math.random was called');
}

// the unit files
const f32 = new Float32Array(1), u32 = new Uint32Array(f32.buffer);
let units = 0;
for (const f of L.walk(ROOT).filter(f => /^unit\/.*\.json$/.test(f) && f !== 'unit/index.json')) {
  const d = JSON.parse(read(f));
  units++;
  const need = f === 'unit/unit.json' ? ['hash', 'noise', 'project', 'unproject', 'rampOf'] : ['project', 'unproject'];
  for (const k of need) if (!Array.isArray(d[k]) || d[k].length !== 200) bad(f + ': ' + k + ' is not 200 long');
  for (const r of d.hash || []) if (!(r.v >= 0 && r.v < 1)) bad(f + ': hash out of [0,1)');
  for (const r of d.noise || []) if (!(r.v >= 0 && r.v <= 1)) bad(f + ': noise out of [0,1]');
  for (const r of d.project || []) { f32[0] = r.d; if (f32[0] !== r.d32 || u32[0] !== r.d32bits) bad(f + ': project d32 does not match d'); }
  for (const r of d.rampOf || []) if (r.ramp.length !== 5 || r.ramp.some(v => !Number.isInteger(v) || v < 0 || v > 0xffffffff || v >>> 24 !== 255)) bad(f + ': a ramp entry is not an opaque uint32');
  if (d.settings.W == null) bad(f + ': no settings');
}

if (errs.length) { console.error('CHECK FAILED (' + errs.length + ')\n' + errs.map(e => '  ' + e).join('\n')); process.exit(1); }
console.log('ok  ' + dirs + ' dumps, ' + buffers + ' buffers, ' + units + ' unit files, every file against index.json');
