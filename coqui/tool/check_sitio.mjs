#!/usr/bin/env node
// Order 03's proof of the site build, brought up to date for the app of order 26: opens a build made by
// tool/build_sitio.sh in headless Chrome, served the way GitHub Pages serves it (the build under /field-notes/app/, the
// repository's own historia/ at /field-notes/historia/), at phone size.
//
//   node coqui/tool/check_sitio.mjs <build dir> [--shot=<png file>] [--build=<n>] [--static-only]
//
// --build is the build number the app was built with (COQUI_BUILD, the workflow reads it from coqui/BUILD); without
// it, the number in coqui/BUILD. Pass --build=dev for a build made without COQUI_BUILD.
// --static-only runs the static build checks (filename rules, no service worker, and built-JS/HTML external host
// allowlist audit) without launching Chromium or requiring Playwright.
//
// Serves <build dir> on a free port of 127.0.0.1 at /field-notes/app/, and every other /field-notes/... path from the
// repository this script is in (so the content the app reads is the real historia/). Playwright is installed globally
// on this machine; it is not a dependency of the repo. Checks, and exits 1 if any fails:
//   - the app starts: with the welcome done (the seed of coqui/ref/pantallas/seeds/vacio.json in localStorage, as
//     check_app.mjs does) it opens on the map: the address is #/tab/map, the tab bar's five names are there, and the
//     map's place chip ("1 . La casa") is, all read from Flutter's accessibility tree; the screenshot is not blank
//   - it reads its content from /field-notes/historia/ (datos/curso.json, audio/ready.json, audio/marcas.json,
//     datos/prueba-voz.json: each asked for there and answered 200), and nothing from inside /field-notes/app/ but the
//     preview content bundled in the app (assets/assets/previa/: its overlay curso.json is asked for and answered 200)
//   - it shows the build number: the Yo tab (the only place the app shows it) says "build <n>"
//   - no console error or warning, no uncaught page error, no failed request
//   - no request leaves 127.0.0.1 (CanvasKit and the fonts come from the build itself)
//   - the manifest, every icon it names, and the favicon answer 200 and decode as pictures of the
//     size the manifest says
//   - no service worker is registered, and none was requested
//   - no file or folder name in the build starts with "_" or "." (GitHub Pages would drop it)
//   - no disallowed external URLs or outside script/worklet hosts in built JS/MJS or index.html <script src>
//   - index.html (the file) has <html lang="en" translate="no">, the notranslate meta, the old app's viewport
//     and theme-color; in the running page translate="no" and the notranslate meta are still there.
//     NOTE: the running page's `lang` and viewport are NOT the file's: Flutter's engine rewrites them at
//     start (lang = the app's locale; viewport = "width=device-width, initial-scale=1.0, maximum-scale=5.0"
//     plus viewport-fit). They are printed as INFO lines, not checked.
//   - console: an error fails; a warning fails except Chrome's own "GL Driver Message" notes, which the
//     headless software GPU prints
//   - both CanvasKit variants a dart2js + CanvasKit build loads work: the Chromium one
//     (canvaskit/chromium/, what Chrome loads) and the full one (canvaskit/, what Safari and Firefox
//     load). Only Chromium is installed here, so the second pass hides Intl.v8BreakIterator, which is
//     what makes the loader choose the full variant. Each pass must open the map and show the build number,
//     answer 200 to every request, send none outside 127.0.0.1, print no error, and request the variant it should.
// The screenshot is phone size (390 x 844), deviceScaleFactor 1.
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

// ---- static built-JS external host allowlist ------------------------------------------------------------

// Explicitly empty: zero permanent outside script/worklet hosts, matching #180's CSP
// (`script-src 'self' 'wasm-unsafe-eval' blob:`, `worker-src 'self' blob:`).
export const ALLOWED_SCRIPT_HOSTS = new Set([]);

// Vendored @elevenlabs/client@1.25.0 (coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js)
// falls back to this URL for non-16 kHz microphones.
// #180's CSP (`script-src 'self' 'wasm-unsafe-eval' blob:`, `worker-src 'self' blob:`) blocks loading
// worklets from cdn.jsdelivr.net.
// Temporary exact-URL exception only until
// coqui/requests/253-tool-needs-coqui-platform-self-host-libsamplerate-worklet.md lands in
// coqui_platform; remove this entry then so #180's CSP and check_sitio.mjs agree on zero outside
// script/worklet hosts.
export const TEMPORARY_ALLOWED_SCRIPT_URLS = new Set([
  'https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js',
]);

// Allowed ONLY in flutter_bootstrap.js and flutter.js, AND ONLY when flutter_bootstrap.js exists in
// the build directory and its _flutter.buildConfig has useLocalCanvasKit === true.
export const ALLOWED_FLUTTER_LOADER_URLS = new Set([
  'https://www.gstatic.com/flutter-canvaskit',
]);

export const ALLOWED_NON_SCRIPT_EXACT_URLS = new Set([
  'https://api.elevenlabs.io', // ElevenLabs REST API origin, matches #180 CSP connect-src
  'https://salimocasio-dev.github.io/field-notes/app/', // Coquí's fallback base URL in browser_io.dart
  'https://fonts.gstatic.com/s/', // Flutter engine default fontFallbackBaseUrl string
  'https://aomediacodec.github.io/av1-rtp-spec/#dependency-descriptor-rtp-header-extension', // RTP header extension URI constant in lib.iife.js
  'https://github.com/rochars/wavefile/blob/master/lib/codecs/mulaw.js', // License/attribution comment embedded inside lib.iife.js's inline AudioWorklet template strings
  'https://web.dev/articles/coop-coep', // Flutter loader doc link
  'https://wicg.github.io/cross-origin-storage/', // Flutter loader doc link
]);

export const ALLOWED_NON_SCRIPT_URL_PREFIXES = [
  'https://api.flutter.dev/',
  'https://docs.flutter.dev/',
  'https://flutter.dev/',
  'https://pub.dev/',
  'https://github.com/flutter/flutter/issues/',
];

function normalizeCandidateUrl(raw) {
  const withScheme = raw.startsWith('//') ? `https:${raw}` : raw;
  const parsed = new URL(withScheme);
  return { parsed, href: parsed.href };
}

const NORMALIZED_TEMP_SCRIPT_URLS = new Set([...TEMPORARY_ALLOWED_SCRIPT_URLS].map((u) => normalizeCandidateUrl(u).href));
const NORMALIZED_FLUTTER_LOADER_URLS = new Set([...ALLOWED_FLUTTER_LOADER_URLS].map((u) => normalizeCandidateUrl(u).href));
const NORMALIZED_NON_SCRIPT_EXACT_URLS = new Set([...ALLOWED_NON_SCRIPT_EXACT_URLS].map((u) => normalizeCandidateUrl(u).href));
const NORMALIZED_NON_SCRIPT_URL_PREFIXES = ALLOWED_NON_SCRIPT_URL_PREFIXES.map((u) => normalizeCandidateUrl(u).href);
const NORMALIZED_SCRIPT_HOSTS = new Set([...ALLOWED_SCRIPT_HOSTS].map((h) => h.toLowerCase()));

const REGEX_PRECEDING_KEYWORDS = new Set([
  'return', 'case', 'throw', 'typeof', 'void', 'delete',
  'in', 'instanceof', 'new', 'of', 'yield', 'await', 'else', 'do',
]);
const CONTROL_FLOW_PARENS = new Set(['if', 'while', 'for', 'with']);
const REGEX_PRECEDING_PUNCT = new Set([
  '=', '(', ',', '[', '{', ':', ';', '!', '&', '|', '?', '+', '-', '*', '%', '^', '~', '<', '>',
]);

function decodeJsEscape(src, idx) {
  // idx points to '\'
  if (idx + 1 >= src.length) return { text: '', next: idx + 1 };
  const c = src[idx + 1];
  if (c === '\n') return { text: '', next: idx + 2 };
  if (c === '\r') return { text: '', next: src[idx + 2] === '\n' ? idx + 3 : idx + 2 };
  if (c === 'n') return { text: '\n', next: idx + 2 };
  if (c === 'r') return { text: '\r', next: idx + 2 };
  if (c === 't') return { text: '\t', next: idx + 2 };
  if (c === 'b') return { text: '\b', next: idx + 2 };
  if (c === 'f') return { text: '\f', next: idx + 2 };
  if (c === 'v') return { text: '\v', next: idx + 2 };
  if (c === 'x') {
    const hex = src.slice(idx + 2, idx + 4);
    if (/^[0-9a-fA-F]{2}$/.test(hex)) {
      return { text: String.fromCharCode(parseInt(hex, 16)), next: idx + 4 };
    }
    return { text: 'x', next: idx + 2 };
  }
  if (c === 'u') {
    if (src[idx + 2] === '{') {
      const end = src.indexOf('}', idx + 3);
      if (end !== -1) {
        const hex = src.slice(idx + 3, end);
        if (/^[0-9a-fA-F]+$/.test(hex)) {
          const cp = parseInt(hex, 16);
          if (cp <= 0x10ffff) {
            return { text: String.fromCodePoint(cp), next: end + 1 };
          }
        }
      }
    } else {
      const hex = src.slice(idx + 2, idx + 6);
      if (/^[0-9a-fA-F]{4}$/.test(hex)) {
        return { text: String.fromCharCode(parseInt(hex, 16)), next: idx + 6 };
      }
    }
    return { text: 'u', next: idx + 2 };
  }
  if (c >= '0' && c <= '7') {
    let oct = c;
    let end = idx + 2;
    while (end < src.length && oct.length < 3 && src[end] >= '0' && src[end] <= '7') {
      const nextOct = oct + src[end];
      if (parseInt(nextOct, 8) > 255) break;
      oct = nextOct;
      end++;
    }
    return { text: String.fromCharCode(parseInt(oct, 8)), next: end };
  }
  return { text: c, next: idx + 2 };
}

function isIdentStart(ch) {
  return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch === '_' || ch === '$';
}

function isIdentPart(ch) {
  return isIdentStart(ch) || (ch >= '0' && ch <= '9');
}

export function extractJsStringLiterals(src) {
  const literals = [];
  const templateStack = [];
  const parenStack = [];
  let canPrecedeRegex = true;
  let prevWasDot = false;
  let lastWord = '';
  let i = 0;

  const scanTemplateChunk = () => {
    let buf = '';
    while (i < src.length) {
      const ch = src[i];
      if (ch === '`') {
        literals.push(buf);
        i++;
        canPrecedeRegex = false;
        prevWasDot = false;
        lastWord = '';
        return;
      }
      if (ch === '$' && src[i + 1] === '{') {
        literals.push(buf);
        i += 2;
        templateStack.push(0);
        canPrecedeRegex = true;
        prevWasDot = false;
        lastWord = '';
        return;
      }
      if (ch === '\\') {
        const esc = decodeJsEscape(src, i);
        buf += esc.text;
        i = esc.next;
        continue;
      }
      buf += ch;
      i++;
    }
    literals.push(buf);
  };

  while (i < src.length) {
    const ch = src[i];

    // Whitespace
    if (ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r' || ch === '\f' || ch === '\v') {
      i++;
      continue;
    }

    // Comments
    if (ch === '/' && src[i + 1] === '/') {
      i += 2;
      while (i < src.length && src[i] !== '\n' && src[i] !== '\r') i++;
      continue;
    }
    if (ch === '/' && src[i + 1] === '*') {
      i += 2;
      while (i < src.length && !(src[i] === '*' && src[i + 1] === '/')) i++;
      if (i < src.length) i += 2;
      continue;
    }

    // Regex literal
    if (ch === '/' && canPrecedeRegex) {
      i++;
      let inClass = false;
      while (i < src.length) {
        const r = src[i];
        if (r === '\\') {
          i += i + 1 < src.length ? 2 : 1;
          continue;
        }
        if (r === '[') {
          inClass = true;
          i++;
          continue;
        }
        if (r === ']' && inClass) {
          inClass = false;
          i++;
          continue;
        }
        if (r === '/' && !inClass) {
          i++;
          while (i < src.length && ((src[i] >= 'a' && src[i] <= 'z') || (src[i] >= 'A' && src[i] <= 'Z'))) i++;
          break;
        }
        if (r === '\n' || r === '\r') {
          break;
        }
        i++;
      }
      canPrecedeRegex = false;
      prevWasDot = false;
      lastWord = '';
      continue;
    }

    // Quoted strings
    if (ch === "'" || ch === '"') {
      const quote = ch;
      i++;
      let buf = '';
      while (i < src.length) {
        const s = src[i];
        if (s === quote) {
          i++;
          break;
        }
        if (s === '\\') {
          const esc = decodeJsEscape(src, i);
          buf += esc.text;
          i = esc.next;
          continue;
        }
        if (s === '\n' || s === '\r') {
          break;
        }
        buf += s;
        i++;
      }
      literals.push(buf);
      canPrecedeRegex = false;
      prevWasDot = false;
      lastWord = '';
      continue;
    }

    // Template literal
    if (ch === '`') {
      i++;
      scanTemplateChunk();
      continue;
    }

    // Parentheses tracking for regex literals after control-flow parens
    if (ch === '(') {
      parenStack.push(CONTROL_FLOW_PARENS.has(lastWord) ? 'control' : 'expr');
      lastWord = '';
      prevWasDot = false;
      canPrecedeRegex = true;
      i++;
      continue;
    }
    if (ch === ')') {
      const kind = parenStack.pop();
      canPrecedeRegex = kind === 'control';
      lastWord = '';
      prevWasDot = false;
      i++;
      continue;
    }

    // Brace tracking for template literal ${...}
    if (ch === '{') {
      if (templateStack.length > 0) {
        templateStack[templateStack.length - 1]++;
      }
      i++;
      canPrecedeRegex = true;
      prevWasDot = false;
      lastWord = '';
      continue;
    }
    if (ch === '}') {
      if (templateStack.length > 0) {
        if (templateStack[templateStack.length - 1] === 0) {
          templateStack.pop();
          i++;
          scanTemplateChunk();
          continue;
        }
        templateStack[templateStack.length - 1]--;
      }
      i++;
      canPrecedeRegex = false;
      prevWasDot = false;
      lastWord = '';
      continue;
    }

    // Identifiers and keywords
    if (isIdentStart(ch)) {
      const start = i;
      i++;
      while (i < src.length && isIdentPart(src[i])) i++;
      const word = src.slice(start, i);
      canPrecedeRegex = !prevWasDot && REGEX_PRECEDING_KEYWORDS.has(word);
      lastWord = prevWasDot ? '' : word;
      prevWasDot = false;
      continue;
    }

    // Numbers
    if (ch >= '0' && ch <= '9') {
      i++;
      while (i < src.length && (isIdentPart(src[i]) || src[i] === '.')) i++;
      canPrecedeRegex = false;
      prevWasDot = false;
      lastWord = '';
      continue;
    }

    // ++ and --
    if ((ch === '+' && src[i + 1] === '+') || (ch === '-' && src[i + 1] === '-')) {
      i += 2;
      canPrecedeRegex = false;
      prevWasDot = false;
      lastWord = '';
      continue;
    }

    prevWasDot = ch === '.';
    canPrecedeRegex = REGEX_PRECEDING_PUNCT.has(ch);
    lastWord = '';
    i++;
  }

  return literals;
}

const HTTP_URL_RE = /https?:\/\/[^\s"'`<>)}\],;]+/gi;
const PROTO_REL_URL_RE = /(?:^|[\s(["'])(\/\/[^\s"'`<>)}\],;]+)/g;

export function extractExternalUrlsFromJs(src) {
  const urls = [];
  for (const literal of extractJsStringLiterals(src)) {
    for (const match of literal.matchAll(HTTP_URL_RE)) {
      urls.push(match[0].replace(/[.,;)\]}]+$/, ''));
    }
    for (const match of literal.matchAll(PROTO_REL_URL_RE)) {
      const candidate = match[1].replace(/[.,;)\]}]+$/, '');
      const rest = candidate.slice(2);
      const sepIdx = rest.search(/[/?#]/);
      const authority = sepIdx === -1 ? rest : rest.slice(0, sepIdx);
      if (/[.%:\[]/.test(authority)) {
        urls.push(candidate);
      }
    }
  }
  return urls;
}

function parseFlutterBuildConfig(src) {
  const m = /_flutter\.buildConfig\s*=\s*\{/.exec(src);
  if (!m) return null;
  const start = m.index + m[0].length - 1;
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = start; i < src.length; i++) {
    const ch = src[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch === '\\') {
        escaped = true;
      } else if (ch === '"') {
        inString = false;
      }
      continue;
    }
    if (ch === '"') {
      inString = true;
    } else if (ch === '{') {
      depth++;
    } else if (ch === '}') {
      depth--;
      if (depth === 0) {
        return JSON.parse(src.slice(start, i + 1));
      }
    }
  }
  return null;
}

function collectJsFiles(rootDir) {
  const files = [];
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (entry.isFile() && (entry.name.endsWith('.js') || entry.name.endsWith('.mjs'))) {
        files.push(path.relative(rootDir, full).split(path.sep).join('/'));
      }
    }
  };
  walk(rootDir);
  files.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  return files;
}

function validateJsUrl(rawUrl, relPath, localCanvasKitConfirmed) {
  let parsed;
  let href;
  try {
    ({ parsed, href } = normalizeCandidateUrl(rawUrl));
  } catch {
    return 'invalid external URL';
  }

  if (NORMALIZED_TEMP_SCRIPT_URLS.has(href)) return null;
  if (NORMALIZED_SCRIPT_HOSTS.has(parsed.host.toLowerCase()) || NORMALIZED_SCRIPT_HOSTS.has(parsed.hostname.toLowerCase())) {
    return null;
  }
  if (
    (relPath === 'flutter_bootstrap.js' || relPath === 'flutter.js') &&
    localCanvasKitConfirmed &&
    NORMALIZED_FLUTTER_LOADER_URLS.has(href)
  ) {
    return null;
  }
  if (NORMALIZED_NON_SCRIPT_EXACT_URLS.has(href)) return null;
  if (NORMALIZED_NON_SCRIPT_URL_PREFIXES.some((prefix) => href.startsWith(prefix))) {
    if (/\.(?:m?js|cjs|wasm)$/i.test(parsed.pathname) || /\+esm\b/i.test(href)) {
      return 'script-like path on allowed non-script prefix';
    }
    return null;
  }
  return 'disallowed external URL in built JS';
}

export function checkBuiltJsHosts(rootDir) {
  const absRoot = path.resolve(rootDir);
  const violations = [];
  let urlsChecked = 0;

  let localCanvasKitConfirmed = false;
  const bootstrapPath = path.join(absRoot, 'flutter_bootstrap.js');
  if (fs.existsSync(bootstrapPath)) {
    const bootstrapSrc = fs.readFileSync(bootstrapPath, 'utf8');
    let cfg = null;
    try {
      cfg = parseFlutterBuildConfig(bootstrapSrc);
    } catch {
      cfg = null;
    }
    if (!cfg || cfg.useLocalCanvasKit !== true) {
      violations.push({
        file: 'flutter_bootstrap.js',
        url: '_flutter.buildConfig',
        reason: 'useLocalCanvasKit is not true',
      });
    } else {
      localCanvasKitConfirmed = true;
    }
  }

  const jsFiles = collectJsFiles(absRoot);
  for (const relPath of jsFiles) {
    const src = fs.readFileSync(path.join(absRoot, relPath), 'utf8');
    for (const url of extractExternalUrlsFromJs(src)) {
      urlsChecked++;
      const reason = validateJsUrl(url, relPath, localCanvasKitConfirmed);
      if (reason !== null) {
        violations.push({ file: relPath, url, reason });
      }
    }
  }

  const indexPath = path.join(absRoot, 'index.html');
  if (fs.existsSync(indexPath)) {
    const html = fs.readFileSync(indexPath, 'utf8').replace(/<!--[\s\S]*?-->/g, '');
    const scriptSrcRe = /<script\b[^>]*\bsrc\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/gi;
    for (const match of html.matchAll(scriptSrcRe)) {
      const src = (match[1] ?? match[2] ?? match[3] ?? '').trim();
      if (!/^(?:https?:)?\/\//i.test(src)) continue;
      urlsChecked++;
      let parsed;
      let href;
      try {
        ({ parsed, href } = normalizeCandidateUrl(src));
      } catch {
        violations.push({ file: 'index.html', url: src, reason: 'invalid external script src URL' });
        continue;
      }
      const allowed =
        NORMALIZED_TEMP_SCRIPT_URLS.has(href) ||
        NORMALIZED_SCRIPT_HOSTS.has(parsed.host.toLowerCase()) ||
        NORMALIZED_SCRIPT_HOSTS.has(parsed.hostname.toLowerCase());
      if (!allowed) {
        violations.push({
          file: 'index.html',
          url: src,
          reason: 'disallowed external script src in index.html',
        });
      }
    }
  }

  return { filesScanned: jsFiles.length, urlsChecked, violations };
}

const isMain = (() => {
  if (!process.argv[1]) return false;
  try {
    return fs.realpathSync(path.resolve(process.argv[1])) === fs.realpathSync(fileURLToPath(import.meta.url));
  } catch {
    return false;
  }
})();

if (isMain) {
// CLI entrypoint kept at column 0 to preserve existing Playwright runner diff/blame
const args = process.argv.slice(2);
const flag = (name, dflt) => { const a = args.find((x) => x.startsWith(`--${name}=`)); return a ? a.slice(name.length + 3) : dflt; };
const staticOnly = args.includes('--static-only');
const dir = args.find((x) => !x.startsWith('--'));
if (!dir || !fs.existsSync(path.join(dir, 'index.html'))) {
  console.error('usage: node coqui/tool/check_sitio.mjs <build dir> [--shot=<png file>] [--build=<n>] [--static-only]');
  process.exit(2);
}
const ROOT = path.resolve(dir);

// ---- results ------------------------------------------------------------------------------------------
let failed = 0;
const check = (ok, what, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${what}${detail ? `  (${detail})` : ''}`);
  if (!ok) failed++;
};

// ---- the names in the build -------------------------------------------------------------------------
const names = [];
const walk = (d) => {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    names.push(path.relative(ROOT, path.join(d, e.name)));
    if (e.isDirectory()) walk(path.join(d, e.name));
  }
};
walk(ROOT);
const dropped = names.filter((n) => n.split(path.sep).some((part) => part.startsWith('_') || part.startsWith('.')));
check(dropped.length === 0, 'no file or folder name starts with "_" or "."', dropped.join(', '));
check(!names.includes('flutter_service_worker.js'), 'no flutter_service_worker.js in the build');
// ---- static built-JS external host audit ------------------------------------------------------------
const hostAudit = checkBuiltJsHosts(ROOT);
check(
  hostAudit.violations.length === 0,
  `no disallowed external URLs in built JS (${hostAudit.filesScanned} JS files, ${hostAudit.urlsChecked} URLs checked)`,
  hostAudit.violations.map((v) => `${v.file}: ${v.url} [${v.reason}]`).join(' | '),
);

if (staticOnly) {
  console.log(failed === 0 ? '\nall checks passed' : `\n${failed} check(s) FAILED`);
  process.exit(failed === 0 ? 0 : 1);
}

const { chromium } = createRequire(import.meta.url)('playwright');

const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const BUILD = flag('build', fs.readFileSync(path.join(REPO, 'coqui/BUILD'), 'utf8').trim());
const SHOT = flag('shot', '');
const PREFIX = '/field-notes/app/';
const HISTORIA = '/field-notes/historia/';
// the progress with the welcome done and nothing played (check_app.mjs puts seeds in the same way)
const SEED = fs.readFileSync(path.join(REPO, 'coqui/ref/pantallas/seeds/vacio.json'), 'utf8').replace(/\n/g, '');

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json',
  '.png': 'image/png', '.wasm': 'application/wasm', '.otf': 'font/otf', '.ttf': 'font/ttf', '.frag': 'text/plain',
  '.mp3': 'audio/mpeg', '.svg': 'image/svg+xml', '.css': 'text/css',
};

// ---- the server: /field-notes/app/ is the build, the rest of /field-notes/ the repository, everything else a 404 ---------
const served = []; // { url, status }
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  let status = 404;
  let body = 'not found';
  let type = 'text/plain';
  const p = decodeURIComponent(url.pathname);
  let root = null;
  let rel = null;
  if (p.startsWith(PREFIX)) { root = ROOT; rel = p.slice(PREFIX.length); }
  else if (p.startsWith('/field-notes/')) { root = REPO; rel = p.slice('/field-notes/'.length); }
  if (root !== null) {
    if (rel === '' || rel.endsWith('/')) rel += 'index.html';
    const file = path.resolve(root, rel);
    if (file.startsWith(root + path.sep) && fs.existsSync(file) && fs.statSync(file).isFile()) {
      status = 200;
      body = fs.readFileSync(file);
      type = TYPES[path.extname(file)] || 'application/octet-stream';
    }
  }
  served.push({ url: url.pathname, status });
  res.writeHead(status, { 'content-type': type, 'cache-control': 'no-store' });
  res.end(body);
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const ORIGIN = `http://127.0.0.1:${server.address().port}`;

// ---- the page ---------------------------------------------------------------------------------------------
const browser = await chromium.launch();
const phone = { viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true };
const gpuNote = /GL Driver Message/; // Chrome's software GPU in headless mode, not the app
// What a page did: its console problems, uncaught errors, requests and failed requests.
const watch = (pg) => {
  const w = { consoleProblems: [], pageErrors: [], requests: [], failedRequests: [] };
  pg.on('console', (m) => {
    if (m.type() === 'error' || (m.type() === 'warning' && !gpuNote.test(m.text()))) w.consoleProblems.push(`${m.type()}: ${m.text()}`);
  });
  pg.on('pageerror', (e) => w.pageErrors.push(String(e)));
  pg.on('request', (r) => w.requests.push(r.url()));
  pg.on('requestfailed', (r) => w.failedRequests.push(`${r.url()} ${r.failure()?.errorText}`));
  return w;
};
// The app draws on a canvas. What is on screen is read from Flutter's accessibility tree, which the page builds when the
// (invisible) "Enable accessibility" button is activated: on a phone it fills the view, and a click at its exact middle
// turns the tree on (as TalkBack's tap does; check_app.mjs does the same).
const enableSemantics = async (pg) => {
  await pg.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 60000 });
  await pg.evaluate(() => {
    const p = document.querySelector('flt-semantics-placeholder');
    const r = p.getBoundingClientRect();
    p.dispatchEvent(new MouseEvent('click', { clientX: r.left + r.width / 2, clientY: r.top + r.height / 2, bubbles: true }));
  });
  await pg.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 0, null, { timeout: 30000 });
};
const nodesOf = (pg) => pg.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => {
  const r = e.getBoundingClientRect();
  const label = (e.getAttribute('aria-label') || '').trim();
  let own = '';
  for (const c of e.childNodes) if (c.nodeType === 3 || (c.nodeType === 1 && c.tagName !== 'FLT-SEMANTICS' && c.tagName !== 'FLT-SEMANTICS-CONTAINER')) own += c.textContent;
  return { text: (label || own).trim(), x: r.x + r.width / 2, y: r.y + r.height / 2, w: r.width, h: r.height };
}).filter((n) => n.text && n.w > 0 && n.h > 0));
// a node's label can hold several lines (a card's title and its line under it): each line is matched alone too
const says = (n, re) => re.test(n.text) || n.text.split('\n').some((l) => re.test(l.trim()));
const wordsOf = async (pg) => (await nodesOf(pg)).map((n) => n.text);
// Waits for the page to say something that matches [re]; the words on screen when it never does.
const waitSays = async (pg, re, what, timeout = 30000) => {
  const t0 = Date.now();
  for (;;) {
    const ns = await nodesOf(pg);
    if (ns.some((n) => says(n, re))) return ns;
    if (Date.now() - t0 > timeout) throw new Error(`${what} never came; on screen: ${JSON.stringify(ns.map((n) => n.text)).slice(0, 600)}`);
    await pg.waitForTimeout(250);
  }
};
// One pass over the app, for either variant: opens it with the welcome done, finds the map, opens Yo, reads the build.
// Returns what it saw, for the checks.
const openApp = async (pg, label) => {
  await pg.goto(`${ORIGIN}${PREFIX}`, { waitUntil: 'load' });
  await pg.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
  await enableSemantics(pg);
  const seen = { label };
  try {
    const onMap = await waitSays(pg, /^1 · La casa$/, 'the map\'s place chip', 60000);
    seen.tabBar = ['Biblioteca', 'Palabras', 'Mapa', 'Hablar', 'Yo'].filter((t) => !onMap.some((n) => n.text === t));
    seen.mapAddress = new URL(pg.url()).hash;
    seen.mapWords = onMap.map((n) => n.text);
  } catch (e) {
    seen.mapError = String(e.message || e);
  }
  return seen;
};
// Yo is the one place the app shows the build number: its tab, then the line "build <n>".
const readBuild = async (pg, seen) => {
  try {
    const ns = await nodesOf(pg);
    const yo = ns.filter((n) => n.text === 'Yo').pop(); // the tab bar's
    if (!yo) throw new Error('no Yo in the tab bar');
    await pg.mouse.click(yo.x, yo.y);
    await pg.waitForFunction(() => location.hash === '#/tab/me', null, { timeout: 15000 });
    const onYo = await waitSays(pg, /^build \S+$/, 'Yo\'s build line', 30000);
    seen.build = onYo.map((n) => n.text).filter((t) => /^build \S+$/.test(t));
  } catch (e) {
    seen.buildError = String(e.message || e);
  }
};
// The same checks of what a page did, for either pass.
const checkTraffic = (label, w, servedFrom) => {
  const seen = served.slice(servedFrom);
  const outside = w.requests.filter((u) => !u.startsWith(ORIGIN) && !u.startsWith('data:') && !u.startsWith('blob:'));
  check(outside.length === 0, `${label}: no request leaves 127.0.0.1 (${w.requests.length} requests)`, outside.join(', '));
  const notFound = seen.filter((s) => s.status !== 200);
  check(notFound.length === 0, `${label}: every request to the server answered 200 (${seen.length})`, notFound.map((s) => `${s.status} ${s.url}`).join(', '));
  check(w.failedRequests.length === 0, `${label}: no failed request`, w.failedRequests.join(', '));
  check(w.consoleProblems.length === 0 && w.pageErrors.length === 0, `${label}: no console error or warning, no page error`,
    [...w.consoleProblems, ...w.pageErrors].join(' | '));
};

// An empty browser, with the progress of a learner who has done the welcome and played nothing (the first screen is then the map).
const newContext = async (extra) => {
  const c = await browser.newContext(phone);
  await c.addInitScript((seed) => {
    if (!localStorage.getItem('coqui.palabras.v1')) localStorage.setItem('coqui.palabras.v1', seed);
  }, SEED);
  if (extra) await c.addInitScript(extra);
  return c;
};
// What the checks of one pass say about [seen] (the app's start and its build line).
const checkApp = (label, seen) => {
  check(!seen.mapError, `${label}: the app starts on the map (the place chip "1 · La casa")`, seen.mapError || '');
  check(seen.mapAddress === '#/tab/map', `${label}: the address is #/tab/map`, seen.mapAddress);
  check(seen.tabBar && seen.tabBar.length === 0, `${label}: the tab bar names Biblioteca, Palabras, Mapa, Hablar and Yo`,
    `missing: ${JSON.stringify(seen.tabBar)}; on screen: ${JSON.stringify(seen.mapWords).slice(0, 400)}`);
  check(!seen.buildError && JSON.stringify(seen.build) === JSON.stringify([`build ${BUILD}`]),
    `${label}: Yo shows "build ${BUILD}"`, seen.buildError || JSON.stringify(seen.build));
};

const context = await newContext();
const page = await context.newPage();
const watched = watch(page);

const first = await openApp(page, 'chromium variant');
// the screenshot is of the map, before the tab is changed
await page.waitForTimeout(600);
const png = await page.screenshot({ path: SHOT || undefined });
await readBuild(page, first);
checkApp('chromium variant', first);
// the content comes from /field-notes/historia/ (the base the app takes from its own address: ../historia/)
const answered = (u) => served.some((x) => x.url === u && x.status === 200);
const content = ['datos/curso.json', 'audio/ready.json', 'audio/marcas.json', 'datos/prueba-voz.json'];
check(content.every((f) => answered(`${HISTORIA}${f}`)), 'the content is read from /field-notes/historia/ (' + content.join(', ') + ')',
  content.filter((f) => !answered(`${HISTORIA}${f}`)).map((f) => `not answered: ${f}`).join(', '));
// the one exception: the preview content bundled in the app (lib/src/previa.dart), its overlay and its story files, under
// assets/assets/previa/ of the build
const PREVIA = `${PREFIX}assets/assets/previa/`;
check(!served.some((x) => x.url.startsWith(PREFIX) && !x.url.startsWith(PREVIA) && /\.json$/.test(x.url) && /curso|ready|marcas|prueba-voz|cuentos|libros/.test(x.url)),
  'none of the content is asked for inside /field-notes/app/, but the bundled preview');
check(answered(`${PREVIA}curso.json`), 'the preview overlay is read from the build (assets/assets/previa/curso.json, 200)');

const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
check(/<html lang="en" translate="no">/.test(html) && /<meta name="google" content="notranslate">/.test(html),
  'index.html: <html lang="en" translate="no"> and the notranslate meta');
check(html.includes('<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no">'),
  'index.html: the old app\'s viewport, as it is');
check(html.includes('<meta name="theme-color" content="#5C94FC">') && html.includes('<base href="/field-notes/app/">')
  && html.includes('<meta name="apple-mobile-web-app-capable" content="yes">') && html.includes('<link rel="apple-touch-icon" href="icons/Icon-192.png">'),
  'index.html: theme-color, base href, apple web-app meta and touch icon');
const head = await page.evaluate(() => ({
  lang: document.documentElement.getAttribute('lang'),
  translate: document.documentElement.getAttribute('translate'),
  notranslate: document.querySelector('meta[name="google"]')?.content,
  viewport: document.querySelector('meta[name="viewport"]')?.content,
  manifest: document.querySelector('link[rel="manifest"]')?.href,
  title: document.title,
}));
check(head.translate === 'no' && head.notranslate === 'notranslate' && head.title === 'Coquí',
  'running page: translate="no", the notranslate meta, title Coquí');
console.log(`INFO  running page, after Flutter's engine rewrote them: lang="${head.lang}", viewport="${head.viewport}"`);

// manifest and icons: fetched by the page, as a browser would
const manifestUrl = head.manifest;
const manifest = await (await page.request.get(manifestUrl)).json();
check(manifest.name === 'Coquí' && manifest.short_name === 'Coquí' && manifest.display === 'standalone'
  && manifest.orientation === 'portrait' && manifest.start_url === PREFIX && manifest.scope === PREFIX,
  'manifest: name, short_name, display, orientation, start_url, scope');
check(manifest.theme_color === '#5C94FC' && manifest.background_color === '#F6F5F1', 'manifest: theme and background colours',
  `${manifest.theme_color} ${manifest.background_color}`);
const icons = [...manifest.icons.map((i) => ({ src: new URL(i.src, manifestUrl).href, size: i.sizes, purpose: i.purpose || 'any' })),
  { src: new URL('favicon.png', manifestUrl).href, size: '32x32', purpose: 'favicon' },
  { src: new URL('icons/Icon-192.png', manifestUrl).href, size: '192x192', purpose: 'apple-touch-icon' }];
check(manifest.icons.some((i) => i.sizes === '192x192' && !i.purpose) && manifest.icons.some((i) => i.sizes === '512x512' && !i.purpose)
  && manifest.icons.some((i) => i.sizes === '192x192' && i.purpose === 'maskable') && manifest.icons.some((i) => i.sizes === '512x512' && i.purpose === 'maskable'),
  'manifest names 192 and 512, and a maskable 192 and 512');
for (const icon of icons) {
  const r = await page.request.get(icon.src);
  const { w, h } = await page.evaluate(async (u) => {
    const bmp = await createImageBitmap(await (await fetch(u)).blob());
    return { w: bmp.width, h: bmp.height };
  }, icon.src);
  check(r.status() === 200 && `${w}x${h}` === icon.size, `${icon.purpose} icon ${path.basename(icon.src)} answers 200 and is ${icon.size}`, `${r.status()} ${w}x${h}`);
}

// no service worker
const regs = await page.evaluate(async () => (await navigator.serviceWorker.getRegistrations()).length);
check(regs === 0, 'no service worker is registered', `${regs} registrations`);
check(!served.some((s) => /service_worker/.test(s.url)), 'no service worker file was requested');

// requests (the whole first pass; the server's list started empty)
checkTraffic('chromium variant', watched, 0);
check(served.some((x) => x.url === `${PREFIX}canvaskit/chromium/canvaskit.wasm`) && !served.some((x) => x.url === `${PREFIX}canvaskit/canvaskit.wasm`),
  'chromium variant: canvaskit/chromium/canvaskit.wasm was loaded, and not the full variant');

// the screenshot (of the map, taken above): phone size, and not blank
const colours = await page.evaluate(async (b64) => {
  const img = new Image();
  img.src = `data:image/png;base64,${b64}`;
  await img.decode();
  const c = new OffscreenCanvas(img.width, img.height);
  const g = c.getContext('2d');
  g.drawImage(img, 0, 0);
  const d = g.getImageData(0, 0, img.width, img.height).data;
  const seen = new Set();
  for (let i = 0; i < d.length; i += 4) seen.add((d[i] << 16) | (d[i + 1] << 8) | d[i + 2]);
  return { w: img.width, h: img.height, colours: seen.size };
}, png.toString('base64'));
check(colours.w === 390 && colours.h === 844 && colours.colours > 2, 'the screenshot is 390 x 844 and not blank', `${colours.w}x${colours.h}, ${colours.colours} colours${SHOT ? `, saved to ${SHOT}` : ''}`);

// ---- second pass: the full CanvasKit variant (Safari, Firefox) -----------------------------------------
const mark = served.length;
const context2 = await newContext(() => { delete Intl.v8BreakIterator; });
const page2 = await context2.newPage();
const watched2 = watch(page2);
const second = await openApp(page2, 'full variant');
await readBuild(page2, second);
checkApp('full variant', second);
checkTraffic('full variant', watched2, mark);
const seen2 = served.slice(mark).map((x) => x.url);
check(seen2.includes(`${PREFIX}canvaskit/canvaskit.wasm`) && seen2.includes(`${PREFIX}canvaskit/canvaskit.js`) && !seen2.some((u) => u.includes('/canvaskit/chromium/')),
  'full variant: canvaskit/canvaskit.js and .wasm were loaded, and nothing from canvaskit/chromium/');
check(seen2.every((u) => !/skwasm|wimp|webparagraph/.test(u)), 'neither pass asked for a skwasm, wimp or webparagraph file');

await browser.close();
server.close();
console.log(failed === 0 ? '\nall checks passed' : `\n${failed} check(s) FAILED`);
process.exit(failed === 0 ? 0 : 1);

}