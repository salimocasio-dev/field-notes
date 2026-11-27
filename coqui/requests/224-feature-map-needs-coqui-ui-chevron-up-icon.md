# Request: Upward chevron icon (`NocheIcons.chevronUp`)

## What I need

In `coqui_ui` (`lib/src/noche_icons.dart`), add:

```dart
/// Upward chevron. Noche-Motion-Visita.dc.html (24, stroke 2.5)
static const chevronUp = NocheIconData([
  NocheIconShape('M6 15l6-6 6 6'),
], strokeWidth: 2.5);
```

(24x24 viewBox, `strokeWidth: 2.5`, matching `NocheIcons.chevronDown`.)

## Why

Story N8.6 ("Map: the place card", issue #224) renders a 48x48 circular button on the focused place card with a 24x24 upward chevron (`Noche-Motion-Visita.dc.html`, lines 143 & 163).

## What I am using meanwhile

In `feature_map` (`lib/src/map_screen.dart`), flipping `NocheIcons.chevronDown` vertically:

```dart
Transform.flip(
  flipY: true,
  child: const NocheIcon(
    NocheIcons.chevronDown,
    size: 24,
    color: NocheColors.text,
  ),
)
```

## Order and branch

- Order: 224 (N8.6 Map: the place card)
- Branch: `lane/feature_map/224`
