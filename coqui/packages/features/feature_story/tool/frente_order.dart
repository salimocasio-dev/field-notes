// El frente has no list of things (frente.js: `hit()` only). The wrong-touch rule of the recorded runs reads them in the order of
// its `hit()`, each with the condition `hit()` tests (coqui/tool/ref/trazas/README.md, "The learner").
import 'package:coqui_pixel/coqui_pixel.dart' show jsTruthy;

final List<(String, bool Function(Map<String, dynamic>))> _frenteOrder = [
  ('abuela', (W) => jsTruthy(W['ab'])),
  ('palma_pequena', (W) => jsTruthy(W['escondite'])),
  ('casa_pequena', (W) => jsTruthy(W['escondite'])),
  ('palma_grande', (W) => jsTruthy(W['escondite'])),
  ('casa_grande', (W) => jsTruthy(W['escondite'])),
  (
    'pajaro',
    (W) {
      final a = W['ave'];
      return a is Map && jsTruthy(a) && a['mode'] != 'none';
    },
  ),
  ('bizcocho', (W) => W['plato'] != null),
  ('nube', (W) => jsTruthy(W['storm']) && jsTruthy(W['nube'])),
  ('puerta', (W) => true),
  ('ventana', (W) => true),
  ('casa', (W) => true),
  ('sol', (W) => !jsTruthy(W['storm'])),
  ('palma', (W) => true),
];

/// The things of El frente in the order the learner's wrong touch reads them, in the world [W].
List<String> frenteThingOrder(Map<String, dynamic> W, int now) => [
  for (final e in _frenteOrder)
    if (e.$2(W)) e.$1,
];
