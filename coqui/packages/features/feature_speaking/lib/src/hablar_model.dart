/// What the Hablar tab shows, without a widget (app.html: `hablar`).
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_speaking/src/call_text.dart';

/// What one card says.
enum HablarCardKind {
  /// The call is open: its disc starts it. `Llamada.tiene(id) && every story played`.
  open,

  /// The call is there but this build cannot place it (`CallSession.available` is false).
  later,

  /// All the place's stories are played and it has no call yet: "Coming soon · La casa" (the place's name).
  soon,

  /// "Opens when you finish" and the place's name.
  locked,
}

class HablarCard {
  HablarCard({
    required this.place,
    required this.kind,
    required this.subtitle,
    this.minutes,
  });

  final Place place;
  final HablarCardKind kind;

  /// The grey line under "Call Danny". For [HablarCardKind.later] the line the caller gives, or empty.
  final String subtitle;
  final int? minutes;
}

// app.html: hablar. One card for each place, in place order.
//
// `on`: the place has a call and all its stories are played (stories the level check skipped count: they are in
// the store's stories). `callsAvailable` is read only when a card is open (the old page loaded the voice library
// when Hablar showed an open card: `Llamada.precarga()`); [callsLater] is the line for a build that cannot call.
List<HablarCard> hablarCards({
  required CourseCatalog course,
  required ProgressStore progress,
  required bool Function() callsAvailable,
  String callsLater = '',
}) {
  var available = false;
  var asked = false;
  bool canCall() {
    if (!asked) {
      asked = true;
      available = callsAvailable();
    }
    return available;
  }

  return [
    for (final l in course.places)
      () {
        final fin = l.stories.isNotEmpty && l.stories.every(progress.played);
        final brief = course.callFor(l.id);
        if (brief != null && fin) {
          return canCall()
              ? HablarCard(
                  place: l,
                  kind: HablarCardKind.open,
                  subtitle: CallTexts.aboutLine(l.name, brief.minutes),
                  minutes: brief.minutes,
                )
              : HablarCard(
                  place: l,
                  kind: HablarCardKind.later,
                  subtitle: callsLater,
                );
        }
        return HablarCard(
          place: l,
          kind: fin ? HablarCardKind.soon : HablarCardKind.locked,
          subtitle: fin
              ? 'Coming soon · ${l.name}'
              : 'Opens when you finish ${l.name}',
        );
      }(),
  ];
}

/// The words open for speaking: `Object.values(db().palabras).filter(r=>r.ear.etapa>=3).map(r=>r.w)`.
/// (The old page asks the ear's stage, not `PAL.abiertaHabla`, which also opens a word he has already said.)
List<String> wordsOpenForSpeaking(ProgressStore progress) => [
  for (final r in progress.words)
    if (r.ear.etapa >= 3) r.w,
];

/// app.html: the two lines of the tab's list.
abstract final class HablarTexts {
  static const wordsTitle = 'Words open for speaking';
  static const wordsNone =
      'None yet. A word opens once your ear has held it for a few days.';
}
