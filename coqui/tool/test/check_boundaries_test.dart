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

    test('fails clearly when there is nothing to compare with', () async {
      git.branch('lane/feature_words/5');
      git.run(['branch', '-D', 'main']);
      expect(await check(branch: null), [
        '[d] branch lane/feature_words/5: neither origin/main nor main '
            'exists to compare with',
      ]);
    });
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
