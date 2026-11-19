// The course and the progress the map's dev entry and tests run on (in test/support/ so that a browser can load it): the ten places of curso.js
// (docs/proyecto/pixel/curso.js; the stories, titles and minutes of the three built places are its own), over
// the fakes of coqui_testing. This is test data, not feature code: the feature reads every name from the
// catalog.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';

import 'map_seeds.dart';

/// app.html: `plan()` writes the title of the review entry itself, and nothing in the catalog holds it. The
/// dev entry and the tests give it to the screen, as a stand-in for what is decided.
const fixtureReviewTitle = '¿Cuál?';

/// curso.js: the places, as [id, n, nombre, en, fork, scenes].
const _placeRows = <List<Object?>>[
  [
    'casa',
    1,
    'La casa',
    "Grandma's house",
    null,
    ['El frente', 'El balcón', 'La sala', 'El patio'],
  ],
  [
    'parque',
    2,
    'El parque',
    'The park',
    '2a',
    ['El camino', 'El campo', 'El lago', 'El banco'],
  ],
  [
    'cocina',
    3,
    'La cocina',
    'The kitchen',
    '2b',
    ['La mesa', 'La estufa', 'La nevera', 'A comer'],
  ],
  [
    'colmado',
    4,
    'El colmado',
    'The corner shop',
    null,
    ['El mostrador', 'Los estantes', 'Las frutas', 'La caja'],
  ],
  [
    'calle',
    5,
    'La calle',
    'The street',
    '4a',
    ['La esquina', 'La parada', 'Las tiendas', 'El cruce'],
  ],
  [
    'plaza',
    6,
    'La plaza',
    'The town square',
    '4b',
    ['El banco de la plaza', 'El reloj', 'El quiosco', 'El calendario'],
  ],
  [
    'playa',
    7,
    'La playa',
    'The beach',
    '5a',
    ['La orilla', 'La sombrilla', 'La ropa', 'El cielo'],
  ],
  [
    'fonda',
    8,
    'La fonda',
    'The diner',
    '5b',
    ['La entrada', 'El pedido', 'La comida', 'La cuenta'],
  ],
  [
    'casa2',
    9,
    'La casa, un día entero',
    'A whole day at home',
    null,
    ['El cuarto', 'El baño', 'La sala, de día', 'La noche'],
  ],
  [
    'fuerte',
    10,
    'El fuerte',
    'The fort',
    null,
    ['El camino al fuerte', 'La música', 'Los regalos', 'La muralla, de noche'],
  ],
];

/// curso.js: the stories of the three built places, as id: [title, minutes].
const _built = <String, List<Object>>{
  'la-lluvia': ['La lluvia', 2],
  'el-bizcocho': ['El bizcocho', 3],
  'donde-esta-el-pajaro': ['¿Dónde está el pájaro?', 3],
  'el-jugo': ['El jugo', 4],
  'que-calor': ['¡Qué calor!', 3],
  'la-familia': ['La familia', 4],
  'la-foto': ['La foto', 3],
  'quien-eres-tu': ['¿Quién eres tú?', 4],
  'las-flores': ['Las flores', 5],
  'que-es-esto': ['¿Qué es esto?', 5],
  'hasta-manana': ['Hasta mañana', 4],
  'uno-dos-tres': ['Uno, dos, tres', 4],
  'donde-esta-el-gato': ['¿Dónde está el gato?', 5],
  'rapido-despacio': ['Rápido, despacio', 4],
  'la-bola': ['La bola', 5],
  'arriba-abajo': ['¡Arriba! ¡Abajo!', 6],
  'otra-vez': ['¡Otra vez!', 5],
  'pan-para-el-pato': ['Pan para el pato', 6],
  'los-botes': ['Los botes', 6],
  'cual': ['¿Cuál?', 5],
  'la-piragua': ['La piragua', 4],
  'senor-senora': ['¡Señor! ¡Señora!', 5],
  'el-bebe-duerme': ['El bebé duerme', 4],
  'la-mesa': ['La mesa', 5],
  'la-cuchara': ['La cuchara', 5],
  'tengo-hambre': ['Tengo hambre', 5],
  'arroz-con-habichuelas': ['Arroz con habichuelas', 5],
  'el-pollo-y-el-huevo': ['El pollo y el huevo', 5],
  'cuidado': ['¡Cuidado!', 5],
  'no-hay-leche': ['No hay leche', 6],
  'para-los-pajaros': ['Para los pájaros', 5],
  'jugo-de-china': ['Jugo de china', 5],
};

/// curso.js: the stories of each built place.
const _storiesOf = <String, List<String>>{
  'casa': [
    'la-lluvia',
    'el-bizcocho',
    'donde-esta-el-pajaro',
    'el-jugo',
    'que-calor',
    'la-familia',
    'la-foto',
    'quien-eres-tu',
    'las-flores',
    'que-es-esto',
    'hasta-manana',
  ],
  'parque': [
    'uno-dos-tres',
    'donde-esta-el-gato',
    'rapido-despacio',
    'la-bola',
    'arriba-abajo',
    'otra-vez',
    'pan-para-el-pato',
    'los-botes',
    'cual',
    'la-piragua',
    'senor-senora',
    'el-bebe-duerme',
  ],
  'cocina': [
    'la-mesa',
    'la-cuchara',
    'tengo-hambre',
    'arroz-con-habichuelas',
    'el-pollo-y-el-huevo',
    'cuidado',
    'no-hay-leche',
    'para-los-pajaros',
    'jugo-de-china',
  ],
};

/// The sample course (coqui_testing) with the ten places of the old map.
///
/// [builtPlaces] is how many places, from the first, have stories: 3 is what v=39 has built; more are made-up
/// stories (`<place id>-1`, `<place id>-2`, titled "Story 4.1" and so on), so a demo can finish every place.
/// [pairWords] are the words that have a picture pair, as the old review sets have (the Today card offers a
/// review of due words that have one).
class MapFixtureCourse extends FakeCourseCatalog {
  MapFixtureCourse({this.builtPlaces = 3, this.pairWords = const []});

  final int builtPlaces;
  final List<String> pairWords;

  late final List<Place> _places = [
    for (var k = 0; k < _placeRows.length; k++) _place(k),
  ];

  Place _place(int k) {
    final r = _placeRows[k];
    final id = r[0]! as String;
    return Place(
      id: id,
      n: r[1]! as int,
      name: r[2]! as String,
      en: r[3]! as String,
      fork: r[4] as String?,
      stories: k >= builtPlaces
          ? const []
          : _storiesOf[id] ?? ['$id-1', '$id-2'],
      scenes: [...(r[5]! as List).cast<String>()],
    );
  }

  @override
  List<Place> get places => _places;

  @override
  StoryMeta? meta(String id) {
    final b = _built[id];
    if (b != null) {
      return StoryMeta(id: id, title: b[0] as String, minutes: b[1] as int);
    }
    final m = RegExp(r'^(\w+)-(\d)$').firstMatch(id);
    if (m == null) return null;
    final n = _placeRows.indexWhere((r) => r[0] == m.group(1)) + 1;
    return StoryMeta(id: id, title: 'Story $n.${m.group(2)}', minutes: 3);
  }

  @override
  List<ReviewPair> get pairs => [
    for (final w in pairWords)
      ReviewPair(
        word: w,
        say: '',
        scene: 'frente',
        yes: PictureSpec(cam: const [0, 0]),
        no: PictureSpec(cam: const [0, 0]),
      ),
  ];
}

/// The clock of the reference pictures: 19 Nov 2026, 12:00 in Puerto Rico (16:00 UTC).
int get fixtureNowMs => DateTime.utc(2026, 11, 19, 16).millisecondsSinceEpoch;

/// What [fixture] makes: the services, and the fakes inside them for a test to read.
typedef MapFixture = ({
  Services services,
  FakeProgressStore progress,
  FakeNavigator nav,
  FakeClock clock,
  FakeClipPlayer clips,
  FakeHaptics haptics,
});

/// Services over the fakes with the course above and the progress of [seed] (a key of [mapSeeds]; none: nothing
/// stored). Every word of the seed has a picture pair, so the review is offered when words are due.
///
/// [todo] turns "Open every place" on. [reduceMotion] is the OS setting. The store, the clock and the
/// navigator are returned for tests to read.
MapFixture fixture({
  String? seed,
  int builtPlaces = 3,
  bool todo = false,
  bool reduceMotion = false,
}) {
  final clock = FakeClock(fixtureNowMs);
  final json = seed == null ? null : mapSeeds[seed];
  final words = json == null
      ? const <String>[]
      : [
          for (final w
              in ((jsonDecode(json) as Map<String, dynamic>)['palabras']
                      as Map<String, dynamic>)
                  .keys)
            w,
        ];
  final progress = FakeProgressStore(clock: clock, json: json);
  if (todo) progress.setSetting('todo', 1);
  // v=39 keeps no return date from a word that has no picture pair out of its Today card; in the `todo` state
  // (everything built is played, nothing is due) the words still "due" are the ones with no pair
  final dueNow = progress.due(Skill.ear).toSet();
  final pairWords = seed == 'todo'
      ? [
          for (final w in words)
            if (!dueNow.contains(w)) w,
        ]
      : words;
  final nav = FakeNavigator();
  final clips = FakeClipPlayer();
  final haptics = FakeHaptics();
  final services = fakeServices(
    progress: progress,
    course: MapFixtureCourse(builtPlaces: builtPlaces, pairWords: pairWords),
    clock: clock,
    nav: nav,
    clips: clips,
    haptics: haptics,
    reduceMotion: reduceMotion,
  );
  return (
    services: services,
    progress: progress,
    nav: nav,
    clock: clock,
    clips: clips,
    haptics: haptics,
  );
}

/// One story finished, the way a story's end records it (`progress.storyFinished`).
void finishStory(FakeProgressStore progress, String id) =>
    progress.storyFinished(
      StoryResult(id: id, focusWords: [], backAgain: [], lost: 0, log: []),
    );

/// The three demo states of the map, as mapa.html's `?hecho=0`, `?hecho=3` and `?hecho=10`:
/// `none` (nothing done; places 1 to 3 have stories, so they are open), `three` (places 1 to 3 done, place 4
/// has stories and is open), `all` (all ten places have stories and are done).
MapFixture fixtureDemoWith(String demo, {bool reduceMotion = false}) {
  switch (demo) {
    case 'three':
      return _demo(4, 3, reduceMotion);
    case 'all':
      return _demo(10, 10, reduceMotion);
    default:
      return _demo(3, 0, reduceMotion);
  }
}

MapFixture _demo(int built, int played, bool reduceMotion) {
  final f = fixture(builtPlaces: built, reduceMotion: reduceMotion);
  final course = MapFixtureCourse(builtPlaces: built);
  for (final l in course.places.take(played)) {
    for (final id in l.stories) {
      finishStory(f.progress, id);
    }
  }
  return f;
}
