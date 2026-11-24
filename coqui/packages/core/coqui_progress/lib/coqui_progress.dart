/// Word records, per-language stores, and the scheduler. Pure Dart.
///
/// [PalabrasStore] is the `ProgressStore` of page 12, section 2 (historia/palabras.js, the
/// global PAL), on a `KeyValueStore` and a `Clock`. [ProgressStores] manages per-language
/// stores with shared cross-language streak, minutes, and legacy Spanish migration.
library;

export 'package:coqui_progress/src/palabras_store.dart' show PalabrasStore;
export 'package:coqui_progress/src/progress_stores.dart' show ProgressStores;
