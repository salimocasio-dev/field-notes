/// Subscription plans and feature access (N2.1).
///
/// Current plan breakdown (provisional, subject to change):
/// - [Plan.free]: the first place in every language and review of its words.
/// - [Plan.course]: every place, every story, and the Library.
/// - [Plan.courseAndCalls]: everything in [Plan.course] plus live calls.
enum Plan { free, course, courseAndCalls }

/// Capabilities gated by a [Plan].
enum Feature { calls, everyPlace, library }

/// Reports what the learner's current [plan] allows and handles plan purchases.
abstract interface class Entitlements {
  Plan get plan;
  bool has(Feature f);
  Stream<void> get changes;
  String? priceOf(Plan p);
  int? callMinutes(Plan p);
  Future<void> buy(Plan p);
  Future<void> restore();
}

/// Default entitlements before billing exists: every feature is open, prices
/// and call-minute caps are unset (null), and [buy]/[restore] are no-ops.
final class AllowAllEntitlements implements Entitlements {
  const AllowAllEntitlements();

  @override
  Plan get plan => Plan.courseAndCalls;

  @override
  bool has(Feature f) => true;

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
