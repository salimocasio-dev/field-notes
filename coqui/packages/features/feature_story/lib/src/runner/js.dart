/// JavaScript's reading of a value, for the places where juego.js leans on it.
library;

import 'package:coqui_pixel/coqui_pixel.dart' show jsNum;

/// JavaScript: `String(v)` for a value out of a JSON-shaped map (or a missing one).
String jsString(Object? v, {bool missing = false}) {
  if (missing) return 'undefined';
  if (v == null) return 'null';
  if (v is String) return v;
  if (v is bool) return v ? 'true' : 'false';
  if (v is num) return jsNum(v);
  if (v is List) return v.map((e) => e == null ? '' : jsString(e)).join(',');
  return '[object Object]';
}

/// JavaScript: `Math.round`.
int jsRound(num v) => (v + 0.5).floor();
