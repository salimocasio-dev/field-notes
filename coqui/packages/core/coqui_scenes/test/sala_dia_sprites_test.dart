// La sala, de día's own sprites (lib/src/sala_dia/sala_dia_sprites.dart): dimensions match sala_dia-sheet.json's
// spot boxes and sala_dia-preview.html's stand-ins, every sprite has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/sala_dia/sala_dia_sprites.dart';
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
  test('preview-matching sprites keep sala_dia-sheet.json box dimensions', () {
    expect((mkLibro().w, mkLibro().h), (12, 8));
    expect((mkLibro(open: true).w, mkLibro(open: true).h), (12, 8));
    expect((mkPapel(5).w, mkPapel(5).h), (12, 8));
    expect(
      (mkPapel(3, miniFrog: true).w, mkPapel(3, miniFrog: true).h),
      (12, 8),
    );
    expect((mkTelefono().w, mkTelefono().h), (10, 6));
    expect(
      (mkTelefono(lit: true, bars: 3).w, mkTelefono(lit: true, bars: 3).h),
      (10, 6),
    );
    expect((mkPagina(1).w, mkPagina(1).h), (16, 12));
    expect((mkPagina(2).w, mkPagina(2).h), (16, 12));
    expect((mkPagina(3).w, mkPagina(3).h), (16, 12));
    expect((mkEstrellasBox(3).w, mkEstrellasBox(3).h), (8, 6));
    expect(
      (mkFoto('luis_computadora').w, mkFoto('luis_computadora').h),
      (10, 8),
    );
  });

  test('every sprite in salaDiaSpritesSheet has opaque pixels', () {
    final sheet = salaDiaSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(60));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(
      _same(
        mkAbuelaSalaDia('idle', false),
        mkAbuelaSalaDia('idle', false, harina: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbuelaSalaDia('idle', false),
        mkAbuelaSalaDia('idle', false, silencio: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbuelaSalaDia('idle', false, phone: 'ear'),
        mkAbuelaSalaDia('idle', false, phone: 'mouth'),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbueloSalaDia('idle', false),
        mkAbueloSalaDia('idle', false, doze: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbueloSalaDia('idle', false),
        mkAbueloSalaDia('idle', false, cupEar: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbueloSalaDia('idle', false),
        mkAbueloSalaDia('idle', false, holdPhone: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkNinoSalaDia(FAM['hermano']!, 'idle', false, notebook: true),
        mkNinoSalaDia(FAM['hermano']!, 'idle', false, ball: true),
      ),
      isFalse,
    );
    expect(_same(mkLibro(), mkLibro(open: true)), isFalse);
    expect(
      _same(
        mkLibro(open: true, scribbled: true),
        mkLibro(open: true, patched: true),
      ),
      isFalse,
    );
    expect(_same(mkPapel(5), mkPapel(3)), isFalse);
    expect(_same(mkPapel(3), mkPapel(3, miniFrog: true)), isFalse);
    expect(_same(mkPapel(1), mkPapel(0)), isFalse);
    expect(_same(mkTelefono(), mkTelefono(lit: true, bars: 3)), isFalse);
    expect(
      _same(mkTelefono(lit: true, bars: 3), mkTelefono(lit: true, bars: 2)),
      isFalse,
    );
    expect(
      _same(
        mkTelefono(lit: true, bars: 2),
        mkTelefono(lit: true, bars: 2, blink: true),
      ),
      isFalse,
    );
    expect(_same(mkPagina(1), mkPagina(1, glow: true)), isFalse);
    expect(
      _same(mkPagina(2), mkPagina(2, photos: const ['luis_computadora'])),
      isFalse,
    );
    expect(
      _same(
        mkPagina(2, photos: const ['luis_computadora']),
        mkPagina(2, photos: const ['luis_computadora', 'abuelo_lee']),
      ),
      isFalse,
    );
    expect(
      _same(
        mkPagina(2, photos: const ['luis_computadora']),
        mkPagina(2, photos: const ['abuela_libro']),
      ),
      isFalse,
    );
    expect(_same(mkPagina(3), mkPagina(3, torn: true)), isFalse);
    expect(_same(mkEstrellasBox(3), mkEstrellasBox(2)), isFalse);
    expect(_same(mkEstrellasBox(2), mkEstrellasBox(1)), isFalse);
    expect(_same(mkEstrellasBox(1), mkEstrellasBox(0)), isFalse);
    expect(
      _same(mkFoto('abuelo_lee'), mkFoto('abuelo_lee', torn: true)),
      isFalse,
    );
    expect(_same(mkFoto('luis_computadora'), mkFoto('abuela_libro')), isFalse);
    expect(
      _same(
        mkAbueloSalaDia('idle', false, phone: 'ear'),
        mkAbueloSalaDia('idle', false, phone: 'mouth'),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbueloSalaDia('idle', false, phone: 'ear', phoneBars: 3),
        mkAbueloSalaDia('idle', false, phone: 'ear', phoneBars: 1),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbueloSalaDia('idle', false, phone: 'ear', phoneBars: 2),
        mkAbueloSalaDia(
          'idle',
          false,
          phone: 'ear',
          phoneBars: 2,
          phoneBlink: true,
        ),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbueloSalaDia('idle', false, holdPhone: true, phoneLit: true),
        mkAbueloSalaDia('idle', false, holdPhone: true, phoneLit: false),
      ),
      isFalse,
    );
    expect(
      _same(
        mkNinoSalaDia(FAM['hermano']!, 'idle', false, reads: true),
        mkNinoSalaDia(FAM['hermano']!, 'idle', false, sheet: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkNinoSalaDia(FAM['hermana']!, 'idle', false),
        mkNinoSalaDia(FAM['hermana']!, 'idle', false, reads: true),
      ),
      isFalse,
    );
    expect(
      _same(mkRelojManecillas(hour: 3), mkRelojManecillas(hour: 6)),
      isFalse,
    );
    expect(
      _same(mkRelojManecillas(hour: 3), mkRelojManecillas(hour: 9)),
      isFalse,
    );
    expect(
      _same(mkRelojManecillas(hour: 3), mkRelojManecillas(hour: 12)),
      isFalse,
    );
    expect(
      _same(mkRelojManecillas(hour: 10), mkRelojManecillas(hour: 14)),
      isFalse,
    );
    expect(
      _same(mkRelojManecillas(hour: 14), mkRelojManecillas(hour: 17)),
      isFalse,
    );
    expect(_same(mkDibujoRana(1), mkDibujoRana(2)), isFalse);
    expect(_same(mkDibujoRana(2), mkDibujoRana(3)), isFalse);
    expect(_same(mkPortadaAlbum(3), mkPortadaAlbum(2)), isFalse);
    expect(_same(mkPortadaAlbum(2), mkPortadaAlbum(1)), isFalse);
    expect(_same(mkAvecesPic('compu'), mkAvecesPic('libro')), isFalse);
  });
}
