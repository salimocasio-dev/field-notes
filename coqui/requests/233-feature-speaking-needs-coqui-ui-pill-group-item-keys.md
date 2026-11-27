# Request: Optional `Key? key` on `NochePillOption` in `coqui_ui`

## What I need

In `coqui/packages/core/coqui_ui/`:

Add an optional `Key? key` parameter to `NochePillOption<T>` and attach it to the rendered `_PillGroupItem` (or its outer `Pressable`) inside `NochePillGroup<T>`, so callers can place stable widget keys directly on each pill item without workarounds.

## Why

Story #233 (`lane:feature_speaking`, N8.15) migrates the Speak tab's reached place pills from individual `NochePill` widgets to `NochePillGroup<String>` so the white selection pill slides smoothly between places. `feature_speaking/AGENTS.md` requires keeping the stable widget key `Key('speak-place-<placeId>')` on each reached place pill. Because `NochePillOption` does not accept a `Key?` yet, the key cannot be attached to the pill item widget directly.

## What I am using meanwhile

In `HablarTab._placePills`, each `NochePillOption<String>` sets `padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 16, 0)` and passes `leading: SizedBox(key: Key('speak-place-${stop.place.id}'), width: 8, height: NocheSize.touch)`. Because `_PillGroupItem` inserts an 8 px gap after `leading`, the start padding remains 16 px (`0 + 8 + 8`) and `find.byKey(Key('speak-place-<id>'))` stays tappable inside the pill's `Pressable`.

## Order and branch

- Order: 233 (`lane:feature_speaking`)
- Branch: `lane/feature_speaking/233`
