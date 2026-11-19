/// The voice test's content, read from `historia/datos/prueba-voz.json` (made from habla-prueba.html by
/// coqui/tool/export_datos.mjs): its twelve lines and the Spanish words around them.
library;

import 'dart:convert';

/// One word to be heard in a line, with the forms of it that count (habla-prueba.html: `g`, `[word, forms]`).
typedef VoiceTestTarget = ({String word, List<String> forms});

/// One line to say: its text (`t`), the hint under it (`h`, where there is one), its targets (`g`).
typedef VoiceTestLineData = ({
  String text,
  String? hint,
  List<VoiceTestTarget> targets,
});

/// The file, read: the lines in order and the labels by the names `VoiceTestLabels` of feature_speaking gives them.
class VoiceTestData {
  const VoiceTestData({required this.lines, required this.labels});

  /// The text of `datos/prueba-voz.json`. Throws a [FormatException] when it is not in that shape.
  factory VoiceTestData.parse(String text) {
    final j = jsonDecode(text);
    if (j is! Map) throw const FormatException('prueba-voz.json: an object');
    final lines = j['lines'], labels = j['labels'];
    if (lines is! List || labels is! Map) {
      throw const FormatException('prueba-voz.json: lines and labels');
    }
    return VoiceTestData(
      lines: [
        for (final l in lines)
          (
            text: (l as Map)['t'] as String,
            hint: l['h'] as String?,
            targets: [
              for (final g in l['g'] as List)
                (
                  word: (g as List)[0] as String,
                  forms: [for (final f in g[1] as List) f as String],
                ),
            ],
          ),
      ],
      labels: {
        for (final k in labelNames)
          k: labels[k] is String
              ? labels[k] as String
              : throw FormatException('prueba-voz.json: labels.$k'),
      },
    );
  }

  final List<VoiceTestLineData> lines;
  final Map<String, String> labels;

  /// The labels the screen needs, by the names of `VoiceTestLabels`.
  static const labelNames = [
    'listening',
    'processing',
    'unavailable',
    'again',
    'mic',
    'next',
    'progress',
  ];
}
