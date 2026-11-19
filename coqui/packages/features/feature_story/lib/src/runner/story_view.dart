/// What the play screen shows, as data: juego.js keeps it in the page's elements (`#cap`, `#bub`, `#mic`, `#bar`, the
/// buttons and `#fin`); the runner keeps it here and a screen reads it. A screen listens with [addListener].
library;

/// What a speech bubble holds (juego.js: `bubEl`).
enum BubbleKind {
  /// A line's words (`bubEl.textContent`).
  words,

  /// A speaking turn's mic icon (`data-mic="mic"`, the pulsing mic).
  mic,

  /// A speaking turn's three dots while the app thinks (`.dt`).
  dots,

  /// The green tick, with his words after it when TXT allows (`data-mic="ok"`).
  tick,
}

/// One of the three states of a lesson screen (juego.js: `estado(s, nopic)`, `#app[data-s]`).
enum StoryScreenState { start, play, end }

/// Which buttons the end of a story shows (juego.js: `foot(a, b, c, d)`).
class StoryFoot {
  const StoryFoot({
    this.next = false,
    this.again = false,
    this.home = false,
    this.map = false,
  });

  /// "Next story" (green).
  final bool next;

  /// "Play again" (outline).
  final bool again;

  /// "Map" (blue, the main button when there is no next story).
  final bool home;

  /// "Map" (outline), beside "Play again" when a next story waits (`#duo.two`).
  final bool map;

  @override
  bool operator ==(Object other) =>
      other is StoryFoot &&
      other.next == next &&
      other.again == again &&
      other.home == home &&
      other.map == map;

  @override
  int get hashCode => Object.hash(next, again, home, map);
}

/// The screen's state. Every field is what the old page sets on an element; the field's comment names it.
class StoryView {
  final List<void Function()> _listeners = [];

  void addListener(void Function() f) => _listeners.add(f);
  void removeListener(void Function() f) => _listeners.remove(f);

  /// Tells the screen something changed.
  void changed() {
    for (final f in List.of(_listeners)) {
      f();
    }
  }

  /// `#app[data-s]`.
  StoryScreenState screen = StoryScreenState.start;

  /// `#app.nopic`.
  bool noPic = false;

  /// The progress dashes: how many, and how many are lit (`mkDots`, `step`).
  int dots = 5;
  int dotsLit = 0;

  /// `#cap` and its `.on`: the narrator's caption.
  String caption = '';
  bool captionOn = false;

  /// `#bub`: the speech bubble. [bubbleOn] is its `.on`; [bubbleWho] is `BUBQ` (who it points at: "coqui", a person's
  /// id, "mic" for just above the mic button, or null); [bubbleEstate] is `data-e` (the mic's state, while a turn).
  bool bubbleOn = false;
  BubbleKind bubbleKind = BubbleKind.words;
  String bubbleText = '';
  String? bubbleWho;
  String bubbleEstate = '';

  /// `#mic[data-s]`: "", dead, ready, listening, processing or ok. "" hides the button.
  String mic = '';

  /// `#go`: the start disc is shown.
  bool startShown = true;

  /// `#fin`: the end screen's title ("" hides it, `pantalla("")`).
  String title = '';

  /// The end buttons.
  StoryFoot foot = const StoryFoot();

  /// `#snd.off`.
  bool muted = false;

  /// Whether the Map button beside "Play again" is the outline one (`#duo.two`).
  bool get two => foot.again && foot.map;
}
