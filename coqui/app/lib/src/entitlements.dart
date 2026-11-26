/// Explicit pre-billing entitlements for release builds (never uses [AllowAllEntitlements]).
library;

import 'package:coqui_contracts/coqui_contracts.dart';

/// Explicit-allow-set [Entitlements] for builds before billing exists.
///
/// Any [Feature] not present in [allowed] is denied by default.
final class ReleaseEntitlements implements Entitlements {
  /// Creates entitlements permitting only the features in [allowed].
  ReleaseEntitlements({required Set<Feature> allowed})
    : _allowed = Set<Feature>.unmodifiable(allowed);

  /// Pre-billing release entitlements: every place and the library are open,
  /// and live calls are granted only when [callsAllowed] is true.
  factory ReleaseEntitlements.preBilling({required bool callsAllowed}) =>
      ReleaseEntitlements(
        allowed: {
          Feature.everyPlace,
          Feature.library,
          if (callsAllowed) Feature.calls,
        },
      );

  final Set<Feature> _allowed;

  /// Unmodifiable view of the granted [Feature] set.
  Set<Feature> get allowed => _allowed;

  @override
  Plan get plan {
    final hasCourse =
        _allowed.contains(Feature.everyPlace) &&
        _allowed.contains(Feature.library);
    if (hasCourse && _allowed.contains(Feature.calls)) {
      return Plan.courseAndCalls;
    }
    if (hasCourse) return Plan.course;
    return Plan.free;
  }

  @override
  bool has(Feature f) => _allowed.contains(f);

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  String? priceOf(Plan p) => null;

  @override
  int? callMinutes(Plan p) => null;

  @override
  Future<void> buy(Plan p) async {}

  @override
  Future<void> restore() async {}
}
