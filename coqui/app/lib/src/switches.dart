/// The switches the page's address can carry, before the `#` (`/field-notes/app/?perf=1#/tab/map`). They are read
/// once, when the app starts, and never kept anywhere: they are for the owner's timing and for checks by machine.
library;

/// What the address asked for at the start.
class AppSwitches {
  const AppSwitches({
    this.perf = false,
    this.callStub = false,
    this.stubOptions = const {},
    this.stubClock = 1,
    this.micStub,
    this.micOff = false,
  });

  /// The query of the page's address, as the old pages read theirs (`new URLSearchParams(location.search)`).
  factory AppSwitches.fromQuery(Map<String, String> q) {
    final mic = q['mic'] ?? '';
    return AppSwitches(
      perf: q['perf'] == '1',
      // llamada.js: STUB=Q.get("callstub")==="1",STUBOPT=new Set((Q.get("stub")||"").split(",")),
      // CLK=STUB?Math.max(1,+(Q.get("clock")||1)||1):1
      callStub: q['callstub'] == '1',
      stubOptions: {
        for (final o in (q['stub'] ?? '').split(','))
          if (o.isNotEmpty) o,
      },
      stubClock: _clock(q['clock']),
      // juego.js: MQ=Q.get("mic")||"",MICOFF=MQ==="off",STUB=MQ.indexOf("stub:")===0?MQ.slice(5).split("|"):null
      micStub: mic.startsWith('stub:') ? mic.substring(5).split('|') : null,
      micOff: mic == 'off',
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

  static int _clock(String? v) {
    final n = num.tryParse(v ?? '1') ?? 0;
    if (n.isNaN || n < 1) return 1;
    return n.isInfinite ? 1 : n.floor();
  }
}
