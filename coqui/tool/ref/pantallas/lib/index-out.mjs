// the index, the seeds and the strings, written next to the pictures
import fs from 'node:fs';
import path from 'node:path';
import { SEED_DEFS } from './seeds.mjs';
import { STRINGS, tickOff } from './strings.mjs';
import { T0, TZ, DEVICES } from './harness.mjs';

const ABOUT = {
  ...Object.fromEntries(Object.entries(SEED_DEFS).map(([k, v]) => [k, v.about])),
  nivel: 'after the level check (nivel.html played: right on every item up to story 11): 11 stories counted as played, their words presumed (stage 3)',
  nivel1: 'after a level check with right answers on story 1 only: 1 story counted as played',
};

export function writeIndex({ recs, finals, outDir, seeds, only, noOpt }) {
  const items = [];
  const rows = [];
  for (const rec of recs) for (const it of rec.items) {
    const f = finals.get(it.device + '/' + it.file);
    items.push({ file: `${it.device}/${it.file}`, device: it.device, screen: it.screen, state: it.state, url: it.meta.url, seed: it.meta.seed, steps: it.meta.steps, orders: it.meta.orders, full_page: it.full, bytes: f.bytes, sha256: f.sha });
    rows.push({ file: it.file, text: it.text });
  }
  const pinned = { date: new Date(T0).toISOString(), local: '2026-11-19 12:00 America/Puerto_Rico (UTC-4)', timezone: TZ, locale: 'en-US', random: 'Mulberry32, seed 1', reduced_motion: 'reduce', audio: 'silent, on the paused clock',
    devices: DEVICES.map(d => ({ id: d.id, css_px: [d.w, d.h], device_scale_factor: d.dsf, user_agent: d.ua })) };
  fs.writeFileSync(path.join(outDir, 'index.json'), JSON.stringify({ pinned, seeds: Object.keys(seeds).map(k => ({ name: k, file: `seeds/${k}.json`, about: ABOUT[k] || '' })), pictures: items }, null, 1) + '\n');
  fs.mkdirSync(path.join(outDir, 'seeds'), { recursive: true });
  for (const [k, v] of Object.entries(seeds)) fs.writeFileSync(path.join(outDir, 'seeds', k + '.json'), JSON.stringify(JSON.parse(v), null, 1) + '\n');
  // the English strings: where each shows
  const tick = tickOff(rows);
  const missing = tick.filter(x => x.count === 0);
  fs.writeFileSync(path.join(outDir, 'strings.json'), JSON.stringify({ about: 'The English strings v=39 can show, and the pictures (file names, the same on both phones) in which each shows. count 0: not shown in any picture.', not_shown: missing.map(x => ({ string: x.string, from: x.from, note: x.note })), strings: tick }, null, 1) + '\n');
  if (only) console.log('(partial run: strings not ticked off here are not an error)');
  console.log(`strings: ${tick.length - missing.length} of ${tick.length} shown in a picture`);
  for (const m of missing) console.log('  NOT SHOWN: ' + m.string + '   [' + m.from + (m.note ? ', ' + m.note : '') + ']');
}
