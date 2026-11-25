import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/licence_text.dart';
import 'package:feature_profile/src/texts.dart';
import 'package:material_ui/material_ui.dart';

/// The licence text as paragraphs: the file wraps its lines at 80 characters, a phone does not, so the
/// lines of a paragraph are joined by a space and the blank lines between paragraphs are kept.
List<String> licenceParagraphs([String text = pixelPlaysLicence]) => [
  for (final p in text.trim().split(RegExp(r'\n\s*\n')))
    p.split('\n').map((l) => l.trim()).join(' '),
];

/// The About sheet body in Noche tokens: the credit line and the MIT licence
/// paragraphs under it, opened inside [showNocheSheet].
Widget aboutSheetBody() => Column(
  key: const ValueKey('about'),
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      aboutCredit,
      style: NocheType.rowTitle.copyWith(color: NocheColors.text),
    ),
    const SizedBox(height: 16),
    for (final p in licenceParagraphs()) ...[
      Text(p, style: NocheType.bodySmall.copyWith(color: NocheColors.label)),
      const SizedBox(height: 12),
    ],
  ],
);
