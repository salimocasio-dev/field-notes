// Order 21: the data of feature_words' dev entry, as Dart strings (a dev entry on the web cannot read files).
//
//   cd coqui/packages/features/feature_words && node tool/make_dev_data.mjs && dart format tool
//
// Writes:
//   tool/dev_data/seeds.g.dart   the stored-progress states of coqui/ref/pantallas/seeds/ that the pictures of
//                                order 21 are taken in (vacio, uno, curso, todo, nivel), exactly as the files are
//   tool/dev_data/course.g.dart  the course files the old app reads (historia/datos/curso.json, nivel.json,
//                                llamadas.json, fijos.json, audio/marcas.json and every story and review set that
//                                curso.json names, historia/cuentos/*.json), as the sample course of coqui_testing
//                                has them, but all of them: the fake catalog takes a `fetch` over this map.
//
// Why the whole course: the sample course holds three stories, so in the reference states the words of every other
// story would fall under "More words" and only El frente's twelve words would have a picture. Nothing in historia/
// is changed; the files are copied as they are (JSON written on one line).

import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const pkg = path.resolve(here, '..');
const coqui = path.resolve(pkg, '..', '..', '..');
const historia = path.resolve(coqui, '..', 'historia');
const seedsDir = path.join(coqui, 'ref', 'pantallas', 'seeds');
const outDir = path.join(here, 'dev_data');
fs.mkdirSync(outDir, {recursive: true});

const dartString = (text) => {
  let o = "'";
  for (const ch of text) {
    const c = ch.codePointAt(0);
    if (ch === "'" || ch === '\\' || ch === '$') o += '\\' + ch;
    else if (c < 0x20 || c > 0x7e) o += '\\u{' + c.toString(16) + '}';
    else o += ch;
  }
  return o + "'";
};
const oneLine = (file) => JSON.stringify(JSON.parse(fs.readFileSync(file, 'utf8')));

// ---------- the seeds ----------
const SEEDS = ['vacio', 'uno', 'curso', 'todo', 'nivel'];
let seeds =
  '// Made by tool/make_dev_data.mjs from coqui/ref/pantallas/seeds/. Do not edit by hand.\n' +
  '// Re-run: cd coqui/packages/features/feature_words && node tool/make_dev_data.mjs && dart format tool\n\n' +
  '/// The stored progress (`coqui.palabras.v1`) of each reference state, by the seed\'s name.\n' +
  'const Map<String, String> devSeeds = {\n';
for (const name of SEEDS) seeds += `  '${name}': ${dartString(oneLine(path.join(seedsDir, name + '.json')))},\n`;
seeds += '};\n';
fs.writeFileSync(path.join(outDir, 'seeds.g.dart'), seeds);

// ---------- the course ----------
const curso = JSON.parse(fs.readFileSync(path.join(historia, 'datos/curso.json'), 'utf8'));
const files = {};
for (const f of ['curso', 'nivel', 'llamadas', 'fijos']) files[`datos/${f}.json`] = oneLine(path.join(historia, `datos/${f}.json`));
files['audio/marcas.json'] = oneLine(path.join(historia, 'audio/marcas.json'));
for (const id of [...Object.keys(curso.cuentos), ...curso.cual]) {
  files[`cuentos/${id}.json`] = oneLine(path.join(historia, `cuentos/${id}.json`));
}
let course =
  '// Made by tool/make_dev_data.mjs from historia/. Do not edit by hand.\n' +
  '// Re-run: cd coqui/packages/features/feature_words && node tool/make_dev_data.mjs && dart format tool\n\n' +
  '/// The course files the old app reads, by their path under historia/ (JSON on one line).\n' +
  'const Map<String, String> devCourseFiles = {\n';
for (const p of Object.keys(files).sort()) course += `  '${p}': ${dartString(files[p])},\n`;
course += '};\n';
fs.writeFileSync(path.join(outDir, 'course.g.dart'), course);

console.log(`dev data: ${SEEDS.length} seeds, ${Object.keys(files).length} course files`);
