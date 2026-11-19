// Small story files for tests.
import 'package:coqui_pixel/coqui_pixel.dart';

/// A story file. [clips] are the lines (an id to its text); a line whose text starts with "tu:" is the coquí's (`who: tu`).
Map<String, dynamic> story({
  List<Object?> beats = const [],
  List<Object?> final_ = const [],
  Map<String, String> clips = const {},
  Map<String, dynamic> extra = const {},
  int steps = 3,
}) => {
  'id': 'prueba',
  'title': 'Prueba',
  'scene': 'prueba',
  'stake': {'thing': 'x', 'steps': steps},
  'dots': 5,
  'focus_words': ['uno'],
  'back_again': ['dos'],
  'clips': <String, dynamic>{
    for (final e in clips.entries)
      e.key: e.value.startsWith('tu:')
          ? {'who': 'tu', 'text': e.value.substring(3)}
          : {'who': 'narr', 'text': e.value},
  },
  'beats': beats,
  'final': final_,
  ...extra,
};

/// `Act` that writes down it was called.
Act noting(List<String> log, String name, {Future<void> Function()? then}) => (o) async {
  log.add(name);
  await then?.call();
};
