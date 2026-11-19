/// What the call screen draws that coqui_ui has no token for yet (llamada.js's CSS, `#llam`), and its numbers.
///
/// Stand-ins, listed in coqui/requests/24-feature-speaking-needs-coqui-ui-call-screen.md: when coqui_ui has the
/// call's colours and widgets, this file goes.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

abstract final class CallColors {
  /// `.lt`, `.ld.q`, `.lo`, the quiet grey of the call: `#A7A7B0`. llamada.js:94, 100, 121
  static const grey = Color(0xFFA7A7B0);

  /// `.ldisc` while Danny speaks and while the call thinks: `#2B2B33`. llamada.js:111
  static const discQuiet = Color(0xFF2B2B33);

  /// `.lhelp.p` the Help button just touched: `#33333B`. llamada.js:123
  static const helpPressed = Color(0xFF33333B);

  /// `.lg` the ring that follows the microphone level: `#3FAE6B`. llamada.js:118
  static const levelRing = Color(0xFF3FAE6B);
}

/// The call's text, as llamada.js sets it (font 400 16px/1.5, the system stack).
abstract final class CallText {
  /// `.ld` Danny's line: 18/24 white. llamada.js:99
  static final line = CoquiText.lessonBody.copyWith(
    fontSize: 18,
    height: 24 / 18,
    color: CoquiColors.lessonInk,
  );

  /// `.ld.q` the line before the call: 16/24 grey. llamada.js:100
  static final lineMuted = CoquiText.lessonBody.copyWith(
    color: CallColors.grey,
  );

  /// `.lh` what the app heard: 16/24 `#9AD5A8`. llamada.js:101
  static final heard = CoquiText.lessonBody.copyWith(color: CoquiColors.heard);

  /// `.ll` the mic's state label: 16/24 semibold white. llamada.js:120
  static final label = CoquiText.lessonBody.copyWith(
    fontWeight: FontWeight.w600,
    color: CoquiColors.lessonInk,
  );

  /// `.lo` the note under it: 14/20 grey. llamada.js:121
  static final note = CoquiText.lessonSub.copyWith(color: CallColors.grey);

  /// `.lt` the timer: 12/16 medium grey, tabular figures. llamada.js:94
  static final timer = CoquiText.lessonStateLabel.copyWith(
    color: CallColors.grey,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// `.lerr` the plain line of an error: 18/24 white. llamada.js:127
  static final error = line;

  /// `.lchips span`: 14 on 21, white. llamada.js:134
  static final chip = CoquiText.lessonSub.copyWith(
    color: CoquiColors.lessonInk,
    height: 21 / 14,
  );
}

/// The call's sizes, in px. Each says its line in llamada.js.
abstract final class CallMetrics {
  /// `.lb` the top bar. llamada.js:91
  static const double bar = 56;

  /// `.lmic` the box the mic disc and its rings stand in, `.ldisc` the disc. llamada.js:103, 104
  static const double micBox = 96;
  static const double disc = 72;

  /// `.ld` two lines of 24; `.lh` one. llamada.js:99, 101
  static const double lineBox = 48;
  static const double heardBox = 24;

  /// `.lhelp` its least width. llamada.js:122
  static const double helpWidth = 136;

  /// `.ltx`, `.lsum` their widest. llamada.js:98, 128
  static const double textMax = 560;

  /// llamada.js `fit`: the picture is 196 by 104.
  static const int pictureW = 196;
  static const int pictureH = 104;

  /// `@media (orientation:landscape) and (max-height:500px)`. llamada.js:136
  static bool landscape(Size size) =>
      size.width > size.height && size.height <= 500;

  /// llamada.js `fit`: device pixels per picture pixel, the largest whole number that fits (never below 1).
  static int pictureScale({
    required Size size,
    required double devicePixelRatio,
  }) {
    final land = landscape(size);
    final aw = land
        ? size.width - 16 - 16 - 16 - 300
        : (size.width < 560 ? size.width : 560) - 32;
    // llamada.js: vh-56-248-48-24-40 (the bar, the zone, Danny's line, what was heard, the gaps)
    final ah = land ? size.height - 32 : size.height - 56 - 248 - 48 - 24 - 40;
    final byW = (aw * devicePixelRatio / pictureW).floor();
    final byH = (ah * devicePixelRatio / pictureH).floor();
    final s = byW < byH ? byW : byH;
    return s < 1 ? 1 : s;
  }
}
