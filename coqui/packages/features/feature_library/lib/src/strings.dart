/// The words the shelf and the reader show that app.html writes itself (not the books', not the
/// catalog's). Each is copied exactly, with the line it comes from. The learning text (the lines of a
/// book, a story's title) is never here: it comes from the books and the catalog.
library;

abstract final class LibraryStrings {
  /// `.btn` Listen. app.html:337
  static const listen = 'Listen';

  /// `.btn` Read. app.html:337
  static const read = 'Read';

  /// The shelf when nothing was played. app.html:340
  static const emptyShelf =
      'Play a story on the map. You can hear it again here and read it.';

  /// The kind of a picture story's row. app.html:333
  static const pictureStory = 'Cuento con dibujos';

  /// The kind of a routine's row. app.html:333
  static const routine = 'Haz esto';

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

  /// The speaker label of the coqui's lines. app.html:374
  static const coqui = 'Coquí';

  /// The end of a book. app.html:365
  static const fin = 'Fin';

  /// "Read again", on the last page. app.html:365
  static const again = 'Otra vez';

  /// The foot's other button, back to the shelf. app.html:365
  static const shelf = 'Biblioteca';

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
