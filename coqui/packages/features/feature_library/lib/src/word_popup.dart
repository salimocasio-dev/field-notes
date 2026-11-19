/// The card that pops over the page when a word that has a picture is tapped: its "si" picture and the word.
/// app.html:124-125 (`#lbcard`), 396-399 (`tarjetaPal`).
library;

import 'dart:math' as math;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/word_marks.dart';
import 'package:material_ui/material_ui.dart';

/// `#lbcard`: a scrim over the whole reader (`rgba(0,0,0,.3)`: the page stays readable behind it) with a white card in
/// the middle. Any tap on it closes it (and does nothing else).
class WordPopup extends StatelessWidget {
  const WordPopup({
    super.key,
    required this.word,
    required this.pictures,
    required this.onClose,
  });

  final PictureWord word;
  final PictureSource pictures;
  final VoidCallback onClose;

  /// `rgba(0,0,0,.3)`. app.html:124
  static const Color scrim = Color(0x4D000000);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    // the picture is as wide as the whole-number scale of the screen allows: `Math.min(innerWidth-64,360)` wide at most
    final room = math.min(screen - 64, 360.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
        color: scrim,
        child: Padding(
          padding: const EdgeInsets.all(CoquiMetrics.s16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(CoquiMetrics.s16),
              decoration: BoxDecoration(
                color: CoquiColors.card,
                borderRadius: BorderRadius.circular(CoquiMetrics.radiusCard),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: room),
                    child: PictureFrame(
                      child: pictures.of(
                        PictureRef.of(word.pair, word.pair.yes),
                        height: 104,
                      ),
                    ),
                  ),
                  const SizedBox(height: CoquiMetrics.s8),
                  Text(
                    word.word,
                    textAlign: TextAlign.center,
                    style: CoquiText.sheetTitle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
