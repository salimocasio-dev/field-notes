// Embeds the places of the old course (historia/curso.js: CURSO.lugares) into this package as test data, so the dev
// entry and the tests have the ten places v=39 has, with their names and stories (the feature reads every name
// from the catalog; the fakes carry only La casa).
//
//   node tool/make_course.mjs          (in this package) writes test/support/course_places.dart
//   node tool/make_course.mjs --check  says whether that file is the one curso.js gives
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import vm from 'node:vm';

const src = '../../../../historia/curso.js';
const target = 'test/support/course_places.dart';
if (!existsSync(src)) {
  console.error('Run this in coqui/packages/features/feature_profile: ' + src + ' is not there.');
  process.exit(2);
}
const ctx = vm.createContext({});
vm.runInContext(readFileSync(src, 'utf8').replace('const CURSO=', 'var CURSO='), ctx);
const lugares = JSON.parse(JSON.stringify(ctx.CURSO.lugares));
const quote = (s) => "'" + s.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$').replace(/\n/g, '\\n') + "'";
const text = [
  '// Made by tool/make_course.mjs from historia/curso.js (CURSO.lugares). Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  '/// The ten places of the old course, as curso.js writes them (`Place.fromJson` reads this).',
  'const String coursePlacesJson = ' + quote(JSON.stringify(lugares)) + ';',
  '',
].join('\n');
if (process.argv.includes('--check')) {
  const same = existsSync(target) && readFileSync(target, 'utf8') === text;
  console.log(same ? target + ' is the places of curso.js, embedded.' : target + ' is NOT what curso.js gives: run `node tool/make_course.mjs`.');
  process.exit(same ? 0 : 1);
}
writeFileSync(target, text);
console.log('wrote ' + target + ' (' + lugares.length + ' places)');
