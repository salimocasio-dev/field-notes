/// The names v=39 hard-codes for its screens and activities, in Spanish. They are the only
/// Spanish a widget may carry (with nothing else: no sentence, no course content). Each says the
/// file and line of the old page it is copied from.
library;

abstract final class CoquiLabels {
  /// The app's name, the page title of every page (`<title>Coquí</title>`). app.html:7
  static const appName = 'Coquí';

  /// The Biblioteca tab's name and its screen's title (`<h1>Biblioteca</h1>`). app.html:192, 337
  static const library = 'Biblioteca';

  /// The Palabras tab's name and its screen's title (`<h1>Palabras</h1>`). app.html:192, 429
  static const words = 'Palabras';

  /// The Mapa tab's name. The map has no title of its own. app.html:192
  static const map = 'Mapa';

  /// The Hablar tab's name and its screen's title (`<h1>Hablar</h1>`). app.html:192, 461
  static const speak = 'Hablar';

  /// The Yo tab's name and its screen's title (`<h1>Yo</h1>`). app.html:192, 473
  static const me = 'Yo';

  /// The review activity's title: the entry the Today card shows (`t:"¿Cuál?"`) and the title
  /// the review lesson is made with (`title:"¿Cuál?"`). app.html:278, 283; cual.js:18
  static const reviewTitle = '¿Cuál?';

  /// "Repaso": the review card's title in Palabras (`<b>Repaso</b>`) and the title of the review
  /// lesson's start screen (`pantalla("Repaso", ...)`). app.html:430; cual.js:101
  static const review = 'Repaso';
}
