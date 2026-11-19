/// The real platform: coqui_platform's audio, speech, call, storage, haptics and build facts, and the course read from
/// the old site by address.
library;

import 'package:app/src/content.dart';
import 'package:app/src/platform.dart';
import 'package:app/src/scripted_speech.dart';
import 'package:app/src/switches.dart';
import 'package:app/src/web/browser.dart';
import 'package:coqui_platform/coqui_platform.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// The platform of the running app, for the address switches [sw].
AppPlatform realPlatform(AppSwitches sw) {
  final base = contentBaseOf(appBaseUri());
  return AppPlatform(
    fetch: contentFetch(base, httpText),
    contentBase: base,
    storage: () async {
      final s = await openStorage();
      return AppStorage(progress: s.progress, space: s.space);
    },
    clipPlayer: (lookup) => createClipPlayer(clipInfo: lookup, base: base),
    speech: sw.micStub != null || sw.micOff
        ? ScriptedSpeechListener(sw.micStub ?? const [], off: sw.micOff)
        : createSpeechListener(),
    call: (info) async => createCallSession(
      appInfo: info,
      stub: sw.callStub
          ? CallStub(
              await CallStubScript.load(),
              options: sw.stubOptions,
              clock: sw.stubClock,
            )
          : null,
    ),
    haptics: createHaptics(),
    info: createAppInfo(),
    clock: const SystemClock(),
    historyBack: kIsWeb ? historyBack : null,
  );
}
