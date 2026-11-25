// Tests for tool/check_boundaries.dart. Each test builds a small made-up
// workspace in a temp folder: only the packages the test needs, each with a
// pubspec and a few Dart files. Rule (d) also needs a git repository.
//
// Run at coqui/:  dart test tool/test

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

  Future<List<String>> check({String? branch = 'main', String? base}) =>
      checkBoundaries(coqui, branch: branch, base: base);

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

    test('fails: the lane names no package', () async {
      git.branch('lane/feature_nothing/1');
      expect(await check(branch: null), [
        '[d] branch lane/feature_nothing/1 names feature_nothing, which is '
            'not a package',
      ]);
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

    test('passes: lane/tool changes tool/ and requests/', () async {
      git.branch('lane/tool/55');
      write('tool/helper.dart', '// tool\n');
      write('requests/tool-needs-a-thing.md', 'please\n');
      git.commit('work');
      expect(await check(branch: null), isEmpty);
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

    test('fails clearly when there is nothing to compare with', () async {
      git.branch('lane/feature_words/5');
      git.run(['branch', '-D', 'main']);
      expect(await check(branch: null), [
        '[d] branch lane/feature_words/5: neither origin/main nor main '
            'exists to compare with',
      ]);
    });
  });

  group('[h] new code uses start/end, not left/right (#55)', () {
    late Git git;

    setUp(() {
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
