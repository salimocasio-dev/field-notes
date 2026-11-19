import 'package:coqui_contracts/coqui_contracts.dart';

/// Where the strings are kept: the browser's localStorage on the web, shared_preferences in a phone
/// build. Reads are synchronous (the phone's is loaded once, when the storage is opened).
abstract interface class StringBackend {
  String? read(String key);
  Future<void> write(String key, String value);
}

/// The app's storage, one [KeyValueStore] per space. A space is a key prefix:
///
/// - [progress], the shared progress store's space, has no prefix: the store writes its own key,
///   `coqui.palabras.v1`, and that is the key in storage, where the old app left it.
/// - [space] `name` is the prefix `coqui.<name>.`. So the old app's own keys are simply there:
///   `coqui.juego.ult` is key `ult` in space `juego`, `coqui.juego.mem` is key `mem` in space `juego`,
///   `coqui.leer.tam` is key `tam` in space `leer`.
///
/// Nothing is ever deleted: the contract has no delete, and nothing here moves or clears a key.
class CoquiStorage {
  CoquiStorage(this.backend);

  final StringBackend backend;

  /// The shared progress store's space (`PalabrasStore` writes `coqui.palabras.v1` into it).
  late final KeyValueStore progress = SpaceStore(backend, '');

  final Map<String, KeyValueStore> _spaces = {};

  /// A feature's own space: keys under `coqui.<name>.`. [name] is letters, digits, `_` or `-`.
  KeyValueStore space(String name) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'a space is letters, digits, _ or -',
      );
    }
    return _spaces[name] ??= SpaceStore(backend, 'coqui.$name.');
  }
}

/// One space: every key read and written under [prefix].
class SpaceStore implements KeyValueStore {
  SpaceStore(this.backend, this.prefix);

  final StringBackend backend;
  final String prefix;

  @override
  String? read(String key) => backend.read('$prefix$key');

  @override
  Future<void> write(String key, String value) =>
      backend.write('$prefix$key', value);
}
