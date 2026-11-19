// Order 02: the sample course of coqui_testing, from the old files.
//
//   cd coqui && node tool/contracts/make_sample.mjs
//
// Writes packages/core/coqui_testing/sample/:
//   cuentos/   la-lluvia, el-bizcocho, donde-esta-el-pajaro (stories 1 to 3) and cual-frente, copied byte for byte
//   libros/    la-lluvia, copied byte for byte
//   datos/curso.json      CURSO (curso.js) with only La casa (El frente's place) and the entries of stories 1 to 3
//   datos/llamadas.json   LLAMADAS (llamada.js): La casa's call
//   datos/nivel.json      NV (nivel.js): the items of stories 1 to 3 (s <= 3)
//   audio/clips.json      twenty clips of stories 1 to 3: {id: {who, text, habla?, marks: [startMs, endMs, lengthMs]}}.
//                         No audio. The marks are made up the way juego.js times a line it has no recording
//                         for (dur(): 360 ms a word + 300 ms): start 0, end and length that.
//
// Nothing in historia/ is changed. Run it again when one of those files changes.

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
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

const evalConst = (file, name) => {
  const text = read(file);
  const at = text.indexOf('const ' + name + '=');
  if (at < 0) throw new Error(name + ' is not in ' + file);
  const i = text.indexOf('=', at) + 1;
  const open = text[i];
  const close = open === '[' ? ']' : '}';
  let depth = 0;
  let j = i;
  for (; j < text.length; j++) {
    if (text[j] === open) depth++;
    else if (text[j] === close && --depth === 0) break;
  }
  return vm.runInNewContext('(' + text.slice(i, j + 1) + ')');
};

const CURSO = vm.runInNewContext(read('curso.js') + '\n;CURSO');
const casa = CURSO.lugares.find((l) => l.id === 'casa');
if (!casa.escenas.includes('El frente')) throw new Error('La casa is not El frente\'s place any more');
const curso = {
  lugares: [casa],
  cuentos: Object.fromEntries(STORIES.map((id) => [id, CURSO.cuentos[id]])),
  cual: ['cual-frente'],
};
write('datos/curso.json', JSON.stringify(curso, null, 1) + '\n');

const LLAMADAS = evalConst('llamada.js', 'LLAMADAS');
write('datos/llamadas.json', JSON.stringify({casa: LLAMADAS.casa}, null, 1) + '\n');

const NV = evalConst('nivel.js', 'NV');
write('datos/nivel.json', JSON.stringify(NV.filter((q) => q.s <= 3), null, 1) + '\n');

// Twenty clips: the first eight of story 1, then the first six new ones of stories 2 and 3.
const files = STORIES.map((id) => JSON.parse(read('cuentos/' + id + '.json')));
const take = [8, 6, 6];
const clips = {};
files.forEach((s, k) => {
  let n = 0;
  for (const [id, c] of Object.entries(s.clips)) {
    if (n >= take[k]) break;
    if (clips[id]) continue;
    const words = (c.text || 'x x').split(/\s+/).length; // juego.js: words(id)
    const ms = 360 * words + 300; // juego.js: dur(id), with no recording
    clips[id] = Object.assign({who: c.who, text: c.text}, c.habla ? {habla: c.habla} : {}, {marks: [0, ms, ms]});
    n++;
  }
});
if (Object.keys(clips).length !== 20) throw new Error('twenty clips, not ' + Object.keys(clips).length);
write('audio/clips.json', JSON.stringify(clips, null, 1) + '\n');

console.log('sample course: ' + STORIES.length + ' stories, cual-frente, 1 book, ' + Object.keys(clips).length + ' clips, ' + NV.filter((q) => q.s <= 3).length + ' level items');
