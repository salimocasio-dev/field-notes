# 24 · feature_speaking needs coqui_contracts (or content): where the voice test's twelve lines come from

## What I need

The voice test's twelve lines, from the course's data and not from code: for each, the text to say, an optional hint, and the targets (each a word with the forms of it that count). habla-prueba.html has them as literals in its page (`LINES`):

```
{t:"Hola, abuela", g:[["hola",["hola"]],["abuela",["abuela"]]]}     {t:"Sí", g:[["sí",["si"]]]}     {t:"No", g:[["no",["no"]]]}
{t:"Gracias", ...}  {t:"Adiós", ...}  {t:"La casa", ...}  {t:"La puerta", ...}  {t:"La ventana", ...}
{t:"Quiero jugo, por favor", g:[["quiero",["quiero"]],["jugo",["jugo"]]]}   {t:"Me llamo…", h:"tu nombre", g:[["me llamo",["me llamo"]]]}
{t:"¿Cómo estás?", g:[["¿cómo estás?",["como estas"]]]}   {t:"Uno, dos, tres", g:[["uno",["uno","1"]],["tres",["tres","3"]]]}
```

A catalog member (for example `List<VoiceTestLine> get voiceTest` on `CourseCatalog`, with a file in `historia/datos/`) or whatever the orchestrator chooses. The words around the lines (the labels in 24-feature-speaking-needs-coqui-ui-call-screen.md) come the same way, or from `CoquiLabels`.

## Why

Order 24: "its lines come from where the old page has them (if they are literals in the page, they are course text and must come from data: STOP and ask where; do not put Spanish in code)". They are literals, so this item is stopped.

## What I am using meanwhile

`VoiceTestScreen` takes a `VoiceTestContent` (the lines and the labels). `SpeakingModule(voiceTest: ...)` takes one, and with none `screenFor(VoiceTestRoute())` returns null: the route is not answered until the lines have a source. The dev entry and the tests give the old page's own twelve lines and labels from `test/support/voice_fixture.dart` (test data, not code under `lib/`), so the screenshots and the tests show the test as v=39 does. When the lines have a source, `SpeakingModule.screenFor` reads them from `Services` and `voiceTest:` goes.

## Order and branch

Order 24, branch `lane/feature_speaking/24`.
