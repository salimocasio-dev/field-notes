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

/// The About sheet (new in order 25): exactly one line, "Map and scene engine: Pixel Plays by Amir Mushich
/// (MIT)", and the licence text under it. An ordinary sheet: the handle, the X, no title.
CoquiSheet aboutSheet({required VoidCallback onClose}) => CoquiSheet(
  key: const ValueKey('about'),
  onClose: onClose,
  child: CollapsingColumn(
    children: [
      Block(bottom: 16, child: Text(aboutCredit, style: CoquiText.rowBold)),
      for (final p in licenceParagraphs())
        Block(bottom: 12, child: Text(p, style: CoquiText.smallMuted)),
    ],
  ),
);
