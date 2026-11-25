// A course catalog that reads the old site's files straight from disk: `historia/datos/*.json`, `historia/cuentos/*.json`,
// `historia/audio/ready.json`, `historia/audio/marcas.json`. For the no-screen player (tool/juega.dart) and the
// differential check against the recorded runs. A clip exists exactly when it is in ready.json, has marks and its mp3 is
// in the worktree (the recording tool's rule: the runner answered "ID3" for a file that exists, 404 when not).
//
// Only what a story needs is implemented: places, which stories the course names (`meta`), a story file, a clip, a fixed
// line. The rest throws.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';

/// The folder that holds `historia/`: [from] or its nearest parent that has one.
Directory findRoot([Directory? from]) {
  var d = (from ?? Directory.current).absolute;
  for (;;) {
    if (Directory('${d.path}/historia/cuentos').existsSync()) return d;
    final p = d.parent;
    if (p.path == d.path) {
      throw StateError(
        'no historia/ folder above ${from ?? Directory.current}',
      );
    }
    d = p;
  }
}

class DiskCourse implements CourseCatalog {
  DiskCourse(this.root) : _hist = '${root.path}/historia';

  final Directory root;
  final String _hist;
  List<Place> _places = const [];
  Map<String, StoryMeta> _metas = const {};
  Map<String, String> _fixed = const {};
  Map<String, Map<String, dynamic>> _lines = {};
  Set<String> _have = {};
  Map<String, List<int>> _marks = {};
  String _version = '0';
  final Map<String, Map<String, dynamic>> _stories = {};

  dynamic _json(String path) =>
      jsonDecode(File('$_hist/$path').readAsStringSync());

  @override
  Future<void> load() async {
    final curso = _json('datos/curso.json') as Map<String, dynamic>;
    _places = [
      for (final l in curso['lugares'] as List)
        Place.fromJson(Map<String, dynamic>.from(l as Map)),
    ];
    _metas = {
      for (final e in (curso['cuentos'] as Map).entries)
        e.key as String: StoryMeta.fromJson(
          e.key as String,
          Map<String, dynamic>.from(e.value as Map),
        ),
    };
    final fijos = _json('datos/fijos.json') as Map<String, dynamic>;
    _fixed = Map<String, String>.from(fijos['clips'] as Map);
    _lines = {
      for (final e in (fijos['lineas'] as Map).entries)
        e.key as String: Map<String, dynamic>.from(e.value as Map),
    };
    final ready = _json('audio/ready.json') as Map<String, dynamic>;
    _have = {for (final c in ready['clips'] as List) c as String};
    _version = '${ready['v'] ?? 0}';
    final marks = _json('audio/marcas.json') as Map<String, dynamic>;
    _marks = {
      for (final e in marks.entries)
        e.key: [for (final m in e.value as List) (m as num).toInt()],
    };
  }

  @override
  List<Place> get places => _places;

  /// A story the course names (`datos/curso.json`, `cuentos`), or null: a file only in `cuentos/` is not one.
  @override
  StoryMeta? meta(String id) => _metas[id];

  @override
  Future<Map<String, dynamic>> story(String id) async => _stories[id] ??=
      Map<String, dynamic>.from(_json('cuentos/$id.json') as Map);

  /// The bytes of a story file (for its SHA-256).
  List<int> storyBytes(String id) =>
      File('$_hist/cuentos/$id.json').readAsBytesSync();

  @override
  ClipInfo? clip(String id) {
    final m = _marks[id];
    if (m == null || !_have.contains(id)) return null;
    if (!File('$_hist/audio/$id.mp3').existsSync()) return null;
    final l = _lines[id];
    return ClipInfo(
      id: id,
      who: (l?['who'] as String?) ?? '',
      text: (l?['text'] as String?) ?? '',
      startMs: m[0],
      endMs: m[1],
      url: 'audio/$id.mp3?v=$_version',
    );
  }

  @override
  String fixedClip(String role) =>
      _fixed[role] ??
      (throw ArgumentError.value(role, 'role', 'no fixed line for this role'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('DiskCourse: ${invocation.memberName}');
}
