# Request: Script font fallback on `NochePrimaryButton` in `coqui_ui`

## What I need

In `coqui/packages/core/coqui_ui/`:

Support rendering mixed English + non-Latin course text (such as `"Back to تكلّم"` in Arabic) inside `NochePrimaryButton` — either by adding `nocheFontArabic` to `fontFamilyFallback` on `NocheType.primary` / `NocheType.primarySmall` or by accepting an optional `script` / `TextSpan` label on `NochePrimaryButton`.

## Why

Story #233 (`lane:feature_speaking`, N8.15) renders `"Back to <Speak tab name>"` (`SpeakWording.backToSpeak`) on `NochePrimaryButton` in `"Call done"`. Because `NocheType.primary` uses the Latin-subset `Atkinson Hyperlegible Next` font without a fallback to bundled `Noto Sans Arabic`, non-Latin course tab names render blank in headless VM screenshots where no platform Arabic font is installed.

## What I am using meanwhile

`_CallDoneSummary` passes `SpeakWording.backToSpeak(widget.speakTabName)` straight into `NochePrimaryButton` so the label text and semantics are exact and real devices fall back to the OS Arabic font.

## Order and branch

- Order: 233 (`lane:feature_speaking`)
- Branch: `lane/feature_speaking/233`
