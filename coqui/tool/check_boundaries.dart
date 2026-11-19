// The boundary check. Pure Dart, no packages.
//
//   dart run tool/check_boundaries.dart            (at coqui/)
//   dart run tool/check_boundaries.dart --base REF  compare a lane branch with REF
//                                                   (default origin/main, else main)
//
// It prints one line per problem and exits with 1, or exits with 0.
//
// What it checks (page 11, "The boundary rules", 1 to 5; page 13, order 01):
//   [a] a pubspec lists a package its row does not allow
//       (workspace packages and third-party packages both)
//   [b] a Dart file imports a package its pubspec does not list
//   [c] a Dart file imports another package's src/
//   [d] the branch is `lane/<package>/...` and changes a file outside that
//       package's folder and requests/
//   [e] a feature's pubspec or imports name another feature
// Added by the orchestrator on Nov 19, 2026 (not in the plan's rules):
//   [f] a Dart file imports package:flutter/material.dart (deprecated in
//       Flutter 3.50; the code uses package:material_ui/material_ui.dart)
//   [g] a file under lib/ imports coqui_testing (it is a dev dependency, for
//       tests and tool/ only)
//
// The tables below are data. They are copied from the plan, with the
// orchestrator's changes of Nov 19, 2026 noted where they differ.

import 'dart:io';

/// One row of the plan's table "Packages: what each replaces and what it may
/// depend on". [dir] is relative to coqui/. [flutter] is false for the pure
/// Dart packages. [workspace] is the "May depend on" column, as package names.
/// [devWorkspace] are workspace packages the package may list under
/// dev_dependencies only.
class PackageRule {
  const PackageRule(
    this.dir, {
    required this.flutter,
    this.workspace = const {},
    this.devWorkspace = const {},
  });

  final String dir;
  final bool flutter;
  final Set<String> workspace;
  final Set<String> devWorkspace;
}

/// coqui_testing (the fakes): a dev dependency of the seven features,
/// coqui_scenes and app. Never under dependencies, never imported from lib/.
const _testingDev = {'coqui_testing'};

const _everything = {
  'coqui_contracts',
  'coqui_progress',
  'coqui_content',
  'coqui_platform',
  'coqui_pixel',
  'coqui_scenes',
  'coqui_ui',
  'feature_map',
  'feature_story',
  'feature_review',
  'feature_words',
  'feature_library',
  'feature_speaking',
  'feature_profile',
};

/// The plan's package table. "plugins" in coqui_platform's row is the
/// third-party table below. `app` may depend on everything, and lists
/// coqui_testing as a dev dependency only.
///
/// Two changes by the orchestrator, Nov 19, 2026: coqui_ui's row is
/// "contracts, Flutter" (the plan says "Flutter only"; page 12, section 3 needs
/// the contracts), and coqui_testing is a dev dependency of the features,
/// coqui_scenes and app.
const packageRules = <String, PackageRule>{
  'coqui_contracts': PackageRule(
    'packages/core/coqui_contracts',
    flutter: false,
  ),
  'coqui_progress': PackageRule(
    'packages/core/coqui_progress',
    flutter: false,
    workspace: {'coqui_contracts'},
  ),
  'coqui_content': PackageRule(
    'packages/core/coqui_content',
    flutter: false,
    workspace: {'coqui_contracts'},
  ),
  'coqui_platform': PackageRule(
    'packages/core/coqui_platform',
    flutter: true,
    workspace: {'coqui_contracts'},
  ),
  'coqui_pixel': PackageRule(
    'packages/core/coqui_pixel',
    flutter: false,
    workspace: {'coqui_contracts'},
  ),
  'coqui_scenes': PackageRule(
    'packages/core/coqui_scenes',
    flutter: true,
    workspace: {'coqui_pixel', 'coqui_contracts', 'coqui_ui'},
    devWorkspace: _testingDev,
  ),
  'coqui_ui': PackageRule(
    'packages/core/coqui_ui',
    flutter: true,
    workspace: {'coqui_contracts'},
  ),
  'coqui_testing': PackageRule(
    'packages/core/coqui_testing',
    flutter: true,
    workspace: {'coqui_contracts', 'coqui_ui'},
  ),
  'feature_map': PackageRule(
    'packages/features/feature_map',
    flutter: true,
    workspace: {'coqui_contracts', 'coqui_ui', 'coqui_pixel'},
    devWorkspace: _testingDev,
  ),
  'feature_story': PackageRule(
    'packages/features/feature_story',
    flutter: true,
    workspace: {'coqui_contracts', 'coqui_ui', 'coqui_pixel', 'coqui_scenes'},
    devWorkspace: _testingDev,
  ),
  'feature_review': PackageRule(
    'packages/features/feature_review',
    flutter: true,
    workspace: {'coqui_contracts', 'coqui_ui'},
    devWorkspace: _testingDev,
  ),
  'feature_words': PackageRule(
    'packages/features/feature_words',
    flutter: true,
    workspace: {'coqui_contracts', 'coqui_ui'},
    devWorkspace: _testingDev,
  ),
  'feature_library': PackageRule(
    'packages/features/feature_library',
    flutter: true,
    workspace: {'coqui_contracts', 'coqui_ui'},
    devWorkspace: _testingDev,
  ),
  'feature_speaking': PackageRule(
    'packages/features/feature_speaking',
    flutter: true,
    workspace: {'coqui_contracts', 'coqui_ui'},
    devWorkspace: _testingDev,
  ),
  'feature_profile': PackageRule(
    'packages/features/feature_profile',
    flutter: true,
    workspace: {'coqui_contracts', 'coqui_ui'},
    devWorkspace: _testingDev,
  ),
  'app': PackageRule(
    'app',
    flutter: true,
    workspace: _everything,
    devWorkspace: _testingDev,
  ),
};

/// Third-party packages that only some packages may list. Builders may not add
/// a package: they file a request in coqui/requests/.
const thirdPartyOnly = <String, Set<String>>{
  'just_audio': {'coqui_platform'},
  'speech_to_text': {'coqui_platform'},
  'shared_preferences': {'coqui_platform'},
  'web': {'coqui_platform'},
  'go_router': {'app'},
  // The Material widgets (Nov 19, 2026). In every Flutter package that draws
  // widgets: not in coqui_platform, and not in the pure Dart packages.
  'material_ui': {
    'coqui_ui',
    'coqui_testing',
    'coqui_scenes',
    'feature_map',
    'feature_story',
    'feature_review',
    'feature_words',
    'feature_library',
    'feature_speaking',
    'feature_profile',
    'app',
  },
};

/// Third-party packages any package may list.
const thirdPartyAnywhere = {'collection'};

/// Dev dependencies. Pure Dart packages: `lints` and `test`. Flutter packages:
/// `flutter_lints` and `flutter_test` (from the SDK).
const devOnlyPure = {'lints', 'test'};
const devOnlyFlutter = {'flutter_lints', 'flutter_test'};

/// The Flutter SDK, a dependency of the Flutter packages only.
const flutterSdk = 'flutter';

/// Folders, relative to coqui/, that no check looks into. `tool/prueba_telefono`
/// is a standalone app of another order and is not part of the workspace.
const skippedDirs = {'tool/prueba_telefono'};

/// Folder names that no check looks into, at any depth.
const skippedNames = {'build', 'node_modules'};

// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  var root = Directory.current;
  String? base;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--root' && i + 1 < args.length) {
      root = Directory(args[++i]);
    } else if (args[i] == '--base' && i + 1 < args.length) {
      base = args[++i];
    } else {
      stderr.writeln(
        'usage: dart run tool/check_boundaries.dart [--root DIR] [--base REF]',
      );
      exit(64);
    }
  }
  // The branch: the CI variables first, then git.
  String? branch;
  for (final name in ['GITHUB_HEAD_REF', 'GITHUB_REF_NAME']) {
    final value = Platform.environment[name];
    if (value != null && value.isNotEmpty) {
      branch = value;
      break;
    }
  }
  final problems = await checkBoundaries(root, branch: branch, base: base);
  if (problems.isEmpty) {
    stdout.writeln('check_boundaries: ok');
    return;
  }
  for (final p in problems) {
    stderr.writeln(p);
  }
  exit(1);
}

/// Runs every check on the workspace at [root] (the coqui/ folder) and returns
/// one line per problem. [branch] overrides the branch git reports; [base]
/// overrides the ref the lane check compares against (default `origin/main`,
/// else `main`).
Future<List<String>> checkBoundaries(
  Directory root, {
  String? branch,
  String? base,
}) async {
  final problems = <String>[];
  final packages = _findPackages(root);
  for (final package in packages) {
    final rule = packageRules[package.name];
    if (rule == null) {
      problems.add(
        '${package.pubspecPath}:1: [a] package ${package.name} is not in the '
        'package table',
      );
      continue;
    }
    problems.addAll(_checkPubspec(package, rule));
    problems.addAll(_checkImports(root, package));
  }
  problems.addAll(await _checkLane(root, branch: branch, base: base));
  return problems;
}

// --- Finding the packages ---------------------------------------------------

class _Package {
  _Package(this.dir, this.pubspecPath, this.pubspec);
  final Directory dir;
  final String pubspecPath;
  final _Pubspec pubspec;
  String get name => pubspec.name;
}

class _Pubspec {
  _Pubspec(this.name, this.dependencies, this.devDependencies);
  final String name;
  final Map<String, int> dependencies; // name -> line number (1-based)
  final Map<String, int> devDependencies;
}

String _norm(String path) {
  var p = File(path).absolute.path.replaceAll(r'\', '/');
  while (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

/// [path] relative to [root], with forward slashes. Empty for [root] itself.
String _rel(Directory root, String path) {
  final base = _norm(root.path);
  final p = _norm(path);
  if (p == base) return '';
  if (p.startsWith('$base/')) return p.substring(base.length + 1);
  return p;
}

bool _skipped(Directory root, FileSystemEntity entity) {
  final rel = _rel(root, entity.path);
  for (final dir in skippedDirs) {
    if (rel == dir || rel.startsWith('$dir/')) return true;
  }
  final name = rel.split('/').last;
  return name.startsWith('.') || skippedNames.contains(name);
}

/// Every pubspec.yaml below [root], except the workspace root's own and the
/// ones in skipped folders.
List<_Package> _findPackages(Directory root) {
  final found = <_Package>[];
  void walk(Directory dir) {
    final entries = dir.listSync(followLinks: false)
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final entity in entries) {
      if (_skipped(root, entity)) continue;
      if (entity is Directory) {
        walk(entity);
      } else if (entity is File &&
          entity.uri.pathSegments.last == 'pubspec.yaml') {
        // The workspace root's own pubspec lists the members. It is not one.
        if (_rel(root, entity.parent.path).isEmpty) continue;
        final pubspec = _parsePubspec(entity.readAsStringSync());
        if (pubspec != null) {
          found.add(_Package(entity.parent, _rel(root, entity.path), pubspec));
        }
      }
    }
  }

  walk(root);
  return found;
}

/// Reads `name`, `dependencies` and `dev_dependencies` from a pubspec. A pubspec
/// is a small, regular file: a section is a top-level key, an entry is a key
/// one level in, and anything deeper belongs to the entry above it.
_Pubspec? _parsePubspec(String text) {
  String? name;
  final deps = <String, int>{};
  final devDeps = <String, int>{};
  String? section;
  int? entryIndent;
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].replaceAll('\r', '');
    final hash = line.indexOf(' #');
    if (hash >= 0) line = line.substring(0, hash);
    if (line.trimLeft().startsWith('#') || line.trim().isEmpty) continue;
    final indent = line.length - line.trimLeft().length;
    final match = RegExp(r'^([A-Za-z0-9_]+):\s*(.*)$').firstMatch(line.trim());
    if (match == null) continue;
    final key = match.group(1)!;
    final value = match.group(2)!.trim();
    if (indent == 0) {
      section = key;
      entryIndent = null;
      if (key == 'name') {
        name = value.replaceAll('"', '').replaceAll("'", '');
      }
      continue;
    }
    if (section != 'dependencies' && section != 'dev_dependencies') continue;
    entryIndent ??= indent;
    if (indent != entryIndent) continue;
    (section == 'dependencies' ? deps : devDeps)[key] = i + 1;
  }
  if (name == null) return null;
  return _Pubspec(name, deps, devDeps);
}

// --- [a] and [e]: the pubspec -----------------------------------------------

List<String> _checkPubspec(_Package package, PackageRule rule) {
  final problems = <String>[];
  final isFeature = package.name.startsWith('feature_');

  void check(String dep, int line, {required bool dev}) {
    final where = '${package.pubspecPath}:$line';
    final section = dev ? 'dev_dependencies' : 'dependencies';
    if (isFeature && dep.startsWith('feature_') && dep != package.name) {
      problems.add(
        '$where: [e] ${package.name} lists $dep: a feature never depends on '
        'another feature',
      );
      return;
    }
    if (packageRules.containsKey(dep)) {
      if (rule.devWorkspace.contains(dep)) {
        if (!dev) {
          problems.add(
            '$where: [a] ${package.name} lists $dep in dependencies: it is a '
            'dev dependency only',
          );
        }
      } else if (!rule.workspace.contains(dep)) {
        problems.add(
          '$where: [a] ${package.name} lists $dep: its row allows '
          '${_list(rule.workspace)}'
          '${rule.devWorkspace.isEmpty ? '' : ' (dev only: ${_list(rule.devWorkspace)})'}',
        );
      }
      return;
    }
    if (dep == flutterSdk) {
      if (!rule.flutter) {
        problems.add(
          '$where: [a] ${package.name} lists the Flutter SDK, but it is a '
          'pure Dart package',
        );
      } else if (dev) {
        problems.add(
          '$where: [a] ${package.name} lists the Flutter SDK in $section',
        );
      }
      return;
    }
    final devOnly = rule.flutter ? devOnlyFlutter : devOnlyPure;
    if (devOnly.contains(dep)) {
      if (!dev) {
        problems.add(
          '$where: [a] ${package.name} lists $dep in dependencies: it is a '
          'dev dependency',
        );
      }
      return;
    }
    if (devOnlyFlutter.contains(dep) || devOnlyPure.contains(dep)) {
      problems.add(
        '$where: [a] ${package.name} lists $dep, which belongs to '
        '${rule.flutter ? 'pure Dart' : 'Flutter'} packages',
      );
      return;
    }
    if (thirdPartyAnywhere.contains(dep)) return;
    final only = thirdPartyOnly[dep];
    if (only != null) {
      if (!only.contains(package.name)) {
        problems.add(
          '$where: [a] ${package.name} lists $dep: only ${_list(only)} may',
        );
      }
      return;
    }
    problems.add(
      '$where: [a] ${package.name} lists $dep: not in the third-party list '
      '(file a request in requests/)',
    );
  }

  package.pubspec.dependencies.forEach((d, l) => check(d, l, dev: false));
  package.pubspec.devDependencies.forEach((d, l) => check(d, l, dev: true));
  return problems;
}

String _list(Set<String> names) =>
    names.isEmpty ? 'no Coquí package' : (names.toList()..sort()).join(', ');

// --- [b], [c] and [e]: the imports ------------------------------------------

List<String> _checkImports(Directory root, _Package package) {
  final problems = <String>[];
  final isFeature = package.name.startsWith('feature_');
  final listed = {
    ...package.pubspec.dependencies.keys,
    ...package.pubspec.devDependencies.keys,
  };
  for (final file in _dartFiles(package.dir)) {
    final path = _rel(root, file.path);
    final inLib = _rel(package.dir, file.path).startsWith('lib/');
    for (final use in _packageUris(file.readAsStringSync())) {
      final target = use.package;
      if (target == package.name) continue;
      final where = '$path:${use.line}';
      if (target == 'flutter' && use.path == 'material.dart') {
        problems.add(
          '$where: [f] ${package.name} imports package:flutter/material.dart: '
          'it is deprecated; import package:material_ui/material_ui.dart',
        );
      }
      if (target == 'coqui_testing' && inLib) {
        problems.add(
          '$where: [g] ${package.name} imports package:coqui_testing in lib/: '
          'the fakes are for tests and tool/ only',
        );
      }
      if (isFeature && target.startsWith('feature_')) {
        problems.add(
          '$where: [e] ${package.name} imports $target: a feature never '
          'depends on another feature',
        );
      } else if (!listed.contains(target)) {
        problems.add(
          '$where: [b] ${package.name} imports package:$target, which its '
          'pubspec does not list',
        );
      }
      if (use.path.startsWith('src/')) {
        problems.add(
          '$where: [c] ${package.name} imports package:$target/${use.path}: '
          'nobody imports another package\'s src/',
        );
      }
    }
  }
  return problems;
}

/// Every .dart file of the package, not looking into hidden folders, build
/// output, or a nested package.
Iterable<File> _dartFiles(Directory dir) sync* {
  final entries = dir.listSync(followLinks: false)
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final entity in entries) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (entity is Directory) {
      if (name.startsWith('.') || skippedNames.contains(name)) continue;
      if (File('${entity.path}/pubspec.yaml').existsSync()) continue;
      yield* _dartFiles(entity);
    } else if (entity is File && name.endsWith('.dart')) {
      yield entity;
    }
  }
}

class _Use {
  _Use(this.package, this.path, this.line);
  final String package;
  final String path;
  final int line;
}

/// The `package:` URIs of every import and export directive in [source],
/// including those after an `if (...)` of a conditional import. Comments are
/// not read.
List<_Use> _packageUris(String source) {
  final text = source.replaceAllMapped(
    RegExp(r'/\*[\s\S]*?\*/'),
    (m) => m.group(0)!.replaceAll(RegExp(r'[^\n]'), ' '),
  );
  final uses = <_Use>[];
  final directive = RegExp(
    r'^[ \t]*(?:import|export)\b([^;]*);',
    multiLine: true,
  );
  final literal = RegExp(r'''(['"])(.*?)\1''');
  for (final m in directive.allMatches(text)) {
    // A directive may carry `//` comments on its lines; drop them.
    final body = m
        .group(0)!
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
        .join('\n');
    final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
    for (final s in literal.allMatches(body)) {
      final uri = s.group(2)!;
      if (!uri.startsWith('package:')) continue;
      final rest = uri.substring('package:'.length);
      final slash = rest.indexOf('/');
      if (slash < 0) continue;
      uses.add(_Use(rest.substring(0, slash), rest.substring(slash + 1), line));
    }
  }
  return uses;
}

// --- [d]: the lane ------------------------------------------------------------

Future<List<String>> _checkLane(
  Directory root, {
  String? branch,
  String? base,
}) async {
  branch ??= _git(root, ['rev-parse', '--abbrev-ref', 'HEAD']).out;
  final match = RegExp(r'^lane/([^/]+)/').firstMatch(branch);
  if (match == null) return const [];
  final name = match.group(1)!;
  final rule = packageRules[name];
  if (rule == null) {
    return ['[d] branch $branch names $name, which is not a package'];
  }

  String? baseRef = base;
  if (baseRef == null) {
    for (final ref in ['origin/main', 'main']) {
      if (_git(root, [
        'rev-parse',
        '--verify',
        '--quiet',
        '$ref^{commit}',
      ]).ok) {
        baseRef = ref;
        break;
      }
    }
  }
  if (baseRef == null) {
    return [
      '[d] branch $branch: neither origin/main nor main exists to compare with',
    ];
  }
  final mergeBase = _git(root, ['merge-base', 'HEAD', baseRef]);
  if (!mergeBase.ok) {
    return ['[d] branch $branch: no common ancestor with $baseRef'];
  }
  final diff = _git(root, [
    'diff',
    '--name-only',
    '--no-renames',
    '-z',
    '${mergeBase.out}..HEAD',
  ]);
  if (!diff.ok) {
    return ['[d] branch $branch: git diff failed: ${diff.err}'];
  }
  final prefix = _git(root, [
    'rev-parse',
    '--show-prefix',
  ]).out; // "coqui/" or ""
  final allowed = ['$prefix${rule.dir}/', '${prefix}requests/'];
  final problems = <String>[];
  for (final file in diff.raw.split('\u0000')) {
    if (file.isEmpty) continue;
    if (allowed.any(file.startsWith)) continue;
    problems.add(
      '$file: [d] branch $branch may change only $prefix${rule.dir}/ and '
      '${prefix}requests/',
    );
  }
  return problems;
}

class _Git {
  _Git(this.ok, this.raw, this.err);
  final bool ok;
  final String raw;
  final String err;
  String get out => raw.trim();
}

_Git _git(Directory dir, List<String> args) {
  final result = Process.runSync('git', args, workingDirectory: dir.path);
  return _Git(
    result.exitCode == 0,
    result.stdout as String,
    (result.stderr as String).trim(),
  );
}
