import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

/// The result of one dev-page speech recognition probe: the structured [report]
/// map and the one-line human [summary].
class DevSpeechProbe {
  const DevSpeechProbe({required this.report, required this.summary});

  final Map<String, Object?> report;
  final String summary;
}

/// Runs the dev page's speech probe using [language]'s recognition locale
/// (defaulting to [Language.spanish]).
Future<DevSpeechProbe> runDevSpeech(
  SpeechListener listener, {
  Language? language,
  Duration limit = const Duration(seconds: 6),
  Duration timeout = const Duration(seconds: 12),
}) async {
  final lang = language ?? Language.spanish;
  final locale = lang.recognitionLocale;
  final avail = await listener.available();
  final sw = Stopwatch()..start();
  final turn = listener.listen(locale: locale, limit: limit);
  var speechEnd = -1;
  unawaited(turn.speechEnd.then((_) => speechEnd = sw.elapsedMilliseconds));
  final r = await turn.result.timeout(
    timeout,
    onTimeout: () =>
        SpeechResult(error: 'HUNG: no result in ${timeout.inSeconds} s'),
  );
  final ms = sw.elapsedMilliseconds;
  return DevSpeechProbe(
    report: {
      'available': avail,
      'locale': locale,
      'error': r.error,
      'alternatives': r.alternatives,
      'msToSound': r.msToSound,
      'endedAfterMs': ms,
      'speechEndAfterMs': speechEnd,
      'limitMs': limit.inMilliseconds + 2500,
    },
    summary:
        'speech: available() $avail; listen($locale, ${limit.inSeconds} s) '
        'ended after $ms ms with '
        '${r.error != null ? 'error "${r.error}"' : 'alternatives ${r.alternatives}'} '
        '(its limit: ${limit.inMilliseconds} + 2500 ms)',
  );
}
