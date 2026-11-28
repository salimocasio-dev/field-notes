/// A string store, one per space (the browser's localStorage today).
abstract interface class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

/// Optional interface for a [KeyValueStore] that supports removing local keys.
///
/// Kept separate from [KeyValueStore] (same pattern as `LanguageCatalog` and
/// `CallProgressStore`): adding an abstract member directly to [KeyValueStore]
/// would break stores implemented in other packages. Stores that do not
/// implement this fail [KeyValueStoreDelete.delete] with an [UnsupportedError]
/// rather than silently reporting success.
abstract interface class DeletableKeyValueStore {
  /// Removes [key] from this store if present.
  Future<void> delete(String key);
}

/// Key-removal helper on [KeyValueStore], delegating to
/// [DeletableKeyValueStore] when implemented and failing with an
/// [UnsupportedError] otherwise.
extension KeyValueStoreDelete on KeyValueStore {
  /// Removes [key] when this store implements [DeletableKeyValueStore], or
  /// returns a future that fails with [UnsupportedError] otherwise.
  Future<void> delete(String key) {
    final s = this;
    return s is DeletableKeyValueStore
        ? (s as DeletableKeyValueStore).delete(key)
        : Future<void>.error(
            UnsupportedError(
              '$runtimeType does not implement DeletableKeyValueStore',
            ),
          );
  }
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

/// Optional interface for an [AppInfo] that supplies the app's numeric version
/// number directly instead of deriving it from [AppInfo.build].
///
/// Kept separate from [AppInfo] (same pattern as `CallsCatalog`,
/// `LanguageCatalog` and `MinAppCatalog`): adding an abstract member directly
/// to [AppInfo] would break implementations in other packages. Implementations
/// that do not implement this derive [AppInfoNumber.appNumber] from
/// [AppInfo.build].
abstract interface class AppNumberInfo {
  /// The app's numeric build number, or `0` for an unnumbered / dev build.
  int get appNumber;
}

final RegExp _leadingDigits = RegExp(r'^\s*(\d+)');

/// Numeric app number and `minApp` compatibility checks on [AppInfo].
extension AppInfoNumber on AppInfo {
  /// The app's own numeric build number.
  ///
  /// Returns [AppNumberInfo.appNumber] (clamped to `>= 0`) when this [AppInfo]
  /// implements [AppNumberInfo]. Otherwise parses the leading decimal digits of
  /// [build] (for example `'16'` -> `16`, `'16+2'` -> `16`, `'16-rc1'` -> `16`),
  /// or returns `0` for non-numeric / unnumbered builds such as `'dev'`,
  /// `'fake'`, or `''`.
  ///
  /// Semantics for `#62` (pre-story compatibility gate):
  /// - `appNumber == 0`: unnumbered / dev build (never blocked by `minApp`;
  ///   [supportsMinApp] returns `true`).
  /// - `appNumber > 0`: numbered build; compatible iff `appNumber >= minApp`.
  int get appNumber {
    final i = this;
    if (i is AppNumberInfo) {
      final n = (i as AppNumberInfo).appNumber;
      return n > 0 ? n : 0;
    }
    final match = _leadingDigits.firstMatch(build);
    if (match == null) return 0;
    return int.tryParse(match.group(1)!) ?? 0;
  }

  /// Whether this app build satisfies [minApp] (the lowest app number required
  /// by a course or story; `null` means any app).
  ///
  /// Returns `true` when [minApp] is `null`, when [appNumber] is `0`
  /// (unnumbered / `'dev'` / `'fake'` build), or when `appNumber >= minApp`.
  bool supportsMinApp(int? minApp) {
    if (minApp == null) return true;
    final n = appNumber;
    if (n == 0) return true;
    return n >= minApp;
  }
}
