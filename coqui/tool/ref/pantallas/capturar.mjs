// Order 05, part C: phone-size reference pictures of every screen of the old JavaScript app (v=39).
//   node coqui/tool/ref/pantallas/capturar.mjs                 everything, into coqui/ref/pantallas/
//   node coqui/tool/ref/pantallas/capturar.mjs --only palabras --out /tmp/x --no-optimise     a group, to a scratch folder
// Options: --only <group,group>  --device <id>  --out <dir>  --no-optimise  --list
// See coqui/ref/pantallas/README.md for what is pinned and how to open a state by hand.
import fs from 'node:fs';
import path from 'node:path';
import { serve, launch, newPage, Recorder, sha256, DEVICES, OUT as OUT0, REPO, T0 } from './lib/harness.mjs';
import { buildSeeds, SEED_DEFS } from './lib/seeds.mjs';
import { GROUPS } from './lib/groups.mjs';
import { optimiseAll } from './lib/optimise.mjs';
import { writeIndex } from './lib/index-out.mjs';
import { nivelSeed } from './lib/g-lessons.mjs';

const arg = (k, d = null) => { const i = process.argv.indexOf('--' + k); return i < 0 ? d : (process.argv[i + 1] && !process.argv[i + 1].startsWith('--') ? process.argv[i + 1] : true); };
const only = arg('only') ? String(arg('only')).split(',') : null;
const outDir = path.resolve(arg('out', OUT0));
const devices = DEVICES.filter(d => !arg('device') || d.id.startsWith(arg('device')));
const noOpt = !!arg('no-optimise');
if (arg('list')) { console.log(GROUPS.map(g => g.id).join('\n')); process.exit(0); }
const groups = GROUPS.filter(g => !only || only.includes(g.id));

const t0 = Date.now();
const { server, port } = await serve();
const base = `http://127.0.0.1:${port}/field-notes`;
const browser = await launch();
try {
  console.log('seeds ...');
  const seeds = await buildSeeds(browser, DEVICES[0], base);
  const C0 = { base, page: sd => newPage(browser, DEVICES[0], { seed: seeds[sd] }) };
  seeds.nivel = await nivelSeed(C0, 11);    // after the level check, made by playing it: right up to story 11
  seeds.nivel1 = await nivelSeed(C0, 1);    // right on story 1 only

  // one run per device, side by side (each has its own browser context per page; nothing is shared)
  const recs = await Promise.all(devices.map(async dev => {
    const rec = new Recorder(dev, f => process.stdout.write(`  ${dev.id.slice(0, 3)} ${f}\n`));
    const C = {
      browser, dev, base, seeds, rec,
      page: (seed, o = {}) => newPage(browser, dev, { seed: seed ? seeds[seed] : null, ...o }),
      shot: (pg, screen, state, meta, opts) => rec.shot(pg, screen, state, meta, opts),
      errors: [],
    };
    for (const g of groups) {
      const t = Date.now();
      await g.run(C);
      console.log(`${dev.id} ${g.id}: ${((Date.now() - t) / 1000).toFixed(1)} s, ${rec.n} pictures so far`);
    }
    return rec;
  }));

  // the same pictures on both phones
  if (recs.length > 1) {
    const a = recs[0].items.map(x => x.file).join('|'), b = recs[1].items.map(x => x.file).join('|');
    if (a !== b) throw new Error('the two phones did not take the same pictures:\n' + a + '\n' + b);
  }
  fs.mkdirSync(outDir, { recursive: true });
  const finals = await optimiseAll(recs, outDir, { skip: noOpt });
  writeIndex({ recs, finals, outDir, seeds, only, noOpt });
  console.log(`done in ${((Date.now() - t0) / 1000).toFixed(0)} s: ${recs.reduce((n, r) => n + r.items.length, 0)} pictures in ${outDir}`);
} finally {
  await browser.close();
  server.close();
}
