import 'package:coqui_contracts/coqui_contracts.dart';

/// A clock that stands still until it is set or moved.
///
/// Starts at 2026-11-19 15:00 UTC unless given another time.
class FakeClock implements Clock {
  FakeClock([int? nowMs])
    : now = nowMs ?? DateTime.utc(2026, 11, 19, 15).millisecondsSinceEpoch;

  /// The time it says, in ms since the epoch. Set it freely.
  int now;

  @override
  int nowMs() => now;

  /// Moves the clock on.
  void advance(Duration d) => now += d.inMilliseconds;
}

/// The one random source, as the app has it: Mulberry32 with a given seed (1 when none).
/// Counts how many values were drawn.
class FakeRng implements Rng {
  FakeRng([this.seed = 1]) : _m = Mulberry32(seed);

  final int seed;
  final Mulberry32 _m;

  /// How many values [next] has given.
  int draws = 0;

  @override
  double next() {
    draws++;
    return _m.next();
  }
}

/// A string store in memory. Writes land at once.
class FakeKeyValueStore implements KeyValueStore {
  FakeKeyValueStore([Map<String, String>? values]) : values = values ?? {};

  /// What it holds. Read or seed it in a test.
  final Map<String, String> values;

  /// Every write, in order, as [key, value].
  final List<List<String>> writes = [];

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
    writes.add([key, value]);
  }
}

/// Counts ticks and unlocks. Nothing vibrates.
class FakeHaptics implements Haptics {
  int ticks = 0;
  int unlocks = 0;

  @override
  void tick() => ticks++;

  @override
  void unlock() => unlocks++;
}

/// Build facts, each settable.
class FakeAppInfo implements AppInfo {
  FakeAppInfo({
    this.build = 'fake',
    this.isWeb = true,
    this.isIos = false,
    this.isAndroid = false,
    this.installed = false,
    this.callsAllowed = true,
  });

  @override
  String build;
  @override
  bool isWeb;
  @override
  bool isIos;
  @override
  bool isAndroid;
  @override
  bool installed;
  @override
  bool callsAllowed;
}

/// Records where a feature asked to go. It goes nowhere.
class FakeNavigator implements AppNavigator {
  /// Every route asked for, in order.
  final List<AppRoute> routes = [];

  /// How many times [back] was called.
  int backs = 0;

  /// The last route asked for, or null.
  AppRoute? get last => routes.isEmpty ? null : routes.last;

  @override
  void go(AppRoute route) => routes.add(route);

  @override
  void back() => backs++;
}
