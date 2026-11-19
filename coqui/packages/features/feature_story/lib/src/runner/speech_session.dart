/// What the app remembers about speaking until it is closed (juego.js: the session flag `coqui.habla.nodisp`).
library;

/// An error that says speaking cannot work on this phone ends the speaking turns for the rest of the session. One
/// object is kept by the module and given to every play.
class SpeechSession {
  /// True once an error showed that speaking cannot work here (`habPon`).
  bool unavailable = false;
}
