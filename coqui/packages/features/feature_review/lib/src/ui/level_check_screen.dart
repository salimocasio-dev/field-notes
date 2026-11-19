/// The level check on screen: nivel.html, built from coqui_ui. The session (logic/level_check.dart) decides
/// everything; this draws it and passes touches on.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/level_check.dart';
import 'package:feature_review/src/ui/block_layout.dart';
import 'package:feature_review/src/ui/host_wait.dart';
import 'package:feature_review/src/ui/lesson_parts.dart';
import 'package:material_ui/material_ui.dart';

class LevelCheckScreen extends StatefulWidget {
  const LevelCheckScreen({
    super.key,
    required this.services,
    this.options = const LevelOptions(),
    this.captions = CaptionMode.during,
    this.wait,
  });

  final Services services;
  final LevelOptions options;
  final CaptionMode captions;

  /// The host's wait. Left out, a timer is used; tests and the dev entry give a virtual clock's.
  final Wait? wait;

  @override
  State<LevelCheckScreen> createState() => LevelCheckScreenState();
}

class LevelCheckScreenState extends State<LevelCheckScreen> {
  late final LevelCheckSession session;
  HostWait? _host;
  final Expando<Widget> _pictures = Expando<Widget>();

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    final wait = widget.wait ?? (_host = HostWait()).call;
    session = LevelCheckSession(
      rng: _s.rng,
      clock: _s.clock,
      course: _s.course,
      progress: _s.progress,
      clips: _s.clips,
      wait: wait,
      captions: widget.captions,
      options: widget.options,
      warm: (refs) => unawaited(_s.pictures.warm(refs)),
    );
    session.prepare();
    session.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    session.removeListener(_changed);
    session.dispose();
    _host?.cancelAll();
    super.dispose();
  }

  void _start() {
    if (session.screen != LessonScreen.start) return;
    unawaited(_s.clips.unlock());
    unawaited(session.run());
  }

  /// The green disc pressed, for a dev entry or a test that cannot reach it by touch.
  Future<void> pressStart() async => _start();

  // `#close`: the page it was opened from (nivel.js has no SALIDA: origen())
  void _close() {
    session.leave();
    _s.nav.back();
  }

  void _toggleSound() => setState(() => _s.clips.muted = !_s.clips.muted);

  // `#next`: "To the map"
  void _toMap() {
    session.leave();
    _s.nav.go(const TabRoute('map'));
  }

  Widget _picture(LevelPanel p, CellRect r) => _pictures[p] ??= SizedBox(
    width: r.width,
    height: r.height,
    child: _s.pictures.of(p.ref, height: p.ref.cam[3].round(), animated: true),
  );

  Widget _choices(LessonBox box) {
    final s = session;
    final panels = s.panels!;
    return PictureBlock(
      fit: box.fit(BlockSpec.level),
      cell: (context, k, r) => k >= panels.length
          ? const SizedBox.shrink()
          : OptionTouch(
              index: k,
              onTouch: s.touch,
              child: PictureChoice(
                ring: choiceRing(s.rings[k]),
                child: _picture(panels[k], r),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final box = LessonBox.of(context, constraints);
      final s = session;
      final start = s.screen == LessonScreen.start;
      final end = s.screen == LessonScreen.end;
      final showPictures = s.screen == LessonScreen.play && s.panels != null;
      return LessonFrame(
        onClose: _close,
        onSound: _toggleSound,
        muted: _s.clips.muted,
        progress: LessonProgressDashes(
          segments: s.barSegments,
          done: s.barLit,
          dense: s.barSegments > 24,
        ),
        picture: showPictures ? _choices(box) : null,
        caption: showPictures && s.caption.isNotEmpty ? s.caption : null,
        overlay: (start || end) && s.screenTitle.isNotEmpty
            ? LessonTextScreen(
                box: box,
                title: s.screenTitle,
                lines: s.screenLines,
              )
            : null,
        bottom: [
          if (start) LessonStartButton(onPressed: _start),
          if (end)
            LessonButton(
              label: ReviewStrings.toTheMap,
              kind: LessonButtonKind.blue,
              onPressed: _toMap,
            ),
        ],
        startState: start,
      );
    },
  );
}
