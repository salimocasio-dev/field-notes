import 'package:coqui_contracts/coqui_contracts.dart';

/// A [KeyValueStore] in memory. [broken] makes every read and write throw, as localStorage does in
/// a blocked private window, or as a page with no localStorage at all does.
class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore({String? stored, this.broken = false, this.key}) {
    if (stored != null && key != null) data[key!] = stored;
  }

  /// What is kept, by key. A broken store keeps nothing but this is still where a test looks.
  final Map<String, String> data = {};
  final String? key;
  bool broken;
  int writes = 0;

  @override
  String? read(String key) {
    if (broken) throw StateError('storage is blocked');
    return data[key];
  }

  @override
  Future<void> write(String key, String value) {
    if (broken) throw StateError('storage is blocked');
    writes++;
    data[key] = value;
    return Future<void>.value();
  }
}

/// A [KeyValueStore] whose write fails later, in the Future, not at once.
class AsyncFailingKeyValueStore implements KeyValueStore {
  @override
  String? read(String key) => null;

  @override
  Future<void> write(String key, String value) =>
      Future<void>.error(StateError('write failed'));
}

/// A [Clock] the test sets.
class SettableClock implements Clock {
  SettableClock([this.now = 0]);
  int now;

  @override
  int nowMs() => now;
}
