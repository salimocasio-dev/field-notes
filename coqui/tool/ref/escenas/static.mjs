// ref/escenas: reading a scene file as text. Function ranges, the screen positions written in it outside its background function and its
// sprite makers, and which W keys each act writes. Nothing here runs the scene.

// the code with strings, comments and regular expressions blanked (same length, same lines), so braces and numbers can be found
export function blank(t) {
  let o = "", i = 0, prev = "";
  while (i < t.length) {
    const ch = t[i], nx = t[i + 1];
    if (ch === "/" && nx === "/") { while (i < t.length && t[i] !== "\n") { o += " "; i++; } continue; }
    if (ch === "/" && nx === "*") { while (i < t.length && !(t[i] === "*" && t[i + 1] === "/")) { o += t[i] === "\n" ? "\n" : " "; i++; } o += "  "; i += 2; continue; }
    if (ch === '"' || ch === "'" || ch === "`") { const q = ch; o += q; i++; while (i < t.length && t[i] !== q) { if (t[i] === "\\") { o += "  "; i += 2; continue; } o += t[i] === "\n" ? "\n" : "_"; i++; } o += q; i++; prev = q; continue; }
    if (ch === "/" && /[(,=:[!&|?{};]/.test(prev)) { o += "/"; i++; while (i < t.length && t[i] !== "/") { if (t[i] === "\\") { o += "  "; i += 2; continue; } if (t[i] === "[") { while (i < t.length && t[i] !== "]") { o += " "; i++; } } o += " "; i++; } o += "/"; i++; prev = "/"; continue; }
    o += ch; if (!/\s/.test(ch)) prev = ch; i++;
  }
  return o;
}
const lineAt = (t, i) => { let n = 1; for (let k = 0; k < i; k++) if (t.charCodeAt(k) === 10) n++; return n; };

// every named function: function NAME(...){...}, NAME=(...)=>{...}, NAME:(...)=>{...}, async NAME(...){...} (methods in acts)
export function functions(text) {
  const b = blank(text), out = [];
  const re = /(?:\bfunction\s+([A-Za-z_$][\w$]*)\s*\(|(?:\b|^)([A-Za-z_$][\w$]*)\s*[=:]\s*(?:async\s*)?(?:\([^()]*\)|[A-Za-z_$][\w$]*)\s*=>\s*\{|\basync\s+([A-Za-z_$][\w$]*)\s*\([^()]*\)\s*\{)/g;
  let m;
  while ((m = re.exec(b))) {
    const name = m[1] || m[2] || m[3];
    let i = b.indexOf("{", m[1] ? b.indexOf(")", m.index) : m.index + m[0].length - 1);
    if (i < 0) continue;
    let d = 0, j = i;
    for (; j < b.length; j++) { if (b[j] === "{") d++; else if (b[j] === "}") { d--; if (!d) break; } }
    out.push({ name, start: m.index, end: j, line0: lineAt(text, m.index), line1: lineAt(text, j) });
  }
  return out;
}

// what an array literal at i belongs to: the key or name it is assigned to, or the call it is an argument of; [] for each list it sits in
function ownerOf(bl, i) {
  const parts = [], key = p => { const k = /([A-Za-z_$][\w$.]*)\s*[:=]\s*$/.exec(p); return k ? k[1] : null; };
  const k0 = key(bl.slice(0, i)); if (k0) parts.unshift(k0);
  let d = 0;
  for (let j = i - 1; j >= 0; j--) {
    const ch = bl[j];
    if (")]}".includes(ch)) { d++; continue; }
    if (!"([{".includes(ch)) continue;
    if (d) { d--; continue; }
    const pre = bl.slice(0, j);
    if (ch === "(") { const call = /([A-Za-z_$][\w$.]*)\s*$/.exec(pre); if (call) parts.unshift(call[1] + "(…)"); break; }
    if (ch === "[") { if (!parts.length || !/^\[\]/.test(parts[0])) parts.unshift("[]"); const k = key(pre); if (k) { parts.unshift(k); } continue; }
    const k = key(pre); if (k) parts.unshift(k); else break;
  }
  return parts.length ? parts.join(".").replace(/\.\[\]/g, "[]") : null;
}
// the screen positions written as numbers in the file, outside the given excluded ranges (background function, sprite makers)
const NUM = "-?(?:\\d+(?:\\.\\d+)?|\\.\\d+)";
export function positions(text, exclude) {
  const b = blank(text), lines = text.split("\n"), blines = b.split("\n"), fns = functions(text), out = [];
  const inside = i => exclude.some(r => i >= r.start && i <= r.end);
  const enclosing = i => { let best = null; for (const f of fns) if (i >= f.start && i <= f.end && (!best || f.start >= best.start)) best = f; return best; };
  let off = 0;
  for (let L = 0; L < blines.length; L++) {
    const bl = blines[L], src = lines[L], base = off; off += bl.length + 1;
    const comment = (/\/\/\s*(.*)$/.exec(src) || [])[1] || null;
    const push = (col, kind, nums, what) => { const i = base + col; if (inside(i)) return; const f = enclosing(i); out.push({ line: L + 1, fn: f ? f.name : null, kind, nums, what, comment }); };
    // arrays of 2 to 4 numbers, with the name or key in front of them
    let m; const ra = new RegExp(`\\[\\s*(${NUM})\\s*,\\s*(${NUM})(?:\\s*,\\s*(${NUM}))?(?:\\s*,\\s*(${NUM}))?\\s*\\]`, "g");
    while ((m = ra.exec(bl))) { const nums = m.slice(1).filter(x => x != null).map(Number);
      push(m.index, nums.length === 4 ? "rect" : nums.length === 3 ? "point+" : "point", nums, ownerOf(bl, m.index)); }
    // {x:N, y:N}
    const ro = new RegExp(`\\bx\\s*:\\s*(${NUM})\\s*,\\s*y\\s*:\\s*(${NUM})`, "g");
    while ((m = ro.exec(bl))) push(m.index, "xy", [+m[1], +m[2]], "x:,y:");
    // calls with two or more number literals among their arguments
    const rc = /([A-Za-z_$][\w$.]*)\s*\(/g;
    while ((m = rc.exec(bl))) {
      const name = m[1]; if (/^(Math\.|R$|spr$|if$|for$|while$|function$|Object\.|JSON\.|Array\.|String$|Number$|setTimeout$|wait$|tone$|sleep$|forEach$|map$|filter$|slice$|push$|find$|some$|every$|includes$|indexOf$|join$|split$|replace$|toFixed$|abs$|floor$|round$|min$|max$|hypot$|sin$|cos$)/.test(name.replace(/^.*\./, "")) && !/^(KIT\.)/.test(name)) continue;
      let d = 0, j = m.index + m[0].length - 1, args = [], cur = "", st = j + 1;
      for (; j < bl.length; j++) { const ch = bl[j]; if ("([{".includes(ch)) { d++; if (d > 1) cur += ch; continue; } if (")]}".includes(ch)) { d--; if (!d) { args.push(cur); break; } cur += ch; continue; } if (ch === "," && d === 1) { args.push(cur); cur = ""; continue; } cur += ch; }
      const isLit = a => new RegExp(`^${NUM}$`).test((a || "").trim()), short = name.replace(/^.*\./, "");
      if (/^mk[A-Z]/.test(short)) continue;   // a sprite maker's own parameters (scale, frame), not a place
      const SLOTS = { fr: [[1, 2]], fillRect: [[0, 1]], rect: [[0, 1]], clearRect: [[0, 1]], strokeRect: [[0, 1]], arc: [[0, 1]], ellipse: [[0, 1]], translate: [[0, 1]], moveTo: [[0, 1]], lineTo: [[0, 1]],
        drawImage: args.length >= 9 ? [[1, 2], [5, 6]] : [[1, 2]], hopTo: [[0, 1]], aveA: [[0, 1]], aveVa: [[0, 1]], tenida: [[2, 3]], cosa: [[2, 3]], bub: [[2, 3]], bub2: [[2, 3]], luna: [[1, 2]], sol: [[1, 2]], mano: [[1, 2]], tarjeta: [[1, 2]], heart: [[1, 2]], star: [[1, 2]], hand: [[1, 2]], vaso: [[1, 2]], jarra: [[1, 2]], medio: [[1, 2]], abanico: [[1, 2]], bizcocho: [[1, 2]], trozo: [[1, 2]], plato: [[1, 2]], dish: [[1, 2]] };
      const slot = Object.hasOwn(SLOTS, short) ? SLOTS[short] : null;   // (a call named like an Object member, toString( or constructor(, has no slots)
      let pairs = slot;
      if (!pairs) { pairs = []; for (let k = 0; k + 1 < args.length; k++) if (isLit(args[k]) && isLit(args[k + 1])) { pairs.push([k, k + 1]); k++; } }
      const sk = /spr\(\s*"([^"]*)"/.exec(src.slice(m.index, m.index + 160));
      for (const [i0, i1] of pairs) if (isLit(args[i0]) && isLit(args[i1])) {
        const four = slot && isLit(args[i1 + 1]) && isLit(args[i1 + 2]) && /^(fr|fillRect|rect|clearRect|strokeRect)$/.test(short);
        push(m.index, four ? "rect" : "point", four ? [+args[i0], +args[i1], +args[i1 + 1], +args[i1 + 2]] : [+args[i0], +args[i1]], `${name}(${args.map(a => a.trim().length > 18 ? "…" : a.trim()).join(",")})` + (sk ? ` [sprite "${sk[1]}"]` : "") + ` args ${i0},${i1}`);
      }
    }
  }
  return out;
}

// the W keys an act's source writes (W.k = ..., W.k.x = ..., W.k++ ...): what the code says, not what was seen
export function writes(src) {
  const b = blank(src), s = new Set();
  const re = /\bW\.([A-Za-z_$][\w$]*)((?:\s*(?:\.[A-Za-z_$][\w$]*|\[[^\]]*\]))*)\s*(=(?!=)|\+\+|--|[+\-*\/|&]=)/g; let m;
  while ((m = re.exec(b))) s.add(m[1]);
  const re2 = /(\+\+|--)\s*W\.([A-Za-z_$][\w$]*)/g; while ((m = re2.exec(b))) s.add(m[2]);
  const re3 = /Object\.assign\(\s*W\s*,/g; if (re3.test(b)) s.add("(Object.assign W)");
  return [...s].sort();
}
