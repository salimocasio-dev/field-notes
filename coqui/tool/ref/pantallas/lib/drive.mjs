// small helpers to drive the old pages like a finger would
import { untilReal, until, adv, sleepReal } from './harness.mjs';

// the centre of the first element matching sel (nth: which one), scrolled into view first
export async function centre(pg, sel, nth = 0, scroll = true) {
  const pt = await pg.evaluate(([sel, nth, scroll]) => {
    const e = document.querySelectorAll(sel)[nth]; if (!e) return null;
    if (scroll) e.scrollIntoView({ block: 'center', inline: 'center' });
    const r = e.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2];
  }, [sel, nth, scroll]);
  if (!pt) throw new Error('tap: no element ' + sel + ' [' + nth + ']');
  return pt;
}
// a touch of the finger on an element (touchstart, touchend, and the click the browser makes of them)
export async function tap(pg, sel, nth = 0, scroll = true) {
  await settleAnims(pg);
  const [x, y] = await centre(pg, sel, nth, scroll);
  await pg.touchscreen.tap(x, y);
  await sleepReal(60);
}
export async function tapAt(pg, x, y) { await settleAnims(pg); await pg.touchscreen.tap(x, y); await sleepReal(60); }
// CSS transitions (a sheet sliding up) run in real time, not on the paused clock: a finger lands only when they are over
export const settleAnims = pg => pg.evaluate(() => Promise.all(document.getAnimations().filter(a => a.effect && a.effect.getComputedTiming().iterations !== Infinity).map(a => a.finished.catch(() => 0))));

// open the app page: wait for its own start (the map drawn, the course loaded) and for the voice library
export async function openApp(pg, base, query = '') {
  await pg.goto(base + '/historia/app.html' + query);
  await untilReal(pg, '!!(window.App&&App.ready)');
  await pg.evaluate('voiceReady');
  await settle(pg);
}
// the tabs that fetch their files draw when the files are here; images load in real time
export async function settle(pg, ms = 0) {
  await untilReal(pg, `(()=>{const t=document.querySelector('.tab.on');return !!t&&(t.id==='t-mapa'||t.children.length>0)})()`);
  await untilReal(pg, 'Array.from(document.images).every(i=>i.complete)');
  if (ms) await adv(pg, ms);
}
export async function goTab(pg, tab) {
  await pg.evaluate(`App.ver(${JSON.stringify(tab)})`);
  await settle(pg);
}
// a tab shot's page: scrolled to the top
export const top = pg => pg.evaluate('scrollTo(0,0)');
export const sheetOpen = pg => untilReal(pg, `document.getElementById('sheet').classList.contains('on')`);

// the progress state a seed holds (parsed), for choosing words and stories from the data and not from memory
export const dbOf = pg => pg.evaluate('JSON.parse(JSON.stringify(PAL.db))');
export { untilReal, until, adv, sleepReal };

// pin every running CSS animation of the page at t ms (for the pictures taken with motion on): paused, whole, the same every run
export const freeze = (pg, t) => pg.evaluate(t => document.getAnimations().forEach(a => { a.pause(); a.currentTime = t; }), t);
