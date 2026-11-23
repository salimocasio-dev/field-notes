/// Temporary local catalog of call titles and smaller calls per place.
///
/// Titles and call lists are course content, not code. This file is the local
/// stand-in until `coqui_contracts` adds `title`, `jobEn`, `isMain`, and
/// `CourseCatalog.callsFor(placeId)` and `coqui_content` supplies the data
/// (see `coqui/requests/25-feature-speaking-needs-coqui-contracts-call-titles.md`).
///
/// Rules enforced here:
/// - Short, beginner-readable Puerto Rican Spanish title (A1/A2).
/// - Plain one-line English job underneath.
/// - No pet names, nothing religious or personal, no "Call Danny" titles.
/// - `pixelAsset` stays null until an original pixel-art asset is drawn for
///   that call (never a story screenshot).
library;

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

  /// Short beginner-readable Puerto Rican Spanish title.
  final String titleEs;

  /// Plain one-line English description of the call's job.
  final String jobEn;

  /// Approximate duration in minutes.
  final int minutes;

  /// Whether this is the place's main job call.
  final bool isMain;

  /// Original pixel-art asset key, or null until drawn. Never a screenshot.
  final String? pixelAsset;
}

/// All 31 reviewed calls across the 10 places (10 main + 21 smaller).
const Map<String, List<HablarCallSpec>> hablarCallCatalog = {
  'casa': [
    HablarCallSpec(
      id: 'casa_main',
      placeId: 'casa',
      titleEs: 'De visita en la casa',
      jobEn: 'Greet Danny, introduce yourself, and accept a drink.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'casa_agua',
      placeId: 'casa',
      titleEs: 'Un vaso de agua',
      jobEn: 'Ask for a drink and say thanks.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'casa_saludo',
      placeId: 'casa',
      titleEs: '¿Cómo estás?',
      jobEn: 'Greet Danny and say how you are doing.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'casa_despedida',
      placeId: 'casa',
      titleEs: 'Nos vemos',
      jobEn: 'Wrap up a quick visit and say goodbye.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'parque': [
    HablarCallSpec(
      id: 'parque_main',
      placeId: 'parque',
      titleEs: 'El perro en el parque',
      jobEn: 'Describe the park, its colours, and what the dog does.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'parque_colores',
      placeId: 'parque',
      titleEs: '¿De qué color es?',
      jobEn: 'Name the colours of things around the park.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'parque_perro',
      placeId: 'parque',
      titleEs: 'Mira el perro',
      jobEn: 'Say what the dog is doing right now.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'cocina': [
    HablarCallSpec(
      id: 'cocina_main',
      placeId: 'cocina',
      titleEs: 'Tengo hambre',
      jobEn: 'Say you are hungry, what you want, and what you like.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'cocina_tomar',
      placeId: 'cocina',
      titleEs: '¿Qué quieres tomar?',
      jobEn: 'Say what you want to drink.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'cocina_comer',
      placeId: 'cocina',
      titleEs: '¿Qué te gusta comer?',
      jobEn: 'Say which foods you like and do not like.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'colmado': [
    HablarCallSpec(
      id: 'colmado_main',
      placeId: 'colmado',
      titleEs: 'Tres cosas del colmado',
      jobEn: 'Ask for three things, ask the price, and pay.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'colmado_precio',
      placeId: 'colmado',
      titleEs: '¿Cuánto es?',
      jobEn: 'Ask how much two items cost together.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'colmado_pagar',
      placeId: 'colmado',
      titleEs: 'Quiero esto, por favor',
      jobEn: 'Pick one item and pay at the counter.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'calle': [
    HablarCallSpec(
      id: 'calle_main',
      placeId: 'calle',
      titleEs: '¿Dónde queda la plaza?',
      jobEn: 'Ask for directions and say where you are going.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'calle_lados',
      placeId: 'calle',
      titleEs: 'Izquierda o derecha',
      jobEn: 'Follow simple left, right, and near directions.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'calle_destino',
      placeId: 'calle',
      titleEs: 'Voy para la plaza',
      jobEn: 'Tell Danny where you are heading.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'plaza': [
    HablarCallSpec(
      id: 'plaza_main',
      placeId: 'plaza',
      titleEs: 'Mucho gusto',
      jobEn: 'Share your name, hometown, and work, and ask back.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'plaza_hora',
      placeId: 'plaza',
      titleEs: '¿Qué hora es?',
      jobEn: 'Ask for and tell the time.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'plaza_origen',
      placeId: 'plaza',
      titleEs: '¿De dónde eres?',
      jobEn: 'Say where you are from and what you do.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'playa': [
    HablarCallSpec(
      id: 'playa_main',
      placeId: 'playa',
      titleEs: '¿Vamos al agua?',
      jobEn: 'Talk about the weather, clothes, and what you can do.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'playa_clima',
      placeId: 'playa',
      titleEs: 'Hace calor hoy',
      jobEn: 'Talk about today\'s weather at the beach.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'playa_nadar',
      placeId: 'playa',
      titleEs: '¿Puedo nadar?',
      jobEn: 'Say what you can and cannot do in the water.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'fonda': [
    HablarCallSpec(
      id: 'fonda_main',
      placeId: 'fonda',
      titleEs: 'Almuerzo en la fonda',
      jobEn: 'Get a table, order lunch, and ask for the bill.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'fonda_mesa',
      placeId: 'fonda',
      titleEs: 'Una mesa para dos',
      jobEn: 'Ask for a table and order a drink.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'fonda_cuenta',
      placeId: 'fonda',
      titleEs: 'La cuenta, por favor',
      jobEn: 'Say how the food was and ask for the bill.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'casa2': [
    HablarCallSpec(
      id: 'casa2_main',
      placeId: 'casa2',
      titleEs: 'De la mañana a la noche',
      jobEn: 'Walk through your daily routine and times.',
      minutes: 5,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'casa2_manana',
      placeId: 'casa2',
      titleEs: 'Mi mañana',
      jobEn: 'Say what you do in the morning and when.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'casa2_noche',
      placeId: 'casa2',
      titleEs: 'Antes de dormir',
      jobEn: 'Say how you spend your evening and go to bed.',
      minutes: 2,
      isMain: false,
    ),
  ],
  'fuerte': [
    HablarCallSpec(
      id: 'fuerte_main',
      placeId: 'fuerte',
      titleEs: '¿Qué hacemos hoy?',
      jobEn: 'Invite Danny out, share plans, and say how you feel.',
      minutes: 6,
      isMain: true,
    ),
    HablarCallSpec(
      id: 'fuerte_invitar',
      placeId: 'fuerte',
      titleEs: '¿Quieres ir conmigo?',
      jobEn: 'Invite someone along and pick a time.',
      minutes: 2,
      isMain: false,
    ),
    HablarCallSpec(
      id: 'fuerte_sentir',
      placeId: 'fuerte',
      titleEs: '¿Cómo te sientes?',
      jobEn: 'Say how you are feeling today.',
      minutes: 2,
      isMain: false,
    ),
  ],
};

/// Returns all configured calls (main first, then smaller calls) for [placeId].
List<HablarCallSpec> callsForPlace(String placeId) =>
    hablarCallCatalog[placeId] ?? const [];

/// Returns the main call for [placeId], if one exists.
HablarCallSpec? mainCallForPlace(String placeId) {
  final list = callsForPlace(placeId);
  for (final c in list) {
    if (c.isMain) return c;
  }
  return list.isEmpty ? null : list.first;
}
