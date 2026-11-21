/// What the shell is built on: the real platform (`real_platform.dart`) in the app, fakes in its tests.
library;

import 'package:app/src/previa.dart';
import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/coqui_platform.dart' show ClipLookup;
import 'package:flutter/services.dart' show AssetBundle;

/// The stored strings: the shared progress store's space, and a feature's own space by name.
class AppStorage {
  const AppStorage({required this.progress, required this.space});

  final KeyValueStore progress;
  final KeyValueStore Function(String name) space;
}

/// Everything the shell takes from the machine it runs on.
class AppPlatform {
  const AppPlatform({
    required this.fetch,
    required this.contentBase,
    required this.storage,
    required this.clipPlayer,
    required this.speech,
    required this.call,
    required this.haptics,
    required this.info,
    required this.clock,
    this.bundle,
    this.historyBack,
    this.previa,
  });

  /// A file under `historia/`, by its path, with the old pages' cache rules (`content.dart`).
  final FetchText fetch;

  /// `historia/` on the site: where clips and book pictures are.
  final Uri contentBase;

  /// Opens the storage (once).
  final Future<AppStorage> Function() storage;

  /// The clip player, given the catalog's clip lookup.
  final ClipPlayer Function(ClipLookup clipInfo) clipPlayer;

  final SpeechListener speech;

  /// The call session, given what the app knows of its build.
  final Future<CallSession> Function(AppInfo info) call;
  final Haptics haptics;
  final AppInfo info;
  final Clock clock;

  /// Where the scenes' sheets and old pictures are read from (the root bundle when null).
  final AssetBundle? bundle;

  /// The browser's back, where there is a browser history.
  final void Function()? historyBack;

  /// The preview content bundled in the app (`previa.dart`: in the app, [bundledPrevia] of the root bundle). Null: none,
  /// every file is the site's.
  final PreviaRead? previa;
}

/// The time now, from the system.
class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}
