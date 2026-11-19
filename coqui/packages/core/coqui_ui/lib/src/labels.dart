/// The names v=39 hard-codes for its screens and activities, in Spanish. They are the only
/// Spanish a widget may carry (with nothing else: no sentence, no course content). Each says the
/// file and line of the old page it is copied from.
library;

abstract final class CoquiLabels {
  /// The app's name, the page title of every page (`<title>Coquí</title>`). It is also the speaker
  /// label above a book line the app's own voice says (`w.textContent="Coquí"` for `cl.who==="tu"`).
  /// app.html:7, 374
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

  /// "Fin": the word above the last page's buttons in the book (`<div class="lbfin" id="lbfin">Fin</div>`).
  /// app.html:365
  static const fin = 'Fin';

  /// "Otra vez": the book's replay button on its last page (`<button class="lbb tx" id="lbagain">`
  /// ... `Otra vez</button>`). app.html:365
  static const again = 'Otra vez';

  /// "Cuento con dibujos": the shelf's name for a story told with pictures
  /// (`dib.map(c=>[c,"","Cuento con dibujos"])`). app.html:331
  static const pictureStory = 'Cuento con dibujos';

  /// "Haz esto": the shelf's name for a routine, which has no book
  /// (`haz.map(c=>[c,"","Haz esto",1])`). app.html:331
  static const routine = 'Haz esto';
}
