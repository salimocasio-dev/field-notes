/// `me`: what `espera` is waiting for (juego.js: the object `espera` makes and `pending` points at).
library;

import 'dart:async';

/// A touch the story waits for. The fields are juego.js's, with 0/1 flags as `bool`.
class Pending {
  Pending({
    required this.live,
    required this.line,
    required this.loose,
    required this.lock,
    required this.sign,
    required this.kind,
    required this.pick,
    required this.alias,
  });

  /// The things a touch counts on (`me.live`).
  final List<String> live;

  /// The question's clip, said again every 9 s.
  final String? line;

  bool asked = false;
  bool busy = false;
  bool done = false;

  /// Where he touched, in the picture (`me.p`), and what (`me.got`).
  ({int x, int y})? p;
  String? got;

  /// Before the door has a name, the door is the house.
  final bool loose;

  /// A touch before the question has been asked once does not count (`me.lock`). Changes during a turn.
  bool lock;
  String? sign;
  final String kind;
  final String? pick;
  final Map<String, dynamic>? alias;

  /// The speaking bubbles are on (`me.voz`).
  bool voz = false;

  /// The time (ms) the lead, the line and the bubbles were over (`me.tEnd`); null until then.
  int? tEnd;

  /// Time to answer, ms (`me.ms`).
  int? ms;

  bool rep = false;
  int nrep = 0;

  /// A speaking turn is on: the mic is up beside this touch (`me.turnoOn`), and he said it (`me.hablado`).
  bool turnoOn = false;
  bool hablado = false;

  /// The green tick's stay, when he spoke (`me.okP`).
  Future<void>? okP;

  /// An elige's turn record (`me.reg`).
  Map<String, dynamic>? reg;

  /// Plays the question again (`me.repite`).
  void Function() repite = () {};

  final Completer<void> got_ = Completer<void>();

  /// `me.res()`.
  void res() {
    if (!got_.isCompleted) got_.complete();
  }

  Future<void> get gotFuture => got_.future;

  /// The old `me` object as a map, for a scene's `await host.espera(...)`.
  Map<String, dynamic> asMap() => {
    'live': live,
    'line': line,
    'asked': asked,
    'done': done,
    'p': p == null ? null : {'x': p!.x, 'y': p!.y},
    'got': got,
    'ms': ms,
    'kind': kind,
    'pick': pick,
    'hablado': hablado,
  };
}
