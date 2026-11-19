// What llamada.js records, for the scripts the Dart tests play: the expected values of the test "the words recorded as
// mouth answers", from the old code itself.
//
//   node tool/llamada_expected.mjs            writes test/fixtures/llamada_expected.json
//   node tool/llamada_expected.mjs --check    compares it with what the old code gives now (exit 1 if they differ)
//
// It serves the worktree at /field-notes/ (as the live site is), opens historia/app.html with the page's own call stub
// (?callstub=1&stub=manual), in the progress state "todo" of coqui/ref/pantallas/seeds (every story of La casa played),
// taps the open "Call Danny" card and the call disc, and for each script feeds the learner's lines to the stub's own
// message callback (CallStub.o.onMessage), as the reference pictures' script does. Every call to PAL.responde is
// recorded, and what the page then says it heard (Llamada.dicho) and sent (CallStub.sent). Nothing leaves the machine:
// every request that is not to the local server is refused, so the voice library never loads and no call is placed.
//
// The result is the same on every run (byte for byte): no time is written, and a speaking turn's `ms` is written only as
// "null" (no turn was open) or "int" (a turn had begun when the line came), because the page's own ms depend on the
// moment.
//
// Needs Node 22 and the pre-installed Playwright.

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../../../..');
const outFile = path.resolve(here, '../test/fixtures/llamada_expected.json');
const check = process.argv.includes('--check');

// The scripts: the learner's lines, in order. A step is a line ("say"), or the stub's own step ("go").
// Every Dart test plays these same scripts (test/llamada_expected_test.dart reads them from the result file).
const SCRIPTS = [
  { name: 'the stub walk', steps: [{ go: 'danny1' }, { go: 'you1' }, { say: 'Hola. Bien, gracias.' }, { go: 'danny2' }, { go: 'you2' }, { say: 'Sí, quiero jugo.' }, { go: 'you3' }, { say: 'Adiós.' }] },
  { name: 'accents, capitals and punctuation', steps: [{ say: '¿CÓMO ESTÁS? Me llamo Ana.' }, { say: 'mamá, PAPÁ y el abuelo' }, { say: 'La niña y el niño juegan.' }] },
  { name: 'words only on their boundaries', steps: [{ say: 'Las casas son grandes' }, { say: 'abuelos, solamente' }, { say: 'la casa grande' }] },
  { name: 'a word said twice is recorded once', steps: [{ say: 'hola hola hola' }, { say: 'Hola, abuela' }, { say: 'abuela, hola' }] },
  { name: 'the page\'s own messages are not his words', steps: [{ say: '(ayuda)' }, { say: '(fin) hola' }, { say: '  (casa)' }, { say: 'puerta' }] },
  { name: 'a phrase of two words', steps: [{ say: 'me llamo' }, { say: 'me  llamo Ana, tengo sed' }, { say: 'hasta mañana' }] },
  { name: 'a speaking turn is open when the line comes', steps: [{ go: 'danny1' }, { go: 'you1' }, { go: 'talk1' }, { wait: 600 }, { go: 'quiet1' }, { say: 'gracias' }] },
  { name: 'nothing of the place', steps: [{ say: 'buenas tardes' }, { say: 'xyz' }] },
  { name: 'Danny\'s goodbye is not the learner\'s', steps: [{ agent: 'Sí. Hasta mañana.' }, { say: 'bien' }] },
];

const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.mp3': 'audio/mpeg', '.txt': 'text/plain; charset=utf-8', '.css': 'text/css' };
function serve() {
  return new Promise((res) => {
    const s = http.createServer((rq, rs) => {
      const u = decodeURIComponent(rq.url.split('?')[0]);
      if (!u.startsWith('/field-notes/')) { rs.writeHead(404); rs.end(); return; }
      let f = path.join(repo, u.slice('/field-notes/'.length));
      if (!f.startsWith(repo)) { rs.writeHead(403); rs.end(); return; }
      if (f.endsWith('/')) f += 'index.html';
      fs.readFile(f, (e, b) => {
        if (e) { rs.writeHead(404); rs.end('not found'); return; }
        rs.writeHead(200, { 'content-type': MIME[path.extname(f)] || 'application/octet-stream', 'cache-control': 'no-store' });
        rs.end(b);
      });
    });
    s.listen(0, '127.0.0.1', () => res({ server: s, port: s.address().port }));
  });
}

const seed = fs.readFileSync(path.join(repo, 'coqui/ref/pantallas/seeds/todo.json'), 'utf8');
const { server, port } = await serve();
const browser = await chromium.launch({ args: ['--mute-audio', '--autoplay-policy=no-user-gesture-required'] });
const real = (ms) => new Promise((r) => setTimeout(r, ms));

async function play(script) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, locale: 'en-US', serviceWorkers: 'block' });
  await ctx.addInitScript(`try{if(!localStorage.getItem('coqui.palabras.v1'))localStorage.setItem('coqui.palabras.v1',${JSON.stringify(seed)})}catch(e){}`);
  await ctx.route((url) => !/^http:\/\/127\.0\.0\.1[:/]/.test(url.href), (r) => r.abort());
  const pg = await ctx.newPage();
  const errors = [];
  pg.on('pageerror', (e) => errors.push(String(e)));
  await pg.goto(`http://127.0.0.1:${port}/field-notes/historia/app.html?tab=hablar&callstub=1&stub=manual`);
  await pg.waitForFunction('window.App&&App.ready', null, { timeout: 30000 });
  await real(300);
  await pg.evaluate("window.__calls=[];const o=PAL.responde;PAL.responde=function(...a){window.__calls.push(a);return o.apply(this,a);};0");
  await pg.click('#t-hablar .card.cc >> nth=0');
  await pg.waitForFunction('Llamada.activo', null, { timeout: 5000 });
  await pg.click('#llam .ldisc');
  await pg.waitForFunction("Llamada.estado==='connecting'&&!!CallStub.opts", null, { timeout: 5000 });
  const vars = await pg.evaluate('CallStub.opts.dynamicVariables');
  await pg.evaluate("CallStub.go('connect')");
  await real(150);
  for (const s of script.steps) {
    if (s.go) { await pg.evaluate((n) => CallStub.go(n), s.go); await real(150); }
    else if (s.say !== undefined) { await pg.evaluate((t) => CallStub.o.onMessage({ role: 'user', source: 'user', message: t }), s.say); await real(80); }
    else if (s.agent !== undefined) { await pg.evaluate((t) => CallStub.o.onMessage({ role: 'agent', source: 'ai', message: t }), s.agent); await real(80); }
    else if (s.wait) await real(s.wait);
  }
  const r = await pg.evaluate(() => ({ calls: window.__calls, said: Llamada.dicho, sent: CallStub.sent.slice() }));
  await ctx.close();
  if (errors.length) throw new Error('page errors: ' + errors.join(' | '));
  return {
    name: script.name,
    steps: script.steps,
    answers: r.calls.map((c) => [c[0], c[1], c[2], c[3] === null || c[3] === undefined ? 'null' : Number.isInteger(c[3]) ? 'int' : 'other']),
    said: r.said,
    sent: r.sent,
    vars,
  };
}

const results = [];
try {
  for (const s of SCRIPTS) results.push(await play(s));
} finally {
  await browser.close();
  server.close();
}
const words = results[0].vars.words_open.split(', ');
const doc = {
  about: 'What historia/llamada.js records for each script, made by tool/llamada_expected.mjs. Do not edit.',
  variables: { place: results[0].vars.place, job: results[0].vars.job, minutes: results[0].vars.minutes, opening: results[0].vars.opening, words_open: words, words_heard: results[0].vars.words_heard, keys: Object.keys(results[0].vars) },
  scripts: results.map(({ vars, ...r }) => r),
};
const text = JSON.stringify(doc, null, 2) + '\n';
if (check) {
  const same = fs.existsSync(outFile) && fs.readFileSync(outFile, 'utf8') === text;
  console.log(same ? 'llamada_expected.json is current' : 'llamada_expected.json is NOT current');
  process.exit(same ? 0 : 1);
}
fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, text);
console.log(`wrote ${outFile}: ${results.length} scripts, ${results.reduce((n, r) => n + r.answers.length, 0)} answers`);
