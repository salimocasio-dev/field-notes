// El pedido's own sprites (lib/src/pedido/pedido_sprites.dart): dimensions match pedido-sheet.json's spot boxes and
// pedido-preview.html's stand-ins, cocinero's chef hat stays within hatch bounds (top row >= 8 at hueco), every sprite
// has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/pedido/pedido_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

int _ink(Sprite s) {
  var n = 0;
  for (final p in s.px) {
    if (p >>> 24 != 0) n++;
  }
  return n;
}

int _topInk(Sprite s) {
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 != 0) return y;
    }
  }
  return s.h;
}

bool _same(Sprite a, Sprite b) {
  if (a.w != b.w || a.h != b.h) return false;
  for (var i = 0; i < a.px.length; i++) {
    if (a.px[i] != b.px[i]) return false;
  }
  return true;
}

void main() {
  test('preview-matching sprites keep pedido-sheet.json box dimensions', () {
    expect((mkGatoPedido('sit').w, mkGatoPedido('sit').h), (26, 20));
    expect((mkCuadroPic('sopa').w, mkCuadroPic('sopa').h), (14, 12));
    expect(
      (mkCuadroPic('sopa', lit: true).w, mkCuadroPic('sopa', lit: true).h),
      (14, 12),
    );
    expect((mkPlato('carne').w, mkPlato('carne').h), (14, 8));
    expect((mkPlatito(3).w, mkPlatito(3).h), (12, 8));
    expect((mkPlatoRana(0).w, mkPlatoRana(0).h), (12, 8));
    expect((mkPlatoRana(3).w, mkPlatoRana(3).h), (12, 10));
    expect((mkPlatanos(3).w, mkPlatanos(3).h), (14, 18));
    expect((mkBebida('refresco').w, mkBebida('refresco').h), (10, 14));
    expect((mkVasito(3).w, mkVasito(3).h), (8, 18));
    expect((mkOrdenBurbuja('sopa').w, mkOrdenBurbuja('sopa').h), (14, 12));
    expect((mkGestoFlecha().w, mkGestoFlecha().h), (9, 7));
    expect(
      (
        mkAbuelaPedido('senala_izq', false).w,
        mkAbuelaPedido('senala_izq', false).h,
      ),
      (52, 50),
    );
  });

  test(
    'cocinero chef hat stays at screen y >= 8 when placed at hueco (146, 61)',
    () {
      for (final s in [
        mkCocinero(),
        mkCocinero(guina: true),
        mkCocinero(prop: 'platano'),
        mkCocinero(prop: 'sarten'),
        mkCocinero(prop: 'prensa'),
        mkCocinero(prop: 'pilon'),
        mkCocinero(prop: 'tres_platanos'),
      ]) {
        final topScreenY = 61 - inkBottom(s) + _topInk(s);
        expect(
          topScreenY,
          greaterThanOrEqualTo(8),
          reason:
              'cocinero top row $topScreenY must stay >= 8 inside hatch hole',
        );
      }
    },
  );

  test('every sprite in pedidoSpritesSheet has opaque pixels', () {
    final sheet = pedidoSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(75));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkCocinero(), mkCocinero(guina: true)), isFalse);
    expect(_same(mkCocinero(), mkCocinero(prop: 'sarten')), isFalse);
    expect(_same(mkMesera(), mkMesera(pad: true)), isFalse);
    expect(_same(mkMesera(), mkMesera(plato: 'carne')), isFalse);
    expect(_same(mkMesero(), mkMesero(abanico: true)), isFalse);
    expect(_same(mkMesero(), mkMesero(sorbo: true)), isFalse);
    expect(
      _same(
        mkAbuelaPedido('senala_izq', false),
        mkAbuelaPedido('senala_der', false),
      ),
      isFalse,
    );
    expect(
      _same(mkAbuelaPedido('senala_izq', false), mkAbuelaPedido('yo', false)),
      isFalse,
    );
    expect(
      _same(mkAbuelaPedido('senala_der', false), mkAbuelaPedido('yo', false)),
      isFalse,
    );
    expect(_same(mkGestoFlecha(), mkGestoFlecha(up: true)), isFalse);
    expect(_same(mkGestoFlecha(), mkGestoFlecha(self: true)), isFalse);
    expect(_same(mkGestoFlecha(up: true), mkGestoFlecha(self: true)), isFalse);
    expect(_same(mkGatoPedido('sit'), mkGatoPedido('mira')), isFalse);
    expect(_same(mkGatoPedido('sit'), mkGatoPedido('pata')), isFalse);
    expect(_same(mkGatoPedido('sit'), mkGatoPedido('lame')), isFalse);
    expect(_same(mkGatoPedido('sit'), mkGatoPedido('duerme')), isFalse);
    expect(_same(mkCuadroPic('sopa'), mkCuadroPic('sopa', lit: true)), isFalse);
    expect(_same(mkPlatito(3), mkPlatito(2)), isFalse);
    expect(_same(mkPlatito(2), mkPlatito(1)), isFalse);
    expect(_same(mkPlatito(1), mkPlatito(0)), isFalse);
    expect(_same(mkPlatoRana(0), mkPlatoRana(1)), isFalse);
    expect(_same(mkPlatoRana(1), mkPlatoRana(2)), isFalse);
    expect(_same(mkPlatoRana(2), mkPlatoRana(3)), isFalse);
    expect(_same(mkPlatanos(3), mkPlatanos(2)), isFalse);
    expect(_same(mkPlatanos(2), mkPlatanos(1)), isFalse);
    expect(_same(mkPlatanos(1), mkPlatanos(0)), isFalse);
    expect(_same(mkVasito(3), mkVasito(2)), isFalse);
    expect(_same(mkVasito(2), mkVasito(1)), isFalse);
    expect(_same(mkVasito(1), mkVasito(0)), isFalse);
  });
}
