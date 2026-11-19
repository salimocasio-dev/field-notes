import 'package:coqui_contracts/coqui_contracts.dart';

/// The build number shown in Yo: `--dart-define=COQUI_BUILD=<n>`, "dev" without.
const coquiBuild = String.fromEnvironment('COQUI_BUILD', defaultValue: 'dev');

/// Whether this build may place calls with Danny: `--dart-define=COQUI_CALLS=false` turns them off.
const coquiCallsAllowed = bool.fromEnvironment(
  'COQUI_CALLS',
  defaultValue: true,
);

/// The iPhone's audio session type, set on `navigator.audioSession` inside [ClipPlayer.unlock] on the web.
/// Null leaves it alone, as the old page does (it never sets one).
///
/// Set after order 00's iPhone result (its test 4 tries "playback" and "play-and-record").
const String? iosAudioSessionType = null;

/// Where the page runs, as the browser tells it.
class BrowserFacts {
  const BrowserFacts({
    required this.userAgent,
    this.platform = '',
    this.maxTouchPoints = 0,
    this.standalone = false,
  });

  final String userAgent;

  /// navigator.platform
  final String platform;

  /// navigator.maxTouchPoints
  final int maxTouchPoints;

  /// display-mode standalone, or navigator.standalone (iPhone): opened from the home screen.
  final bool standalone;

  /// An iPhone, iPod or iPad, including the iPad that calls itself a Mac (Safari on iPadOS 13 and on).
  bool get isIos =>
      RegExp(r'iPhone|iPad|iPod').hasMatch(userAgent) ||
      (platform == 'MacIntel' && maxTouchPoints > 1);

  bool get isAndroid => !isIos && RegExp('Android').hasMatch(userAgent);
}

/// [AppInfo] from fixed values.
class FixedAppInfo implements AppInfo {
  const FixedAppInfo({
    this.build = coquiBuild,
    required this.isWeb,
    required this.isIos,
    required this.isAndroid,
    required this.installed,
    this.callsAllowed = coquiCallsAllowed,
  });

  /// The web's: from what the browser says.
  factory FixedAppInfo.web(BrowserFacts f) => FixedAppInfo(
    isWeb: true,
    isIos: f.isIos,
    isAndroid: f.isAndroid,
    installed: f.standalone,
  );

  @override
  final String build;
  @override
  final bool isWeb;
  @override
  final bool isIos;
  @override
  final bool isAndroid;
  @override
  final bool installed;
  @override
  final bool callsAllowed;
}

/// The tap tick of the web (app.html, `tick`): `navigator.vibrate(8)` where the browser has it; nothing on
/// an iPhone. [unlock] does nothing: the old app has no other vibration.
class WebHaptics implements Haptics {
  WebHaptics({required this.isIos, required this.vibrate});

  final bool isIos;

  /// navigator.vibrate(ms), or null when the browser has none.
  final void Function(int ms)? vibrate;

  @override
  void tick() {
    if (isIos) return;
    try {
      vibrate?.call(8);
    } catch (_) {}
  }

  @override
  void unlock() {}
}
