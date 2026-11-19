import 'package:coqui_contracts/src/json.dart';

/// The two skills a word has a record for: listening (ear) and speaking (mouth).
enum Skill { ear, mouth }

/// One skill of one word. Field for field today's record (historia/palabras.js, skill()).
///
/// Numbers are read and written as palabras.js leaves them: `gap` and `due` can hold fractions (lines 32,
/// 33, 35) and are written back unrounded; a whole value is written as an integer (5, not 5.0), as
/// JSON.stringify does. The other fields are counters or clock readings (`ultima`, `aciertos`, `aparcada`
/// = now + 7 days, line 36) and are whole numbers.
class SkillRecord {
  SkillRecord({
    this.etapa = 0,
    this.paso = 1,
    this.seguidas = 0,
    this.fallos = 0,
    this.gap = 0,
    this.due = 0,
    List<int>? aciertos,
    this.ultima = 0,
    this.aparcada = 0,
    this.marca = 0,
    this.n = 0,
    this.bien = 0,
    this.presunta,
  }) : aciertos = aciertos ?? <int>[];

  /// A record as palabras.js stores it. A missing key takes skill()'s value.
  factory SkillRecord.fromJson(Map<String, dynamic> j) => SkillRecord(
    etapa: jsonInt(j['etapa']),
    paso: jsonInt(j['paso'], 1),
    seguidas: jsonInt(j['seguidas']),
    fallos: jsonInt(j['fallos']),
    gap: jsonDouble(j['gap']),
    due: jsonNum(j['due']),
    aciertos: [
      for (final t in (j['aciertos'] as List?) ?? const []) jsonInt(t),
    ],
    ultima: jsonInt(j['ultima']),
    aparcada: jsonInt(j['aparcada']),
    marca: jsonInt(j['marca']),
    n: jsonInt(j['n']),
    bien: jsonInt(j['bien']),
    presunta: jsonIntOrNull(j['presunta']),
  );

  int etapa, paso, seguidas, fallos, n, bien, marca;
  double gap; // days

  /// When the word comes back, ms since epoch, 0 = none. A `num`, not an int: palabras.js line 33
  /// (`e.due=t+e.gap*DAY`) can give a fraction of a ms, and the stored JSON keeps exactly what it wrote.
  num due;
  int ultima, aparcada; // ms since epoch, 0 = none
  List<int> aciertos;
  int? presunta;

  /// The keys in skill()'s order; `presunta` only when PAL.presume set it.
  Map<String, dynamic> toJson() => {
    'etapa': etapa,
    'paso': paso,
    'seguidas': seguidas,
    'fallos': fallos,
    'gap': jsonNumber(gap),
    'due': jsonNumber(due),
    'aciertos': [...aciertos],
    'ultima': ultima,
    'aparcada': aparcada,
    'marca': marca,
    'n': n,
    'bien': bien,
    'presunta': ?presunta,
  };
}

/// One word: palabras.js, rec(): {w, primera, oida, ear, mouth}.
class WordRecord {
  WordRecord({
    required this.w,
    required this.primera,
    this.oida = 0,
    SkillRecord? ear,
    SkillRecord? mouth,
  }) : ear = ear ?? SkillRecord(),
       mouth = mouth ?? SkillRecord();

  factory WordRecord.fromJson(Map<String, dynamic> j) => WordRecord(
    w: j['w'] as String,
    primera: jsonInt(j['primera']),
    oida: jsonInt(j['oida']),
    ear: SkillRecord.fromJson(jsonMap(j['ear'])),
    mouth: SkillRecord.fromJson(jsonMap(j['mouth'])),
  );

  String w;
  int primera;
  int oida;
  SkillRecord ear;
  SkillRecord mouth;

  /// The record of one skill.
  SkillRecord of(Skill skill) => skill == Skill.ear ? ear : mouth;

  Map<String, dynamic> toJson() => {
    'w': w,
    'primera': primera,
    'oida': oida,
    'ear': ear.toJson(),
    'mouth': mouth.toJson(),
  };
}

/// One story: palabras.js, db.cuentos[id]: {n, primera, ultima, perdido, presunto}.
/// A key the old code has not set is left out, as JSON.stringify leaves out undefined.
class StoryRecord {
  StoryRecord({
    required this.n,
    required this.primera,
    this.ultima,
    this.perdido,
    this.presunto,
  });

  factory StoryRecord.fromJson(Map<String, dynamic> j) => StoryRecord(
    n: jsonInt(j['n']),
    primera: jsonInt(j['primera']),
    ultima: jsonIntOrNull(j['ultima']),
    perdido: jsonIntOrNull(j['perdido']),
    presunto: jsonIntOrNull(j['presunto']),
  );

  int n;
  int primera;
  int? ultima;
  int? perdido;
  int? presunto;

  Map<String, dynamic> toJson() => {
    'n': n,
    'primera': primera,
    'ultima': ?ultima,
    'perdido': ?perdido,
    'presunto': ?presunto,
  };
}

/// One decision inside a story, as juego.js logs it (LOG entries: word, asked, got, ok, ms).
class Decision {
  Decision({this.word, this.asked, this.got, required this.ok, this.ms});

  factory Decision.fromJson(Map<String, dynamic> j) => Decision(
    word: j['word'] as String?,
    asked: j['asked'] as String?,
    got: j['got'] as String?,
    ok: j['ok'] == true,
    ms: jsonIntOrNull(j['ms']),
  );

  String? word;
  String? asked;
  String? got;
  bool ok;
  int? ms;

  /// juego.js writes `word` even when it is null (elige), and no `ms` in an elige.
  Map<String, dynamic> toJson() => {
    'word': word,
    'asked': asked,
    'got': got,
    'ok': ok,
    'ms': ?ms,
  };
}

/// What a played story hands to the progress store (PAL.cuento's S and LOG):
/// S.id, S.focus_words, S.back_again, S._lost, and LOG.
class StoryResult {
  StoryResult({
    required this.id,
    this.focusWords = const [],
    this.backAgain = const [],
    this.lost = 0,
    this.log = const [],
  });

  String id;
  List<String> focusWords;
  List<String> backAgain;
  int lost;
  List<Decision> log;
}

/// The learner's progress: the one shared state (palabras.js, PAL).
abstract interface class ProgressStore {
  Stream<void> get changes; // fires after every save
  Map<String, dynamic> get raw; // the whole JSON, read only
  Iterable<WordRecord> get words;
  WordRecord? word(String w);
  StoryRecord? story(String id);
  bool played(String id); // app.html: hecho
  List<String> due(Skill skill, {int? at}); // PAL.vence
  WordRecord heard(String w); // PAL.oida
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }); // PAL.responde
  void storyFinished(StoryResult r); // PAL.cuento
  void presume(
    List<String> words,
    List<String> stories,
    List<Object?> log,
  ); // PAL.presume
  void listened(String id); // PAL.oido
  bool hasRead(String id); // db.leidos
  void markRead(String id); // db.leidos
  void addMinutes(double m); // PAL.minutos
  double get minutes; // db.minutos
  int get streak; // PAL.racha
  bool openForSpeaking(String w); // PAL.abiertaHabla
  Object? setting(String key); // db.ajustes: min, todo, bienvenida, habla
  void setSetting(String key, Object value);
  List<String> get added; // db.extra
  void add(String wordOrGoal);
  Map<String, dynamic>? get levelResult; // db.nivel
  String export();
  void import(String json);
  void reset();
}
