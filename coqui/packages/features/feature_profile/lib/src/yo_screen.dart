import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/about_sheet.dart';
import 'package:feature_profile/src/install_hint.dart';
import 'package:feature_profile/src/js.dart';
import 'package:feature_profile/src/texts.dart';
import 'package:feature_profile/src/welcome.dart';
import 'package:material_ui/material_ui.dart';

/// The day the "speaking is not available" note was first shown on this page (app.html: `NOTAPAG`). It lives
/// as long as the app does, and the app has one [Services].
final Expando<String> _notePage = Expando<String>('NOTAPAG');

/// What the sheet over Yo shows.
enum _Sheet { howItWorks, about }

/// The Yo tab (app.html: `yo`): the four numbers, where he is, minutes a day, the switches, the level
/// check, "How it works". It draws again whenever the progress store saves (`progress.changes`).
///
/// It draws the whole screen, as the tab bar is drawn over it by the shell; its sheets (How it works,
/// About) sit above the tab bar's height.
class YoScreen extends StatefulWidget {
  const YoScreen({
    super.key,
    required this.services,
    this.howItWorksStep,
    this.aboutOpen = false,
  });

  final Services services;

  /// For a dev entry and its screenshots: open "How it works" at this step (0 to 2) as soon as the screen is up.
  final int? howItWorksStep;

  /// For a dev entry and its screenshots: open the About sheet as soon as the screen is up.
  final bool aboutOpen;

  @override
  State<YoScreen> createState() => _YoScreenState();
}

class _YoScreenState extends State<YoScreen> {
  StreamSubscription<void>? _changes;

  _Sheet _sheet = _Sheet.howItWorks;
  bool _sheetOpen = false;
  int _step = 0;

  /// notaHabla(): whether the note is on this draw.
  bool _note = false;

  /// The recogniser is being asked (a store that saves twice in a row asks once).
  bool _asking = false;

  /// New: the install hint is on screen.
  bool _hint = false;

  Services get _s => widget.services;
  ProgressStore get _progress => _s.progress;

  @override
  void initState() {
    super.initState();
    final step = widget.howItWorksStep;
    if (step != null) {
      _sheet = _Sheet.howItWorks;
      _step = step;
      _sheetOpen = true;
    } else if (widget.aboutOpen) {
      _sheet = _Sheet.about;
      _sheetOpen = true;
    }
    _listen();
    _initHint();
    _checkNote();
  }

  void _listen() {
    _changes?.cancel();
    _changes = _progress.changes.listen((_) {
      if (!mounted) return;
      setState(() {}); // yo()
      _checkNote();
    });
  }

  @override
  void didUpdateWidget(YoScreen old) {
    super.didUpdateWidget(old);
    if (old.services != widget.services) {
      _listen();
      _checkNote();
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  // ---- the install hint (new in order 25) ----

  /// On an iPhone in the browser, not installed, and not shown before: show it, and remember that it was
  /// shown (in this feature's own storage space), so it is shown once.
  void _initHint() {
    final i = _s.info;
    if (!(i.isWeb && i.isIos && !i.installed)) return;
    final store = _s.storage(installHintSpace);
    if (store.read(installHintKey) != null) return;
    _hint = true;
    store.write(installHintKey, '1');
  }

  // ---- notaHabla (app.html:466) ----

  // app.html: notaHabla. `habDisp()` is the recogniser's `available()`; the day is the clock's, UTC.
  Future<void> _checkNote() async {
    if (_asking) return;
    _asking = true;
    final bool available;
    try {
      available = await _s.speech.available();
    } finally {
      _asking = false;
    }
    if (!mounted) return;
    var show = false;
    if (!available) {
      final today = DateTime.fromMillisecondsSinceEpoch(
        _s.clock.nowMs(),
        isUtc: true,
      ).toIso8601String().substring(0, 10);
      if (_notePage[_s] != today) {
        if (_progress.setting('notaHabla') != today) {
          _progress.setSetting('notaHabla', today);
          _notePage[_s] = today;
          show = true;
        }
      } else {
        show = true;
      }
    }
    if (show != _note) setState(() => _note = show);
  }

  // ---- the sheet ----

  // app.html: bienvenida(0)
  void _openHow() => setState(() {
    _sheet = _Sheet.howItWorks;
    _step = 0;
    _sheetOpen = true;
  });

  void _openAbout() => setState(() {
    _sheet = _Sheet.about;
    _sheetOpen = true;
  });

  // app.html: cierra
  void _close() => setState(() => _sheetOpen = false);

  // app.html: fuera (a tap on the page above a sheet closes it; the welcome ignores it)
  void _scrimTap() {
    if (_sheet == _Sheet.howItWorks &&
        !jsTruthy(_progress.setting('bienvenida'))) {
      return;
    }
    _close();
  }

  // app.html: listo
  void _listo() {
    _progress.setSetting('bienvenida', 1);
    _close();
  }

  CoquiSheet _sheetWidget() {
    if (_sheet == _Sheet.about) return aboutSheet(onClose: _close);
    return welcomeSheet(
      services: _s,
      step: _step,
      onStep: (k) => setState(() => _step = k),
      onNew: _listo,
      onClose: _close,
      onLeave: _close,
    );
  }

  // ---- the page ----

  // app.html: aqui
  int _here(List<Place> places) {
    final i = places.indexWhere(
      (l) => l.stories.isNotEmpty && !l.stories.every(_progress.played),
    );
    return math.max(0, i);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final words = progress.words.toList(); // Object.values(d.palabras)
    final minutes = jsRound(progress.minutes); // Math.round(d.minutos||0)
    final good = words.where((w) => w.ear.etapa >= 4).length;
    final places = _s.course.places;
    final here = places.isEmpty ? null : places[_here(places)];
    final level = progress.levelResult; // db().nivel
    final setting = progress.setting;

    return ColoredBox(
      color: CoquiColors.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TabPage(
            children: [
              const ScreenTitle(CoquiLabels.me),
              if (_hint)
                Block(
                  bottom: CoquiMetrics.s16,
                  child: KeyedSubtree(
                    key: const Key('install-hint'),
                    child: CoquiCard(
                      padding: installHintPadding,
                      child: InstallHint(
                        onDismiss: () => setState(() => _hint = false),
                      ),
                    ).content,
                  ),
                ),
              Block(
                bottom: CoquiMetrics.s16,
                child: _StatsGrid(
                  stats: [
                    ('🔥 ${progress.streak}', yoStreakLabel),
                    ('$minutes', '${plural(minutes, 'minute')} listened'),
                    (
                      '${words.length}',
                      '${plural(words.length, 'word')} heard',
                    ),
                    ('$good', '${plural(good, 'word')} good'),
                  ],
                ),
              ),
              if (here != null)
                CoquiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel(yoWhereYouAre),
                      const SizedBox(height: 4),
                      Text(
                        'A1 · place ${here.n} of 10 · ${here.name}',
                        style: CoquiText.h2,
                      ),
                    ],
                  ),
                ),
              const SectionTitle(yoMinutesADay),
              SegmentedPills(
                labels: [for (final m in minutePills) '$m'],
                selected: minutePillIndex(setting('min')),
                // AJ().min=m; PAL.save(); tick(); yo()
                onSelected: (i) {
                  progress.setSetting('min', minutePills[i]);
                  _s.haptics.tick();
                },
              ),
              Block(
                top: CoquiMetrics.s16,
                bottom: CoquiMetrics.s16,
                child: Text(yoPlanSized, style: CoquiText.smallMuted),
              ),
              _RowCard(
                topLine: false,
                title: yoOpenEveryPlace,
                help: yoOpenEveryPlaceHelp,
                trailing: CoquiSwitch(
                  key: const Key('yo-todo'),
                  value: jsTruthy(setting('todo')),
                  // AJ().todo=AJ().todo?0:1; PAL.save(); tick(); yo()
                  onChanged: (_) {
                    progress.setSetting(
                      'todo',
                      jsTruthy(setting('todo')) ? 0 : 1,
                    );
                    _s.haptics.tick();
                  },
                ),
              ),
              _RowCard(
                topLine: true,
                title: yoSpeakInStories,
                help: yoSpeakInStoriesHelp,
                trailing: CoquiSwitch(
                  key: const Key('yo-habla'),
                  semanticLabel: yoSpeakInStories,
                  value: setting('habla') != 0, // AJ().habla!==0
                  // AJ().habla=AJ().habla===0?1:0; PAL.save(); tick(); yo()
                  onChanged: (_) {
                    progress.setSetting('habla', setting('habla') == 0 ? 1 : 0);
                    _s.haptics.tick();
                  },
                ),
              ),
              if (_note) const KeyLine(yoSpeechNote),
              _RowCard(
                // `.row+.row`: the border-top only when the card before it is a row, not the note
                topLine: !_note,
                title: yoLevelCheck,
                help:
                    '$yoLevelCheckHelp ${level != null ? 'Done: ${jsString(level['historias'])} ${plural(level['historias'] is num ? level['historias'] as num : double.nan, 'story', 'stories')} skipped.' : yoLevelCheckNotDone}',
                trailing: CoquiButton(
                  key: const Key('yo-level-check'),
                  label: yoStart,
                  kind: CoquiButtonKind.outline,
                  // tick(); location.href='nivel.html'
                  onPressed: () {
                    _s.haptics.tick();
                    _s.nav.go(const LevelCheckRoute());
                  },
                ),
              ),
              CoquiButton(
                key: const Key('yo-how-it-works'),
                label: yoHowItWorks,
                kind: CoquiButtonKind.outline,
                full: true,
                onPressed: _openHow,
              ),
              Block(
                top: CoquiMetrics.s16,
                bottom: CoquiMetrics.s16,
                child: _AboutRow(onTap: _openAbout),
              ),
              Block(
                bottom: 0,
                child: Center(
                  child: Text(
                    'build ${_s.info.build}',
                    key: const Key('build-number'),
                    style: CoquiText.meterLabel,
                  ),
                ),
              ),
            ],
          ),
          ExcludeSemantics(
            excluding: !_sheetOpen,
            child: CoquiSheetLayer(
              open: _sheetOpen,
              onScrimTap: _scrimTap,
              modal:
                  _sheet == _Sheet.howItWorks &&
                  !jsTruthy(progress.setting('bienvenida')),
              sheet: _sheetWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

/// `display:grid;grid-template-columns:repeat(2,1fr);gap:16px`: the four numbers, two by two; a row is as
/// high as its taller card.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    Widget row(int i) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(value: stats[i].$1, label: stats[i].$2),
          ),
          const SizedBox(width: CoquiMetrics.s16),
          Expanded(
            child: StatCard(value: stats[i + 1].$1, label: stats[i + 1].$2),
          ),
        ],
      ),
    );
    return Column(
      children: [
        row(0),
        const SizedBox(height: CoquiMetrics.s16),
        row(2),
      ],
    );
  }
}

/// `.card.row`: a bold title and a grey line, and a control at the right. [topLine] is `.row+.row`: a 1 px
/// `--line` on top of a row that follows another row (the card's own ring is the `box-shadow`, so the line
/// is a border inside it: a crescent that thins out where the corner curves away).
class _RowCard extends BlockWidget {
  const _RowCard({
    required this.title,
    required this.help,
    required this.trailing,
    required this.topLine,
  });

  final String title;
  final String help;
  final Widget trailing;
  final bool topLine;

  @override
  double get marginTop => 0;
  @override
  double get marginBottom => CoquiMetrics.s16;

  @override
  Widget get content => _RowCardBody(
    topLine: topLine,
    child: CoquiRow(
      minHeight: 24, // `.row{min-height:56px}` is border-box: 24 inside the card's padding
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CoquiText.rowBold),
              Text(help, style: CoquiText.smallMuted),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _RowCardBody extends StatelessWidget {
  const _RowCardBody({required this.topLine, required this.child});

  final bool topLine;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final card = CoquiCard(
      padding: EdgeInsets.fromLTRB(
        CoquiMetrics.s16,
        CoquiMetrics.s16 + (topLine ? 1 : 0),
        CoquiMetrics.s16,
        CoquiMetrics.s16,
      ),
      child: child,
    ).content;
    if (!topLine) return card;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Chrome draws a 1 px border as the whole device pixels it floors to, at least one
    final width = math.max(1, dpr.floor()) / dpr;
    return CustomPaint(foregroundPainter: _TopLinePainter(width), child: card);
  }
}

class _TopLinePainter extends CustomPainter {
  _TopLinePainter(this.width);

  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    const r = CoquiMetrics.radiusCard;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(r),
    );
    // the padding box: the top edge moves down by the border, so the top corners are r wide and r - width
    // high; the other corners are untouched
    final inner = RRect.fromLTRBAndCorners(
      0,
      width,
      size.width,
      size.height,
      topLeft: Radius.elliptical(r, r - width),
      topRight: Radius.elliptical(r, r - width),
      bottomLeft: const Radius.circular(r),
      bottomRight: const Radius.circular(r),
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outer),
      Path()..addRRect(inner),
    );
    canvas.drawPath(path, Paint()..color = CoquiColors.line);
  }

  @override
  bool shouldRepaint(_TopLinePainter old) => old.width != width;
}

/// New in order 25: the row at the foot of Yo that opens the About sheet. A card holding one list row
/// (`.card` with `padding:0 16px` around a `.li`, as the word sheet's "Heard in"): the word in bold, an arrow.
class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const Key('about-row'),
    child: CoquiCard(
      marginBottom: 0,
      padding: const EdgeInsets.symmetric(horizontal: CoquiMetrics.s16),
      child: ListRow(
        title: const ListRowTitle(aboutRow),
        trailing: const CoquiIcon(CoquiIcons.right, color: CoquiColors.mut),
        onTap: onTap,
      ),
    ).content,
  );
}
