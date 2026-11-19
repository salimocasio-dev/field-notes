// Order 02: the sample course of coqui_testing, from the course files (historia/cuentos, libros, and order 04's
// datos/ and audio/marcas.json).
//
//   cd coqui && node tool/contracts/make_sample.mjs
//
// Writes packages/core/coqui_testing/sample/:
//   cuentos/   la-lluvia, el-bizcocho, donde-esta-el-pajaro (stories 1 to 3) and cual-frente, copied byte for byte
//   libros/    la-lluvia, copied byte for byte
//   datos/fijos.json      copied byte for byte (the fixed lines by role, and the goodbye words)
//   datos/curso.json      datos/curso.json with only La casa (El frente's place) and the entries of stories 1 to 3
//   datos/llamadas.json   datos/llamadas.json: La casa's call
//   datos/nivel.json      datos/nivel.json: the items of stories 1 to 3 (s <= 3)
//   audio/marcas.json     audio/marcas.json for twenty clips of stories 1 to 3 (their [startMs, endMs, lengthMs]).
//                         No audio files.
//
// and packages/core/coqui_testing/lib/src/sample_files.dart: the same files as Dart strings, which is what
// the fake catalog reads (a dev dependency's assets are left out of a web build, so the dev entries could not
// read the files themselves). A test checks the strings against the files.
//
// Nothing in historia/ is changed. Run it again when one of those files changes, then
// dart format packages/core/coqui_testing.

import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const coqui = path.resolve(here, '..', '..');
const historia = path.resolve(coqui, '..', 'historia');
const out = path.join(coqui, 'packages/core/coqui_testing/sample');
const read = (p) => fs.readFileSync(path.join(historia, p), 'utf8');
const write = (p, text) => {
  fs.mkdirSync(path.dirname(path.join(out, p)), {recursive: true});
  fs.writeFileSync(path.join(out, p), text);
};

const STORIES = ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro'];
for (const f of [...STORIES, 'cual-frente']) fs.copyFileSync(path.join(historia, 'cuentos', f + '.json'), path.join(out, 'cuentos', f + '.json'));
fs.copyFileSync(path.join(historia, 'libros/la-lluvia.json'), path.join(out, 'libros/la-lluvia.json'));

const datos = (f) => JSON.parse(read('datos/' + f));
fs.copyFileSync(path.join(historia, 'datos/fijos.json'), path.join(out, 'datos/fijos.json'));

const CURSO = datos('curso.json');
const casa = CURSO.lugares.find((l) => l.id === 'casa');
if (!casa.escenas.includes('El frente')) throw new Error('La casa is not El frente\'s place any more');
const curso = {
  lugares: [casa],
  cuentos: Object.fromEntries(STORIES.map((id) => [id, CURSO.cuentos[id]])),
  cual: ['cual-frente'],
};
write('datos/curso.json', JSON.stringify(curso, null, 2) + '\n');
write('datos/llamadas.json', JSON.stringify({casa: datos('llamadas.json').casa}, null, 2) + '\n');
const NV = datos('nivel.json').filter((q) => q.s <= 3);
write('datos/nivel.json', JSON.stringify(NV, null, 2) + '\n');

// Twenty clips: the first eight of story 1, then the first six new ones of stories 2 and 3.
const marcas = JSON.parse(read('audio/marcas.json'));
const files = STORIES.map((id) => JSON.parse(read('cuentos/' + id + '.json')));
const take = [8, 6, 6];
const clips = {};
files.forEach((s, k) => {
  let n = 0;
  for (const id of Object.keys(s.clips)) {
    if (n >= take[k]) break;
    if (clips[id]) continue;
    if (!marcas[id]) throw new Error('no marks for ' + id);
    clips[id] = marcas[id];
    n++;
  }
});
if (Object.keys(clips).length !== 20) throw new Error('twenty clips, not ' + Object.keys(clips).length);
write('audio/marcas.json', '{\n' + Object.entries(clips).map(([id, m]) => `  ${JSON.stringify(id)}: ${JSON.stringify(m).replace(/,/g, ', ')}`).join(',\n') + '\n}\n');
for (const f of fs.readdirSync(path.join(out, 'audio'))) if (f !== 'marcas.json') fs.unlinkSync(path.join(out, 'audio', f));

// ---------- the same files, as Dart strings ----------
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
const listed = [];
for (const dir of ['cuentos', 'libros', 'datos', 'audio']) {
  for (const f of fs.readdirSync(path.join(out, dir)).sort()) listed.push(dir + '/' + f);
}
let dart =
  '// Made by coqui/tool/contracts/make_sample.mjs from coqui_testing/sample/. Do not edit by hand.\n' +
  '// Re-run: cd coqui && node tool/contracts/make_sample.mjs && dart format packages/core/coqui_testing\n\n' +
  '/// Every file of the sample course, by its path under sample/, exactly as the file is.\n' +
  'const Map<String, String> sampleFiles = {\n';
for (const p of listed) dart += `  '${p}': ${dartString(fs.readFileSync(path.join(out, p), 'utf8'))},\n`;
dart += '};\n';
fs.writeFileSync(path.join(coqui, 'packages/core/coqui_testing/lib/src/sample_files.dart'), dart);

console.log('sample course: ' + STORIES.length + ' stories, cual-frente, 1 book, ' + Object.keys(clips).length + ' clips, ' + NV.length + ' level items');
