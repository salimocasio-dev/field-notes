// The reference states of the dev entry: a lesson on a virtual clock, played by a script up to the instant a
// reference picture (coqui/ref/pantallas/) was taken, and held there. Used by `tool/dev_main.dart?state=...` and
// by the screenshot script (tool/shots.mjs).
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/level_check.dart';
import 'package:feature_review/src/logic/review_session.dart';

import 'support/virtual_time.dart';

/// The states of Repaso, as `ref/pantallas/index.json` names them (screen "repaso"), with the seed each was taken in.
const reviewStates = <String, String>{
  'inicio': 'curso',
  'frase-suena-imagenes-oscuras': 'curso',
  'tu-turno': 'curso',
  'toque-bien': 'curso',
  'toque-mal': 'curso',
  'toque-mal-se-muestra-la-buena': 'curso',
  'sin-toque-se-muestra-la-buena': 'curso',
  'fin-a-subir-y-a-repasar': 'curso',
  'fin-a-subir-y-a-repasar-al-final': 'curso',
  'inicio-una-palabra': 'uno',
  'inicio-practica': 'todo',
  'fin-practica': 'todo',
  'fin-practica-al-final': 'todo',
};

/// The states of the level check (screen "nivel").
const levelStates = <String, String>{
  'explicacion': 'vacio',
  'pregunta-suena': 'vacio',
  'pregunta-tocada': 'vacio',
  'resultado-11-historias': 'vacio',
  'resultado-1-historia': 'vacio',
  'resultado-desde-el-principio': 'vacio',
};

int _rightIndex(List<ReviewPanel> p) => p.indexWhere((x) => x.right);

/// Plays [s] (already prepared, its screen built) to [state] and stops there.
Future<void> playReviewState(
  ReviewSession s,
  VirtualTime vt,
  String state,
  Future<void> Function() press,
) async {
  await vt.settle();
  if (state.startsWith('inicio')) return;
  await press();
  Future<void> toReady() async {
    await vt.runUntil(() => s.ready);
    await vt.advance(150);
  }

  Future<void> touchRight() async {
    s.touch(_rightIndex(s.panels!));
    await vt.settle();
  }

  Future<void> touchWrong() async {
    s.touch(1 - _rightIndex(s.panels!));
    await vt.settle();
  }

  switch (state) {
    case 'frase-suena-imagenes-oscuras':
      await vt.runUntil(() => s.speaking > 0);
      await vt.advance(300);
    case 'tu-turno':
      await toReady();
    case 'toque-bien':
      await toReady();
      await touchRight();
      await vt.advance(100);
    case 'toque-mal':
    case 'toque-mal-se-muestra-la-buena':
      await toReady();
      await touchRight();
      await vt.runUntil(() => s.index == 1 && s.ready);
      await vt.advance(300);
      await touchWrong();
      await vt.advance(state == 'toque-mal' ? 100 : 560);
    case 'sin-toque-se-muestra-la-buena':
      await toReady();
      await touchRight();
      await vt.runUntil(() => s.index == 1 && s.ready);
      await vt.advance(300);
      await touchWrong();
      await vt.runUntil(() => s.panels!.any((p) => p.sign));
      s.touch(s.panels!.indexWhere((p) => p.sign));
      await vt.runUntil(() => s.index == 2 && s.ready);
      // no touch for 12 s: the sentence plays again at 6 s, and the right picture is shown a little after 12 s
      await vt.runUntil(() => s.panels!.any((p) => p.sign));
      await vt.advance(200);
    case 'fin-a-subir-y-a-repasar':
    case 'fin-a-subir-y-a-repasar-al-final':
      // the first word right, the second and third missed (each touched right once shown), the rest right
      await _playToEnd(s, vt, (ask) => ask == 1 || ask == 2);
    case 'fin-practica':
    case 'fin-practica-al-final':
      // right on every ask but the third and the sixth (the wrong one, then the right one)
      await _playToEnd(s, vt, (ask) => ask == 2 || ask == 5);
  }
}

Future<void> _playToEnd(
  ReviewSession s,
  VirtualTime vt,
  bool Function(int ask) wrong,
) async {
  var acted = -1;
  var shown = -1;
  for (var i = 0; i < 1000000 && s.screen != LessonScreen.end; i++) {
    final ps = s.panels;
    if (ps != null && s.ready && acted != s.index) {
      acted = s.index;
      final right = _rightIndex(ps);
      s.touch(wrong(s.index) ? 1 - right : right);
    }
    if (ps != null && shown != s.index && ps.any((p) => p.sign)) {
      shown = s.index;
      s.touch(ps.indexWhere((p) => p.sign));
    }
    if (!vt.fireNext()) break;
    await vt.settle();
  }
  await vt.advance(200);
}

/// Plays the level check [s] to [state] and stops there.
Future<void> playLevelState(
  LevelCheckSession s,
  VirtualTime vt,
  String state,
  Future<void> Function() press,
) async {
  await vt.settle();
  if (state == 'explicacion') return;
  await press();
  switch (state) {
    case 'pregunta-suena':
      await vt.runUntil(() => s.speaking > 0);
      await vt.advance(300);
    case 'pregunta-tocada':
      await vt.runUntil(() => s.ready);
      await vt.advance(150);
      s.touch(1);
      await vt.advance(100);
    case 'resultado-11-historias':
      await _levelToEnd(s, vt, (story) => story <= 11);
    case 'resultado-1-historia':
      await _levelToEnd(s, vt, (story) => story <= 1);
    case 'resultado-desde-el-principio':
      await _levelToEnd(s, vt, (story) => false);
  }
}

Future<void> _levelToEnd(
  LevelCheckSession s,
  VirtualTime vt,
  bool Function(int story) right,
) async {
  var acted = -1;
  for (var i = 0; i < 1000000 && s.screen != LessonScreen.end; i++) {
    final ps = s.panels;
    if (ps != null && s.ready && acted != s.index) {
      acted = s.index;
      final r = ps.indexWhere((p) => p.right);
      s.touch(right(s.currentStory ?? 0) ? r : (r + 1) % 4);
    }
    if (!vt.fireNext()) break;
    await vt.settle();
  }
  await vt.advance(200);
}
