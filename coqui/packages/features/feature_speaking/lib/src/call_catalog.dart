/// Call presentation spec for the Speak tab and legacy fallback constants.
///
/// Call titles, jobs, durations, and openings come from `CourseCatalog.callsFor`
/// (`CallBrief`). Only the legacy fallback constants for the single-object
/// Spanish `casa` entry remain while `historia/datos/llamadas.json` still uses
/// the pre-`CallsCatalog` format.
library;

/// Legacy fallback title for Spanish `casa` when `datos/llamadas.json` uses the
/// pre-CallsCatalog single-object format without a `title` field (see
/// `coqui/requests/6-coqui-content-needs-content-publish-llamadas-data.md`).
const String legacySpanishCasaTitle = 'De visita en la casa';

/// Legacy fallback English job line for Spanish `casa` when `jobEn` is empty.
const String legacySpanishCasaJobEn =
    'Greet {partner}, introduce yourself, and accept a drink.';

/// One call inside a place (either the place's main job call or a smaller call).
class HablarCallSpec {
  const HablarCallSpec({
    required this.id,
    required this.placeId,
    required this.titleEs,
    required this.jobEn,
    required this.minutes,
    required this.isMain,
    this.pixelAsset,
  });

  /// Stable call identifier, e.g. `casa_main` or `casa_agua`.
  final String id;

  /// Place identifier matching `Place.id` in `coqui_contracts`.
  final String placeId;

  /// Short beginner-readable title in the course language.
  final String titleEs;

  /// Plain one-line English description of the call's job.
  final String jobEn;

  /// Approximate duration in minutes.
  final int minutes;

  /// Whether this is the place's main job call.
  final bool isMain;

  /// Original pixel-art asset key, or null until drawn. Never a screenshot.
  final String? pixelAsset;

  String jobFor(String partnerName) =>
      jobEn.replaceAll('{partner}', partnerName);
}
