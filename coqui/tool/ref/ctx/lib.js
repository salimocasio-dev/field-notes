'use strict';
// Helpers shared by the scripts of this folder. The same file is copied, byte for byte, into
// coqui/tool/ref/ctx/ and coqui/tool/ref/sprites/ so that each part stands alone.
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const crypto = require('crypto');

const sha256 = buf => crypto.createHash('sha256').update(buf).digest('hex');

// ---- PNG (RGBA, 8 bit, no interlace; zlib level 9, so the same bytes every run on the same Node) ----
const CRC = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC[(c ^ buf[i]) & 255] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  out.write(type, 4, 'latin1');
  data.copy(out, 8);
  out.writeUInt32BE(crc32(out.subarray(4, 8 + data.length)), 8 + data.length);
  return out;
}
function png(w, h, rgba) {
  if (rgba.length !== w * h * 4) throw new Error('png: bad length ' + rgba.length + ' for ' + w + 'x' + h);
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0;
    Buffer.from(rgba.buffer, rgba.byteOffset + y * w * 4, w * 4).copy(raw, y * (w * 4 + 1) + 1);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}
// width and height of a PNG file's bytes, or null when it is not one
function pngSize(buf) {
  if (buf.length < 24 || buf.readUInt32BE(0) !== 0x89504e47) return null;
  return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
}

// ---- files ----
// pretty JSON, two spaces; a short array of plain values stays on one line
function json(obj) {
  const scalar = v => v === null || typeof v !== 'object';
  const rec = (v, ind) => {
    if (scalar(v)) return JSON.stringify(v);
    const pad = ind + '  ';
    if (Array.isArray(v)) {
      if (!v.length) return '[]';
      if (v.every(scalar)) { const one = '[' + v.map(x => JSON.stringify(x)).join(', ') + ']'; if (one.length <= 110) return one; }
      return '[\n' + v.map(x => pad + rec(x, pad)).join(',\n') + '\n' + ind + ']';
    }
    const keys = Object.keys(v).filter(k => v[k] !== undefined);
    if (!keys.length) return '{}';
    return '{\n' + keys.map(k => pad + JSON.stringify(k) + ': ' + rec(v[k], pad)).join(',\n') + '\n' + ind + '}';
  };
  return rec(obj, '') + '\n';
}
function write(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, data);
}
// every file under root, as paths with '/', sorted by code unit (not by locale)
function walk(root) {
  const out = [];
  (function rec(dir) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) rec(p); else out.push(path.relative(root, p).split(path.sep).join('/'));
    }
  })(root);
  return out.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
}
// index.json: every file under root except itself, with size and SHA-256
function writeIndex(root, what) {
  const files = walk(root).filter(f => f !== 'index.json').map(f => {
    const b = fs.readFileSync(path.join(root, f));
    return { path: f, bytes: b.length, sha256: sha256(b) };
  });
  const total = files.reduce((a, f) => a + f.bytes, 0);
  write(path.join(root, 'index.json'), json({ what, files: files.length, totalBytes: total, entries: files }));
  return { files: files.length, totalBytes: total };
}
// the problems found when reading root back against its index.json
function verifyIndex(root) {
  const errs = [];
  let idx;
  try { idx = JSON.parse(fs.readFileSync(path.join(root, 'index.json'), 'utf8')); } catch (e) { return ['index.json: ' + e.message]; }
  const seen = new Set();
  for (const e of idx.entries) {
    seen.add(e.path);
    let b;
    try { b = fs.readFileSync(path.join(root, e.path)); } catch (x) { errs.push(e.path + ': missing'); continue; }
    if (b.length !== e.bytes) errs.push(e.path + ': ' + b.length + ' bytes, index says ' + e.bytes);
    if (sha256(b) !== e.sha256) errs.push(e.path + ': sha256 differs from the index');
  }
  for (const f of walk(root)) if (f !== 'index.json' && !seen.has(f)) errs.push(f + ': in the folder but not in the index');
  if (idx.files !== idx.entries.length) errs.push('index: files count wrong');
  return errs;
}
module.exports = { sha256, png, pngSize, json, write, walk, writeIndex, verifyIndex };
