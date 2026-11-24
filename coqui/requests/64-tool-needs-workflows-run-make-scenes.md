# 64: tool needs workflows to run make_scenes.dart before mobile builds

## What I need

In `.github/workflows/coqui-android.yml` and `.github/workflows/coqui-ios.yml`, add a step right after `flutter pub get` (with `working-directory: coqui`):

```yaml
      - name: Generate shared scene lists
        run: dart run tool/make_scenes.dart
```

(`.github/workflows/coqui.yml` already invokes `bash coqui/tool/test_all.sh` and `.github/workflows/coqui-sitio.yml` already invokes `bash coqui/tool/build_sitio.sh`, and both scripts now run `dart run tool/make_scenes.dart`.)

## Why

Story `#64` untracks the 4 generated files in `coqui/packages/core/coqui_scenes/` (`lib/src/registry.dart`, `lib/src/converted_scenes.dart`, `test/support/fixtures/sheets.dart`, `test/support/fixtures/old_hashes.dart`) and generates them via `coqui/tool/make_scenes.dart`. Unlike `coqui.yml` and `coqui-sitio.yml`, `coqui-android.yml` and `coqui-ios.yml` invoke `flutter build apk --debug` and `flutter build ios --no-codesign` directly without calling `test_all.sh` or `build_sitio.sh`, so they need to generate `registry.dart` and `converted_scenes.dart` before building `coqui/app`.

## What I am using meanwhile

Running `dart run tool/make_scenes.dart` locally (and inside `coqui/tool/test_all.sh` and `coqui/tool/build_sitio.sh`). `.github/` is outside `lane:coqui_scenes` and `lane:tool`, so this request asks the orchestrator to update the two mobile build workflows.

## Order and branch

Order `#64`, branch `story/64`.
