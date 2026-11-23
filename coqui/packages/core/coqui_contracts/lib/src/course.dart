import 'package:coqui_contracts/src/json.dart';
import 'package:coqui_contracts/src/language.dart';

/// A place on the map: one entry of CURSO.lugares (curso.js).
/// JSON keys: id, n, nombre, en, fork, cuentos, dibujos, haz, escenas.
class Place {
  Place({
    required this.id,
    required this.n,
    required this.name,
    required this.en,
    this.fork,
    this.stories = const [],
    this.pictureStories = const [],
    this.routines = const [],
    this.scenes = const [],
  });

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    id: j['id'] as String,
    n: jsonInt(j['n']),
    name: j['nombre'] as String,
    en: j['en'] as String,
    fork: j['fork'] as String?,
    stories: jsonStrings(j['cuentos']),
    pictureStories: jsonStrings(j['dibujos']),
    routines: jsonStrings(j['haz']),
    scenes: jsonStrings(j['escenas']),
  );

  String id;
  int n;
  String name;
  String en;
  String? fork;
  List<String> stories;
  List<String> pictureStories;
  List<String> routines;
  List<String> scenes;

  /// curso.js leaves out a list a place does not have yet, and `fork` where there is none.
  Map<String, dynamic> toJson() => {
    'id': id,
    'n': n,
    'nombre': name,
    'en': en,
    'fork': ?fork,
    if (stories.isNotEmpty) 'cuentos': [...stories],
    if (pictureStories.isNotEmpty) 'dibujos': [...pictureStories],
    if (routines.isNotEmpty) 'haz': [...routines],
    if (scenes.isNotEmpty) 'escenas': [...scenes],
  };
}

/// A story's entry in CURSO.cuentos (curso.js): {t, min}, under its id.
class StoryMeta {
  StoryMeta({required this.id, required this.title, required this.minutes});

  factory StoryMeta.fromJson(String id, Map<String, dynamic> j) =>
      StoryMeta(id: id, title: j['t'] as String, minutes: jsonInt(j['min']));

  String id;
  String title;
  int minutes;

  Map<String, dynamic> toJson() => {'t': title, 'min': minutes};
}

/// One recorded line. who, text and habla are the story file's clip entry
/// (`clips[id]`); startMs and endMs are its marks (juego.js, trim); url is where
/// its audio is.
class ClipInfo {
  ClipInfo({
    required this.id,
    required this.who,
    required this.text,
    this.habla,
    required this.startMs,
    required this.endMs,
    required this.url,
  });

  String id;
  String who;
  String text;
  String? habla;
  int startMs;
  int endMs;
  String url;
}

/// One side of a review pair (cual-*.json, an item's `si` or `no`): {esc, set, cam}.
class PictureSpec {
  PictureSpec({this.scene, Map<String, dynamic>? set, required this.cam})
    : set = set ?? <String, dynamic>{};

  factory PictureSpec.fromJson(Map<String, dynamic> j) => PictureSpec(
    scene: j['esc'] as String?,
    set: j['set'] == null ? null : jsonMap(j['set']),
    cam: [for (final v in j['cam'] as List) v as num],
  );

  /// `esc`: a picture drawn by another scene than its file's. Null: the file's scene.
  String? scene;
  Map<String, dynamic> set;
  List<num> cam;

  /// The files leave out `esc` and an empty `set`.
  Map<String, dynamic> toJson() => {
    'esc': ?scene,
    if (set.isNotEmpty) 'set': set,
    'cam': [...cam],
  };
}

/// One item of a review set (cual-*.json): {w, say, si, no}, with the file's `scene`.
class ReviewPair {
  ReviewPair({
    required this.word,
    required this.say,
    required this.scene,
    required this.yes,
    required this.no,
  });

  /// An item of a review file; [scene] is the file's `scene`.
  factory ReviewPair.fromJson(
    Map<String, dynamic> item, {
    required String scene,
  }) => ReviewPair(
    word: item['w'] as String,
    say: item['say'] as String,
    scene: scene,
    yes: PictureSpec.fromJson(jsonMap(item['si'])),
    no: PictureSpec.fromJson(jsonMap(item['no'])),
  );

  String word;
  String say;
  String scene;
  PictureSpec yes;
  PictureSpec no;

  /// The item as the file has it (the scene is the file's, not the item's).
  Map<String, dynamic> toJson() => {
    'w': word,
    'say': say,
    'si': yes.toJson(),
    'no': no.toJson(),
  };
}

/// One item of the level check (nivel.js, NV): {w, s, p}.
/// p: four pictures, the first is the one that fits; each is [the pair's word,
/// "si" or "no", and, when given, the x the square crop is centred on].
class LevelItem {
  LevelItem({required this.word, required this.step, required this.pictures});

  factory LevelItem.fromJson(Map<String, dynamic> j) => LevelItem(
    word: j['w'] as String,
    step: jsonInt(j['s']),
    pictures: [for (final p in j['p'] as List) List<Object?>.from(p as List)],
  );

  String word;
  int step;
  List<List<Object?>> pictures;

  Map<String, dynamic> toJson() => {
    'w': word,
    's': step,
    'p': [
      for (final p in pictures) [...p],
    ],
  };
}

/// What the call partner is told for one place's call (llamada.js, LLAMADAS[placeId]):
/// {minutos, job, opening, foto}. [agentId] comes from the course's language
/// (`course.language.callAgentId`), defaulting to Spanish's Danny agent.
class CallBrief {
  CallBrief({
    required this.placeId,
    required this.minutes,
    required this.job,
    required this.opening,
    required this.photo,
    this.agentId = spanishCallAgentId,
  });

  factory CallBrief.fromJson(
    String placeId,
    Map<String, dynamic> j, {
    String? agentId,
  }) => CallBrief(
    placeId: placeId,
    minutes: jsonInt(j['minutos']),
    job: j['job'] as String,
    opening: j['opening'] as String,
    photo: j['foto'] as String,
    agentId:
        agentId ??
        j['agentId'] as String? ??
        j['agentid'] as String? ??
        spanishCallAgentId,
  );

  String placeId;
  int minutes;
  String job;
  String opening;
  String photo;
  String agentId;

  Map<String, dynamic> toJson() => {
    'minutos': minutes,
    'job': job,
    'opening': opening,
    'foto': photo,
    if (agentId != spanishCallAgentId) 'agentId': agentId,
  };
}

/// One page of a book (libros/*.json, `pages[i]`): {img, clips}.
class BookPage {
  BookPage({required this.image, required this.clips});

  factory BookPage.fromJson(Map<String, dynamic> j) =>
      BookPage(image: j['img'] as String, clips: jsonStrings(j['clips']));

  String image;
  List<String> clips;

  Map<String, dynamic> toJson() => {
    'img': image,
    'clips': [...clips],
  };
}

/// A book (libros/*.json): {id, title, lee, pages}. lee -> readable.
class Book {
  Book({
    required this.id,
    required this.title,
    required this.readable,
    required this.pages,
  });

  factory Book.fromJson(Map<String, dynamic> j) => Book(
    id: j['id'] as String,
    title: j['title'] as String,
    readable: j['lee'] == true,
    pages: [for (final p in j['pages'] as List) BookPage.fromJson(jsonMap(p))],
  );

  String id;
  String title;
  bool readable;
  List<BookPage> pages;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lee': readable,
    'pages': [for (final p in pages) p.toJson()],
  };
}

/// One line a word was heard in (app.html, oidoEn).
class HeardLine {
  HeardLine({
    required this.storyId,
    required this.storyTitle,
    required this.clipId,
    required this.text,
  });

  String storyId;
  String storyTitle;
  String clipId;
  String text;
}

/// The course: places, stories, review pairs, level check, calls, clips, books.
abstract interface class CourseCatalog {
  Future<void> load();
  List<Place> get places;
  StoryMeta? meta(String id);
  Future<Map<String, dynamic>> story(String id); // the raw story file
  Future<Book?> book(String id);
  List<ReviewPair> get pairs;
  ReviewPair? pairFor(String word); // matched on normalize()
  List<LevelItem> get levelItems;
  CallBrief? callFor(String placeId);
  ClipInfo? clip(String id);
  String fixedClip(String role); // historia/datos/fijos.json
  List<String> get goodbyeWords;
  Future<List<HeardLine>> linesWith(
    String word,
    Iterable<String> storyIds, {
    int max = 5,
  });
}
