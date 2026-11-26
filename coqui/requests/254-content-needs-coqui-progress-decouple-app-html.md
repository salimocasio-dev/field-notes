# 254: `content` needs `coqui_progress` to decouple `historia/app.html` disk check

## What I need
Update `coqui/packages/core/coqui_progress/test/fixture_files_test.dart` (lines 38–67, group `'historia/app.html still has what the app.html sequences were run from'`) so it no longer reads `File('../../../../historia/app.html')` from disk during `dart test -p vm`.

## Why
Issue #254 (`First-version pages: keep, move or remove`) removes the retired first-version public HTML pages and `?legacy=1` escape hatches. Deleting `historia/app.html` currently fails 18 tests in `coqui_progress` (`PathNotFoundException: Cannot open file, path = '../../../../historia/app.html'`), blocking full removal of `historia/app.html`.

## What I am using meanwhile
Kept `historia/app.html` on disk temporarily (503 lines preserved) with line 2 updated to a loopback (`127.0.0.1` / `localhost` / `[::1]`) + `navigator.webdriver` tooling guard calling `if(window.stop)window.stop();` before `location.replace("../app/");`, plus `<noscript><meta http-equiv="refresh" content="0; url=../app/"></noscript>`. This removes `?legacy=1` and redirects public visitors to `../app/` while preserving local headless Playwright capture (`coqui/tool/ref/pantallas/capturar.mjs`) and leaving all `fixtureAppPieces` substrings intact so `coqui_progress` tests stay green until this decoupling lands.

## Order and branch
Issue `#254`, branch `content/254` (`lane:content`).
