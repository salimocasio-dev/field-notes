/// The old app's icons, drawn from the same SVG path data it uses.
///
/// app.html:190 (`IC`) and the `<svg>` markup of cual.html:101, 103, 115 draw each
/// icon on a 24 x 24 box with `fill="none" stroke="currentColor"
/// stroke-width="2" stroke-linecap="round" stroke-linejoin="round"`. The path
/// strings below are copied from there; [parseSvgPath] reads them.
library;

import 'dart:math' as math;

import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// One shape of an icon: an SVG path, filled or stroked or both.
class IconShape {
  const IconShape(this.d, {this.fill = false, this.stroke = true, this.color});

  /// The SVG path data (`M`, `L`, `H`, `V`, `A`, `C`, `Z` and their lower case).
  final String d;

  /// A colour of its own, for an icon that is not one tone (the flame). Null: the icon's colour
  /// (`currentColor`).
  final Color? color;

  /// `fill="currentColor"` (the play triangle, the speaker body).
  final bool fill;

  /// Stroked with the icon's stroke width (everything but a few solid shapes).
  final bool stroke;
}

/// An icon on a 24 x 24 box (28 x 28 for the answer badge's tick, whose SVG has that viewBox), with its
/// stroke width (2, or 2.4 for the lesson's close and sound, 3 for the tick).
class CoquiIconData {
  const CoquiIconData(this.shapes, {this.strokeWidth = 2, this.viewBox = 24});
  final List<IconShape> shapes;
  final double strokeWidth;

  /// The side of the SVG's square viewBox.
  final double viewBox;
}

/// `<rect x y width height rx>` as path data.
String svgRect(double x, double y, double w, double h, double r) {
  final x2 = x + w;
  final y2 = y + h;
  return 'M${x + r} ${y}H${x2 - r}A$r $r 0 0 1 $x2 ${y + r}V${y2 - r}'
      'A$r $r 0 0 1 ${x2 - r} ${y2}H${x + r}A$r $r 0 0 1 $x ${y2 - r}V${y + r}'
      'A$r $r 0 0 1 ${x + r} ${y}Z';
}

/// `<circle cx cy r>` as path data.
String svgCircle(double cx, double cy, double r) =>
    'M${cx - r} ${cy}A$r $r 0 1 0 ${cx + r} ${cy}A$r $r 0 1 0 ${cx - r} ${cy}Z';

/// The icons. Names are the old `IC` keys, in English.
abstract final class CoquiIcons {
  /// `IC.libro` (the Biblioteca tab). app.html:190
  static final book = CoquiIconData([
    const IconShape('M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z'),
    const IconShape('M4 19V5'),
  ]);

  /// `IC.cartas` (the Palabras tab). app.html:190
  static final cards = CoquiIconData([
    IconShape(svgRect(7, 4, 13, 16, 2)),
    const IconShape('M4 7v12a2 2 0 0 0 2 2h10'),
  ]);

  /// `IC.mapa` (the Mapa tab). app.html:190
  static const map = CoquiIconData([
    IconShape('M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2z'),
    IconShape('M9 4v14M15 6v14'),
  ]);

  /// `IC.mic` (the Hablar tab). app.html:191
  static final mic = CoquiIconData([
    IconShape(svgRect(9, 3, 6, 11, 3)),
    const IconShape('M5 11a7 7 0 0 0 14 0M12 18v3'),
  ]);

  /// `IC.yo` (the Yo tab). app.html:191
  static final me = CoquiIconData([
    IconShape(svgCircle(12, 8, 4)),
    const IconShape('M4 21a8 8 0 0 1 16 0'),
  ]);

  /// `IC.play`: a filled triangle, stroked 2 px round like the rest. app.html:191
  static const play = CoquiIconData([IconShape('M8 5v14l11-7z', fill: true)]);

  /// `IC.stop`: a filled rounded square. app.html:191
  static final stop = CoquiIconData([
    IconShape(svgRect(6, 6, 12, 12, 2), fill: true),
  ]);

  /// `IC.x` (the sheet's close). app.html:191
  static const close = CoquiIconData([IconShape('M6 6l12 12M18 6L6 18')]);

  /// `IC.vol`. app.html:191
  static const volume = CoquiIconData([
    IconShape('M11 5 6 9H3v6h3l5 4z', fill: true),
    IconShape('M16 9a4 4 0 0 1 0 6'),
  ]);

  /// `IC.phone`. app.html:191
  static const phone = CoquiIconData([
    IconShape(
      'M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z',
    ),
  ]);

  /// `IC.leer` (the Read button). app.html:191
  static const read = CoquiIconData([
    IconShape(
      'M12 6c-2-1.5-5-2-8-2v14c3 0 6 .5 8 2 2-1.5 5-2 8-2V4c-3 0-6 .5-8 2z',
    ),
    IconShape('M12 6v14'),
  ]);

  /// `IC.otra` (the replay arrow). app.html:191
  static const replay = CoquiIconData([
    IconShape('M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8'),
    IconShape('M3 3v5h5'),
  ]);

  /// `IC.izq` (back). app.html:191
  static const left = CoquiIconData([IconShape('M15 5l-7 7 7 7')]);

  /// `IC.der` (next). app.html:191
  static const right = CoquiIconData([IconShape('M9 5l7 7-7 7')]);

  /// `IC.ok` (a tick). app.html:191
  static const check = CoquiIconData([IconShape('M5 12.5l4.5 4.5L19 7')]);

  /// The lesson's close X: stroke 2.4. cual.html:101 (`#close`)
  static const lessonClose = CoquiIconData([
    IconShape('M6 6l12 12M18 6 6 18'),
  ], strokeWidth: 2.4);

  /// The lesson's sound icon, sound on: the speaker and two waves, stroke 2.4. cual.html:103 (`#snd`)
  static const lessonSound = CoquiIconData([
    IconShape('M11 5 6 9H3v6h3l5 4z', fill: true),
    IconShape('M15.5 8.5a5 5 0 0 1 0 7'),
    IconShape('M18.5 5.5a9 9 0 0 1 0 13'),
  ], strokeWidth: 2.4);

  /// The lesson's sound icon, muted (`#snd.off`: the waves go, the cross shows). cual.html:22-24
  static const lessonSoundOff = CoquiIconData([
    IconShape('M11 5 6 9H3v6h3l5 4z', fill: true),
    IconShape('m16 9 6 6m0-6-6 6'),
  ], strokeWidth: 2.4);

  /// The lesson's start disc triangle: filled, no stroke, drawn at 32 px. cual.html:115 (`#go`)
  static const startTriangle = CoquiIconData([
    IconShape('M8 4.5v15l12-7.5z', fill: true, stroke: false),
  ]);

  /// The microphone as the lesson's mic disc draws it (stroke 2). index.html:135
  static final lessonMic = CoquiIconData([
    IconShape(svgRect(9, 3, 6, 11, 3)),
    const IconShape('M5 11a7 7 0 0 0 14 0M12 18v3'),
  ]);

  /// The tick in the check badge of a right answer: its SVG has a 28 x 28 viewBox, drawn at 28 px
  /// (stroke 3, round). cual.html:49
  static const badgeCheck = CoquiIconData(
    [IconShape('M8 14.5l4 4 8-9')],
    strokeWidth: 3,
    viewBox: 28,
  );

  /// The map's tab: the Mapa disc's icon is this same map drawn at 28 px.
  static const mapDisc = map;

  /// The streak's flame: two tones, an orange body ([CoquiColors.flameBody]) and a yellow core
  /// ([CoquiColors.flameCore]). It stands in for the fire emoji glyph that the old chip and the Yo stat write as
  /// text (`hud()`, app.html:286; app.html:472): the outline is traced from that glyph as it is drawn
  /// on references 012 and 069 (the body, then the core), on the 24 x 24 box, 21.7 high and 17.4 wide. Its own
  /// colours: [CoquiIcon]'s `color` does not tint it. Draw it with [CoquiFlame].
  static const flame = CoquiIconData([
    IconShape(
      'M10.1 1.2C12.9 1.9 16.2 3.3 16.4 7.1C16.7 9 16.3 10.4 16.2 11.5L16.9 12.4L18.6 10.8C19.5 11.8 20.7 13.6 20.7 15.7C20.7 19.3 17.6 22.9 12 22.9C6.9 22.9 3.3 18.8 3.3 14.8C3.3 12.7 3.9 10.8 4.5 9.6C5.1 8.5 5.7 7.8 6.9 7.6C6.9 8.7 7 10.1 7.6 11.1C8 8 10.4 7.3 10.7 4.7C10.9 2.9 9.8 2.4 10.1 1.2Z',
      fill: true,
      stroke: false,
      color: CoquiColors.flameBody,
    ),
    IconShape(
      'M13.2 9C14.3 10.8 15.5 13.6 15.7 16.9C16 20.2 14.3 22.1 11.5 22.1C9 22.1 7.1 20.7 7.2 18.6C7.3 17.1 8.5 16.2 9.2 16.4C9.8 16.6 9.9 17.1 10 16.9C10.1 14.6 11.3 11.3 13.2 9Z',
      fill: true,
      stroke: false,
      color: CoquiColors.flameCore,
    ),
  ]);
}

/// The streak's flame at the size of the fire emoji glyph next to text of [fontSize]: the glyph is 0.86 em wide and
/// 1.1 em tall (12.2 x 15.6 px next to the map chip's 14 px text; 20.6 x 26.3 next to Yo's 24 px
/// number: measured on references 012 and 069), so the icon's box is 1.2 em. Put [gapFor] between it
/// and the text (the ink of the glyph is 0.49 em from the text that follows). A flame is a picture of
/// a flame, so a screen reader is told nothing.
class CoquiFlame extends StatelessWidget {
  const CoquiFlame({super.key, this.fontSize = 14});

  /// The font size of the text beside it, in px.
  final double fontSize;

  /// The space between the flame's box and the text that follows it: 0.26 em.
  static double gapFor(double fontSize) => fontSize * 0.26;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CoquiIcon(
      CoquiIcons.flame,
      size: fontSize * 1.2,
      color: CoquiColors.flameBody,
    ),
  );
}

/// An icon at [size] px (the old CSS sizes: 24 in the tab bar, 28 in the Mapa
/// disc, 20 in a button, 24 in a play disc, 32 on the start disc).
class CoquiIcon extends StatelessWidget {
  const CoquiIcon(this.data, {super.key, this.size = 24, required this.color});

  final CoquiIconData data;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _IconPainter(data, color)),
  );
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.data, this.color);
  final CoquiIconData data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // An SVG draws inside its own box and clips what falls outside it (the book icon's
    // spine runs to y=26).
    canvas.clipRect(Offset.zero & size);
    final k = size.width / data.viewBox;
    canvas.scale(k);
    for (final s in data.shapes) {
      final path = parseSvgPath(s.d);
      if (s.fill) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = s.color ?? color,
        );
      }
      if (s.stroke) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = data.strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = s.color ?? color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.data != data || old.color != color;
}

/// Reads SVG path data into a [Path]: `M m L l H h V v A a C c Z z`, with the
/// implicit repeats SVG allows (`M9 4 3 6` is a move then a line).
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = RegExp(
    r'([MmLlHhVvAaCcZz])|([-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?)',
  ).allMatches(d).map((m) => m.group(1) ?? m.group(2)!).toList();
  var i = 0;
  var cmd = '';
  var x = 0.0;
  var y = 0.0;
  var startX = 0.0;
  var startY = 0.0;
  double num() => double.parse(tokens[i++]);
  bool isCommand(String t) => t.length == 1 && RegExp('[A-Za-z]').hasMatch(t);
  while (i < tokens.length) {
    if (isCommand(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    switch (cmd.toUpperCase()) {
      case 'M':
        final nx = num() + (rel ? x : 0);
        final ny = num() + (rel ? y : 0);
        path.moveTo(nx, ny);
        x = startX = nx;
        y = startY = ny;
        cmd = rel ? 'l' : 'L';
      case 'L':
        final nx = num() + (rel ? x : 0);
        final ny = num() + (rel ? y : 0);
        path.lineTo(nx, ny);
        x = nx;
        y = ny;
      case 'H':
        x = num() + (rel ? x : 0);
        path.lineTo(x, y);
      case 'V':
        y = num() + (rel ? y : 0);
        path.lineTo(x, y);
      case 'C':
        final c1x = num() + (rel ? x : 0);
        final c1y = num() + (rel ? y : 0);
        final c2x = num() + (rel ? x : 0);
        final c2y = num() + (rel ? y : 0);
        final nx = num() + (rel ? x : 0);
        final ny = num() + (rel ? y : 0);
        path.cubicTo(c1x, c1y, c2x, c2y, nx, ny);
        x = nx;
        y = ny;
      case 'A':
        final rx = num();
        final ry = num();
        final rot = num();
        final large = num() != 0;
        final sweep = num() != 0;
        final nx = num() + (rel ? x : 0);
        final ny = num() + (rel ? y : 0);
        path.arcToPoint(
          Offset(nx, ny),
          radius: Radius.elliptical(rx, ry),
          rotation: rot * math.pi / 180,
          largeArc: large,
          clockwise: sweep,
        );
        x = nx;
        y = ny;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
      default:
        throw FormatException('Unsupported SVG path command $cmd in "$d"');
    }
  }
  return path;
}
