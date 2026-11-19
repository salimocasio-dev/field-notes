// The expected values of test/js_sort_test.dart: what Node 22's Array.prototype.sort does with the comparisons the
// old pages use (`() => Math.random() - .5`, cual.js and nivel.js) and with consistent comparisons on data with runs.
//
//   node tool/diff/sort_probe.mjs > test/fixtures/sort.json        (from this package; byte-identical every run)
//
// Mulberry32 is the generator of coqui_contracts (the same one the old pages' recorded runs use).

function mulberry32(a) {
  return function () {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// FNV-1a over a list of ints, so a long call sequence is one number.
function fnv(list) {
  let h = 0x811c9dc5;
  for (const x of list) {
    for (let k = 0; k < 4; k++) {
      h ^= (x >>> (8 * k)) & 255;
      h = Math.imul(h, 0x01000193) >>> 0;
    }
  }
  return h >>> 0;
}

const cases = [];

// 1. the old shuffle: a list 0..n-1 sorted with () => random() - .5
const lengths = [];
for (let n = 0; n <= 40; n++) lengths.push(n);
lengths.push(50, 63, 64, 65, 66, 70, 80, 96, 100, 127, 128, 129, 150, 200, 256, 300, 500);
for (const n of lengths) {
  const seeds = n <= 70 ? [1, 2, 3, 7, 42, 1234, 99999] : [1, 2, 3];
  for (const seed of seeds) {
    const rnd = mulberry32(seed);
    let calls = 0;
    const a = Array.from({ length: n }, (_, i) => i);
    a.sort(() => {
      calls++;
      return rnd() - 0.5;
    });
    cases.push({ kind: 'shuffle', n, seed, calls, result: n <= 130 ? a : undefined, hash: fnv(a) });
  }
}

// 2. consistent comparisons on data with runs, ties and long ordered stretches (merges and galloping): the whole
// sequence of calls (each pair as two ints) is hashed, so any difference in the order of the calls shows.
function structured(n, seed) {
  const rnd = mulberry32(seed);
  const out = [];
  while (out.length < n) {
    const len = 1 + Math.floor(rnd() * 40);
    const dir = rnd() < 0.5 ? 1 : -1;
    let v = Math.floor(rnd() * 1000);
    for (let i = 0; i < len && out.length < n; i++) {
      out.push(v);
      v += dir * Math.floor(rnd() * 3);
    }
  }
  return out;
}
for (const n of [10, 40, 64, 65, 100, 128, 200, 333, 500, 1000]) {
  for (const seed of [1, 2, 3, 4, 5]) {
    const data = structured(n, seed);
    // tag each element with its index so the (stable) result is unambiguous
    const items = data.map((v, i) => i);
    const seq = [];
    items.sort((x, y) => {
      seq.push(x, y);
      return data[x] - data[y];
    });
    cases.push({ kind: 'structured', n, seed, calls: seq.length / 2, calls_hash: fnv(seq), hash: fnv(items) });
  }
}

process.stdout.write(JSON.stringify({ node: process.version, cases }) + '\n');
