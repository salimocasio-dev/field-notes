// juego.js placeBub (lines 144 to 148) reduced to its numbers, run in node: the expected values of test/bubble_place_test.dart.
//   node tool/ref/placebub.mjs > test/fixtures/placebub.json   (in this package)
const R = Math.round;
const frogBox = q => { const w = R(30 * q.s) + 2, h = R(25 * q.s) + 2; return { x: R(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };
function place(c) {
  const { who, cam, cw, ch, bw, bh, q, at, mr, sr, innerWidth } = c;
  if (who === "mic") {
    const cx = mr.left + mr.width / 2 - sr.left, l = Math.max(bw / 2 + 4 - sr.left, Math.min(innerWidth - sr.left - bw / 2 - 4, cx));
    return { left: R(l), top: R(mr.top - sr.top - 24), mode: "above", tail: R(Math.max(14, Math.min(bw - 14, cx - l + bw / 2))) };
  }
  if (!at) return null;
  const X = v => (v - cam[0]) / cam[2] * cw, Y = v => (v - cam[1]) / cam[3] * ch;
  if (who === "coqui") {
    const b = frogBox(q), xr = X(b.x + b.w) + 4, xl = X(b.x) - 4, y = Y(b.y + b.h * .45 + R(q.dy)), rR = cw - xr - 18, rL = xl - 18, right = rR >= rL, room = Math.min(right ? rR : rL, cw * .72);
    if (room >= 110) return { left: R(right ? xr + 12 : xl - 12), top: R(Math.max(bh / 2 + 4, Math.min(ch - bh / 2 - 4, y))), mode: right ? "right" : "left", maxWidth: Math.floor(room) };
  }
  const x = X(at[0]), y = Y(at[1]), l = Math.max(bw / 2 + 4, Math.min(cw - bw / 2 - 4, x));
  return { left: R(l), top: R(Math.max(bh + 4, y)), mode: "above", tail: R(Math.max(14, Math.min(bw - 14, x - l + bw / 2))) };
}
const wide = [0, 0, 196, 216], close = [10, 10, 98, 108];
const cases = [
  { who: "coqui", cam: wide, cw: 380, ch: 419, bw: 120, bh: 44, q: { x: 150, y: 178, s: 1, dy: 0 }, at: [166, 158] },
  { who: "coqui", cam: wide, cw: 380, ch: 419, bw: 120, bh: 44, q: { x: 40, y: 178, s: 1, dy: -3.5 }, at: [56, 158] },
  { who: "coqui", cam: wide, cw: 380, ch: 419, bw: 60, bh: 45, q: { x: 96, y: 120, s: .62, dy: 0 }, at: [112, 102] },
  { who: "coqui", cam: close, cw: 380, ch: 419, bw: 150, bh: 62, q: { x: 40, y: 80, s: 1.2, dy: 0 }, at: [56, 60] },
  { who: "coqui", cam: wide, cw: 200, ch: 220, bw: 100, bh: 44, q: { x: 90, y: 150, s: 1, dy: 0 }, at: [106, 130] },
  { who: "abuela", cam: wide, cw: 380, ch: 419, bw: 140, bh: 50, q: { x: 150, y: 178, s: 1, dy: 0 }, at: [60, 70] },
  { who: "abuela", cam: close, cw: 380, ch: 419, bw: 140, bh: 50, q: { x: 150, y: 178, s: 1, dy: 0 }, at: [30, 12] },
  { who: "abuela", cam: wide, cw: 380, ch: 419, bw: 340, bh: 50, q: { x: 150, y: 178, s: 1, dy: 0 }, at: [190, 5] },
  { who: "mic", bw: 56, mr: { left: 170, top: 760, width: 72 }, sr: { left: 20, top: 222 }, innerWidth: 412 },
  { who: "mic", bw: 56, mr: { left: 10, top: 760, width: 72 }, sr: { left: 20, top: 222 }, innerWidth: 412 },
  { who: "mic", bw: 120, mr: { left: 350, top: 760, width: 72 }, sr: { left: 20, top: 222 }, innerWidth: 412 },
];
console.log(JSON.stringify(cases.map(c => ({ in: c, out: place(c) }))));
