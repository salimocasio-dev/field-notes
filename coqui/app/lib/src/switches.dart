/// The switches the page's address can carry, before the `#` (`/field-notes/app/?perf=1#/tab/map`). They are read
/// once, when the app starts, and never kept anywhere: they are for the owner's timing and for checks by machine.
library;

import 'package:feature_story/feature_story.dart' show TxtMode;

const String _coquiBuild = String.fromEnvironment(
  'COQUI_BUILD',
  defaultValue: 'dev',
);

const bool _coquiTestSwitches = bool.fromEnvironment(
  'COQUI_TEST_SWITCHES',
  defaultValue: false,
);

/// Whether test-only query switches (`callstub`, `stub`, `clock`, `mic`) are
/// enabled in this build: active when `COQUI_BUILD == 'dev'` or when
/// `--dart-define=COQUI_TEST_SWITCHES=true` is passed.
bool testSwitchesAllowed({
  String build = _coquiBuild,
  bool forceEnabled = _coquiTestSwitches,
}) => build == 'dev' || forceEnabled;

/// What the address asked for at the start.
class AppSwitches {
  const AppSwitches({
    this.perf = false,
    this.callStub = false,
    this.stubOptions = const {},
    this.stubClock = 1,
    this.micStub,
    this.micOff = false,
    this.txt = TxtMode.con,
  });

  /// The query of the page's address, as the old pages read theirs (`new URLSearchParams(location.search)`).
  ///
  /// Test-only stub switches (`callStub`, `stubOptions`, `stubClock`, `micStub`,
  /// `micOff`) are ignored when `COQUI_BUILD != 'dev'` unless
  /// `--dart-define=COQUI_TEST_SWITCHES=true` is set (or [allowTestSwitches] is
  /// passed explicitly in tests). `?perf=1` and `?txt=` remain active in every
  /// build.
  factory AppSwitches.fromQuery(
    Map<String, String> q, {
    bool? allowTestSwitches,
  }) {
    final allow = allowTestSwitches ?? testSwitchesAllowed();
    final mic = allow ? (q['mic'] ?? '') : '';
    return AppSwitches(
      perf: q['perf'] == '1',
      // llamada.js: STUB=Q.get("callstub")==="1",STUBOPT=new Set((Q.get("stub")||"").split(",")),
      // CLK=STUB?Math.max(1,+(Q.get("clock")||1)||1):1
      callStub: allow && q['callstub'] == '1',
      stubOptions: allow
          ? {
              for (final o in (q['stub'] ?? '').split(','))
                if (o.isNotEmpty) o,
            }
          : const {},
      stubClock: allow ? _clock(q['clock']) : 1,
      // juego.js: MQ=Q.get("mic")||"",MICOFF=MQ==="off",STUB=MQ.indexOf("stub:")===0?MQ.slice(5).split("|"):null
      micStub: allow && mic.startsWith('stub:')
          ? mic.substring(5).split('|')
          : null,
      micOff: allow && mic == 'off',
      // juego.js: TXT=["con","tras","no"].includes(Q.get("txt"))?Q.get("txt"):"con"
      txt: switch (q['txt']) {
        'tras' => TxtMode.tras,
        'no' => TxtMode.no,
        _ => TxtMode.con,
      },
    );
  }

  /// `?perf=1`: the map's and a story's timings in a corner chip.
  final bool perf;

  /// `?callstub=1`: the call is the old page's scripted stub (no network, no microphone).
  final bool callStub;

  /// `?stub=a,b`: the stub's options (manual, mic, fail, nofin, hasta, dannybye, loop).
  final Set<String> stubOptions;

  /// `?clock=N` with the stub: its fast clock.
  final int stubClock;

  /// `?mic=stub:<r1>|<r2>|...`: the recogniser is scripted: each result is alternatives split by "/", "none" or
  /// "error:<code>", used in order (docs/hablar/01-decisiones.md, "Machine tests").
  final List<String>? micStub;

  /// `?mic=off`: recognition is unavailable.
  final bool micOff;

  /// `?txt=con|tras|no`: when a story's words show (as the line is spoken, right after it, never). Anything else, and
  /// no `?txt=`, is `con`.
  final TxtMode txt;

  static int _clock(String? v) {
    final n = num.tryParse(v ?? '1') ?? 0;
    if (n.isNaN || n < 1) return 1;
    return n.isInfinite ? 1 : n.floor();
  }
}
