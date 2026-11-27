# 254: `content` needs `coqui_ui` to decouple `historia/app.html` disk check

## What I need
Update `coqui/packages/core/coqui_ui/test/widgets_test.dart` (lines 71–81, test `'each label is copied from the line of the old page it names'`) so it no longer reads `File('../../../../historia/app.html').readAsLinesSync()` from disk during `flutter test`.

## Why
Issue #254 (`First-version pages: keep, move or remove`) removes the retired first-version public HTML pages and `?legacy=1` escape hatches. Deleting `historia/app.html` currently fails 1 test in `coqui_ui` (`PathNotFoundException: Cannot open file, path = '../../../../historia/app.html'`), blocking full removal of `historia/app.html`.

## What I am using meanwhile
Kept `historia/app.html` on disk temporarily (503 lines preserved so lines 7, 331, 365, and 374 remain unchanged) with line 2 updated to a loopback (`127.0.0.1` / `localhost` / `[::1]`) + `navigator.webdriver` tooling guard calling `if(window.stop)window.stop();` before `location.replace("../app/");`, plus `<noscript><meta http-equiv="refresh" content="0; url=../app/"></noscript>`. This removes `?legacy=1` and redirects public visitors to `../app/` while preserving local headless Playwright capture (`coqui/tool/ref/pantallas/capturar.mjs`) and keeping `coqui_ui` tests green until this decoupling lands.

## Order and branch
Issue `#254`, branch `content/254` (`lane:content`).
