# Flutter contracts and porting rules

Nov 19 2026, after the second review. Goes with 11-flutter-plan and 13-flutter-orders.

Every builder is given sections 1, 2, 3, 6 and 7. Builders in the pixel, scenes, map and story lanes also sections 4 and 5. A builder may also read the public file (`lib/<package>.dart`) of each package in its own row of the plan's package table. Nothing else.

Order 02 turns sections 2 to 4 into compiling code. The names and shapes here are binding. Where the old code needs a member that is missing here, order 02 adds it and lists it in its report. After order 02 only the orchestrator changes a contract, through a request.

## 1. Words used on these pages

- **Old code:** the JavaScript under `historia/` and `docs/proyecto/pixel/`. It is the reference. Builders never edit it.
- **Lane:** one package. **Order:** one task for one builder in one lane.
- **Port:** the same behaviour in Dart, line for line where possible. Not a redesign. Not an improvement.
- **Set:** a scene's background, built with the Pixel Plays engine (page 11-pixel-engine).
- **Set reference:** a scene's set built first in JavaScript, like `pixel/frente-set.html`, with every state. Design work, done and checked before any builder ports it.
- **Sheet:** the data that goes with a set reference (section 5).
- **Sprite layer:** everything drawn over the set: characters, props that move, signs, bubbles.
- **Picture:** a `Uint32List` of width × height pixels, each `0xAABBGGRR` (the engine's `rgb()`), RGBA bytes in memory order.

## 2. coqui_contracts (pure Dart)

```dart
enum Skill { ear, mouth }

/// One skill of one word. Field for field today's record (historia/palabras.js, skill()).
class SkillRecord {
  int etapa, paso, seguidas, fallos, n, bien, marca;
  double gap;                      // days
  int due, ultima, aparcada;       // ms since epoch, 0 = none
  List<int> aciertos;
  int? presunta;
}
class WordRecord { String w; int primera; int oida; SkillRecord ear; SkillRecord mouth; }
class StoryRecord { int n; int primera; int? ultima; int? perdido; int? presunto; }

/// One decision inside a story, as juego.js logs it (LOG entries: word, asked, got, ok, ms).
class Decision { String? word; String? asked; String? got; bool ok; int? ms; }
class StoryResult { String id; List<String> focusWords; List<String> backAgain; int lost; List<Decision> log; }

abstract interface class ProgressStore {
  Stream<void> get changes;                      // fires after every save
  Map<String, dynamic> get raw;                  // the whole JSON, read only
  Iterable<WordRecord> get words;
  WordRecord? word(String w);
  StoryRecord? story(String id);
  bool played(String id);                        // app.html: hecho
  List<String> due(Skill skill, {int? at});      // PAL.vence
  WordRecord heard(String w);                    // PAL.oida
  SkillRecord answer(String w, Skill skill, {required bool ok, int? ms, bool intro = false});  // PAL.responde
  void storyFinished(StoryResult r);             // PAL.cuento
  void presume(List<String> words, List<String> stories, List<Object?> log);  // PAL.presume
  void listened(String id);                      // PAL.oido
  bool hasRead(String id);  void markRead(String id);       // db.leidos
  void addMinutes(double m);                     // PAL.minutos
  double get minutes;  int get streak;           // db.minutos, PAL.racha
  bool openForSpeaking(String w);                // PAL.abiertaHabla
  Object? setting(String key);  void setSetting(String key, Object value);   // db.ajustes: min, todo, bienvenida, habla
  List<String> get added;  void add(String wordOrGoal);     // db.extra
  Map<String, dynamic>? get levelResult;         // db.nivel
  String export();  void import(String json);
  void reset();
}

class Place { String id; int n; String name; String en; String? fork;
  List<String> stories; List<String> pictureStories; List<String> routines; List<String> scenes; }
class StoryMeta { String id; String title; int minutes; }
class ClipInfo { String id; String who; String text; String? habla; int startMs; int endMs; String url; }
class PictureSpec { String? scene; Map<String, dynamic> set; List<num> cam; }   // one side of a pair
class ReviewPair { String word; String say; String scene; PictureSpec yes; PictureSpec no; }  // items: w, say, si, no
class LevelItem { String word; int step; List<List<Object?>> pictures; }       // NV: w, s, p
class CallBrief { String placeId; int minutes; String job; String opening; String photo; }
class BookPage { String image; List<String> clips; }
class Book { String id; String title; bool readable; List<BookPage> pages; }  // lee -> readable
class HeardLine { String storyId; String storyTitle; String clipId; String text; }

abstract interface class CourseCatalog {
  Future<void> load();
  List<Place> get places;
  StoryMeta? meta(String id);
  Future<Map<String, dynamic>> story(String id); // the raw story file
  Future<Book?> book(String id);
  List<ReviewPair> get pairs;
  ReviewPair? pairFor(String word);              // matched on normalize()
  List<LevelItem> get levelItems;
  CallBrief? callFor(String placeId);
  ClipInfo? clip(String id);
  String fixedClip(String role);                 // historia/datos/fijos.json
  List<String> get goodbyeWords;
  Future<List<HeardLine>> linesWith(String word, Iterable<String> storyIds, {int max = 5});
}

abstract interface class ClipPlayer {
  Future<void> unlock();                         // call inside the first tap
  Future<List<String>> preload(Iterable<String> clipIds);   // the ids that could NOT be made ready; empty = all ready (changed Nov 19, order 02b)
  Future<bool> play(String clipId, {Duration? limit});   // true when it played to its end mark
  void tone(double hz, {double at = 0, double dur = .1, String wave = 'square', double vol = .05, double? toHz});
  void noiseBurst({double vol = 1});             // thunder
  void loop(String name, bool on);               // 'rain'
  bool muted;
  Future<void> stop();
}

class SpeechResult { List<String> alternatives; String? error; int? msToSound; }
abstract interface class SpeechTurn { Future<SpeechResult> get result; Future<void> get speechEnd; void cancel(); }
abstract interface class SpeechListener {
  Future<bool> available();
  SpeechTurn listen({required String locale, required Duration limit, int maxAlternatives = 5});
}

sealed class CallEvent {}   // Connected, AgentLine(text), Heard(text), Mode(speaking|listening), Tool(name, args), CallError(message), Ended(reason)
abstract interface class CallSession {
  bool get available;                            // false in a phone build until there is a token server
  Future<void> start(CallBrief brief, Map<String, String> variables);
  Stream<CallEvent> get events;
  void send(String text);
  void setVolume(double v);
  Future<void> end();
}

abstract interface class KeyValueStore { String? read(String key); Future<void> write(String key, String value); }
abstract interface class Clock { int nowMs(); }
/// The one random source. Mulberry32 (given in coqui_contracts, with tests), because the old page's recorded runs
/// are made with the same generator. Never dart:math Random in engine, scene or runner code.
abstract interface class Rng { double next(); }   // 0 <= x < 1, as Math.random()
abstract interface class Haptics { void tick(); void unlock(); }
abstract interface class AppInfo {
  String get build;                              // shown in Yo
  bool get isWeb;  bool get isIos;  bool get isAndroid;
  bool get installed;                            // web: opened from the home screen
  bool get callsAllowed;                         // a build setting (order 44)
}

sealed class AppRoute {}
class StoryRoute extends AppRoute { final String id; final bool listen; }
class ReviewRoute extends AppRoute { final bool practice; }
class LevelCheckRoute extends AppRoute {}
class BookRoute extends AppRoute { final String id; }
class CallRoute extends AppRoute { final String placeId; }
class VoiceTestRoute extends AppRoute {}
class TabRoute extends AppRoute { final String tab; }   // library, words, map, speak, me
abstract interface class AppNavigator { void go(AppRoute route); void back(); }

/// Today's PAL.norm, copied exactly.
String normalize(String? s);
```

The stored JSON keeps today's shape exactly (key `coqui.palabras.v1`):
`{palabras:{<w>:{w,primera,oida,ear,mouth}}, dias:{<yyyy-mm-dd>:n}, cuentos:{<id>:{n,primera,ultima,perdido,presunto}}, ajustes:{min,todo,bienvenida,habla}, minutos, v, nivel, oidos, leidos, extra}`. Unknown keys are kept on save. Day keys and the 4 am cut are computed exactly as palabras.js computes them (it mixes local time and UTC; keep the mix).

## 3. coqui_ui (needs Flutter): the widget-level contracts

```dart
class PictureRef { final String scene; final Map<String, dynamic> set; final List<num> cam; }
abstract interface class PictureSource {
  /// A scene in a given state, the 196-wide window at cam (section 5, "The camera"), cropped to height.
  Widget of(PictureRef ref, {int height = 104, int? scale, bool animated = false});
  Future<void> warm(Iterable<PictureRef> refs);  // bake ahead
}

class Services {
  final ProgressStore progress; final CourseCatalog course; final ClipPlayer clips;
  final SpeechListener speech; final CallSession call; final AppNavigator nav;
  final Clock clock; final Rng rng; final Haptics haptics; final AppInfo info; final PictureSource pictures;
  final KeyValueStore Function(String space) storage;
  final bool reduceMotion;
}

class FeatureTab { final String id; final String label; final IconData icon; final WidgetBuilder builder; }
abstract interface class FeatureModule {
  String get id;
  FeatureTab? tab(Services s);
  Widget? screenFor(AppRoute route, Services s);   // null: not mine
}

/// Shows a picture at a whole-number scale with no smoothing (page 11-pixel-engine, decision 3).
/// Device pixels per picture pixel = max(1, floor(availableWidth * devicePixelRatio / width)).
/// The widget is laid out at that size divided by devicePixelRatio and snapped to whole device pixels.
/// It repaints when `repaint` fires (the game ticks it; a still picture never does).
class PixelView extends StatefulWidget { /* pixels, width, height, Listenable? repaint, onTapPixel(x, y) */ }
```

## 4. coqui_pixel (pure Dart)

No globals: the old code's globals become fields of these classes.

```dart
/// Port of pixel/pp-engine.js. Every function there becomes a method with the same name and parameters.
class PpEngine {
  PpEngine({required int w, required int h, required double s, double originX = 0, double originY = 0,
            double shadowX = 1.3, double shadowY = -.12, bool still = false});
  final Uint32List pix, bakedPix;  final Float32List zb, bakedZ, groundZ;
  final Uint8List ground, shadowMask, staticShadow, kinds;
  // rgb, rampOf, bayerAt, tint, hash, noise, project, unproject, sphere, capsule, box, castShadow, applyShadows,
  // shadeEdges, growGrass, drawTufts, drawLeaves, bakeOcclusion, plot, growTree, figure, flushShadows,
  // drawDots, haloDots, drawArrow
}
/// Port of the palette and "building helpers" in pixel/mapa.js: C, toneOf, ST, shade, block, onWall, windowOn,
/// gable, flatRoof, shadowBox, bush, palm, person. Plus any helper a set reference adds (order 07 and 30a to 39a).
class PpBuild { PpBuild(PpEngine e); }

/// Port of historia/engine.js: Buf, RP, OUT, bay, hs, rgb, fr, every mk* sprite, sky, grass, shadow, face, coqui, bubble, GL, GC.
class Sprite { final int w, h; final Uint32List px; }

/// The software canvas the sprite layer draws with. Same operations and meaning as the browser's 2D canvas,
/// writing into a picture. Images are sampled nearest-neighbour unless `smoothing` is on (the old code turns
/// it on in three places in sala.js; nowhere else).
/// Decided Nov 19: the old scene canvas smoothed by default, so sprites at fractional positions were blurred. The new one
/// does not: an unscaled, unrotated drawImage lands on its position rounded to a whole pixel, `(x + 0.5).floor()`.
class Ctx {
  Ctx(Uint32List target, int w, int h);
  void save(); void restore(); void translate(double x, double y); void scale(double x, double y); void rotate(double a);
  double globalAlpha;  int fillStyle;  int strokeStyle;  double lineWidth;  bool smoothing;
  void fillRect(num x, num y, num w, num h);  void clearRect(num x, num y, num w, num h);
  void drawImage(Sprite s, num dx, num dy, [num? dw, num? dh]);
  void drawImageRect(Sprite s, num sx, num sy, num sw, num sh, num dx, num dy, num dw, num dh);
  void beginPath(); void rect(num x, num y, num w, num h); void arc(num x, num y, num r, num a0, num a1);
  void ellipse(num x, num y, num rx, num ry, num rot, num a0, num a1); void moveTo(num x, num y); void lineTo(num x, num y);
  void fill(); void stroke(); void clip();
  Sprite snapshot(int x, int y, int w, int h);   // a copy of part of the picture (sala.js, banco.js)
}
```

A scene, and what it may call. The scene-facing names are kept exactly as in juego.js and kit.js, Spanish ones included, so a scene ports line for line. This is the one place Dart code is not renamed.

```dart
class Thing {                                    // kit.js: cosas
  String id; dynamic box;                        // [x, y, w, h] on screen, or a function of W: from the sheet
  List<double>? world;                           // x0, y0, z0, x1, y1, z1 when it is part of the set
  bool Function(Map<String, dynamic> W)? si; dynamic hand; num? m; bool z;
}
abstract class Scene {                           // what KIT.escena() takes and returns (kit.js, function escena)
  String get id;
  Map<String, List<num>> get CAM;
  List<num> get heartAt;
  Map<String, List<num>> get lugar;              // spots where the frog stands: [x, y, scale]
  List<Thing> get cosas;
  Map<String, dynamic> fresh(Map<String, dynamic> story);
  String setKey(Map<String, dynamic> W);         // which baked set this state needs
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W);   // port of the set reference
  List<num> remap(List<num> xy);                 // a position written in a story or pair file -> today's place (from the sheet)
  void draw(Ctx c, Map<String, dynamic> W, int a);   // the sprite layer only
  void hud(Ctx c, Map<String, dynamic> W);
  dynamic poke(String what);
  Map<String, Future<void> Function(Map<String, dynamic> o)> get acts;
  void stake(int lost, int max);
  List<num>? talkAt(String who);  dynamic respIcon(String k);  String estado();
  // given by the kit for every scene: box(k, W), hit(x, y, W), handAt(k), and the shared acts ir, burbuja, calla, pose, fin
}

/// What a scene may call. Every name is used by today's scenes or kit (count = uses). Order 02 writes each with
/// the parameters it has in juego.js. feature_story implements it for play; coqui_scenes has a still one for
/// pictures (waits return at once, sound is silent).
abstract class SceneHost {
  // state: W (2673), V (55), S (8), F (182), cam (9), TICK (98), FAST (5), SW (86), SH (61), DW (9), DH (1), runId (10), live (11), TALK (21), BUBL (4)
  // time: wait (1090), sleep (4), espera (23)
  // sound: SFX.<name>() (557), tone (50), say (2)
  // the frog: frog (118), frogBox (50), hopTo (49), bounce (61), foot (6), at (118)
  // signs and effects: fx (47), star (41), hand (25), heart (6), spot (6), bub (29), bx (10), muestra (5)
  // the story: pasos (47), paso (5), bien (10), estado (21), donde (1), baraja (1), camGo (6), poke (24), draw (23), fresh (19)
}
```

`SFX` is an object on the host with the names juego.js defines (18 on Nov 19; take the list from the file). Each calls `ClipPlayer.tone`, `noiseBurst` or `loop` with today's numbers. Scenes also call `tone` directly.

## 5. Scenes: from the old scene to the new one

Page 11-pixel-engine decides what a converted scene is: the same objects, states and touch keys; the set built from the 3D helpers; the characters as today's sprites on top; touch boxes from the 3D objects; each character at a spot in world coordinates.

The second review showed that this cannot be done by wrapping old screen numbers: the new set puts things too far from where they were, the one finished set (El frente) has one state and lacks things its stories use, and the story and review files themselves hold screen positions. So each scene is converted in two steps, by two different kinds of worker.

**Step a. The set reference and the sheet. Design. Done by the orchestrator, never by a builder.**

For each scene, in `docs/proyecto/pixel/`:

- `<id>-set.html`: the set in JavaScript on pp-engine.js, like frente-set.html, taking its states from the address (`?door=open&win=shut&lamp=1`). Every state the scene's stories and review pairs use. Every thing the stories touch or name.
- `<id>-sheet.json`:
    - `origin`: originX, originY (`S` is always 26).
    - `things`: for each touch key: its world box (x0, y0, z0, x1, y1, z1) when it is in the set; or `"sprite"` when it stays in the sprite layer.
    - `spots`: for each `lugar` name and each place a character stands or appears: a world point (x, y, z) and the frog's scale there.
    - `views`: for each `CAM` name: the world point the view centres on.
    - `remap`: every distinct screen position found in the scene's stories, review pairs and level-check items (order 06 lists them): the spot it means, or a world point.
    - `clips`: each clip region the old scene uses (a window, a doorway): the thing and face it belongs to.
    - `front`: the things that must cover a character. They stay in the sprite layer, drawn after the character, as today.
    - `shadows`: which characters cast a shadow and with what radius (the frog .45, abuela .35 in frente-set.html). Shadows the old code draws under a character are dropped for those.
- Checked before step b: every state rendered; a fresh reader, with no words, names what is in each and tells each review pair's two pictures apart; nothing green over a touch box.

**Step b. The port. Mechanical. Done by a builder.**

The builder ports `<id>-set.html` to `buildSet` and proves it against the JavaScript, state by state (no more than 0.5% of pixels differ). It ports the old scene file line for line, minus its background drawing (`bg` in frente, balcon and sala; `fondo` in the other eight; `mkPuesto` in mesa). Every screen position in the old file is replaced by the sheet's spot or view of the same name; a position the sheet does not cover is a stop-and-report, not a guess.

**The camera.** The old game draws 240 × 216, then stretches a view rectangle to 196 × 216, by amounts that are not whole numbers. Page 11-pixel-engine, decision 3, forbids that. So:

- (Changed Nov 19 by the orchestrator. The first text here said "a view never zooms". That over-applied decision 3, which forbids only a fractional scale: the old close views are 98 × 108, exactly 2×. Only the old `casa` view was fractional, 1.085×.)
- A view has a centre and a zoom of 1 or 2. Zoom 1: the 196 × 216 window over the 240 × 216 picture. Zoom 2: a 98 × 108 region, each picture pixel drawn as a 2 × 2 block. No other zoom; a fractional scale is never drawn, not for one frame.
- A view's place: centred on the sheet's world point for that view, kept inside the picture. The sheet gives each view its zoom: an old 98 × 108 view is zoom 2, every other view is zoom 1.
- `camGo` between two views of the same zoom slides in whole pixels. Between views of different zoom it is a cut: the camera is at the target from the first step, and `camGo` still takes the time it takes today.
- A review or level-check picture is a whole-number crop too: zoom 1 is the 196 × 104 window; zoom 2 is a 98 × 52 region doubled. The sheet gives each picture its centre and zoom.

**The frame, every tick:**

1. Copy the baked set for `setKey(W)` into the 240 × 216 picture (bake it first if not cached).
2. `drawLeaves`, `drawTufts` (wind, 8 steps a second; still when `reduceMotion`).
3. Cast the shadow of each character the sheet names, at the ground point under its feet. `applyShadows`.
4. The sprite layer: the scene's `draw(c, W, a)`, then the game's signs.
5. Copy the window at `cam` into the 196 × 216 display picture. Then `hud` and the hand sign, drawn on the display picture as today. `PixelView` shows the display picture.

**The story and pair files are not edited.** The host passes every position it reads from a file (a `set` step's x and y, a pair's `cam`, a level item's crop) through the scene's `remap`.

**Never:** scale a sprite beyond what today's code does. Restyle a sprite. Change a touch key, a state name, an act's name, or what an act does. Place something by eye in step b.

## 6. Porting rules: JavaScript to Dart

These are where a port goes wrong without anyone noticing. Pure-Dart packages run their tests twice, `dart test -p vm` and `dart test -p chrome`: numbers behave differently on a phone and in a browser.

| JavaScript | Dart, exactly |
| --- | --- |
| `x \| 0` | `x.truncate()` for a number in int range. For a hash, `toInt32(x)` from coqui_pixel (wraps to 32 bits) |
| `Math.imul(a, b)` | `imul(a, b)` from coqui_pixel (16-bit halves). Never `a * b` on 32-bit values: the web loses bits |
| `>>>`, `>>`, `<<` on 32-bit values | the same operator, then `& 0xFFFFFFFF`. Check both test platforms |
| `a % b` with a negative `a` | `a.remainder(b)`. Dart's `%` never returns a negative |
| `Math.round(x)` | `(x + 0.5).floor()`. Dart's `round()` differs for negative halves |
| `Math.hypot`, `Math.cbrt` | `sqrt(a*a + b*b)`; `pow(x, 1/3)` for x ≥ 0 |
| `if (x)`, `x \|\| y`, `!x` on numbers, strings, null | spell it out: `x != 0`, `x != null && x.isNotEmpty`, `x ?? y`. JavaScript treats 0, "", null, undefined and NaN as false |
| `a == b` across types | compare the same types. `== null` covers undefined too |
| Reading past the end of a list, or a missing key | JavaScript gives undefined; Dart throws. Guard it the way the old code relies on |
| `arr.sort(f)` | JavaScript's sort is stable. Use `mergeSort` from package:collection, or add the index as a tie-break |
| `Math.random()` | the `Rng` passed in. Never a new one. `Math.floor(Math.random() * n)` is `(rng.next() * n).floor()` |
| `Date.now()`, `new Date()` | the `Clock` passed in |
| `setTimeout`, `await sleep(ms)` | the host's `wait` or `sleep`. Never `Future.delayed` in engine, scene or runner code: tests run on a fake clock |
| An `async` act that is not awaited (`suelto`) | keep it un-awaited, exactly where the old code does |
| Float32Array | `Float32List`. Do not swap it for doubles: `zb[i] === groundZ[i]` depends on the rounding |
| Colours `#RRGGBB` | convert once to `0xFFBBGGRR` |
| `canvas`, `document`, `localStorage`, `fetch`, `AudioContext` | never in a port. Each is behind a contract |

Other rules:

- Keep the old function's name in a comment above each ported function (`// juego.js: decide`).
- Keep the old code's constants as they are. A number that looks arbitrary was tuned.
- Do not fix a bug you find in the old code. Port it and report it.
- No Spanish text and no clip id in code. Take the fixed lines from `course.fixedClip(role)`.
- English on screen stays exactly as in v=39. Copy the strings.
- No `print`. No TODO left behind. `dart format`. `flutter analyze` with zero issues.

## 7. Commands and reports

- Get packages: `flutter pub get` at `coqui/`.
- One package's tests: `flutter test` in the package; pure Dart packages: `dart test -p vm` and `dart test -p chrome`.
- The boundary check: `dart run tool/check_boundaries.dart` at `coqui/`.
- A feature alone: `flutter run -d chrome -t lib/dev_main.dart` in the feature.
- A story played with no screen: `dart run tool/juega.dart <story> <plan> <seed>` at `coqui/` (after order 15).
- Git: branch `lane/<package>/<order number>`, your own worktree, commit small, push often. Never push to main. Never open a pull request. Never touch `historia/`, `docs/` or another package.
- Nothing that costs money: no ElevenLabs calls or tests, no push under `historia/cuentos/` (it starts the paid audio job), no accounts, no keys.
- Report, short: what you did; each check and its number; what failed; requests filed; anything you had to choose (there should be nothing). Never claim a check you did not run.
