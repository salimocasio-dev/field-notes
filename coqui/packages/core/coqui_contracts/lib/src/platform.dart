/// A string store, one per space (the browser's localStorage today).
abstract interface class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

/// The time now (Date.now()).
abstract interface class Clock {
  int nowMs();
}

/// The one random source. Mulberry32 (given in coqui_contracts, with tests), because the old page's recorded runs
/// are made with the same generator. Never dart:math Random in engine, scene or runner code.
abstract interface class Rng {
  double next(); // 0 <= x < 1, as Math.random()
}

/// The phone's vibration.
abstract interface class Haptics {
  void tick();
  void unlock();
}

/// What the app knows about the build it is and where it runs.
abstract interface class AppInfo {
  String get build; // shown in Yo
  bool get isWeb;
  bool get isIos;
  bool get isAndroid;
  bool get installed; // web: opened from the home screen
  bool get callsAllowed; // a build setting (order 44)
}
