// The course the differential tests run on: the review pairs, their clip lines, the level-check items, the places
// and each story's focus words, as tool/diff/make_fixture.mjs copied them from historia/.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';

Map<String, dynamic> readFixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

class FixtureCatalog implements CourseCatalog {
  FixtureCatalog([Map<String, dynamic>? course])
    : _c = course ?? readFixture('course.json') {
    _pairs = [
      for (final p in _c['pairs'] as List)
        ReviewPair.fromJson(
          (p as Map<String, dynamic>)['item'] as Map<String, dynamic>,
          scene: p['scene'] as String,
        ),
    ];
    _places = [
      for (final l in _c['places'] as List)
        Place.fromJson(l as Map<String, dynamic>),
    ];
    _levels = [
      for (final q in _c['levelItems'] as List)
        LevelItem.fromJson(q as Map<String, dynamic>),
    ];
    _clips = {
      for (final e in (_c['clips'] as Map<String, dynamic>).entries)
        e.key: e.value as Map<String, dynamic>,
    };
  }

  final Map<String, dynamic> _c;
  late final List<ReviewPair> _pairs;
  late final List<Place> _places;
  late final List<LevelItem> _levels;
  late final Map<String, Map<String, dynamic>> _clips;

  @override
  Future<void> load() async {}

  @override
  List<Place> get places => _places;

  @override
  List<ReviewPair> get pairs => _pairs;

  @override
  List<LevelItem> get levelItems => _levels;

  @override
  ClipInfo? clip(String id) {
    final c = _clips[id];
    if (c == null) return null;
    return ClipInfo(
      id: id,
      who: c['who'] as String,
      text: c['text'] as String,
      habla: c['habla'] as String?,
      startMs: 0,
      endMs: 1000,
      url: 'audio/$id.mp3',
    );
  }

  @override
  String fixedClip(String role) {
    final id = (_c['fixed'] as Map<String, dynamic>)[role] as String?;
    if (id == null) throw ArgumentError.value(role, 'role');
    return id;
  }

  @override
  Future<Map<String, dynamic>> story(String id) async {
    final s = (_c['stories'] as Map<String, dynamic>)[id];
    if (s == null) throw StateError('no story $id');
    return s as Map<String, dynamic>;
  }

  @override
  ReviewPair? pairFor(String word) {
    final n = language.normalize(word);
    for (final p in _pairs) {
      if (language.normalize(p.word) == n) return p;
    }
    return null;
  }

  @override
  StoryMeta? meta(String id) => null;
  @override
  Future<Book?> book(String id) async => null;
  @override
  CallBrief? callFor(String placeId) => null;
  @override
  List<String> get goodbyeWords => const [];
  @override
  Future<List<HeardLine>> linesWith(
    String word,
    Iterable<String> storyIds, {
    int max = 5,
  }) async => const [];
}
