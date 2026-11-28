// La entrada's own sprites (lib/src/entrada/entrada_sprites.dart): dimensions match entrada-sheet.json's spot boxes
// and entrada-preview.html's stand-ins, every sprite has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/entrada/entrada_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

int _ink(Sprite s) {
  var n = 0;
  for (final p in s.px) {
    if (p >>> 24 != 0) n++;
  }
  return n;
}

bool _same(Sprite a, Sprite b) {
  if (a.w != b.w || a.h != b.h) return false;
  for (var i = 0; i < a.px.length; i++) {
    if (a.px[i] != b.px[i]) return false;
  }
  return true;
}

void main() {
  test('preview-matching sprites keep entrada-sheet.json box dimensions', () {
    expect((mkFlores().w, mkFlores().h), (10, 12));
    expect((mkEstrella().w, mkEstrella().h), (8, 10));
    expect((mkPlatos().w, mkPlatos().h), (16, 18));
    expect((mkBandejaT().w, mkBandejaT().h), (30, 3));
    expect((mkVela().w, mkVela().h), (6, 10));
    expect((mkCosaAgua(con: true).w, mkCosaAgua(con: true).h), (10, 12));
    expect((mkCosaAgua(con: false).w, mkCosaAgua(con: false).h), (10, 12));
    expect((mkCosaPan(con: true).w, mkCosaPan(con: true).h), (10, 12));
    expect((mkCosaPan(con: false).w, mkCosaPan(con: false).h), (10, 12));
    expect((mkMenu(open: true).w, mkMenu(open: true).h), (14, 12));
    expect((mkMenu(open: false).w, mkMenu(open: false).h), (14, 12));
    expect((mkDulces(3).w, mkDulces(3).h), (12, 8));
    expect((mkTaburete().w, mkTaburete().h), (14, 14));
    expect(
      (mkMantel(57, 24, 15, 'rojo').w, mkMantel(57, 24, 15, 'rojo').h),
      (57, 24),
    );
  });

  test('every sprite in entradaSpritesSheet has opaque pixels', () {
    final sheet = entradaSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(35));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants and colours differ visually', () {
    expect(_same(mkVela(lit: true), mkVela(lit: false)), isFalse);
    expect(
      _same(mkVela(lit: false, smoke: false), mkVela(lit: false, smoke: true)),
      isFalse,
    );
    expect(_same(mkCosaAgua(con: true), mkCosaAgua(con: false)), isFalse);
    expect(_same(mkCosaPan(con: true), mkCosaPan(con: false)), isFalse);
    expect(_same(mkCosaAgua(con: true), mkCosaPan(con: true)), isFalse);
    expect(_same(mkMenu(open: true), mkMenu(open: false)), isFalse);
    expect(_same(mkDulces(3), mkDulces(2)), isFalse);
    expect(_same(mkDulces(2), mkDulces(1)), isFalse);
    expect(_same(mkDulces(1), mkDulces(0)), isFalse);
    expect(_same(mkCafe(conLeche: true), mkCafe(conLeche: false)), isFalse);
    expect(_same(mkSalpicadura(0), mkSalpicadura(1)), isFalse);
    expect(_same(mkNotasMusica(0), mkNotasMusica(1)), isFalse);

    final colors = const ['rojo', 'azul', 'verde', 'amarillo', 'blanco'];
    final cloths = [for (final c in colors) mkMantel(57, 24, 15, c)];
    for (var i = 0; i < cloths.length; i++) {
      for (var j = i + 1; j < cloths.length; j++) {
        expect(
          _same(cloths[i], cloths[j]),
          isFalse,
          reason: '${colors[i]} and ${colors[j]} cloths must differ',
        );
      }
    }

    expect(
      _same(
        mkPersona(mkMeseroWho(bowtie: true), 'idle', false, true),
        mkPersona(
          mkMeseroWho(bowtie: false, bandage: true, cane: true),
          'idle',
          false,
          true,
        ),
      ),
      isFalse,
    );
    expect(
      _same(
        mkPersona(mkMeseraWho(pad: false), 'idle', false, false),
        mkPersona(mkMeseraWho(pad: true), 'idle', false, false),
      ),
      isFalse,
    );
  });
}
