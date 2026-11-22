// La plaza's cast (lib/src/plaza/plaza_cast.dart): every sprite it draws is there and draws something, the people
// stand as the sheets' rules.anchor says a person of mkPersona stands (plaza-sheet.json rules.anchor: column 24, 53 rows
// drawn standing for a grown-up, 41 for a child, the feet at the bottom edge), and everyone is someone else.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/plaza/plaza_cast.dart';
import 'package:flutter_test/flutter_test.dart';

int _top(Sprite s) {
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 != 0) return y;
    }
  }
  return s.h;
}

void main() {
  test('every sprite of the cast draws something', () {
    final all = plazaCastSheet();
    expect(all.length, greaterThan(200));
    for (final (name, s) in all) {
      expect(s.px.any((c) => c >>> 24 != 0), isTrue, reason: name);
    }
  });

  test('the new people of page 13 are all here, with the speaker keys of the scripts', () {
    for (final k in const [
      'ana',
      'mama_ana',
      'beto',
      'abuela_ana',
      'tito',
      'vendedor',
      'maestra',
      'doctor',
      'cocinero',
      'policia',
      'la_joven',
    ]) {
      expect(PLAZA_GENTE.containsKey(k), isTrue, reason: k);
    }
    expect(TURISTAS, hasLength(6));
    for (final t in TURISTAS) {
      expect(PLAZA_GENTE.containsKey(t), isTrue, reason: t);
    }
  });

  test('a person stands as a person of mkPersona: 48 wide, the feet at the bottom edge, as tall as the kit makes him', () {
    for (final id in PLAZA_QUIENES) {
      final s = mkPlazaPersona(id, 'idle');
      expect(s.w, 48, reason: id);
      expect(inkBottom(s), s.h - 1, reason: id);
      // a grown-up is 53 rows from his crown to his feet, a child 41 (rules.anchor); a hat adds rows above, a bald head is 2 lower
      final body = plazaNino(id) ? 41 : 53;
      expect(
        inkBottom(s) - _top(s),
        greaterThanOrEqualTo(body - 3),
        reason: id,
      ); // a bald head: 2 rows less
      expect(inkBottom(s) - _top(s), lessThanOrEqualTo(body + 12), reason: id);
    }
  });

  test('every pose draws, and the poses differ from standing still', () {
    for (final id in PLAZA_GENTE.keys) {
      final idle = mkPlazaPersona(id, 'idle').px;
      for (final p in PLAZA_POSES.skip(1)) {
        final s = mkPlazaPersona(id, p);
        expect(s.px, isNot(idle), reason: '$id $p');
      }
    }
  });

  test('no two of the new people look the same', () {
    final seen = <String, String>{};
    for (final id in PLAZA_GENTE.keys) {
      final k = mkPlazaPersona(id, 'idle').px.join(',');
      expect(seen.containsKey(k), isFalse, reason: '$id looks like ${seen[k]}');
      seen[k] = id;
    }
  });

  test('El banco\'s people and the family are taken from where they are; an unknown one is refused', () {
    for (final id in [...GENTE_BANCO, 'luis', 'carmen']) {
      expect(mkPlazaPersona(id, 'idle').w, 48, reason: id);
    }
    expect(() => mkPlazaPersona('nadie', 'idle'), throwsArgumentError);
  });

  test('the pigeon, the flags and the things', () {
    for (final p in PALOMA_POSES) {
      final s = mkPalomaPz(p);
      expect([s.w, s.h], [18, 13], reason: p);
    }
    expect(mkPalomaPz('vuela', 0).px, isNot(mkPalomaPz('vuela', 1).px));
    expect(mkBandera('us').px, isNot(mkBandera('pr').px));
  });
}
