import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

/// In-memory [Entitlements] fake for tests.
///
/// What it does: starts on [plan] (default [Plan.courseAndCalls]) and exposes
/// a mutable [plan] setter that emits on [changes] whenever the plan actually
/// changes. [has] gates [Feature]s by the current [plan]: [Plan.free] unlocks
/// nothing, [Plan.course] unlocks [Feature.everyPlace] and [Feature.library],
/// and [Plan.courseAndCalls] unlocks every feature. [priceOf] and [callMinutes]
/// read from the mutable [prices] and [minutes] maps. [buy] appends the
/// requested plan to [bought] and [restore] increments [restores]. [dispose]
/// closes the [changes] stream.
///
/// What it does not do: no real store billing, receipts, or network calls.
/// [buy] and [restore] only record calls and do not change [plan] by
/// themselves.
class FakeEntitlements implements Entitlements {
  FakeEntitlements({
    this._plan = Plan.courseAndCalls,
    Map<Plan, String>? prices,
    Map<Plan, int>? minutes,
  }) : prices = Map.of(prices ?? const {}),
       minutes = Map.of(minutes ?? const {});

  Plan _plan;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Formatted prices by plan, returned by [priceOf]. Mutate freely in tests.
  final Map<Plan, String> prices;

  /// Call-minute allowances by plan, returned by [callMinutes]. Mutate freely in tests.
  final Map<Plan, int> minutes;

  /// Every [Plan] passed to [buy], in order.
  final List<Plan> bought = [];

  /// How many times [restore] was called.
  int restores = 0;

  @override
  Plan get plan => _plan;

  /// Updates the active [plan] and emits on [changes] when it differs from the
  /// current plan.
  set plan(Plan next) {
    if (_plan == next) return;
    _plan = next;
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  bool has(Feature f) => switch (_plan) {
    Plan.free => false,
    Plan.course => f == Feature.everyPlace || f == Feature.library,
    Plan.courseAndCalls => true,
  };

  @override
  Stream<void> get changes => _changes.stream;

  @override
  String? priceOf(Plan p) => prices[p];

  @override
  int? callMinutes(Plan p) => minutes[p];

  @override
  Future<void> buy(Plan p) async {
    bought.add(p);
  }

  @override
  Future<void> restore() async {
    restores++;
  }

  /// Closes the [changes] stream.
  void dispose() {
    if (!_changes.isClosed) _changes.close();
  }
}
