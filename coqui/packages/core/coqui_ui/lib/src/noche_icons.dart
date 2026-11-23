/// Noche board icons, drawn from the exact SVG path data on the board files
/// (`docs/proyecto/noche/Noche-*.dc.html`), on a 24 x 24 viewBox with round
/// caps and joins.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// One shape inside a [NocheIconData]: SVG path data, stroked or filled or both.
class NocheIconShape {
  const NocheIconShape(this.d, {this.fill = false, this.stroke = true});

  /// SVG path data (`M`, `L`, `H`, `V`, `A`, `C`, `Z` and lowercase relative
  /// forms), copied verbatim from the board HTML.
  final String d;

  /// Whether the shape is filled with the icon's colour (`fill="currentColor"`).
  final bool fill;

  /// Whether the shape is stroked with the icon's colour and stroke width.
  final bool stroke;
}

/// Vector icon definition on a square SVG [viewBox] (24 for all Noche boards).
class NocheIconData {
  const NocheIconData(
    this.shapes, {
    this.strokeWidth = 2,
    this.viewBox = 24,
    this.matchTextDirection = false,
  });

  final List<NocheIconShape> shapes;
  final double strokeWidth;
  final double viewBox;

  /// Mirrors horizontally when ambient [TextDirection] is RTL (e.g. [NocheIcons.back]).
  final bool matchTextDirection;
}

/// Converts `<rect x y width height rx>` to SVG path data.
String nocheSvgRect(double x, double y, double w, double h, double r) {
  final x2 = x + w;
  final y2 = y + h;
  return 'M${x + r} ${y}H${x2 - r}A$r $r 0 0 1 $x2 ${y + r}V${y2 - r}'
      'A$r $r 0 0 1 ${x2 - r} ${y2}H${x + r}A$r $r 0 0 1 $x ${y2 - r}V${y + r}'
      'A$r $r 0 0 1 ${x + r} ${y}Z';
}

/// Converts `<circle cx cy r>` to SVG path data.
String nocheSvgCircle(double cx, double cy, double r) =>
    'M${cx - r} ${cy}A$r $r 0 1 0 ${cx + r} ${cy}A$r $r 0 1 0 ${cx - r} ${cy}Z';

/// Every icon on the Noche boards (`docs/proyecto/noche/Noche-*.dc.html`).
abstract final class NocheIcons {
  /// Library tab book. Noche-Mapa.dc.html, Noche-Palabras.dc.html (22, stroke 2)
  static const library = NocheIconData([
    NocheIconShape('M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z'),
    NocheIconShape('M4 19V5'),
  ], strokeWidth: 2);

  /// Words tab cards. Noche-Mapa.dc.html, Noche-Palabras.dc.html (22, stroke 2)
  static final words = NocheIconData([
    NocheIconShape(nocheSvgRect(7, 4, 13, 16, 2)),
    const NocheIconShape('M4 7v12a2 2 0 0 0 2 2h10'),
  ], strokeWidth: 2);

  /// Map tab folded map. Noche-Mapa.dc.html (26, stroke 2.2)
  static const map = NocheIconData([
    NocheIconShape('M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2z'),
    NocheIconShape('M9 4v14M15 6v14'),
  ], strokeWidth: 2.2);

  /// Microphone. Noche-Mapa.dc.html (22, stroke 2), Noche-Hablar.dc.html (40, stroke 2),
  /// Noche-Cuento.dc.html (40, stroke 2), Noche-Mic.dc.html (40, stroke 2)
  static final mic = NocheIconData([
    NocheIconShape(nocheSvgRect(9, 3, 6, 11, 3)),
    const NocheIconShape('M5 11a7 7 0 0 0 14 0M12 18v3'),
  ], strokeWidth: 2);

  /// Me tab person. Noche-Mapa.dc.html (22, stroke 2)
  static final me = NocheIconData([
    NocheIconShape(nocheSvgCircle(12, 8, 4)),
    const NocheIconShape('M4 21a8 8 0 0 1 16 0'),
  ], strokeWidth: 2);

  /// Close X. Noche-Idiomas.dc.html, Noche-Cuento.dc.html (24, stroke 2.5);
  /// Noche-Importar.dc.html (24, stroke 2.4)
  static const close = NocheIconData([
    NocheIconShape('M6 6l12 12M18 6 6 18'),
  ], strokeWidth: 2.5);

  /// Back chevron (mirrors in RTL). Noche-Lugar.dc.html, Noche-Planes.dc.html
  /// (24, stroke 2.5); Noche-Lector.dc.html, Noche-Video.dc.html (24, stroke 2.2)
  static const back = NocheIconData(
    [NocheIconShape('M15 5l-7 7 7 7')],
    strokeWidth: 2.5,
    matchTextDirection: true,
  );

  /// Downward chevron. Noche-Mapa.dc.html, Noche-Yo.dc.html (16, stroke 2.5)
  static const chevronDown = NocheIconData([
    NocheIconShape('M6 9l6 6 6-6'),
  ], strokeWidth: 2.5);

  /// Streak flame. Noche-Mapa.dc.html, Noche-Yo.dc.html (18, stroke 2)
  static const flame = NocheIconData([
    NocheIconShape(
      'M12 3c1 3 5 5 5 10a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-5 1-9z',
    ),
  ], strokeWidth: 2);

  /// Play triangle (filled). Noche-Mapa.dc.html (28), Noche-Lugar.dc.html (24),
  /// Noche-Lector.dc.html (28)
  static const play = NocheIconData([
    NocheIconShape('M8 4v16l12-8z', fill: true, stroke: false),
  ], strokeWidth: 0);

  /// Video player play triangle (filled). Noche-Video-Texto.dc.html (24)
  static const videoPlay = NocheIconData([
    NocheIconShape('M9 5v14l11-7z', fill: true, stroke: false),
  ], strokeWidth: 0);

  /// Pause bars (filled). Noche-Video-Texto.dc.html, Noche-Video-Ver.dc.html (26)
  static const pause = NocheIconData([
    NocheIconShape('M7 5h4v14H7zM13 5h4v14h-4z', fill: true, stroke: false),
  ], strokeWidth: 0);

  /// Padlock. Noche-Hablar.dc.html (20, stroke 2), Noche-Importar.dc.html (24, stroke 2)
  static final lock = NocheIconData([
    NocheIconShape(nocheSvgRect(5, 11, 14, 9, 2)),
    const NocheIconShape('M8 11V8a4 4 0 0 1 8 0v3'),
  ], strokeWidth: 2);

  /// Check mark. Noche-Idiomas.dc.html (18, stroke 3.5), Noche-Lugar.dc.html
  /// (14, stroke 3.5), Noche-Mic.dc.html (44, stroke 3)
  static const check = NocheIconData([
    NocheIconShape('M4 12l6 6L20 6'),
  ], strokeWidth: 3.5);

  /// Plus. Noche-Idiomas.dc.html (22, stroke 2.5)
  static const plus = NocheIconData([
    NocheIconShape('M12 5v14M5 12h14'),
  ], strokeWidth: 2.5);

  /// Hear again / replay arrow. Noche-Cuento.dc.html (22, stroke 2),
  /// Noche-Mic.dc.html (40, stroke 2)
  static const replay = NocheIconData([
    NocheIconShape('M4 12a8 8 0 1 0 3-6.2'),
    NocheIconShape('M4 4v5h5'),
  ], strokeWidth: 2);

  /// Sentence/line again replay arrow. Noche-Lector.dc.html (22, stroke 2.2),
  /// Noche-Video-Texto.dc.html (24, stroke 2.2)
  static const sentenceAgain = NocheIconData([
    NocheIconShape('M4.5 12a7.5 7.5 0 1 0 2.6-5.7'),
    NocheIconShape('M4 4.5v4.6h4.6'),
  ], strokeWidth: 2.2);

  /// Chapters list. Noche-Lector.dc.html, Noche-Lector-Aa.dc.html (24, stroke 2.2)
  static const chapters = NocheIconData([
    NocheIconShape('M9 6h11M9 12h11M9 18h11M4.5 6h.01M4.5 12h.01M4.5 18h.01'),
  ], strokeWidth: 2.2);

  /// Tight line spacing. Noche-Lector-Aa.dc.html (22, stroke 2)
  static const lineSpacingTight = NocheIconData([
    NocheIconShape('M5 8h14M5 12h14M5 16h14'),
  ], strokeWidth: 2);

  /// Normal line spacing. Noche-Lector-Aa.dc.html (22, stroke 2)
  static const lineSpacingNormal = NocheIconData([
    NocheIconShape('M5 6h14M5 12h14M5 18h14'),
  ], strokeWidth: 2);

  /// Loose line spacing. Noche-Lector-Aa.dc.html (22, stroke 2)
  static const lineSpacingLoose = NocheIconData([
    NocheIconShape('M5 4h14M5 12h14M5 20h14'),
  ], strokeWidth: 2);

  /// Speaker with two sound waves. Noche-Lector.dc.html (20, stroke 2.2)
  static const speaker = NocheIconData([
    NocheIconShape('M4 9.5v5h3.5L12 18V6L7.5 9.5z'),
    NocheIconShape('M15.5 9a4.2 4.2 0 0 1 0 6M18.2 6.5a8 8 0 0 1 0 11'),
  ], strokeWidth: 2.2);

  /// Clock. Noche-Lector.dc.html (14, stroke 2.4)
  static final clock = NocheIconData([
    NocheIconShape(nocheSvgCircle(12, 12, 9)),
    const NocheIconShape('M12 7v5l3 2'),
  ], strokeWidth: 2.4);

  /// Paste text clipboard. Noche-Importar.dc.html (22, stroke 2)
  static final clipboard = NocheIconData([
    NocheIconShape(nocheSvgRect(8, 3, 8, 4, 1)),
    const NocheIconShape(
      'M8 5H6a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V6a1 1 0 0 0-1-1h-2M9 12h6M9 16h4',
    ),
  ], strokeWidth: 2);

  /// Web page link. Noche-Importar.dc.html (22, stroke 2)
  static const link = NocheIconData([
    NocheIconShape('M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1'),
    NocheIconShape('M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1'),
  ], strokeWidth: 2);

  /// Video frame with play triangle. Noche-Importar.dc.html (22, stroke 2)
  static final video = NocheIconData([
    NocheIconShape(nocheSvgRect(3, 5, 18, 14, 3)),
    const NocheIconShape('M10 9.5v5l4.5-2.5z', fill: true),
  ], strokeWidth: 2);

  /// Search magnifier. Noche-Video.dc.html (20, stroke 2.2)
  static final search = NocheIconData([
    NocheIconShape(nocheSvgCircle(11, 11, 7)),
    const NocheIconShape('M16.5 16.5 21 21'),
  ], strokeWidth: 2.2);

  /// Share arrow. Noche-Video.dc.html (24, stroke 2)
  static const share = NocheIconData([
    NocheIconShape('M12 15V4M8 8l4-4 4 4'),
    NocheIconShape('M5 12v7a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-7'),
  ], strokeWidth: 2);

  /// Open external arrow. Noche-Video-Texto.dc.html, Noche-Video-Ver.dc.html (16, stroke 2.4)
  static const externalLink = NocheIconData([
    NocheIconShape('M8 16 18 6M10 6h8v8'),
  ], strokeWidth: 2.4);

  /// Loop arrows. Noche-Video-Texto.dc.html, Noche-Video-Ver.dc.html (24, stroke 2.2)
  static const loop = NocheIconData([
    NocheIconShape('M17 3l3 3-3 3'),
    NocheIconShape('M4 11V9a3 3 0 0 1 3-3h13M7 21l-3-3 3-3'),
    NocheIconShape('M20 13v2a3 3 0 0 1-3 3H4'),
  ], strokeWidth: 2.2);

  /// Saved bookmark (filled + stroked). Noche-Video-Texto.dc.html, Noche-Video-Ver.dc.html (24, stroke 2.2)
  static const bookmark = NocheIconData([
    NocheIconShape('M6 4h12v16l-6-4-6 4z', fill: true),
  ], strokeWidth: 2.2);

  /// Listening headphones. Noche-Video-Ver.dc.html (22, stroke 2)
  static final headphones = NocheIconData([
    const NocheIconShape('M4 14v-2a8 8 0 0 1 16 0v2'),
    NocheIconShape(nocheSvgRect(3, 14, 4, 6, 1.5)),
    NocheIconShape(nocheSvgRect(17, 14, 4, 6, 1.5)),
  ], strokeWidth: 2);

  /// All board icons by name, for tests and the dev gallery.
  static Map<String, NocheIconData> get all => {
    'library': library,
    'words': words,
    'map': map,
    'mic': mic,
    'me': me,
    'close': close,
    'back': back,
    'chevronDown': chevronDown,
    'flame': flame,
    'play': play,
    'videoPlay': videoPlay,
    'pause': pause,
    'lock': lock,
    'check': check,
    'plus': plus,
    'replay': replay,
    'sentenceAgain': sentenceAgain,
    'chapters': chapters,
    'lineSpacingTight': lineSpacingTight,
    'lineSpacingNormal': lineSpacingNormal,
    'lineSpacingLoose': lineSpacingLoose,
    'speaker': speaker,
    'clock': clock,
    'clipboard': clipboard,
    'link': link,
    'video': video,
    'search': search,
    'share': share,
    'externalLink': externalLink,
    'loop': loop,
    'bookmark': bookmark,
    'headphones': headphones,
  };
}

/// Draws a [NocheIconData] at [size] logical pixels in [color].
class NocheIcon extends StatelessWidget {
  const NocheIcon(
    this.data, {
    super.key,
    this.size = 24,
    required this.color,
    this.strokeWidth,
    this.semanticLabel,
  });

  final NocheIconData data;
  final double size;
  final Color color;

  /// Overrides [NocheIconData.strokeWidth] when a board draws the same path
  /// with a slightly different weight (e.g. close at 2.4, check at 3).
  final double? strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mirror =
        data.matchTextDirection &&
        Directionality.maybeOf(context) == TextDirection.rtl;
    Widget icon = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _NocheIconPainter(
          data,
          color,
          strokeWidth ?? data.strokeWidth,
        ),
      ),
    );
    if (mirror) {
      icon = Transform.flip(flipX: true, child: icon);
    }
    if (semanticLabel != null) {
      return Semantics(label: semanticLabel, image: true, child: icon);
    }
    return ExcludeSemantics(child: icon);
  }
}

class _NocheIconPainter extends CustomPainter {
  _NocheIconPainter(this.data, this.color, this.strokeWidth);

  final NocheIconData data;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final scale = size.width / data.viewBox;
    canvas.scale(scale);
    for (final shape in data.shapes) {
      final path = parseNocheSvgPath(shape.d);
      if (shape.fill) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = color,
        );
      }
      if (shape.stroke && strokeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NocheIconPainter old) =>
      old.data != data || old.color != color || old.strokeWidth != strokeWidth;
}

/// Parses SVG path data (`M m L l H h V v A a C c Z z`) into a [Path].
Path parseNocheSvgPath(String d) {
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
