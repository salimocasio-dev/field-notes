/// Noche colours, text styles, and layout metrics for the speaking call and voice test screens.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Noche semantic colours used by the speaking call and voice test screens.
abstract final class CallColors {
  static const ground = NocheColors.lessonGround;
  static const grey = NocheColors.lessonLabel;
  static const text = NocheColors.text;
  static const heard = NocheColors.right;
  static const border = NocheColors.lessonBorder;
  static const line = NocheColors.lessonLine;
  static const helpPressed = NocheColors.lessonPanel;
}

/// Noche text styles for the speaking call and voice test screens.
abstract final class CallText {
  static final line = NocheType.lessonPrompt.copyWith(color: NocheColors.text);

  static final lineMuted = NocheType.bodyLarge.copyWith(
    color: NocheColors.lessonLabel,
  );

  static final heard = NocheType.bodyLarge.copyWith(color: NocheColors.right);

  static final label = NocheType.rowTitle.copyWith(
    height: 24 / 16,
    color: NocheColors.text,
  );

  static final note = NocheType.body.copyWith(color: NocheColors.lessonLabel);

  static final timer = NocheType.tabLabel.copyWith(
    height: 16 / 12,
    color: NocheColors.lessonLabel,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final error = line;

  static final chip = NocheType.body.copyWith(color: NocheColors.text);

  static final doneTitle = NocheType.pageTitle.copyWith(
    color: NocheColors.text,
  );

  static final summary = NocheType.bodyLarge.copyWith(
    color: NocheColors.lessonLabel,
  );

  static final voiceCount = NocheType.label.copyWith(
    color: NocheColors.lessonLabel,
  );

  static final voiceLine = NocheType.lessonLine.copyWith(
    color: NocheColors.text,
  );

  static final voiceHint = NocheType.bodyLarge.copyWith(
    color: NocheColors.lessonLabel,
  );

  static final voiceHeard = NocheType.bodyLarge.copyWith(
    color: NocheColors.text,
  );

  static final voiceHeardRight = NocheType.bodyLarge.copyWith(
    color: NocheColors.right,
  );

  static final voiceRowLine = NocheType.rowTitle.copyWith(
    color: NocheColors.text,
  );

  static final voiceRowAlt = NocheType.tabLabel.copyWith(
    color: NocheColors.lessonLabel,
  );

  static final voiceStatus = NocheType.tabLabel.copyWith(
    height: 16 / 12,
    color: NocheColors.lessonLabel,
  );
}

/// Layout sizes and whole-number picture scaling for the speaking call screen.
abstract final class CallMetrics {
  static const double bar = 56;
  static const double micBox = NocheSize.mic;
  static const double lineBox = 48;
  static const double heardBox = 24;
  static const double helpWidth = 136;
  static const double textMax = 560;

  static const int pictureW = 196;
  static const int pictureH = 104;

  static bool landscape(Size size) =>
      size.width > size.height && size.height <= 500;

  /// Device pixels per picture pixel: the largest whole number that fits (never below 1).
  static int pictureScale({
    required Size size,
    required double devicePixelRatio,
  }) {
    final land = landscape(size);
    final aw = land
        ? size.width - 16 - 16 - 16 - 300
        : (size.width < 560 ? size.width : 560) - 32;
    final ah = land ? size.height - 32 : size.height - 56 - 248 - 48 - 24 - 40;
    final byW = (aw * devicePixelRatio / pictureW).floor();
    final byH = (ah * devicePixelRatio / pictureH).floor();
    final s = byW < byH ? byW : byH;
    return s < 1 ? 1 : s;
  }
}
