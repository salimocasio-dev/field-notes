import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/me_data.dart';
import 'package:feature_profile/src/texts.dart';
import 'package:material_ui/material_ui.dart';

/// The Noche Plans screen (`docs/proyecto/noche/Noche-Planes.dc.html`, story
/// N3.2 / issue #96), reached via [PlansRoute] from Me's `"Your plan"` row.
///
/// Shows the three plans in fixed order (`Free`, `Course`, `Course + Calls`),
/// tags the learner's active plan with `"Your plan"`, highlights only the next
/// tier up with a 2 px `next` border and a single orange `"Get <plan>"` button,
/// and omits price or call-minute lines whenever [Entitlements] returns `null`.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key, required this.services, this.entitlements});

  final Services services;

  /// Optional override for tests; defaults to [Services.entitlements].
  final Entitlements? entitlements;

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  StreamSubscription<void>? _entitlementChanges;

  Services get _s => widget.services;
  Entitlements get _entitlements => widget.entitlements ?? _s.entitlements;

  @override
  void initState() {
    super.initState();
    _listenEntitlements();
  }

  void _listenEntitlements() {
    _entitlementChanges?.cancel();
    _entitlementChanges = _entitlements.changes.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(PlansScreen old) {
    super.didUpdateWidget(old);
    final oldEntitlements = old.entitlements ?? old.services.entitlements;
    if (oldEntitlements != _entitlements) {
      _listenEntitlements();
    }
  }

  @override
  void dispose() {
    _entitlementChanges?.cancel();
    super.dispose();
  }

  Plan? _nextTierUp(Plan current) => switch (current) {
    Plan.free => Plan.course,
    Plan.course => Plan.courseAndCalls,
    Plan.courseAndCalls => null,
  };

  String? _priceLine(Plan plan) {
    final price = _entitlements.priceOf(plan);
    if (price == null || price.isEmpty) return null;
    return plansPricePerMonth(price);
  }

  void _onBack() {
    _s.haptics.tick();
    _s.nav.back();
  }

  void _onBuy(Plan plan) {
    _s.haptics.tick();
    unawaited(_entitlements.buy(plan));
  }

  void _onRestore() {
    _s.haptics.tick();
    unawaited(_entitlements.restore());
  }

  @override
  Widget build(BuildContext context) {
    final entitlements = _entitlements;
    final current = entitlements.plan;
    final nextTier = _nextTierUp(current);
    final pad = MediaQuery.paddingOf(context);
    final coursePrice = _priceLine(Plan.course);
    final callsPrice = _priceLine(Plan.courseAndCalls);
    final callMinutes = entitlements.callMinutes(Plan.courseAndCalls);

    return ColoredBox(
      color: NocheColors.ground,
      child: DefaultTextStyle.merge(
        style: NocheType.body.copyWith(color: NocheColors.text),
        child: CustomScrollView(
          key: const Key('plans-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: pad.top),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlansHeader(onBack: _onBack),
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16,
                      ),
                      child: Text(
                        plansIntro,
                        style: NocheType.bodyLarge.copyWith(
                          color: NocheColors.label,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: _FreePlanCard(
                        key: const Key('plans-card-free'),
                        isCurrent: current == Plan.free,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: _PaidPlanCard(
                        key: const Key('plans-card-course'),
                        title: planDisplayName(Plan.course),
                        priceLine: coursePrice,
                        isCurrent: current == Plan.course,
                        isNext: nextTier == Plan.course,
                        bullets: [
                          for (final line in plansCourseBullets)
                            _PlanBullet(text: line),
                        ],
                        actionKey: const Key('plans-buy-course'),
                        actionLabel: plansGetLabel(
                          planDisplayName(Plan.course),
                        ),
                        onBuy: () => _onBuy(Plan.course),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: _PaidPlanCard(
                        key: const Key('plans-card-course-and-calls'),
                        title: planDisplayName(Plan.courseAndCalls),
                        priceLine: callsPrice,
                        isCurrent: current == Plan.courseAndCalls,
                        isNext: nextTier == Plan.courseAndCalls,
                        bullets: [
                          const _PlanBullet(text: plansCallsEverythingInCourse),
                          const _PlanBullet(
                            text: plansCallsLiveCalls,
                            emphasized: true,
                          ),
                          if (callMinutes != null)
                            _PlanBullet(
                              text: plansCallMinutesPerMonth(callMinutes),
                            ),
                        ],
                        actionKey: const Key('plans-buy-course-and-calls'),
                        actionLabel: plansGetLabel(
                          planDisplayName(Plan.courseAndCalls),
                        ),
                        onBuy: () => _onBuy(Plan.courseAndCalls),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    16,
                    24,
                    16,
                    24 + pad.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _RestoreButton(
                        key: const Key('plans-restore'),
                        onPressed: _onRestore,
                      ),
                      const SizedBox(height: NocheSize.grid),
                      Text(
                        plansFootNote,
                        key: const Key('plans-footnote'),
                        textAlign: TextAlign.center,
                        style: NocheType.bodySmall.copyWith(
                          fontSize: 12,
                          height: 16 / 12,
                          color: NocheColors.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlansHeader extends StatelessWidget {
  const _PlansHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 16, 0),
        child: Row(
          children: [
            Pressable(
              key: const Key('plans-back'),
              onPressed: onBack,
              semanticLabel: plansBackLabel,
              builder: (context, pressed) => Transform.scale(
                scale: pressed ? 0.94 : 1,
                child: SizedBox(
                  width: NocheSize.touch,
                  height: NocheSize.touch,
                  child: Center(
                    child: NocheIcon(
                      NocheIcons.back,
                      size: 24,
                      color: NocheColors.text,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: NocheSize.grid),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  plansTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NocheType.pageTitle.copyWith(color: NocheColors.text),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YourPlanTag extends StatelessWidget {
  const _YourPlanTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('plans-current-tag'),
      height: 24,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: NocheColors.text,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: AlignmentDirectional.center,
      child: Text(
        plansYourPlan,
        maxLines: 1,
        softWrap: false,
        style: NocheType.tabLabelOn.copyWith(color: NocheColors.ground),
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard({super.key, required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: NocheColors.line, width: 1),
        borderRadius: BorderRadius.circular(NocheSize.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    planDisplayName(Plan.free),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NocheType.sheetTitle.copyWith(
                      color: NocheColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: NocheSize.grid),
                if (isCurrent)
                  const _YourPlanTag()
                else
                  Text(
                    plansNoCost,
                    maxLines: 1,
                    softWrap: false,
                    style: NocheType.button.copyWith(color: NocheColors.label),
                  ),
              ],
            ),
            if (isCurrent) ...[
              const SizedBox(height: 4),
              Text(
                plansNoCost,
                style: NocheType.button.copyWith(
                  height: 20 / 14,
                  color: NocheColors.label,
                ),
              ),
            ],
            const SizedBox(height: NocheSize.grid),
            _BulletList(
              bullets: [
                for (final line in plansFreeBullets) _PlanBullet(text: line),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidPlanCard extends StatelessWidget {
  const _PaidPlanCard({
    super.key,
    required this.title,
    required this.priceLine,
    required this.isCurrent,
    required this.isNext,
    required this.bullets,
    required this.actionKey,
    required this.actionLabel,
    required this.onBuy,
  });

  final String title;
  final String? priceLine;
  final bool isCurrent;
  final bool isNext;
  final List<_PlanBullet> bullets;
  final Key actionKey;
  final String actionLabel;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final price = priceLine;
    return NocheCard(
      variant: isNext ? NocheCardVariant.highlight : NocheCardVariant.standard,
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NocheType.sheetTitle.copyWith(color: NocheColors.text),
                ),
              ),
              if (isCurrent || price != null) ...[
                const SizedBox(width: NocheSize.grid),
                if (isCurrent)
                  const _YourPlanTag()
                else
                  Text(
                    price!,
                    maxLines: 1,
                    softWrap: false,
                    style: NocheType.button.copyWith(color: NocheColors.text),
                  ),
              ],
            ],
          ),
          if (isCurrent && price != null) ...[
            const SizedBox(height: 4),
            Text(
              price,
              style: NocheType.button.copyWith(
                height: 20 / 14,
                color: NocheColors.text,
              ),
            ),
          ],
          const SizedBox(height: NocheSize.grid),
          _BulletList(bullets: bullets),
          if (isNext) ...[
            const SizedBox(height: 16),
            NochePrimaryButton(
              key: actionKey,
              label: actionLabel,
              onPressed: onBuy,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanBullet {
  const _PlanBullet({required this.text, this.emphasized = false});

  final String text;
  final bool emphasized;
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.bullets});

  final List<_PlanBullet> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bullets.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          Text(
            bullets[i].text,
            style: NocheType.body.copyWith(
              color: bullets[i].emphasized
                  ? NocheColors.text
                  : NocheColors.label,
              fontWeight: bullets[i].emphasized
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _RestoreButton extends StatelessWidget {
  const _RestoreButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      semanticLabel: plansRestorePurchases,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.98 : 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: NocheSize.touch,
            minHeight: NocheSize.touch,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
                plansRestorePurchases,
                maxLines: 1,
                softWrap: false,
                style: NocheType.button.copyWith(
                  color: NocheColors.text,
                  decoration: TextDecoration.underline,
                  decorationColor: NocheColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
