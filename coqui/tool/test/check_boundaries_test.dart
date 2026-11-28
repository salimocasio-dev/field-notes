// Tests for tool/check_boundaries.dart. Each test builds a small made-up
// workspace in a temp folder: only the packages the test needs, each with a
// pubspec and a few Dart files. Rule (d) also needs a git repository.
//
// Run at coqui/:  dart test tool/test

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../check_boundaries.dart';

late Directory repo; // the git repository (the "field-notes" of the test)
late Directory coqui; // repo/coqui, the workspace the check reads

void main() {
  setUp(() {
    repo = Directory.systemTemp.createTempSync('coqui_boundaries_');
    coqui = Directory('${repo.path}/coqui')..createSync();
  });

  tearDown(() => repo.deleteSync(recursive: true));

  Future<List<String>> check({
    String? branch = 'main',
    String? base,
    File? laneMapFile,
  }) => checkBoundaries(
    coqui,
    branch: branch,
    base: base,
    laneMapFile: laneMapFile,
  );

  group('[a] a pubspec lists a package its row does not allow', () {
    test(
      'passes: a feature lists its row, the SDK and its dev tools',
      () async {
        package('feature_words', deps: ['coqui_contracts', 'coqui_ui']);
        expect(await check(), isEmpty);
      },
    );

    test('fails: a feature lists a package outside its row', () async {
      package('feature_words', deps: ['coqui_ui', 'coqui_pixel']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[a]'));
      expect(problems.single, contains('feature_words lists coqui_pixel'));
      expect(
        problems.single,
        startsWith('packages/features/feature_words/pubspec.yaml:'),
      );
    });

    test('fails: a package lists a third-party package of another', () async {
      package('feature_words', deps: ['coqui_ui', 'just_audio']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[a]'));
      expect(problems.single, contains('just_audio'));
      expect(problems.single, contains('only coqui_platform may'));
    });

    test(
      'fails: a package lists a third-party package not in the list',
      () async {
        package('coqui_pixel', deps: ['coqui_contracts', 'http']);
        final problems = await check();
        expect(problems, hasLength(1));
        expect(problems.single, contains('[a]'));
        expect(problems.single, contains('http'));
        expect(problems.single, contains('third-party list'));
      },
    );

    test(
      'passes: coqui_platform lists the plugins; app lists go_router',
      () async {
        package(
          'coqui_platform',
          deps: [
            'coqui_contracts',
            'just_audio',
            'speech_to_text',
            'shared_preferences',
            'web',
          ],
        );
        package(
          'app',
          deps: ['feature_words', 'feature_map', 'coqui_platform', 'go_router'],
        );
        expect(await check(), isEmpty);
      },
    );

    test('fails: a feature lists go_router', () async {
      package('feature_map', deps: ['coqui_ui', 'go_router']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('go_router'));
      expect(problems.single, contains('only app may'));
    });

    test('passes: collection is allowed everywhere', () async {
      package('coqui_contracts', deps: ['collection']);
      package('feature_review', deps: ['coqui_ui', 'collection']);
      expect(await check(), isEmpty);
    });

    test(
      'fails: a core package lists a package its row does not allow',
      () async {
        package('coqui_contracts', deps: ['coqui_progress']);
        final problems = await check();
        expect(problems, hasLength(1));
        expect(
          problems.single,
          contains('coqui_contracts lists coqui_progress'),
        );
        expect(problems.single, contains('no Coquí package'));
      },
    );

    test('fails: a pure Dart package lists Flutter', () async {
      package('coqui_progress', deps: ['coqui_contracts'], flutter: true);
      final problems = await check();
      expect(problems, hasLength(3));
      expect(problems.join('\n'), contains('the Flutter SDK'));
      expect(problems.join('\n'), contains('flutter_lints'));
      expect(problems.join('\n'), contains('flutter_test'));
    });

    test('fails: a package that is not in the table', () async {
      package(
        'feature_extra',
        deps: [],
        dir: 'packages/features/feature_extra',
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('not in the package table'));
    });

    test('skips tool/prueba_telefono and the workspace root', () async {
      write(
        'pubspec.yaml',
        'name: coqui_workspace\ndependencies:\n  http: any\n',
      );
      write(
        'tool/prueba_telefono/pubspec.yaml',
        'name: prueba_telefono\ndependencies:\n  http: any\n',
      );
      expect(await check(), isEmpty);
    });
  });

  group('[b] a file imports a package its pubspec does not list', () {
    test('passes: it imports a listed package, itself and dart:', () async {
      package('feature_words', deps: ['coqui_contracts', 'coqui_ui']);
      src('feature_words', 'lib/feature_words.dart', '''
import 'dart:async';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart' show Foo;
import 'package:feature_words/src/words.dart';
export 'package:coqui_ui/coqui_ui.dart';
''');
      expect(await check(), isEmpty);
    });

    test('fails: it imports a package that is not listed', () async {
      package('feature_words', deps: ['coqui_ui']);
      src('feature_words', 'lib/src/words.dart', '''
import 'package:coqui_ui/coqui_ui.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
''');
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[b]'));
      expect(problems.single, contains('package:coqui_contracts'));
      expect(
        problems.single,
        startsWith('packages/features/feature_words/lib/src/words.dart:2:'),
      );
    });

    test('fails: a pure Dart package imports Flutter', () async {
      package('coqui_pixel', deps: ['coqui_contracts']);
      src(
        'coqui_pixel',
        'lib/src/x.dart',
        "import 'package:flutter/widgets.dart';\n",
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[b]'));
      expect(problems.single, contains('package:flutter'));
    });

    test('fails: the import is after a conditional-import `if`', () async {
      package('coqui_platform', deps: ['coqui_contracts']);
      src('coqui_platform', 'lib/src/clips.dart', '''
export 'package:coqui_contracts/coqui_contracts.dart'
    if (dart.library.js_interop) 'package:web/web.dart';
''');
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('package:web'));
      expect(problems.single, contains('lib/src/clips.dart:1:'));
    });

    test('ignores imports in comments', () async {
      package('feature_words', deps: ['coqui_ui']);
      src('feature_words', 'lib/src/words.dart', '''
// import 'package:coqui_pixel/coqui_pixel.dart';
/* import 'package:coqui_pixel/coqui_pixel.dart'; */
/// import 'package:coqui_pixel/src/x.dart';
void main() {}
''');
      expect(await check(), isEmpty);
    });

    test('reads test/ files too', () async {
      package('feature_words', deps: ['coqui_ui']);
      src(
        'feature_words',
        'test/words_test.dart',
        "import 'package:coqui_testing/coqui_testing.dart';\n",
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[b]'));
      expect(problems.single, contains('package:coqui_testing'));
    });
  });

  group('[c] a file imports another package\'s src/', () {
    test(
      'passes: the public file of another package, and its own src/',
      () async {
        package('feature_words', deps: ['coqui_ui']);
        src('feature_words', 'lib/src/a.dart', '''
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/b.dart';
''');
        expect(await check(), isEmpty);
      },
    );

    test('fails: it imports the src/ of a listed package', () async {
      package('feature_words', deps: ['coqui_ui']);
      src(
        'feature_words',
        'lib/src/a.dart',
        "import 'package:coqui_ui/src/x.dart';\n",
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[c]'));
      expect(problems.single, contains('package:coqui_ui/src/x.dart'));
    });

    test('fails: it imports the src/ of a third-party package', () async {
      package('coqui_content', deps: ['coqui_contracts', 'collection']);
      src(
        'coqui_content',
        'lib/src/a.dart',
        "import 'package:collection/src/utils.dart';\n",
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[c]'));
    });
  });

  group('[e] a feature names another feature', () {
    test('fails: its pubspec lists another feature', () async {
      package('feature_words', deps: ['coqui_ui', 'feature_story']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[e]'));
      expect(problems.single, contains('feature_words lists feature_story'));
    });

    test('fails: its dev dependencies list another feature', () async {
      package('feature_words', deps: ['coqui_ui'], devDeps: ['feature_story']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[e]'));
    });

    test('fails: it imports another feature', () async {
      package('feature_words', deps: ['coqui_ui']);
      src(
        'feature_words',
        'lib/src/a.dart',
        "import 'package:feature_story/feature_story.dart';\n",
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[e]'));
      expect(problems.single, contains('feature_words imports feature_story'));
    });

    test('passes: the shell lists and imports every feature', () async {
      package('app', deps: ['feature_words', 'feature_story', 'coqui_ui']);
      src('app', 'lib/src/modules.dart', '''
import 'package:feature_story/feature_story.dart';
import 'package:feature_words/feature_words.dart';
''');
      expect(await check(), isEmpty);
    });
  });

  group('[a] coqui_ui, material_ui and coqui_testing (Nov 19 decisions)', () {
    test('passes: coqui_ui lists coqui_contracts', () async {
      package('coqui_ui', deps: ['coqui_contracts', 'material_ui']);
      expect(await check(), isEmpty);
    });

    test('fails: coqui_ui lists another Coquí package', () async {
      package('coqui_ui', deps: ['coqui_contracts', 'coqui_pixel']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('coqui_ui lists coqui_pixel'));
      expect(problems.single, contains('its row allows coqui_contracts'));
    });

    test(
      'passes: material_ui in a feature, coqui_ui, scenes and app',
      () async {
        package('feature_words', deps: ['coqui_ui', 'material_ui']);
        package('coqui_ui', deps: ['coqui_contracts', 'material_ui']);
        package('coqui_scenes', deps: ['coqui_ui', 'material_ui']);
        package('app', deps: ['coqui_ui', 'material_ui']);
        expect(await check(), isEmpty);
      },
    );

    test('fails: material_ui in a pure Dart package', () async {
      package('coqui_pixel', deps: ['coqui_contracts', 'material_ui']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[a]'));
      expect(problems.single, contains('coqui_pixel lists material_ui'));
    });

    test('fails: material_ui in coqui_platform', () async {
      package('coqui_platform', deps: ['coqui_contracts', 'material_ui']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('coqui_platform lists material_ui'));
    });

    test(
      'passes: coqui_testing as a dev dependency where it is allowed',
      () async {
        package(
          'feature_words',
          deps: ['coqui_ui'],
          devDeps: ['coqui_testing'],
        );
        package('coqui_scenes', deps: ['coqui_ui'], devDeps: ['coqui_testing']);
        package('app', deps: ['coqui_ui'], devDeps: ['coqui_testing']);
        expect(await check(), isEmpty);
      },
    );

    test('fails: coqui_testing under dependencies', () async {
      package('feature_words', deps: ['coqui_ui', 'coqui_testing']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[a]'));
      expect(
        problems.single,
        contains(
          'feature_words lists coqui_testing in dependencies: it is a dev '
          'dependency only',
        ),
      );
    });

    test('fails: app lists coqui_testing under dependencies', () async {
      package('app', deps: ['coqui_ui', 'coqui_testing']);
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('app lists coqui_testing in dep'));
    });

    test('fails: coqui_testing where it is not allowed, even as dev', () async {
      package(
        'coqui_ui',
        deps: ['coqui_contracts'],
        devDeps: ['coqui_testing'],
      );
      package(
        'coqui_progress',
        deps: ['coqui_contracts'],
        devDeps: ['coqui_testing'],
      );
      package(
        'coqui_pixel',
        deps: ['coqui_contracts'],
        devDeps: ['coqui_testing'],
      );
      package(
        'coqui_platform',
        deps: ['coqui_contracts'],
        devDeps: ['coqui_testing'],
      );
      final problems = await check();
      expect(problems, hasLength(4));
      for (final name in [
        'coqui_ui',
        'coqui_progress',
        'coqui_pixel',
        'coqui_platform',
      ]) {
        expect(
          problems.where((p) => p.contains('$name lists coqui_testing')),
          hasLength(1),
          reason: name,
        );
      }
    });
  });

  group('[a] coqui_story_checks (#65)', () {
    test('passes: coqui_story_checks lists contracts, pixel, scenes and feature_story', () async {
      package(
        'coqui_story_checks',
        deps: [
          'coqui_contracts',
          'coqui_pixel',
          'coqui_scenes',
          'feature_story',
        ],
      );
      src('coqui_story_checks', 'test/sample_test.dart', '''
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:feature_story/feature_story.dart';
''');
      expect(await check(), isEmpty);
    });

    test('fails: coqui_story_checks lists another feature, coqui_ui or coqui_testing', () async {
      package(
        'coqui_story_checks',
        deps: ['coqui_scenes', 'feature_story', 'feature_map', 'coqui_ui'],
        devDeps: ['coqui_testing'],
      );
      final problems = await check();
      expect(problems, hasLength(3));
      expect(
        problems.join('\n'),
        contains('coqui_story_checks lists feature_map'),
      );
      expect(
        problems.join('\n'),
        contains('coqui_story_checks lists coqui_ui'),
      );
      expect(
        problems.join('\n'),
        contains('coqui_story_checks lists coqui_testing'),
      );
    });

    test('fails: coqui_story_checks imports feature_story src/', () async {
      package('coqui_story_checks', deps: ['feature_story']);
      src(
        'coqui_story_checks',
        'test/a_test.dart',
        "import 'package:feature_story/src/play/play.dart';\n",
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[c]'));
      expect(
        problems.single,
        contains('package:feature_story/src/play/play.dart'),
      );
    });

    test('fails: app or a feature lists coqui_story_checks', () async {
      package('app', deps: ['coqui_ui', 'coqui_story_checks']);
      package('feature_story', deps: ['coqui_ui', 'coqui_story_checks']);
      final problems = await check();
      expect(problems, hasLength(2));
      expect(problems.join('\n'), contains('app lists coqui_story_checks'));
      expect(
        problems.join('\n'),
        contains('feature_story lists coqui_story_checks'),
      );
    });
  });

  group('[f] nobody imports package:flutter/material.dart', () {
    test('fails: a file in lib/ imports it', () async {
      package('feature_words', deps: ['coqui_ui']);
      src(
        'feature_words',
        'lib/src/words.dart',
        "import 'package:flutter/material.dart';\n",
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[f]'));
      expect(problems.single, contains('package:flutter/material.dart'));
      expect(problems.single, contains('package:material_ui/material_ui.dart'));
      expect(
        problems.single,
        startsWith('packages/features/feature_words/lib/src/words.dart:1:'),
      );
    });

    test('fails: a test, or an export, imports it', () async {
      package('feature_words', deps: ['coqui_ui']);
      src(
        'feature_words',
        'test/a_test.dart',
        "import 'package:flutter/material.dart' show Text;\n",
      );
      src(
        'feature_words',
        'lib/feature_words.dart',
        "export 'package:flutter/material.dart';\n",
      );
      expect(await check(), hasLength(2));
    });

    test('passes: material_ui and the other Flutter libraries', () async {
      package('feature_words', deps: ['coqui_ui', 'material_ui']);
      src('feature_words', 'lib/src/words.dart', '''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
''');
      expect(await check(), isEmpty);
    });
  });

  group('[g] lib/ never imports coqui_testing', () {
    test('passes: tests and tool/ import it', () async {
      package('feature_words', deps: ['coqui_ui'], devDeps: ['coqui_testing']);
      src(
        'feature_words',
        'test/a_test.dart',
        "import 'package:coqui_testing/coqui_testing.dart';\n",
      );
      src(
        'feature_words',
        'tool/dev_main.dart',
        "import 'package:coqui_testing/coqui_testing.dart';\n",
      );
      expect(await check(), isEmpty);
    });

    test('fails: a file in lib/ imports it, though it is listed', () async {
      package('feature_words', deps: ['coqui_ui'], devDeps: ['coqui_testing']);
      src(
        'feature_words',
        'lib/dev_main.dart',
        "import 'package:coqui_testing/coqui_testing.dart';\n",
      );
      final problems = await check();
      expect(problems, hasLength(1));
      expect(problems.single, contains('[g]'));
      expect(
        problems.single,
        startsWith('packages/features/feature_words/lib/dev_main.dart:1:'),
      );
    });

    test('coqui_testing may import itself in lib/', () async {
      package('coqui_testing', deps: ['coqui_contracts', 'coqui_ui']);
      src(
        'coqui_testing',
        'lib/src/a.dart',
        "import 'package:coqui_testing/src/b.dart';\n",
      );
      expect(await check(), isEmpty);
    });
  });

  group('[d] a lane branch changes only its own package and requests/', () {
    late Git git;

    setUp(() {
      installRealLaneMap();
      package('feature_words', deps: ['coqui_ui']);
      package('feature_map', deps: ['coqui_ui']);
      src('feature_words', 'lib/src/a.dart', '// a\n');
      src('feature_map', 'lib/src/m.dart', '// m\n');
      git = Git(repo)..init();
    });

    test('passes: the lane changes its own package and requests/', () async {
      git.branch('lane/feature_words/99');
      src('feature_words', 'lib/src/a.dart', '// changed\n');
      write('requests/words-needs-a-thing.md', 'please\n');
      git.commit('work');
      expect(await check(branch: null), isEmpty);
    });

    test('passes: lane/coqui_story_checks changes coqui_story_checks and requests/', () async {
      git.branch('lane/coqui_story_checks/99');
      package('coqui_story_checks', deps: ['coqui_scenes', 'feature_story']);
      src('coqui_story_checks', 'test/a_test.dart', '// test\n');
      write('requests/checks-needs-a-thing.md', 'please\n');
      git.commit('work');
      expect(await check(branch: null), isEmpty);
    });

    test('fails: the lane changes a file of another package', () async {
      git.branch('lane/feature_words/99');
      src('feature_words', 'lib/src/a.dart', '// changed\n');
      src('feature_map', 'lib/src/m.dart', '// changed\n');
      git.commit('work');
      final problems = await check(branch: null);
      expect(problems, hasLength(1));
      expect(problems.single, contains('[d]'));
      expect(
        problems.single,
        startsWith('coqui/packages/features/feature_map/lib/src/m.dart:'),
      );
      expect(problems.single, contains('lane/feature_words/99'));
    });

    test('fails: the lane changes a file outside coqui/', () async {
      git.branch('lane/feature_words/99');
      File('${repo.path}/.github/workflows/coqui.yml')
        ..createSync(recursive: true)
        ..writeAsStringSync('name: x\n');
      git.commit('work');
      final problems = await check(branch: null);
      expect(problems, hasLength(1));
      expect(problems.single, startsWith('.github/workflows/coqui.yml: [d]'));
    });

    test('fails: the lane moves a file out of another package', () async {
      git.branch('lane/feature_words/99');
      git.run([
        'mv',
        'coqui/packages/features/feature_map/lib/src/m.dart',
        'coqui/packages/features/feature_words/lib/src/m.dart',
      ]);
      git.commit('move');
      final problems = await check(branch: null);
      expect(problems, hasLength(1));
      expect(problems.single, contains('feature_map/lib/src/m.dart'));
    });

    test('a branch that is not a lane is not checked', () async {
      git.branch('orden/01');
      src('feature_words', 'lib/src/a.dart', '// changed\n');
      src('feature_map', 'lib/src/m.dart', '// changed\n');
      git.commit('work');
      expect(await check(branch: null), isEmpty);
    });

    test('fails: the lane names an unknown lane', () async {
      git.branch('lane/feature_nothing/1');
      final problems = await check(branch: null);
      expect(problems, hasLength(1));
      expect(problems.single, contains('[d]'));
      expect(problems.single, contains('unknown lane'));
      expect(problems.single, contains('feature_nothing'));
    });

    test('takes the branch name from the argument (CI variables)', () async {
      git.branch('work-in-progress');
      src('feature_map', 'lib/src/m.dart', '// changed\n');
      git.commit('work');
      final problems = await check(branch: 'lane/feature_words/7');
      expect(problems, hasLength(1));
      expect(problems.single, contains('feature_map'));
      // the same change on a branch the argument does not call a lane
      expect(await check(branch: 'feature/anything'), isEmpty);
    });

    test('compares with origin/main when it exists, else main', () async {
      // main gains a commit in feature_map, then the lane branches from it.
      git.run(['update-ref', 'refs/remotes/origin/main', 'HEAD']);
      src('feature_map', 'lib/src/m.dart', '// main moved\n');
      git.commit('main moved');
      git.branch('lane/feature_words/5');
      src('feature_words', 'lib/src/a.dart', '// changed\n');
      git.commit('work');
      // against origin/main (one commit behind) feature_map's change shows
      final withOrigin = await check(branch: null);
      expect(withOrigin, hasLength(1));
      expect(withOrigin.single, contains('feature_map'));
      // against main only the lane's own change is left
      git.run(['update-ref', '-d', 'refs/remotes/origin/main']);
      expect(await check(branch: null), isEmpty);
    });

    test('compares with the ref it is given', () async {
      git.branch('lane/feature_words/5');
      src('feature_map', 'lib/src/m.dart', '// changed\n');
      git.commit('work');
      git.branch('lane/feature_words/6');
      src('feature_words', 'lib/src/a.dart', '// changed\n');
      git.commit('more work');
      // against main both commits show; against the first branch only one
      expect(await check(branch: null), hasLength(1));
      expect(await check(branch: null, base: 'lane/feature_words/5'), isEmpty);
    });

    test(
      'passes: lane/tool changes coqui/tool/, tools/, tool/, and requests/',
      () async {
        git.branch('lane/tool/55');
        write('tool/helper.dart', '// tool\n');
        writeRepo('tools/helper.py', '# tool\n');
        writeRepo('tool/hook.py', '# hook\n');
        write('requests/tool-needs-a-thing.md', 'please\n');
        git.commit('work');
        expect(await check(branch: null), isEmpty);
      },
    );

    test('fails: lane/tool rejects coqui_scenes/tool/, ref/pp/, coqui_scenes/lib/, ref/other/, and ref/pp_extra/', () async {
      git.branch('lane/tool/263');
      write('packages/core/coqui_scenes/tool/dev_main.dart', '// dev main\n');
      write('ref/pp/orilla/index.json', '{}\n');
      write('packages/core/coqui_scenes/lib/src/x.dart', '// disallowed\n');
      write('ref/other/x.json', '{}\n');
      write('ref/pp_extra/x.json', '{}\n');
      git.commit('disallowed paths on lane/tool');
      final problems = await check(branch: null);
      expect(problems, hasLength(5));
      for (final path in [
        'coqui/packages/core/coqui_scenes/tool/dev_main.dart',
        'coqui/ref/pp/orilla/index.json',
        'coqui/packages/core/coqui_scenes/lib/src/x.dart',
        'coqui/ref/other/x.json',
        'coqui/ref/pp_extra/x.json',
      ]) {
        expect(
          problems.any((p) => p.startsWith('$path: [d]')),
          isTrue,
          reason: 'expected $path to be rejected',
        );
      }
    });

    test(
      'fails: lane/tool changes a package outside tool/ and requests/',
      () async {
        git.branch('lane/tool/55');
        write('tool/helper.dart', '// tool\n');
        src('feature_words', 'lib/src/a.dart', '// changed\n');
        git.commit('work');
        final problems = await check(branch: null);
        expect(problems, hasLength(1));
        expect(problems.single, contains('[d]'));
        expect(
          problems.single,
          startsWith('coqui/packages/features/feature_words/lib/src/a.dart:'),
        );
        expect(problems.single, contains('coqui/tool/'));
      },
    );

    test('passes: story/<n> changes coqui_scenes, feature_story, '
        'coqui_story_checks, ref/pp, and requests/', () async {
      git.branch('story/42');
      package('coqui_scenes', deps: ['coqui_ui']);
      package('feature_story', deps: ['coqui_ui', 'coqui_scenes']);
      package('coqui_story_checks', deps: ['coqui_scenes', 'feature_story']);
      src('coqui_scenes', 'lib/src/scene.dart', '// scene\n');
      src('feature_story', 'lib/src/story.dart', '// story\n');
      src('coqui_story_checks', 'test/scene_test.dart', '// test\n');
      write('ref/pp/plaza/sheet.json', '{}\n');
      write('requests/42-story-needs-thing.md', 'please\n');
      git.commit('scene port');
      expect(await check(branch: null), isEmpty);
    });

    test('fails: story/<n> changes coqui_contracts or app/', () async {
      git.branch('story/42');
      package('coqui_contracts', deps: []);
      package('app', deps: ['coqui_contracts']);
      src('coqui_contracts', 'lib/coqui_contracts.dart', '// contracts\n');
      src('app', 'lib/main.dart', '// app\n');
      git.commit('disallowed edits');
      final problems = await check(branch: null);
      expect(problems, hasLength(4));
      final joined = problems.join('\n');
      expect(joined, contains('coqui/packages/core/coqui_contracts/'));
      expect(joined, contains('coqui/app/'));
      expect(joined, contains('[d] branch story/42 may change only'));
      expect(joined, contains('coqui/packages/core/coqui_scenes/'));
      expect(joined, contains('coqui/packages/features/feature_story/'));
      expect(joined, contains('coqui/packages/coqui_story_checks/'));
      expect(joined, contains('coqui/ref/pp/'));
      expect(joined, contains('coqui/requests/'));
    });

    test(
      'fails: story/<n> changes ref/ outside ref/pp/, tool/, or outside coqui/',
      () async {
        git.branch('story/42');
        write('ref/other/data.json', '{}\n');
        write('ref/pp_extra/data.json', '{}\n');
        write('tool/check_boundaries.dart', '// nope\n');
        File('${repo.path}/.github/workflows/coqui.yml')
          ..createSync(recursive: true)
          ..writeAsStringSync('name: x\n');
        git.commit('more disallowed edits');
        final problems = await check(branch: null);
        expect(problems, hasLength(4));
        expect(
          problems.any((p) => p.startsWith('coqui/ref/other/data.json: [d]')),
          isTrue,
        );
        expect(
          problems.any(
            (p) => p.startsWith('coqui/ref/pp_extra/data.json: [d]'),
          ),
          isTrue,
        );
        expect(
          problems.any(
            (p) => p.startsWith('coqui/tool/check_boundaries.dart: [d]'),
          ),
          isTrue,
        );
        expect(
          problems.any((p) => p.startsWith('.github/workflows/coqui.yml: [d]')),
          isTrue,
        );
      },
    );

    test(
      'fails: story/<n> passed via branch argument rejects disallowed paths',
      () async {
        git.branch('work-in-progress');
        src('feature_map', 'lib/src/m.dart', '// changed\n');
        git.commit('work');
        final problems = await check(branch: 'story/99');
        expect(problems, hasLength(1));
        expect(problems.single, contains('[d] branch story/99'));
        expect(problems.single, contains('feature_map'));
      },
    );

    test('fails clearly when there is nothing to compare with', () async {
      git.branch('lane/feature_words/5');
      git.run(['branch', '-D', 'main']);
      expect(await check(branch: null), [
        '[d] branch lane/feature_words/5: neither origin/main nor main '
            'exists to compare with',
      ]);
    });

    test(
      'passes: real tools/lanes.json validates cleanly on main and tool/263',
      () async {
        expect(await check(branch: 'main'), isEmpty);
        expect(await check(branch: 'tool/263'), isEmpty);
      },
    );

    test('fails: custom tools/lanes.json with overlapping concurrent lanes reports witness even on main', () async {
      final raw = jsonDecode(
        realLaneMapFile().readAsStringSync(),
      ) as Map<String, Object?>;
      final lanes = (raw['lanes'] as Map).cast<String, Object?>();
      lanes['clash_a'] = {
        'kind': 'non_package',
        'paths': ['sandbox/sala_*_test.dart'],
      };
      lanes['clash_b'] = {
        'kind': 'non_package',
        'paths': ['sandbox/sala_dia_*_test.dart'],
      };
      writeRepo('tools/lanes.json', '${jsonEncode(raw)}\n');
      final problems = await check(branch: 'main');
      expect(problems, hasLength(1));
      expect(problems.single, contains('[d]'));
      expect(problems.single, contains('clash_a'));
      expect(problems.single, contains('clash_b'));
      expect(problems.single, contains('sandbox/sala_dia_'));
    });

    test('fails: missing tools/lanes.json fails on lane branch, board repo, or explicit --lane-map', () async {
      File('${repo.path}/tools/lanes.json').deleteSync();
      final onLane = await check(branch: 'lane/feature_words/99');
      expect(onLane, hasLength(1));
      expect(onLane.single, contains('[d] missing lane map'));

      writeRepo('tools/board.py', '# board\n');
      final withBoard = await check(branch: 'main');
      expect(withBoard, hasLength(1));
      expect(withBoard.single, contains('[d] missing lane map'));

      File('${repo.path}/tools/board.py').deleteSync();
      final explicit = await check(
        branch: 'main',
        laneMapFile: File('${repo.path}/tools/nope.json'),
      );
      expect(explicit, hasLength(1));
      expect(explicit.single, contains('[d] missing lane map'));
    });

    test('per-scene lane allows owned paths, generated_paths, and requests/, and rejects other scenes', () async {
      git.branch('lane/scene.entrada/301');
      write('packages/core/coqui_scenes/lib/src/entrada/scene.dart', '// ok\n');
      write(
        'packages/core/coqui_scenes/assets/sheets/entrada-sheet.json',
        '{}\n',
      );
      write(
        'packages/core/coqui_scenes/test/entrada_acts_test.dart',
        '// ok\n',
      );
      write(
        'packages/coqui_story_checks/test/entrada_stories_test.dart',
        '// ok\n',
      );
      write('ref/pp/entrada/frame.png', 'png\n');
      write('packages/core/coqui_scenes/tool/dev_main.dart', '// generated\n');
      write(
        'packages/core/coqui_scenes/tool/make_set_fixture.dart',
        '// gen\n',
      );
      write('ref/pp/index.json', '{}\n');
      write('requests/301-entrada.md', 'req\n');
      git.commit('valid entrada work');
      expect(await check(branch: null), isEmpty);

      write(
        'packages/core/coqui_scenes/lib/src/pedido/scene.dart',
        '// stray\n',
      );
      git.commit('stray into pedido');
      final problems = await check(branch: null);
      expect(problems, hasLength(1));
      expect(
        problems.single,
        startsWith(
          'coqui/packages/core/coqui_scenes/lib/src/pedido/scene.dart: [d]',
        ),
      );
    });

    test('scene.sala and scene.sala_dia are strictly disjoint', () async {
      git.branch('lane/scene.sala/10');
      write('packages/core/coqui_scenes/test/sala_acts_test.dart', '// ok\n');
      write('packages/core/coqui_scenes/lib/src/sala/a.dart', '// ok\n');
      git.commit('sala');
      expect(await check(branch: null), isEmpty);

      write(
        'packages/core/coqui_scenes/test/sala_dia_acts_test.dart',
        '// stray\n',
      );
      git.commit('stray sala_dia');
      final salaProblems = await check(branch: null);
      expect(salaProblems, hasLength(1));
      expect(salaProblems.single, contains('sala_dia_acts_test.dart'));

      git.run(['checkout', '-q', 'main']);
      git.branch('lane/scene.sala_dia/11');
      write(
        'packages/core/coqui_scenes/test/sala_dia_acts_test.dart',
        '// ok\n',
      );
      git.commit('sala_dia');
      expect(await check(branch: null), isEmpty);

      write(
        'packages/core/coqui_scenes/test/sala_acts_test.dart',
        '// stray\n',
      );
      git.commit('stray sala');
      final salaDiaProblems = await check(branch: null);
      expect(salaDiaProblems, hasLength(1));
      expect(salaDiaProblems.single, contains('sala_acts_test.dart'));
    });

    test('feature_library.reader and feature_library.shelf enforce screen boundaries', () async {
      git.branch('lane/feature_library.reader/401');
      write(
        'packages/features/feature_library/lib/src/reader_page.dart',
        '// ok\n',
      );
      write(
        'packages/features/feature_library/lib/src/text_reader.dart',
        '// ok\n',
      );
      write(
        'packages/features/feature_library/lib/src/reader/sub.dart',
        '// ok\n',
      );
      write(
        'packages/features/feature_library/test/reader_test.dart',
        '// ok\n',
      );
      write(
        'packages/features/feature_library/test/screenshots/reader_1.png',
        'p\n',
      );
      git.commit('reader');
      expect(await check(branch: null), isEmpty);

      write(
        'packages/features/feature_library/lib/src/reading_home.dart',
        '// stray\n',
      );
      git.commit('stray shelf');
      final readerProblems = await check(branch: null);
      expect(readerProblems, hasLength(1));
      expect(readerProblems.single, contains('reading_home.dart'));

      git.run(['checkout', '-q', 'main']);
      git.branch('lane/feature_library.shelf/402');
      write(
        'packages/features/feature_library/lib/src/reading_home.dart',
        '// ok\n',
      );
      write(
        'packages/features/feature_library/lib/src/write_story_sheet.dart',
        '// ok\n',
      );
      write(
        'packages/features/feature_library/lib/src/story_generator.dart',
        '// ok\n',
      );
      write(
        'packages/features/feature_library/test/reading_home_test.dart',
        '// ok\n',
      );
      write(
        'packages/features/feature_library/test/screenshots/library_1.png',
        'p\n',
      );
      git.commit('shelf');
      expect(await check(branch: null), isEmpty);

      write(
        'packages/features/feature_library/lib/src/text_reader.dart',
        '// stray\n',
      );
      git.commit('stray reader');
      final shelfProblems = await check(branch: null);
      expect(shelfProblems, hasLength(1));
      expect(shelfProblems.single, contains('text_reader.dart'));
    });

    test(
      'content.lines.es accepts Spanish lines and rejects French lines',
      () async {
        git.branch('lane/content.lines.es/501');
        writeRepo('content/lines/es/01.json', '{}\n');
        git.commit('es');
        expect(await check(branch: null), isEmpty);

        writeRepo('content/lines/fr/01.json', '{}\n');
        git.commit('stray fr');
        final problems = await check(branch: null);
        expect(problems, hasLength(1));
        expect(problems.single, startsWith('content/lines/fr/01.json: [d]'));
      },
    );

    test('design lane allows coqui_ui and docs/proyecto/noche/ and rejects other docs', () async {
      git.branch('lane/design/601');
      write('packages/core/coqui_ui/lib/src/tokens.dart', '// ok\n');
      writeRepo('docs/proyecto/noche/spec.md', '# noche\n');
      git.commit('design');
      expect(await check(branch: null), isEmpty);

      writeRepo('docs/other.md', '# stray\n');
      git.commit('stray docs');
      final problems = await check(branch: null);
      expect(problems, hasLength(1));
      expect(problems.single, startsWith('docs/other.md: [d]'));
    });

    test(
      'non-package lanes github, docs, and content enforce their own paths',
      () async {
        git.branch('lane/github/1');
        writeRepo('.github/scripts/helper.py', '# ok\n');
        git.commit('github');
        expect(await check(branch: null), isEmpty);
        writeRepo('tools/x.py', '# stray\n');
        git.commit('stray');
        expect(await check(branch: null), hasLength(1));

        git.run(['checkout', '-q', 'main']);
        git.branch('lane/docs/2');
        writeRepo('docs/guide.md', '# ok\n');
        writeRepo('AGENTS.md', '# ok\n');
        write('AGENTS.md', '# ok\n');
        git.commit('docs');
        expect(await check(branch: null), isEmpty);
        writeRepo('tools/x.py', '# stray\n');
        git.commit('stray');
        expect(await check(branch: null), hasLength(1));

        git.run(['checkout', '-q', 'main']);
        git.branch('lane/content/3');
        writeRepo('content/games/a.json', '{}\n');
        writeRepo('historia/datos/a.json', '{}\n');
        git.commit('content');
        expect(await check(branch: null), isEmpty);
        writeRepo('historia/cuentos/a.mp3', 'nope\n');
        git.commit('stray');
        expect(await check(branch: null), hasLength(1));
      },
    );

    test('multi-lane github+tool and sanctioned app+coqui_platform pass, unsanctioned multi-package fails', () async {
      git.branch('lane/github+tool/263');
      writeRepo('.github/scripts/x.py', '# ok\n');
      writeRepo('tools/x.py', '# ok\n');
      write('tool/x.dart', '// ok\n');
      write('requests/263.md', 'ok\n');
      git.commit('github+tool');
      expect(await check(branch: null), isEmpty);

      git.run(['checkout', '-q', 'main']);
      git.branch('lane/app+coqui_platform/72');
      write('app/lib/main.dart', '// app\n');
      write('packages/core/coqui_platform/lib/p.dart', '// plat\n');
      git.commit('platform_app');
      expect(await check(branch: null), isEmpty);

      final unsanctioned = await check(
        branch: 'lane/feature_words+feature_map/99',
      );
      expect(unsanctioned, hasLength(1));
      expect(unsanctioned.single, contains('[d]'));
      expect(unsanctioned.single, contains('unsanctioned'));

      final madeup = await check(branch: 'lane/madeup_lane/999');
      expect(madeup, hasLength(1));
      expect(madeup.single, contains('[d]'));
      expect(madeup.single, contains('unknown lane'));
      expect(madeup.single, contains('madeup_lane'));
    });

    test('adding a new lane only in tools/lanes.json works immediately with zero Dart changes', () async {
      final raw = jsonDecode(
        realLaneMapFile().readAsStringSync(),
      ) as Map<String, Object?>;
      final lanes = (raw['lanes'] as Map).cast<String, Object?>();
      lanes['experimental_lab'] = {
        'kind': 'non_package',
        'paths': ['lab/**'],
      };
      writeRepo('tools/lanes.json', '${jsonEncode(raw)}\n');
      git.commit('add experimental_lab lane to json');

      git.branch('lane/experimental_lab/777');
      writeRepo('lab/hello.txt', 'hi\n');
      git.commit('owned lab file');
      expect(await check(branch: null), isEmpty);

      writeRepo('docs/stray.md', 'nope\n');
      git.commit('stray outside lab');
      final problems = await check(branch: null);
      expect(problems, hasLength(1));
      expect(problems.single, startsWith('docs/stray.md: [d]'));
    });

    test('passes: contracts/<n> allows contracts-only, requests-only, and contracts + conformance edits', () async {
      // Contracts only
      git.branch('contracts/260');
      package('coqui_contracts', deps: []);
      src('coqui_contracts', 'lib/src/platform.dart', '// contracts\n');
      git.commit('contracts only');
      expect(await check(branch: null), isEmpty);

      // Contracts + conformance across packages, app, and requests/
      package('coqui_platform', deps: ['coqui_contracts']);
      package('coqui_testing', deps: ['coqui_contracts', 'coqui_ui']);
      package('feature_library', deps: ['coqui_contracts', 'coqui_ui']);
      package('app', deps: ['coqui_contracts']);
      src('coqui_platform', 'lib/src/store.dart', '// conform\n');
      src('coqui_testing', 'lib/src/fakes.dart', '// conform\n');
      src('feature_library', 'lib/src/reader.dart', '// conform\n');
      src('app', 'lib/src/main.dart', '// conform\n');
      write('requests/260-note.md', '# note\n');
      git.commit('conformance edits');
      expect(await check(branch: null), isEmpty);

      // Requests-only on contracts/<n>
      git.run(['checkout', '-q', 'main']);
      git.branch('contracts/261');
      write('requests/261-note.md', '# req only\n');
      git.commit('requests only');
      expect(await check(branch: null), isEmpty);
    });

    test('fails: contracts/<n> rejects non-package paths (docs/, .github/, tools/, coqui/tool/)', () async {
      git.branch('contracts/260');
      package('coqui_contracts', deps: []);
      src('coqui_contracts', 'lib/src/platform.dart', '// contracts\n');
      writeRepo('docs/guide.md', '# nope\n');
      writeRepo('.github/scripts/helper.py', '# nope\n');
      writeRepo('tools/helper.py', '# nope\n');
      write('tool/helper.dart', '// nope\n');
      git.commit('non-package paths on contracts branch');
      final problems = await check(branch: null);
      expect(problems, hasLength(4));
      for (final path in [
        'docs/guide.md',
        '.github/scripts/helper.py',
        'tools/helper.py',
        'coqui/tool/helper.dart',
      ]) {
        expect(
          problems.any((p) => p.startsWith('$path: [d]')),
          isTrue,
          reason: 'expected $path to be rejected',
        );
      }
    });

    test('fails: contracts/<n> rejects conformance edits without changing coqui_contracts', () async {
      git.branch('contracts/260');
      src('feature_words', 'lib/src/a.dart', '// conform without contracts\n');
      package('app', deps: ['coqui_ui']);
      src('app', 'lib/src/main.dart', '// app without contracts\n');
      write('requests/260-note.md', '# shared request is exempt\n');
      git.commit('conformance without contracts');
      final problems = await check(branch: null);
      expect(problems, hasLength(3));
      final joined = problems.join('\n');
      expect(
        joined,
        contains('coqui/packages/features/feature_words/lib/src/a.dart: [d]'),
      );
      expect(joined, contains('coqui/app/pubspec.yaml: [d]'));
      expect(joined, contains('coqui/app/lib/src/main.dart: [d]'));
      expect(joined, contains('for conformance only alongside changes in'));
      expect(joined, contains('coqui/packages/core/coqui_contracts/**'));
      expect(joined, isNot(contains('requests/260-note.md')));
    });

    test('fails: malformed contracts/ branch names are rejected', () async {
      for (final bad in [
        'contracts/',
        'contracts/abc',
        'contracts/260/extra',
        'contracts/260-fix',
      ]) {
        final problems = await check(branch: bad);
        expect(problems, hasLength(1), reason: bad);
        expect(problems.single, contains('[d]'), reason: bad);
        expect(problems.single, contains("contracts/<number>"), reason: bad);
      }
    });

    test('contracts/<n> respects CI branch override argument', () async {
      git.branch('work-in-progress');
      src('feature_map', 'lib/src/m.dart', '// changed without contracts\n');
      git.commit('work');
      final problems = await check(branch: 'contracts/260');
      expect(problems, hasLength(1));
      expect(problems.single, contains('branch contracts/260'));
      expect(problems.single, contains('for conformance only'));

      package('coqui_contracts', deps: []);
      src('coqui_contracts', 'lib/src/platform.dart', '// contracts\n');
      git.commit('add contracts change');
      expect(await check(branch: 'contracts/260'), isEmpty);
    });

    test(
      'fails: missing tools/lanes.json fails on contracts/<n> branch',
      () async {
        File('${repo.path}/tools/lanes.json').deleteSync();
        final onContracts = await check(branch: 'contracts/260');
        expect(onContracts, hasLength(1));
        expect(onContracts.single, contains('[d] missing lane map'));
      },
    );

    test('fails: custom tools/lanes.json rejects invalid contracts_* fields in branch_rules', () async {
      final baseRaw = jsonDecode(
        realLaneMapFile().readAsStringSync(),
      ) as Map<String, Object?>;

      Map<String, Object?> cloneRaw() =>
          jsonDecode(jsonEncode(baseRaw)) as Map<String, Object?>;

      // Bad contracts_prefix
      final badPrefix = cloneRaw();
      (badPrefix['branch_rules'] as Map)['contracts_prefix'] = 'contracts';
      writeRepo('tools/lanes.json', '${jsonEncode(badPrefix)}\n');
      expect(
        (await check(branch: 'main')).join('\n'),
        contains('branch_rules.contracts_prefix'),
      );

      // Unknown contracts_owner_lane
      final unknownOwner = cloneRaw();
      (unknownOwner['branch_rules'] as Map)['contracts_owner_lane'] = 'nope';
      writeRepo('tools/lanes.json', '${jsonEncode(unknownOwner)}\n');
      expect(
        (await check(branch: 'main')).join('\n'),
        contains(
          "branch_rules.contracts_owner_lane references unknown lane 'nope'",
        ),
      );

      // Empty contracts_conformance_paths
      final emptyPaths = cloneRaw();
      (emptyPaths['branch_rules'] as Map)['contracts_conformance_paths'] = [];
      writeRepo('tools/lanes.json', '${jsonEncode(emptyPaths)}\n');
      expect(
        (await check(branch: 'main')).join('\n'),
        contains('branch_rules.contracts_conformance_paths'),
      );

      // Malformed glob in contracts_conformance_paths
      final badGlob = cloneRaw();
      (badGlob['branch_rules'] as Map)['contracts_conformance_paths'] = [
        'coqui/**/lib.dart',
      ];
      writeRepo('tools/lanes.json', '${jsonEncode(badGlob)}\n');
      expect(
        (await check(branch: 'main')).join('\n'),
        contains('branch_rules.contracts_conformance_paths'),
      );
    });
  });

  group('[h] new code uses start/end, not left/right (#55)', () {
    late Git git;

    setUp(() {
      installRealLaneMap();
      package('coqui_ui', deps: ['coqui_contracts']);
      package(
        'coqui_scenes',
        deps: ['coqui_pixel', 'coqui_contracts', 'coqui_ui'],
      );
      package('coqui_pixel', deps: ['coqui_contracts']);
      package('feature_words', deps: ['coqui_ui']);
      package('app', deps: ['coqui_ui', 'feature_words']);
      src('feature_words', 'lib/src/legacy.dart', '''
final oldInsets = EdgeInsets.only(left: 16, top: 8);
final oldFromLtrb = EdgeInsets.fromLTRB(4, 0, 8, 0);
final oldAlign = Alignment.centerLeft;
final oldPositioned = Positioned(
  left: 12,
  top: 4,
  child: child,
);
final keepLine = 1;
''');
      src('coqui_ui', 'lib/src/widget.dart', '// clean\n');
      git = Git(repo)..init();
    });

    test('fails: added EdgeInsets.only(left:/right:) in a feature (single and multi-line)', () async {
      git.branch('lane/feature_words/55');
      src('feature_words', 'lib/src/new_screen.dart', '''
final a = EdgeInsets.only(left: 12);
final b = EdgeInsets.only(
  top: 4,
  right: 8,
);
''');
      git.commit('add non-directional insets');
      final problems = await check(branch: null);
      expect(problems, hasLength(2));
      expect(
        problems[0],
        contains(
          'packages/features/feature_words/lib/src/new_screen.dart:1: [h]',
        ),
      );
      expect(problems[0], contains('EdgeInsets.only(left: ...)'));
      expect(
        problems[1],
        contains(
          'packages/features/feature_words/lib/src/new_screen.dart:4: [h]',
        ),
      );
      expect(problems[1], contains('EdgeInsets.only(right: ...)'));
    });

    test('fails: added EdgeInsets.fromLTRB, Alignment.*Left/Right, Positioned(left:), TextAlign, Border, BorderRadius in coqui_ui', () async {
      git.branch('lane/coqui_ui/55');
      src('coqui_ui', 'lib/src/widget.dart', '''
final a = EdgeInsets.fromLTRB(1, 2, 3, 4);
final b = Alignment.centerLeft;
final c = Alignment.topRight;
final d = FractionalOffset.bottomLeft;
final e = TextAlign.right;
final f = Positioned(
  left: 10,
  child: x,
);
final f2 = Positioned.fill(
  left: 16,
  right: 0,
  child: x,
);
final g = AnimatedPositioned(right: 5, child: x);
final h = Border(left: BorderSide());
final i = BorderRadius.only(topLeft: Radius.circular(8));
final j = BorderRadius.horizontal(right: Radius.circular(8));
final k = RelativeRect.fromLTRB(1, 2, 3, 4);
''');
      git.commit('add non-directional ui');
      final problems = await check(branch: null);
      expect(problems, hasLength(13));
      final joined = problems.join('\n');
      expect(joined, contains('EdgeInsets.fromLTRB'));
      expect(joined, contains('Alignment.centerLeft'));
      expect(joined, contains('Alignment.topRight'));
      expect(joined, contains('FractionalOffset.bottomLeft'));
      expect(joined, contains('TextAlign.right'));
      expect(joined, contains('Positioned(left: ...)'));
      expect(joined, contains('Positioned.fill(left: ...)'));
      expect(joined, contains('Positioned.fill(right: ...)'));
      expect(joined, contains('AnimatedPositioned(right: ...)'));
      expect(joined, contains('Border(left: ...)'));
      expect(joined, contains('BorderRadius.only(topLeft: ...)'));
      expect(joined, contains('BorderRadius.horizontal(right: ...)'));
      expect(joined, contains('RelativeRect.fromLTRB'));
    });

    test('passes: directional APIs, symmetric/vertical-only calls, nested widgets and ternaries', () async {
      git.branch('lane/feature_words/55');
      src('feature_words', 'lib/src/good.dart', '''
final a = EdgeInsetsDirectional.only(start: 12, end: 8);
final b = EdgeInsetsDirectional.fromSTEB(1, 2, 3, 4);
final c = EdgeInsets.only(top: 8, bottom: 16);
final d = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
final e = EdgeInsets.all(8);
final f = AlignmentDirectional.centerStart;
final g = Alignment.center;
final h = TextAlign.start;
final i = TextAlign.end;
final j = PositionedDirectional(start: 8, top: 4, child: x);
final k = Positioned.fill(child: x);
final k2 = Positioned.fill(top: 4, bottom: 8, child: x);
final l = Positioned(
  top: flag ? left : right,
  bottom: 0,
  child: CustomWidget(left: 4, right: 8),
);
final m = AnimatedPositionedDirectional(end: 4, child: x);
final n = BorderDirectional(start: BorderSide());
final o = Border(top: BorderSide(), bottom: BorderSide());
final p = BorderRadiusDirectional.only(topStart: Radius.circular(8));
final q = BorderRadius.circular(8);
''');
      git.commit('add directional code');
      expect(await check(branch: null), isEmpty);
    });

    test('passes: unchanged legacy lines are not flagged when editing nearby lines', () async {
      git.branch('lane/feature_words/55');
      src('feature_words', 'lib/src/legacy.dart', '''
final oldInsets = EdgeInsets.only(left: 16, top: 8);
final oldFromLtrb = EdgeInsets.fromLTRB(4, 0, 8, 0);
final oldAlign = Alignment.centerLeft;
final oldPositioned = Positioned(
  left: 12,
  top: 10,
  child: child,
);
final keepLine = 2;
''');
      git.commit('edit unrelated lines in legacy file');
      expect(await check(branch: null), isEmpty);
    });

    test(
      'fails: adding a new left: argument into an existing Positioned call',
      () async {
        git.branch('lane/feature_words/55');
        src('feature_words', 'lib/src/legacy.dart', '''
final oldInsets = EdgeInsets.only(left: 16, top: 8);
final oldFromLtrb = EdgeInsets.fromLTRB(4, 0, 8, 0);
final oldAlign = Alignment.centerLeft;
final oldPositioned = Positioned(
  left: 12,
  right: 12,
  top: 4,
  child: child,
);
final keepLine = 1;
''');
        git.commit('add right arg to existing Positioned');
        final problems = await check(branch: null);
        expect(problems, hasLength(1));
        expect(problems.single, contains(':6: [h]'));
        expect(problems.single, contains('Positioned(right: ...)'));
      },
    );

    test(
      'passes: coqui_scenes, coqui_pixel, app, and tool are exempt',
      () async {
        git.branch('orden/55');
        src('coqui_scenes', 'lib/src/scene.dart', '''
final a = EdgeInsets.fromLTRB(1, 2, 3, 4);
final b = Alignment.centerLeft;
final c = Positioned(left: 10, child: x);
''');
        src('coqui_pixel', 'lib/src/pixel.dart', '''
final a = EdgeInsets.only(left: 4);
final b = Alignment.topLeft;
''');
        src('app', 'lib/src/shell.dart', '''
final a = EdgeInsets.only(left: 4);
''');
        write('tool/script.dart', 'final a = Alignment.centerLeft;\n');
        git.commit('exempt packages');
        expect(await check(branch: null), isEmpty);
      },
    );

    test('passes: ignores comments and string literals (including raw and triple-quoted)', () async {
      git.branch('lane/feature_words/55');
      src('feature_words', 'lib/src/strings.dart', r'''
// EdgeInsets.fromLTRB(1, 2, 3, 4)
/* Alignment.centerLeft /* nested Positioned(left: 1) */ */
final re1 = RegExp(r'EdgeInsets\.fromLTRB|Alignment\.centerLeft');
final s1 = "Positioned(left: 4)";
final s2 = """
EdgeInsets.only(left: 8)
TextAlign.left
""";
final s3 = 'escaped \' EdgeInsets.fromLTRB(1,2,3,4)';
final s4 = 'interp ${foo("Alignment.topLeft")} Alignment.bottomRight';
''');
      git.commit('comments and strings only');
      expect(await check(branch: null), isEmpty);
    });

    test(
      'fails: detects violation inside string interpolation expression',
      () async {
        git.branch('lane/feature_words/55');
        src('feature_words', 'lib/src/interp.dart', '''
final s = 'value: \${Alignment.centerLeft}';
''');
        git.commit('interp violation');
        final problems = await check(branch: null);
        expect(problems, hasLength(1));
        expect(problems.single, contains('[h]'));
        expect(problems.single, contains('Alignment.centerLeft'));
      },
    );
  });

  group('[i] package AGENTS.md holds standing rules only (#257)', () {
    late Git git;

    setUp(() {
      installRealLaneMap();
      package('coqui_ui', deps: ['coqui_contracts']);
      package('feature_words', deps: ['coqui_ui']);
      package('coqui_story_checks', deps: ['coqui_scenes', 'feature_story']);
      package('app', deps: ['coqui_ui', 'feature_words']);
      src('feature_words', 'AGENTS.md', '''
# feature_words

- Historical line from #42 that already exists on main.
- Another old note (#99) to delete in a test.
- Keep wording in one file.
''');
      src('coqui_ui', 'AGENTS.md', '# coqui_ui\n');
      src('coqui_story_checks', 'AGENTS.md', '# coqui_story_checks\n');
      src('app', 'AGENTS.md', '# app\n');
      write('AGENTS.md', '# Coquí runbook\n');
      git = Git(repo)..init();
    });

    test(
      'fails: adding a line with #<digits> to a feature package AGENTS.md',
      () async {
        git.branch('lane/feature_words/257');
        src('feature_words', 'AGENTS.md', '''
# feature_words

- Historical line from #42 that already exists on main.
- Another old note (#99) to delete in a test.
- Keep wording in one file.
- Added in #257: never do this.
''');
        git.commit('add issue ref to feature AGENTS.md');
        final problems = await check(branch: null);
        expect(problems, hasLength(1));
        expect(
          problems.single,
          startsWith('packages/features/feature_words/AGENTS.md:6: [i]'),
        );
        expect(problems.single, contains('issue reference #257'));
      },
    );

    test('fails: adding issue refs to core package, coqui_story_checks, and app AGENTS.md', () async {
      git.branch('orden/257');
      src('coqui_ui', 'AGENTS.md', '''
# coqui_ui
- Added gallery test (#257).
- Backticked `#49` reference.
''');
      src('coqui_story_checks', 'AGENTS.md', '''
# coqui_story_checks
- Issue #6: check all paths.
- Scenes #18–#20 ported.
''');
      src('app', 'AGENTS.md', '''
# app
- See salimocasio-dev/field-notes#257 for context.
''');
      git.commit('add issue refs across package AGENTS.md files');
      final problems = await check(branch: null);
      expect(problems, hasLength(5));
      expect(
        problems,
        containsAll([
          allOf(
            startsWith('packages/core/coqui_ui/AGENTS.md:2: [i]'),
            contains('issue reference #257'),
          ),
          allOf(
            startsWith('packages/core/coqui_ui/AGENTS.md:3: [i]'),
            contains('issue reference #49'),
          ),
          allOf(
            startsWith('packages/coqui_story_checks/AGENTS.md:2: [i]'),
            contains('issue reference #6'),
          ),
          allOf(
            startsWith('packages/coqui_story_checks/AGENTS.md:3: [i]'),
            contains('issue reference #18'),
          ),
          allOf(
            startsWith('app/AGENTS.md:2: [i]'),
            contains('issue reference #257'),
          ),
        ]),
      );
    });

    test('passes: unchanged existing lines with #<digits> are not flagged when adding clean lines or deleting old lines', () async {
      git.branch('lane/feature_words/257');
      src('feature_words', 'AGENTS.md', '''
# feature_words

- Historical line from #42 that already exists on main.
- Keep wording in one file.
- Every screen reads wording from lib/src/wording.dart.
''');
      git.commit('add clean standing rule and delete old note');
      expect(await check(branch: null), isEmpty);
    });

    test(
      'fails: modifying an existing line that still contains #<digits>',
      () async {
        git.branch('lane/feature_words/257');
        src('feature_words', 'AGENTS.md', '''
# feature_words

- Historical line from #42 that was edited on this branch.
- Another old note (#99) to delete in a test.
- Keep wording in one file.
''');
        git.commit('edit existing line with issue ref');
        final problems = await check(branch: null);
        expect(problems, hasLength(1));
        expect(
          problems.single,
          startsWith('packages/features/feature_words/AGENTS.md:3: [i]'),
        );
        expect(problems.single, contains('issue reference #42'));
      },
    );

    test('passes: hex colors, CSS selectors, routes, markdown headings, and HTML entities', () async {
      git.branch('lane/coqui_ui/257');
      src('coqui_ui', 'AGENTS.md', '''
# coqui_ui
## 123
- Palette: #0C1926, #17803F, #3B5BDB, #1B1B1F, #9AD5A8, #000000.
- Legacy CSS hooks: #bub and #fin.
- Story route format: #/cuento/123.
- Non-breaking space entity: &#160;.
''');
      git.commit('add non-issue hash tokens');
      expect(await check(branch: null), isEmpty);
    });

    test('passes: issue refs in coqui/AGENTS.md, repo-root AGENTS.md, tool/prueba_telefono/AGENTS.md, and requests/', () async {
      git.branch('orden/257');
      write('AGENTS.md', '''
# Coquí runbook
- Standing rules added in #257.
''');
      File('${repo.path}/AGENTS.md')
        ..createSync(recursive: true)
        ..writeAsStringSync('# Repo root\n- Tracked in #257.\n');
      write(
        'tool/prueba_telefono/AGENTS.md',
        '# prueba_telefono\n- Note #257.\n',
      );
      write('requests/257-note.md', '# Request #257\n- Need a thing.\n');
      git.commit('allowed issue refs outside package AGENTS.md');
      expect(await check(branch: null), isEmpty);
    });

    test(
      'respects explicit base ref (only checks lines added since base)',
      () async {
        git.branch('orden/257-base');
        src('coqui_ui', 'AGENTS.md', '''
# coqui_ui
- Added before base (#100).
''');
        git.commit('before base');

        git.branch('orden/257-head');
        src('coqui_ui', 'AGENTS.md', '''
# coqui_ui
- Added before base (#100).
- Clean standing rule added after base.
''');
        git.commit('after base');

        // Against main, #100 is flagged.
        final againstMain = await check(branch: null);
        expect(againstMain, hasLength(1));
        expect(againstMain.single, contains('issue reference #100'));

        // Against orden/257-base, only the clean line is new.
        expect(await check(branch: null, base: 'orden/257-base'), isEmpty);
      },
    );
  });

  group('as a command', () {
    Future<ProcessResult> run() => Process.run(
      Platform.resolvedExecutable,
      [File('tool/check_boundaries.dart').absolute.path, '--root', coqui.path],
      environment: {'GITHUB_HEAD_REF': '', 'GITHUB_REF_NAME': ''},
    );

    test('exits 0 and says ok on a clean workspace', () async {
      package('feature_words', deps: ['coqui_ui']);
      final result = await run();
      expect(result.exitCode, 0);
      expect(result.stdout, 'check_boundaries: ok\n');
    });

    test('exits 1 with one line per problem', () async {
      package('feature_words', deps: ['coqui_ui', 'feature_story']);
      src(
        'feature_words',
        'lib/src/a.dart',
        "import 'package:coqui_ui/src/x.dart';\n",
      );
      final result = await run();
      expect(result.exitCode, 1);
      final lines = (result.stderr as String).trimRight().split('\n');
      expect(lines, hasLength(2));
      expect(lines.first, contains('[e]'));
      expect(lines.last, contains('[c]'));
    });
  });
}

// --- Helpers that build the made-up workspace ---------------------------------

/// A package of the table, placed where the table says, with a pubspec shaped
/// like the real ones. [deps] and [devDeps] are listed as they are; the SDK
/// and the dev tools of its kind are added unless [flutter] says otherwise.
void package(
  String name, {
  required List<String> deps,
  List<String> devDeps = const [],
  bool? flutter,
  String? dir,
}) {
  final rule = packageRules[name];
  final isFlutter = flutter ?? rule?.flutter ?? true;
  final folder = dir ?? rule!.dir;
  final text = StringBuffer('name: $name\n')
    ..writeln('environment:')
    ..writeln('  sdk: ^3.14.0')
    ..writeln('dependencies:');
  if (isFlutter) text.writeln('  flutter:\n    sdk: flutter');
  for (final d in deps) {
    text.writeln('  $d: any');
  }
  text.writeln('dev_dependencies:');
  if (isFlutter) {
    text.writeln('  flutter_lints: ^6.0.0\n  flutter_test:\n    sdk: flutter');
  } else {
    text.writeln('  lints: ^6.0.0\n  test: ^1.32.0');
  }
  for (final d in devDeps) {
    text.writeln('  $d: any');
  }
  write('$folder/pubspec.yaml', text.toString());
}

/// A Dart file in a package of the table.
void src(String name, String path, String text) =>
    write('${packageRules[name]!.dir}/$path', text);

void write(String path, String text) {
  File('${coqui.path}/$path')
    ..createSync(recursive: true)
    ..writeAsStringSync(text);
}

void writeRepo(String path, String text) {
  File('${repo.path}/$path')
    ..createSync(recursive: true)
    ..writeAsStringSync(text);
}

File realLaneMapFile() {
  final parent = File('../tools/lanes.json');
  if (parent.existsSync()) return parent;
  return File('tools/lanes.json');
}

void installRealLaneMap() {
  writeRepo('tools/lanes.json', realLaneMapFile().readAsStringSync());
}

/// A throwaway git repository in [repo].
class Git {
  Git(this.dir);
  final Directory dir;

  void run(List<String> args) {
    final result = Process.runSync('git', [
      '-c', 'user.name=test', '-c', 'user.email=test@example.com',
      '-c', 'commit.gpgsign=false', //
      ...args,
    ], workingDirectory: dir.path);
    if (result.exitCode != 0) {
      throw StateError('git ${args.join(' ')}: ${result.stderr}');
    }
  }

  void init() {
    run(['init', '-q', '-b', 'main']);
    commit('first');
  }

  void branch(String name) => run(['checkout', '-q', '-b', name]);

  void commit(String message) {
    run(['add', '-A']);
    run(['commit', '-q', '--allow-empty', '-m', message]);
  }
}
