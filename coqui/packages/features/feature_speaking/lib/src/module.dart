import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:feature_speaking/src/entitlements_hook.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:feature_speaking/src/voice_test_controller.dart';
import 'package:feature_speaking/src/voice_test_screen.dart';
import 'package:material_ui/material_ui.dart';

/// feature_speaking's module: the Hablar tab (id `speak`), the call with Danny (`CallRoute`) and the voice test
/// (`VoiceTestRoute`).
///
/// The grey line on a call when `call.available` is false is "Calls with Danny open later." unless
/// [callsLater] says otherwise.
///
/// Two things v=39 does not settle are given to the module by whoever builds it, and are left out when not given
/// (order 24, "STOP": see coqui/requests/24-feature-speaking-needs-coqui-contracts-voice-test-lines.md):
/// - [voiceTest]: the twelve lines of the voice test and the Spanish words around them (course text, not code); until
///   they come from somewhere, `VoiceTestRoute` is not answered;
/// - [voiceTestEntry]: the title of the entry to the voice test on the Hablar tab; with none there is no entry.
///
/// Order 25 adds two stand-ins until the contracts carry them (coqui/requests/25-feature-speaking-needs-coqui-contracts-call-titles.md):
/// [entitlementCheck] (the live-calls plan) and [completedCallIds] (until `ProgressStore` keeps the calls done).
class SpeakingModule implements FeatureModule {
  const SpeakingModule({
    this.callsLater,
    this.voiceTest,
    this.voiceTestEntry,
    this.showSpeechNote = false,
    this.entitlementCheck = defaultCallEntitlement,
    this.completedCallIds = const {},
  });

  /// The line shown when the build cannot place a call; null uses `CallTexts.callsLater`.
  final String? callsLater;

  final VoiceTestContent? voiceTest;
  final String? voiceTestEntry;

  /// Shows `notaHabla` on the Hablar tab when requested.
  final bool showSpeechNote;

  /// Subscription tier check hook for live calls.
  final CallEntitlementCheck entitlementCheck;

  /// Completed call IDs (temporary until `ProgressStore` tracks completed calls).
  final Set<String> completedCallIds;

  @override
  String get id => 'speak';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: CoquiTabs.speakId,
    label: CoquiLabels.speak,
    icon: Icons.mic,
    builder: (_) => HablarTab(
      services: s,
      callsLater: callsLater,
      voiceTestLabel: voiceTest == null ? null : voiceTestEntry,
      showSpeechNote: showSpeechNote,
      entitlementCheck: entitlementCheck,
      completedCallIds: completedCallIds,
    ),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) {
    if (route is CallRoute) {
      final known =
          s.course.callFor(route.placeId) != null &&
          s.course.places.any((p) => p.id == route.placeId);
      return known
          ? CallScreen(
              key: ValueKey('call-${route.placeId}'),
              services: s,
              placeId: route.placeId,
            )
          : null;
    }
    if (route is VoiceTestRoute) {
      final v = voiceTest;
      return v == null ? null : VoiceTestScreen(services: s, content: v);
    }
    return null;
  }
}
