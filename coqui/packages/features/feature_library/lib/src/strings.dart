/// The English words the shelf and the reader show that app.html writes itself (not the books', not the
/// catalog's). Each is copied exactly, with the line it comes from. The Spanish names of the screens and activities (the
/// shelf's name, the end of a book, its replay button, the app's name over the coqui's lines, the kinds of a row) are
/// not here: they are `CoquiLabels`.
/// The learning text (the lines of a book, a story's title) is never here: it comes from the books and the catalog.
library;

abstract final class LibraryStrings {
  /// `.btn` Listen. app.html:337
  static const listen = 'Listen';

  /// `.btn` Read. app.html:337
  static const read = 'Read';

  /// The shelf when nothing was played. app.html:340
  static const emptyShelf =
      'Play a story on the map. You can hear it again here and read it.';

  /// "Heard 2× · ". app.html:337
  static String heard(num n) => 'Heard ${_whole(n)}× · ';

  /// "about 3 min". app.html:337
  static String about(int minutes) => 'about $minutes min';

  /// The grey line at the foot of the shelf. app.html:341
  static String closed(int n) =>
      '$n more ${n == 1 ? "opens" : "open"} as you play the map';

  /// `aria-label` of the Listen button. app.html:337
  static String listenLabel(String title) => 'Listen: $title';

  /// `aria-label` of the Read button. app.html:337
  static String readLabel(String title, {required bool again}) =>
      'Read${again ? " again" : ""}: $title';

  /// `aria-label`s of the reader's buttons and bar. app.html:165-167, 365
  static const book = 'Book';
  static const closeLabel = 'Close';
  static const textSizeLabel = 'Text size';
  static const previousPage = 'Previous page';
  static const nextPage = 'Next page';
  static const pageLabel = 'Page';

  /// `aria-valuetext` of the page bar. app.html:358
  static String pageOf(int i, int n) => 'Page $i of $n';

  static String _whole(num n) => n == n.truncate() ? '${n.truncate()}' : '$n';
}
