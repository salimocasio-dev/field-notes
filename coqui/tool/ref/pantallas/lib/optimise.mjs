// Writes the pictures, lossless-optimised (oxipng, through @napi-rs/image, pinned). The optimiser is installed once into the system temp folder (outside the repository).
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { sha256 } from './harness.mjs';

const PKG = '@napi-rs/image', VER = '1.16.0';
const DIR = path.join(os.tmpdir(), 'coqui-pantallas-opt-' + VER);

export function loadOptimiser() {
  const req = createRequire(path.join(DIR, 'x.js'));
  try { return req(PKG); } catch (e) { /* not here yet */ }
  fs.mkdirSync(DIR, { recursive: true });
  fs.writeFileSync(path.join(DIR, 'package.json'), '{"name":"coqui-pantallas-opt","private":true}');
  console.log(`installing ${PKG}@${VER} into ${DIR} (the PNG optimiser) ...`);
  execFileSync('npm', ['install', `${PKG}@${VER}`, '--no-audit', '--no-fund', '--loglevel=error'], { cwd: DIR, stdio: 'inherit' });
  return req(PKG);
}

// recs: the recorders of the phones. Returns Map(device/file -> { bytes, sha }). Old pictures of a full run are removed first.
export async function optimiseAll(recs, outDir, { skip = false, full = true } = {}) {
  const opt = skip ? null : loadOptimiser();
  const out = new Map();
  const jobs = [];
  for (const rec of recs) {
    const dir = path.join(outDir, rec.dev.id);
    fs.mkdirSync(dir, { recursive: true });
    if (full) for (const f of fs.readdirSync(dir)) if (f.endsWith('.png')) fs.unlinkSync(path.join(dir, f));
    for (const it of rec.items) jobs.push({ dir, it });
  }
  let i = 0, done = 0;
  const worker = async () => {
    for (;;) {
      const j = jobs[i++]; if (!j) return;
      const b = opt ? await opt.losslessCompressPng(j.it.raw, { level: 4 }) : j.it.raw;
      const buf = Buffer.from(b);
      fs.writeFileSync(path.join(j.dir, j.it.file), buf);
      out.set(j.it.device + '/' + j.it.file, { bytes: buf.length, sha: sha256(buf) });
      j.it.raw = null; done++;
      if (done % 20 === 0) console.log(`  optimised ${done}/${jobs.length}`);
    }
  };
  await Promise.all([0, 1, 2, 3].map(worker));
  return out;
}
