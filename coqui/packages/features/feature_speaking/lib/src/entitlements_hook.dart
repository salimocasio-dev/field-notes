/// Subscription tier hook for live calls.
///
/// Live voice calls belong to the top subscription tier. Until `Services.entitlements`
/// lands (see `coqui/requests/5-coqui-contracts-needs-coqui-ui-services-entitlements.md`),
/// callers pass a [CallEntitlementCheck] into `SpeakingModule` or `HablarTab`.
library;

/// Whether the current learner's subscription tier allows live voice calls.
enum CallEntitlement {
  /// Included in the learner's plan (or dev/fake build).
  included,

  /// Requires upgrading to the live-calls tier.
  upgradeRequired,
}

/// Callback checked by Hablar before enabling the primary Start call action.
typedef CallEntitlementCheck = CallEntitlement Function();

/// Default entitlement check used until `coqui_contracts` exposes `Entitlements`.
CallEntitlement defaultCallEntitlement() => CallEntitlement.included;
