/// The old page's address switches, as constructor options (juego.js: `Q`).
library;

/// When the words show (juego.js: TXT, `?txt=`): "con" while the line is spoken, "tras" right after it, "no" never.
enum TxtMode { con, tras, no }

/// What the story page was given in its address, one field each. The defaults are the page with no query.
class StoryOptions {
  const StoryOptions({
    this.fast = 1,
    this.listen = false,
    this.txt = TxtMode.con,
    this.micOff = false,
    this.micStub,
    this.allOpen = false,
    this.recordsProgress = true,
    this.forced = const {},
    this.mem = const {},
  });

  /// `?fast=`: how much faster time runs (FAST). 1 in play.
  final num fast;

  /// `?oir=1`: told straight through, nothing to touch (Escuchar: Otra vez). Same as [StoryRoute.listen].
  final bool listen;

  /// `?txt=` (the setting TXT).
  final TxtMode txt;

  /// `?mic=off`: recognition is unavailable.
  final bool micOff;

  /// `?mic=stub:<r1>|<r2>|...`: the results fed to the next attempts, in order. Each is alternatives split by "/", or
  /// "none", or "error:<code>". Null: no stub. The list is read at each attempt, so a test (or the no-screen player)
  /// may add to it between attempts.
  final List<String>? micStub;

  /// `?abiertas=todas`: every word counts as open for speaking.
  final bool allOpen;

  /// False under `?fast` without `?rec`: nothing is written into the progress store (PAL.cuento, PAL.minutos, the
  /// mouth answers of a turn).
  final bool recordsProgress;

  /// `?<name>=<value>`: a draw, a decide's `as` or a `reparte` name fixed from outside (`Q.get(name)`).
  final Map<String, String> forced;

  /// `?mem=<key>:<value>,...`: story memory fixed from outside (`V.mem_<key>`).
  final Map<String, String> mem;
}
