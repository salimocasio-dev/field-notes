// The English strings that v=39 can put on a screen, written out from app.html, cual.js, nivel.js, llamada.js, juego.js, index.html and habla-prueba.html (and, for the
// place sheet, the English place names of curso.js). After the pictures are taken, each is looked for in the text that shows in them (see VISIBLE_TEXT in harness.mjs);
// the result is strings.json: where each shows, and which do not show anywhere.
// An entry is [text or regular expression, where it comes from]. A string starts "[aria-label] " or "[placeholder] " when it is an attribute and not text on the screen.
const R = (s, f = '') => new RegExp(s, f);
export const STRINGS = [
  // ---- the tab bar, the map, the Today card
  ['Biblioteca', 'app.html tabs'], ['Palabras', 'app.html tabs'], ['Mapa', 'app.html tabs'], ['Hablar', 'app.html tabs'], ['Yo', 'app.html tabs'],
  [R('^🔥 \\d+ days$'), 'app.html hud (chip)'], [R('^🔥 1 day$'), 'app.html hud (chip), singular'], [R('^\\d+ · (La casa|El parque|La cocina)$'), 'app.html hud (chip)'],
  ['Today', 'app.html hud (Today card)'], [R('^Today · 1 of \\d+$'), 'app.html hud (Today card)'], ['¿Cuál?', 'app.html plan'],
  [R('^\\d+ words coming back · \\d+ min$'), 'app.html plan'], [R('^1 word coming back · \\d+ min$'), 'app.html plan, singular'],
  [R('^New story · play it twice · \\d+ min$'), 'app.html plan'], [R('^Second play · \\d+ min$'), 'app.html plan'], [R('^Listen again · \\d+ min$'), 'app.html plan'],
  ['All your words', 'app.html plan (reached only when there is no story at all)', 'unreachable'],
  // ---- the place sheet
  [R('^Place 1 · Grandma\'s house$'), 'app.html lugar, curso.js'], [R('^Place 2 · The park · a fork: either place first$'), 'app.html lugar, curso.js'], [R('^Place 3 · The kitchen · a fork: either place first$'), 'app.html lugar, curso.js'],
  ['Place 4 · The corner shop', 'curso.js'], ['Place 5 · The street · a fork: either place first', 'curso.js'], ['Place 6 · The town square · a fork: either place first', 'curso.js'], ['Place 7 · The beach · a fork: either place first', 'curso.js'],
  ['Place 8 · The diner · a fork: either place first', 'curso.js'], ['Place 9 · A whole day at home', 'curso.js'], ['Place 10 · The fort', 'curso.js'],
  ['New', 'app.html lugar'], ['Played', 'app.html lugar'], [R('^about \\d+ min$|about \\d+ min'), 'app.html lugar'], ['Not built yet.', 'app.html lugar'], ['Locked until the places before it are done.', 'app.html lugar'], [R('^Scenes: '), 'app.html lugar'],
  // ---- Biblioteca and the book
  ['Listen', 'app.html biblioteca'], ['Read', 'app.html biblioteca'], ['✓', 'app.html biblioteca (Read ✓)'], ['Cuento con dibujos', 'app.html biblioteca'], ['Haz esto', 'app.html biblioteca'], [R('Heard \\d+×'), 'app.html biblioteca'],
  ['Play a story on the map. You can hear it again here and read it.', 'app.html biblioteca'], [R('^\\d+ more open as you play the map$'), 'app.html biblioteca'], ['1 more opens as you play the map', 'app.html biblioteca, singular'],
  ['Fin', 'app.html pie'], ['Otra vez', 'app.html pie'], ['Coquí', 'app.html lineaEl (the coquí\'s label)'], [R('^\\d+ / \\d+$'), 'app.html pinta (page count)'], ['Aa', 'app.html (text size)'],
  ['[aria-label] Book', 'app.html'], ['[aria-label] Close', 'app.html'], ['[aria-label] Text size', 'app.html'], ['[aria-label] Previous page', 'app.html pie'], ['[aria-label] Next page', 'app.html pie'],
  // ---- Palabras and the word sheet
  ['Repaso', 'app.html palabras, cual.js'], [R('^\\d+ words today · about \\d+ min$'), 'app.html palabras'], [R('^1 word today · about 1 min$'), 'app.html palabras, singular'], ['Start', 'app.html palabras, yo'],
  ['Nothing due today', 'app.html palabras'], ['Practice', 'app.html palabras'], ['Ear: you know it when you hear it. Mouth: you can say it.', 'app.html palabras'], ['Ear', 'app.html meter'], ['Mouth', 'app.html meter'],
  ['Play the first story on the map. Your words show up here.', 'app.html palabras'], ['More words', 'app.html palabras (a recorded word that no played story brings)', 'unreachable'],
  ['Add a word or a goal', 'app.html palabras'], ['For example: "talk to my 1-year-old around the house".', 'app.html palabras'], ['[placeholder] A word or a goal', 'app.html palabras'], ['Add', 'app.html palabras'], ['Saved. Material for it comes later.', 'app.html palabras'],
  ['Comes back today', 'app.html vuelve'], [R('^Comes back in \\d+ days$'), 'app.html vuelve'], ['Comes back in 1 day', 'app.html vuelve, singular'], ['Heard in', 'app.html palabra'],
  // ---- Hablar
  ['Call Danny', 'app.html hablar'], [R('· about 5 min$'), 'app.html hablar'], [R('^Opens when you finish '), 'app.html hablar'], [R('^Coming soon · '), 'app.html hablar'], ['Words open for speaking', 'app.html hablar'],
  ['None yet. A word opens once your ear has held it for a few days.', 'app.html hablar'],
  // ---- Yo
  ['day streak', 'app.html yo'], ['minutes listened', 'app.html yo'], ['1 minute listened', 'app.html yo, singular'], ['words heard', 'app.html yo'], ['1 word heard', 'app.html yo, singular'], ['words good', 'app.html yo'], ['1 word good', 'app.html yo, singular'],
  ['Where you are', 'app.html yo'], [R('^A1 · place \\d+ of 10 · '), 'app.html yo'], ['Minutes a day', 'app.html yo'], ['15', 'app.html yo'], ['30', 'app.html yo'], ['60', 'app.html yo'], ['120', 'app.html yo'],
  ["Today's plan is sized to this.", 'app.html yo'], ['Open every place', 'app.html yo'], ['To look ahead. Places not built yet stay empty.', 'app.html yo'], ['Speak in stories', 'app.html yo'],
  ["Some of the coquí's lines become your turn: you say them and the app listens.", 'app.html yo'], ["Speaking in stories isn't available on this phone right now.", 'app.html notaHabla'],
  ['Level check', 'app.html yo'], [R('^For people who already understand some Spanish\\. About 3 minutes, touch only\\. Covers the stories built so far\\.$'), 'app.html yo'],
  [R('^For people who already understand some Spanish\\. About 3 minutes, touch only\\. Done: \\d+ stories skipped\\.$'), 'app.html yo'], [R('Done: 1 story skipped\\.'), 'app.html yo, singular'], ['How it works', 'app.html yo'],
  // ---- the welcome
  ['Welcome to Coquí', 'app.html bienvenida'], ['You learn Spanish the way children do: by hearing it, with pictures, in short stories.', 'app.html bienvenida'],
  ['You answer by touching the picture. What you touch changes what happens.', 'app.html bienvenida'], ['Words come back just before you would forget them.', 'app.html bienvenida'],
  ['English is only in the menus, to help you find your way.', 'app.html bienvenida'],
  ['The words of the stories you already understand are yours to keep: each gets one cold check tomorrow, and they are open for speaking now.', 'app.html NIVELTXT (How it works, opened again)'],
  ['Next', 'app.html bienvenida'], ['How much time a day?', 'app.html bienvenida'], ["Today's plan is sized to it. You can change it in Yo.", 'app.html bienvenida'], ['15 min', 'app.html bienvenida'], ['30 min', 'app.html bienvenida'], ['60 min', 'app.html bienvenida'], ['120 min', 'app.html bienvenida'],
  ['Where do you start?', 'app.html bienvenida'], ['The level check takes about 3 minutes. You hear a sentence and touch one of four pictures.', 'app.html bienvenida'], ["I'm new to Spanish", 'app.html bienvenida'], ['I understand some Spanish', 'app.html bienvenida'],
  // ---- Repaso and the level check
  ['Listen, then touch the picture that fits.', 'cual.js'], [R('^\\d+ words · about \\d+ min$'), 'cual.js'], [R('^1 word · about 1 min$'), 'cual.js, singular'], ['Done', 'cual.js'], [R('^\\d+ moving up'), 'cual.js'], [R('coming back soon$'), 'cual.js'],
  [R('^\\d+ right'), 'cual.js (practice)'], [R('\\d+ missed$'), 'cual.js (practice)'], ['Moving up', 'cual.js'], ["You'll see these less often", 'cual.js'], ['Coming back soon', 'cual.js'], ["You'll see these again soon", 'cual.js'],
  ['Right', 'cual.js (practice)'], ['Missed', 'cual.js (practice)'], ['Back to Palabras', 'cual.js'], ['[aria-label] Picture 1', 'cual.js'], ['[aria-label] Sound', 'cual.html'],
  [R('^\\d+ pictures · about \\d+ min$'), 'nivel.js'], ['Level check done', 'nivel.js'], [R('^You already understand the first \\d+ stories\\.$'), 'nivel.js'], ['You already understand the first 1 story.', 'nivel.js, singular'], ['You start at the beginning.', 'nivel.js'], ['To the map', 'nivel.js'],
  // ---- the story page
  ['Play again', 'juego.js'], ['Next story', 'juego.js'], ['Map', 'juego.js'], ['[aria-label] Micrófono', 'index.html'], ['[aria-label] Start', 'index.html'],
  // ---- the call
  ['Start call', 'llamada.js'], ['Calling…', 'llamada.js'], ['Danny', 'llamada.js'], ['Your turn', 'llamada.js'], ['One moment', 'llamada.js'], ['Help', 'llamada.js'], ['Danny will say it again, slowly.', 'llamada.js'],
  ['Call done', 'llamada.js'], [R('^\\d+ min · \\d+ words said$'), 'llamada.js'], [R('^\\d+ min · 1 word said$'), 'llamada.js, singular'], ['Back to Hablar', 'llamada.js'],
  ['The microphone is off. Allow it in your browser to call.', 'llamada.js'], ['The call did not start. Check your connection and try again.', 'llamada.js'], ['The voice part did not load. Check your connection and try again.', 'llamada.js'],
  // ---- the voice test page
  ['Tap the mic and say each Spanish line.', 'habla-prueba.html'], ['Escuchando…', 'habla-prueba.html'], ['Un momento…', 'habla-prueba.html'], [R('^Heard right: \\d+ of 12$'), 'habla-prueba.html'], ['El micrófono no está disponible.', 'habla-prueba.html'],
];

// texts: [{ file, text: [..] }] of every picture (both phones: the names are the same). Returns the rows of strings.json.
export function tickOff(rows) {
  const out = [];
  for (const [pat, src, flag] of STRINGS) {
    const isRx = pat instanceof RegExp;
    const found = [];
    for (const r of rows) {
      const hit = r.text.some(t => { const x = t.replace(/\s+/g, ' ').trim(); return isRx ? pat.test(x) : (x === pat || x.includes(pat)); });
      if (hit) found.push(r.file);
    }
    out.push({ string: isRx ? pat.source : pat, regex: isRx, from: src, pictures: found.slice(0, 6), count: found.length, note: flag || null });
  }
  return out;
}
