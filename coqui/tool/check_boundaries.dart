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
//   [d] the branch is `lane/<lane>/...`, `story/<n>`, or `contracts/<n>` and
//       changes a file outside the paths allowed by tools/lanes.json (plus
//       shared_paths and generated_paths), or edits conformance paths on
//       `contracts/<n>` without changing `coqui_contracts`, or tools/lanes.json
//       itself fails schema/overlap checks
//   [e] a feature's pubspec or imports name another feature
// Added by the orchestrator on Nov 19, 2026 (not in the plan's rules):
//   [f] a Dart file imports package:flutter/material.dart (deprecated in
//       Flutter 3.50; the code uses package:material_ui/material_ui.dart)
//   [g] a file under lib/ imports coqui_testing (it is a dev dependency, for
//       tests and tool/ only)
// Added in #55:
//   [h] added lines in feature packages or coqui_ui introduce non-directional
//       left/right Flutter layout calls (coqui_scenes and coqui_pixel are
//       exempt; unchanged existing lines are not flagged)
// Added in #257:
//   [i] added lines in a package or app AGENTS.md (`coqui/**/AGENTS.md`,
//       excluding `coqui/AGENTS.md`) contain an issue reference (`#<digits>`);
//       unchanged existing lines are not flagged
//
// The tables below are data. They are copied from the plan, with the
// orchestrator's changes of Nov 19, 2026 noted where they differ.

import 'dart:collection';
import 'dart:convert';
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
  // Scene play-every-path and sheet-rules checks (#65). Depends on coqui_scenes
  // and feature_story; never depended on by app or any other package.
  'coqui_story_checks': PackageRule(
    'packages/coqui_story_checks',
    flutter: true,
    workspace: {
      'coqui_contracts',
      'coqui_pixel',
      'coqui_scenes',
      'feature_story',
    },
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
  File? laneMapFile;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--root' && i + 1 < args.length) {
      root = Directory(args[++i]);
    } else if (args[i] == '--base' && i + 1 < args.length) {
      base = args[++i];
    } else if (args[i] == '--lane-map' && i + 1 < args.length) {
      laneMapFile = File(args[++i]);
    } else {
      stderr.writeln(
        'usage: dart run tool/check_boundaries.dart '
        '[--root DIR] [--base REF] [--lane-map PATH]',
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
  final problems = await checkBoundaries(
    root,
    branch: branch,
    base: base,
    laneMapFile: laneMapFile,
  );
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
/// else `main`); [laneMapFile] overrides `<repoRoot>/tools/lanes.json`.
Future<List<String>> checkBoundaries(
  Directory root, {
  String? branch,
  String? base,
  File? laneMapFile,
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
  problems.addAll(
    await _checkLane(
      root,
      branch: branch,
      base: base,
      laneMapFile: laneMapFile,
    ),
  );
  problems.addAll(await _checkDirectional(root, base: base));
  problems.addAll(await _checkAgentsIssueRefs(root, base: base));
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

// --- [d]: the lane (reads tools/lanes.json) ----------------------------------

final _laneIdRe = RegExp(r'^[A-Za-z0-9._-]+$');
final _placeholderRe = RegExp(r'\{([A-Za-z0-9_]+)\}');
final _digitsRe = RegExp(r'^[0-9]+$');

class _LaneEntry {
  _LaneEntry({
    required this.id,
    required this.kind,
    required this.paths,
    required this.generatedPaths,
    required this.parents,
    required this.spans,
    required this.conflictsWith,
    required this.multiPackageOk,
  });

  final String id;
  final String kind;
  final List<String> paths;
  final List<String> generatedPaths;
  final List<String> parents;
  final List<String> spans;
  final List<String> conflictsWith;
  final bool multiPackageOk;
}

class _SanctionedMultiPackage {
  _SanctionedMultiPackage({
    required this.name,
    required this.combinations,
    required this.extraPaths,
    required this.branchStyle,
    required this.requiresLabel,
  });

  final String name;
  final List<List<String>> combinations;
  final List<String> extraPaths;
  final String branchStyle;
  final String? requiresLabel;
}

class _BranchRules {
  _BranchRules({
    required this.lanePrefix,
    required this.storyPrefix,
    required this.storyDefaultLane,
    this.contractsPrefix = 'contracts/',
    this.contractsOwnerLane = 'coqui_contracts',
    this.contractsConformancePaths = const [
      'coqui/packages/**',
      'coqui/app/**',
    ],
  });

  final String lanePrefix;
  final String storyPrefix;
  final String storyDefaultLane;
  final String contractsPrefix;
  final String contractsOwnerLane;
  final List<String> contractsConformancePaths;
}

class _LaneMap {
  _LaneMap({
    required this.version,
    required this.sharedPaths,
    required this.packageRootPrefix,
    required this.multiPackageLabel,
    required this.branchRules,
    required this.generatedPathGroups,
    required this.sanctionedMultiPackage,
    required this.lanes,
  });

  final int version;
  final List<String> sharedPaths;
  final String packageRootPrefix;
  final String multiPackageLabel;
  final _BranchRules branchRules;
  final Map<String, List<String>> generatedPathGroups;
  final Map<String, _SanctionedMultiPackage> sanctionedMultiPackage;
  final Map<String, _LaneEntry> lanes;
}

class _ParsedPattern {
  _ParsedPattern(this.raw, this.segs, this.rec, this.hasStar);

  final String raw;
  final List<String> segs;
  final bool rec;
  final List<bool> hasStar;
}

class _BranchResolution {
  _BranchResolution({
    required this.branch,
    required this.restricted,
    this.laneIds = const [],
    this.allowedPaths = const [],
    this.generatedPaths = const [],
    this.sharedPaths = const [],
    this.requiredOwnerPaths = const [],
    this.error,
  });

  final String branch;
  final bool restricted;
  final List<String> laneIds;
  final List<String> allowedPaths;
  final List<String> generatedPaths;
  final List<String> sharedPaths;
  final List<String> requiredOwnerPaths;
  final String? error;

  List<String> get allAllowedPatterns =>
      _dedupeStrings([...allowedPaths, ...generatedPaths, ...sharedPaths]);
}

List<String> _dedupeStrings(Iterable<String> items) {
  final seen = <String>{};
  final out = <String>[];
  for (final item in items) {
    if (seen.add(item)) out.add(item);
  }
  return out;
}

String? _validateLanePattern(String pattern) {
  if (pattern.isEmpty) return 'pattern must be a non-empty string';
  if (pattern.contains(r'\')) {
    return "pattern '$pattern' must use POSIX '/' separators, not '\\'";
  }
  if (pattern.startsWith('/')) {
    return "pattern '$pattern' must not start with '/'";
  }
  if (pattern.endsWith('/')) {
    return "pattern '$pattern' must not end with '/' (use '/**' for directories)";
  }
  final segments = pattern.split('/');
  for (var i = 0; i < segments.length; i++) {
    final seg = segments[i];
    if (seg.isEmpty) {
      return "pattern '$pattern' contains an empty path segment";
    }
    if (seg == '.' || seg == '..') {
      return "pattern '$pattern' contains disallowed segment '$seg'";
    }
    if (seg.contains('**')) {
      if (seg != '**') {
        return "pattern '$pattern' uses '**' inside segment '$seg'; "
            "only trailing '/**' is allowed";
      }
      if (i != segments.length - 1 || segments.length < 2) {
        return "pattern '$pattern' may only use '**' as a trailing '/**'";
      }
    }
  }
  return null;
}

bool _matchSegment(String patSeg, String valSeg) {
  if (!patSeg.contains('*')) return patSeg == valSeg;
  final parts = patSeg.split('*').map(RegExp.escape).join('[^/]*');
  return RegExp('^$parts\$').hasMatch(valSeg);
}

bool _matchLanePattern(String pattern, String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.endsWith('/') ||
      path.contains(r'\')) {
    return false;
  }
  final pSegs = pattern.split('/');
  final fSegs = path.split('/');
  for (final seg in fSegs) {
    if (seg.isEmpty || seg == '.' || seg == '..') return false;
  }
  if (pSegs.last == '**') {
    final prefixLen = pSegs.length - 1;
    if (fSegs.length <= prefixLen) return false;
    for (var i = 0; i < prefixLen; i++) {
      if (!_matchSegment(pSegs[i], fSegs[i])) return false;
    }
    return true;
  }
  if (fSegs.length != pSegs.length) return false;
  for (var i = 0; i < pSegs.length; i++) {
    if (!_matchSegment(pSegs[i], fSegs[i])) return false;
  }
  return true;
}

int _nextSegKind(int kind, int ch) {
  // 0 = "", 1 = ".", 2 = "..", 3 = valid non-dot-dot non-empty segment
  if (kind == 0) return ch == 0x2E /* . */ ? 1 : 3;
  if (kind == 1) return ch == 0x2E /* . */ ? 2 : 3;
  return 3;
}

String? _segmentOverlap(String pat1, String pat2) {
  final hasStar1 = pat1.contains('*');
  final hasStar2 = pat2.contains('*');
  if (!hasStar1 && !hasStar2) {
    return pat1 == pat2 && pat1.isNotEmpty && pat1 != '.' && pat1 != '..'
        ? pat1
        : null;
  }
  if (pat1.isNotEmpty && pat2.isNotEmpty) {
    final f1 = pat1.codeUnitAt(0);
    final f2 = pat2.codeUnitAt(0);
    if (f1 != 0x2A && f2 != 0x2A && f1 != f2) return null;
    final l1 = pat1.codeUnitAt(pat1.length - 1);
    final l2 = pat2.codeUnitAt(pat2.length - 1);
    if (l1 != 0x2A && l2 != 0x2A && l1 != l2) return null;
  }

  final n1 = pat1.length;
  final n2 = pat2.length;
  final strideJ = 4;
  final strideI = (n2 + 1) * strideJ;
  int key(int i, int j, int kind) => i * strideI + j * strideJ + kind;

  final visited = <int>{key(0, 0, 0)};
  final queue = Queue<(int, int, int, String)>()..add((0, 0, 0, ''));

  void enqueue(int i, int j, int kind, String witness) {
    final k = key(i, j, kind);
    if (visited.add(k)) {
      queue.add((i, j, kind, witness));
    }
  }

  while (queue.isNotEmpty) {
    final (i, j, kind, witness) = queue.removeFirst();
    if (i == n1 && j == n2 && kind == 3) return witness;

    if (i < n1 && pat1.codeUnitAt(i) == 0x2A /* * */ ) {
      enqueue(i + 1, j, kind, witness);
    }
    if (j < n2 && pat2.codeUnitAt(j) == 0x2A /* * */ ) {
      enqueue(i, j + 1, kind, witness);
    }

    if (i < n1 && j < n2) {
      final c1 = pat1.codeUnitAt(i);
      final c2 = pat2.codeUnitAt(j);
      if (c1 != 0x2A && c2 != 0x2A) {
        if (c1 == c2) {
          enqueue(
            i + 1,
            j + 1,
            _nextSegKind(kind, c1),
            '$witness${String.fromCharCode(c1)}',
          );
        }
      } else if (c1 == 0x2A && c2 != 0x2A) {
        enqueue(
          i,
          j + 1,
          _nextSegKind(kind, c2),
          '$witness${String.fromCharCode(c2)}',
        );
      } else if (c1 != 0x2A && c2 == 0x2A) {
        enqueue(
          i + 1,
          j,
          _nextSegKind(kind, c1),
          '$witness${String.fromCharCode(c1)}',
        );
      } else {
        enqueue(i, j, _nextSegKind(kind, 0x78 /* x */), '${witness}x');
      }
    }
  }
  return null;
}

String _concreteSegment(String patSeg) {
  final stripped = patSeg.replaceAll('*', '');
  if (stripped.isNotEmpty && stripped != '.' && stripped != '..') {
    return stripped;
  }
  return patSeg.replaceFirst('*', 'x').replaceAll('*', '');
}

_ParsedPattern _parseLanePattern(String pattern) {
  final parts = pattern.split('/');
  final rec = parts.last == '**';
  final segs = rec ? parts.sublist(0, parts.length - 1) : parts;
  return _ParsedPattern(pattern, segs, rec, [
    for (final s in segs) s.contains('*'),
  ]);
}

String? _parsedPatternsOverlap(_ParsedPattern p1, _ParsedPattern p2) {
  final a = p1.segs;
  final b = p2.segs;
  final na = a.length;
  final nb = b.length;
  final int k;
  if (!p1.rec && !p2.rec) {
    if (na != nb) return null;
    k = na;
  } else if (p1.rec && !p2.rec) {
    if (nb <= na) return null;
    k = na;
  } else if (!p1.rec && p2.rec) {
    if (na <= nb) return null;
    k = nb;
  } else {
    k = na < nb ? na : nb;
  }

  for (var i = k - 1; i >= 0; i--) {
    if (!p1.hasStar[i] && !p2.hasStar[i] && a[i] != b[i]) {
      return null;
    }
  }

  final witness = <String>[];
  for (var i = 0; i < k; i++) {
    if (!p1.hasStar[i] && !p2.hasStar[i]) {
      witness.add(a[i]);
    } else {
      final w = _segmentOverlap(a[i], b[i]);
      if (w == null) return null;
      witness.add(w);
    }
  }

  if (!p1.rec && !p2.rec) return witness.join('/');
  if (p1.rec && !p2.rec) {
    for (var i = na; i < nb; i++) {
      witness.add(_concreteSegment(b[i]));
    }
    return witness.join('/');
  }
  if (!p1.rec && p2.rec) {
    for (var i = nb; i < na; i++) {
      witness.add(_concreteSegment(a[i]));
    }
    return witness.join('/');
  }

  final longer = na >= nb ? a : b;
  for (var i = k; i < longer.length; i++) {
    witness.add(_concreteSegment(longer[i]));
  }
  witness.add('file');
  return witness.join('/');
}

String? _patternsOverlap(String p1, String p2) =>
    _parsedPatternsOverlap(_parseLanePattern(p1), _parseLanePattern(p2));

List<String> _asStringList(
  Object? obj,
  String field,
  List<String> errors, {
  bool allowEmpty = true,
}) {
  if (obj is! List || obj.any((e) => e is! String)) {
    errors.add('$field must be a list of strings');
    return const [];
  }
  final list = obj.cast<String>();
  if (!allowEmpty && list.isEmpty) {
    errors.add('$field must be a non-empty list of strings');
  }
  return list;
}

String _expandTemplatePath(
  String templatePath,
  Map<String, String> params,
  String laneId,
  List<String> errors,
) {
  return templatePath.replaceAllMapped(_placeholderRe, (m) {
    final key = m.group(1)!;
    final val = params[key];
    if (val == null) {
      errors.add(
        "lane '$laneId': template path '$templatePath' references missing "
        "param '$key'",
      );
      return m.group(0)!;
    }
    return val;
  });
}

(_LaneMap?, List<String>) _parseLaneMap(Object? raw) {
  final errors = <String>[];
  if (raw is! Map) {
    return (null, ['lane map root must be a JSON object']);
  }
  final data = raw.cast<String, Object?>();

  final version = data['version'];
  if (version is! int || version != 1) {
    errors.add('unsupported lane map version $version; expected 1');
  }

  final sharedPaths = _asStringList(
    data['shared_paths'] ?? const <Object?>[],
    'shared_paths',
    errors,
  );

  var packageRootPrefix = 'coqui/packages/';
  final rawPkgPrefix = data['package_root_prefix'];
  if (rawPkgPrefix is! String ||
      !rawPkgPrefix.endsWith('/') ||
      rawPkgPrefix.startsWith('/')) {
    errors.add(
      "package_root_prefix must be a non-empty relative path ending with '/'",
    );
  } else {
    packageRootPrefix = rawPkgPrefix;
  }

  var multiPackageLabel = 'multi-package-ok';
  final rawMpLabel = data['multi_package_label'];
  if (rawMpLabel is! String || rawMpLabel.isEmpty) {
    errors.add('multi_package_label must be a non-empty string');
  } else {
    multiPackageLabel = rawMpLabel;
  }

  var lanePrefix = 'lane/';
  var storyPrefix = 'story/';
  var storyDefaultLane = '';
  var contractsPrefix = 'contracts/';
  var contractsOwnerLane = '';
  var contractsConformancePaths = const <String>[];
  final rawBranchRules = data['branch_rules'];
  if (rawBranchRules is! Map) {
    errors.add('branch_rules must be an object');
  } else {
    final br = rawBranchRules.cast<String, Object?>();
    final lp = br['lane_prefix'];
    final sp = br['story_prefix'];
    final sdl = br['story_default_lane'];
    final cp = br['contracts_prefix'];
    final col = br['contracts_owner_lane'];
    final ccp = br['contracts_conformance_paths'];
    if (lp is! String || !lp.endsWith('/')) {
      errors.add("branch_rules.lane_prefix must be a string ending with '/'");
    } else {
      lanePrefix = lp;
    }
    if (sp is! String || !sp.endsWith('/')) {
      errors.add("branch_rules.story_prefix must be a string ending with '/'");
    } else {
      storyPrefix = sp;
    }
    if (sdl is! String || sdl.isEmpty) {
      errors.add('branch_rules.story_default_lane must be a non-empty string');
    } else {
      storyDefaultLane = sdl;
    }
    if (cp is! String || !cp.endsWith('/')) {
      errors.add(
        "branch_rules.contracts_prefix must be a string ending with '/'",
      );
    } else {
      contractsPrefix = cp;
    }
    if (col is! String || col.isEmpty) {
      errors.add(
        'branch_rules.contracts_owner_lane must be a non-empty string',
      );
    } else {
      contractsOwnerLane = col;
    }
    contractsConformancePaths = _asStringList(
      ccp,
      'branch_rules.contracts_conformance_paths',
      errors,
      allowEmpty: false,
    );
  }

  final generatedPathGroups = <String, List<String>>{};
  final rawGenGroups =
      data['generated_path_groups'] ?? const <String, Object?>{};
  if (rawGenGroups is! Map) {
    errors.add('generated_path_groups must be an object');
  } else {
    rawGenGroups.forEach((key, val) {
      if (key is! String || key.isEmpty) {
        errors.add('generated_path_groups keys must be non-empty strings');
        return;
      }
      generatedPathGroups[key] = _asStringList(
        val,
        'generated_path_groups.$key',
        errors,
        allowEmpty: false,
      );
    });
  }

  final rawTemplatesObj = data['templates'] ?? const <String, Object?>{};
  final rawTemplates = <String, Object?>{};
  if (rawTemplatesObj is! Map) {
    errors.add('templates must be an object');
  } else {
    rawTemplates.addAll(rawTemplatesObj.cast<String, Object?>());
  }

  final lanes = <String, _LaneEntry>{};
  final rawLanes = data['lanes'];
  if (rawLanes is! Map || rawLanes.isEmpty) {
    errors.add('lanes must be a non-empty object');
  } else {
    rawLanes.forEach((rawId, rawLaneObj) {
      if (rawId is! String || !_laneIdRe.hasMatch(rawId)) {
        errors.add(
          "invalid lane id '$rawId' (allowed: letters, digits, '.', '_', '-')",
        );
        return;
      }
      if (rawLaneObj is! Map) {
        errors.add("lane '$rawId' must be an object");
        return;
      }
      final rawLane = rawLaneObj.cast<String, Object?>();
      final tmplName = rawLane['template'];
      var tmpl = <String, Object?>{};
      final params = <String, String>{};
      if (tmplName != null) {
        if (tmplName is! String || !rawTemplates.containsKey(tmplName)) {
          errors.add("lane '$rawId': unknown template '$tmplName'");
        } else if (rawTemplates[tmplName] is! Map) {
          errors.add("template '$tmplName' must be an object");
        } else {
          tmpl = (rawTemplates[tmplName] as Map).cast<String, Object?>();
        }
        final rawParams = rawLane['params'] ?? const <String, Object?>{};
        if (rawParams is! Map) {
          errors.add("lane '$rawId'.params must be an object");
        } else {
          rawParams.forEach((pk, pv) {
            if (pk is! String ||
                pv is! String ||
                pv.isEmpty ||
                pv.contains('/') ||
                pv.contains(r'\')) {
              errors.add(
                "lane '$rawId'.params['$pk'] must be a non-empty single-segment string",
              );
            } else {
              params[pk] = pv;
            }
          });
        }
      }

      final kindObj = rawLane.containsKey('kind')
          ? rawLane['kind']
          : tmpl['kind'];
      var kind = '';
      if (kindObj is! String || kindObj.isEmpty) {
        errors.add("lane '$rawId'.kind must be a non-empty string");
      } else {
        kind = kindObj;
      }

      final parents = _asStringList(
        rawLane.containsKey('parents')
            ? rawLane['parents']
            : (tmpl['parents'] ?? const <Object?>[]),
        'lanes.$rawId.parents',
        errors,
      );
      final spans = _asStringList(
        rawLane.containsKey('spans')
            ? rawLane['spans']
            : (tmpl['spans'] ?? const <Object?>[]),
        'lanes.$rawId.spans',
        errors,
      );
      final conflictsWith = _asStringList(
        rawLane.containsKey('conflicts_with')
            ? rawLane['conflicts_with']
            : (tmpl['conflicts_with'] ?? const <Object?>[]),
        'lanes.$rawId.conflicts_with',
        errors,
      );

      final multiOkObj = rawLane.containsKey('multi_package_ok')
          ? rawLane['multi_package_ok']
          : (tmpl['multi_package_ok'] ?? false);
      var multiOk = false;
      if (multiOkObj is! bool) {
        errors.add('lanes.$rawId.multi_package_ok must be a boolean');
      } else {
        multiOk = multiOkObj;
      }

      final genGroupObj = rawLane.containsKey('generated_group')
          ? rawLane['generated_group']
          : tmpl['generated_group'];
      var generatedPaths = const <String>[];
      if (genGroupObj != null) {
        if (genGroupObj is! String ||
            !generatedPathGroups.containsKey(genGroupObj)) {
          errors.add(
            "lanes.$rawId.generated_group references unknown group '$genGroupObj'",
          );
        } else {
          generatedPaths = generatedPathGroups[genGroupObj]!;
        }
      }

      final List<String> paths;
      if (rawLane['paths'] == null) {
        final tmplPaths = _asStringList(
          tmpl['paths'] ?? const <Object?>[],
          'templates.$tmplName.paths',
          errors,
          allowEmpty: false,
        );
        paths = [
          for (final p in tmplPaths)
            _expandTemplatePath(p, params, rawId, errors),
        ];
      } else {
        paths = _asStringList(
          rawLane['paths'],
          'lanes.$rawId.paths',
          errors,
          allowEmpty: false,
        );
      }

      lanes[rawId] = _LaneEntry(
        id: rawId,
        kind: kind,
        paths: paths,
        generatedPaths: generatedPaths,
        parents: parents,
        spans: spans,
        conflictsWith: conflictsWith,
        multiPackageOk: multiOk,
      );
    });
  }

  final sanctioned = <String, _SanctionedMultiPackage>{};
  final rawSanctioned =
      data['sanctioned_multi_package'] ?? const <String, Object?>{};
  if (rawSanctioned is! Map) {
    errors.add('sanctioned_multi_package must be an object');
  } else {
    rawSanctioned.forEach((ruleName, rawRuleObj) {
      if (ruleName is! String || ruleName.isEmpty) {
        errors.add('sanctioned_multi_package keys must be non-empty strings');
        return;
      }
      if (rawRuleObj is! Map) {
        errors.add('sanctioned_multi_package.$ruleName must be an object');
        return;
      }
      final rawRule = rawRuleObj.cast<String, Object?>();
      final rawCombos = rawRule['combinations'];
      final combos = <List<String>>[];
      if (rawCombos is! List || rawCombos.isEmpty) {
        errors.add(
          'sanctioned_multi_package.$ruleName.combinations must be a non-empty list',
        );
      } else {
        for (var i = 0; i < rawCombos.length; i++) {
          final combo = _asStringList(
            rawCombos[i],
            'sanctioned_multi_package.$ruleName.combinations[$i]',
            errors,
            allowEmpty: false,
          );
          if (combo.isNotEmpty) {
            combos.add([...combo]..sort());
          }
        }
      }
      final extraPaths = _asStringList(
        rawRule['extra_paths'] ?? const <Object?>[],
        'sanctioned_multi_package.$ruleName.extra_paths',
        errors,
      );
      final styleObj = rawRule['branch_style'] ?? 'lane';
      var branchStyle = 'lane';
      if (styleObj is! String || (styleObj != 'lane' && styleObj != 'story')) {
        errors.add(
          "sanctioned_multi_package.$ruleName.branch_style must be 'lane' or 'story'",
        );
      } else {
        branchStyle = styleObj;
      }
      final reqObj = rawRule['requires_label'];
      String? reqLabel;
      if (reqObj != null) {
        if (reqObj is! String || reqObj.isEmpty) {
          errors.add(
            'sanctioned_multi_package.$ruleName.requires_label must be null or a non-empty string',
          );
        } else {
          reqLabel = reqObj;
        }
      }
      sanctioned[ruleName] = _SanctionedMultiPackage(
        name: ruleName,
        combinations: combos,
        extraPaths: extraPaths,
        branchStyle: branchStyle,
        requiresLabel: reqLabel,
      );
    });
  }

  final laneMap = _LaneMap(
    version: version is int ? version : 0,
    sharedPaths: sharedPaths,
    packageRootPrefix: packageRootPrefix,
    multiPackageLabel: multiPackageLabel,
    branchRules: _BranchRules(
      lanePrefix: lanePrefix,
      storyPrefix: storyPrefix,
      storyDefaultLane: storyDefaultLane,
      contractsPrefix: contractsPrefix,
      contractsOwnerLane: contractsOwnerLane,
      contractsConformancePaths: contractsConformancePaths,
    ),
    generatedPathGroups: generatedPathGroups,
    sanctionedMultiPackage: sanctioned,
    lanes: lanes,
  );
  return (laneMap, errors);
}

Set<String> _ancestorsOf(_LaneMap map, String laneId) {
  final result = <String>{};
  final lane = map.lanes[laneId];
  if (lane == null) return result;
  final stack = [...lane.parents];
  while (stack.isNotEmpty) {
    final cur = stack.removeLast();
    if (cur == laneId || !result.add(cur)) continue;
    final parentLane = map.lanes[cur];
    if (parentLane != null) {
      stack.addAll(parentLane.parents);
    }
  }
  return result;
}

List<String> _validateLaneMap(_LaneMap map) {
  final errors = <String>[];
  final invalidPatterns = <String>{};

  void checkPat(String pat, String where) {
    final err = _validateLanePattern(pat);
    if (err != null) {
      errors.add('$where: $err');
      invalidPatterns.add(pat);
    }
  }

  for (final p in map.sharedPaths) {
    checkPat(p, 'shared_paths');
  }
  map.generatedPathGroups.forEach((group, paths) {
    for (final p in paths) {
      checkPat(p, 'generated_path_groups.$group');
    }
  });
  if (!map.lanes.containsKey(map.branchRules.storyDefaultLane)) {
    errors.add(
      "branch_rules.story_default_lane references unknown lane "
      "'${map.branchRules.storyDefaultLane}'",
    );
  }
  if (!map.lanes.containsKey(map.branchRules.contractsOwnerLane)) {
    errors.add(
      "branch_rules.contracts_owner_lane references unknown lane "
      "'${map.branchRules.contractsOwnerLane}'",
    );
  }
  for (final p in map.branchRules.contractsConformancePaths) {
    checkPat(p, 'branch_rules.contracts_conformance_paths');
  }
  map.sanctionedMultiPackage.forEach((name, rule) {
    for (final combo in rule.combinations) {
      for (final lid in combo) {
        if (!map.lanes.containsKey(lid)) {
          errors.add(
            "sanctioned_multi_package.$name references unknown lane '$lid'",
          );
        }
      }
    }
    for (final p in rule.extraPaths) {
      checkPat(p, 'sanctioned_multi_package.$name.extra_paths');
    }
  });

  map.lanes.forEach((laneId, lane) {
    if (lane.paths.isEmpty) {
      errors.add('lanes.$laneId.paths must be non-empty');
    }
    for (final p in lane.paths) {
      checkPat(p, 'lanes.$laneId.paths');
    }
    for (final parent in lane.parents) {
      if (parent == laneId) {
        errors.add('lanes.$laneId.parents cannot reference itself');
      } else if (!map.lanes.containsKey(parent)) {
        errors.add("lanes.$laneId.parents references unknown lane '$parent'");
      }
    }
    for (final span in lane.spans) {
      if (span == laneId) {
        errors.add('lanes.$laneId.spans cannot reference itself');
      } else if (!map.lanes.containsKey(span)) {
        errors.add("lanes.$laneId.spans references unknown lane '$span'");
      }
    }
    for (final other in lane.conflictsWith) {
      if (other == laneId) {
        errors.add('lanes.$laneId.conflicts_with cannot reference itself');
      } else if (!map.lanes.containsKey(other)) {
        errors.add(
          "lanes.$laneId.conflicts_with references unknown lane '$other'",
        );
      }
    }
  });

  // Detect parent cycles via 3-color DFS.
  final color = <String, int>{}; // 0=unvisited, 1=visiting, 2=done
  void dfsCycle(String lid, List<String> trail) {
    color[lid] = 1;
    for (final parent in map.lanes[lid]!.parents) {
      if (!map.lanes.containsKey(parent)) continue;
      final state = color[parent] ?? 0;
      if (state == 1) {
        final cycle = [
          ...trail.sublist(trail.indexOf(parent)),
          parent,
        ].join(' -> ');
        errors.add('parent cycle detected: $cycle');
      } else if (state == 0) {
        dfsCycle(parent, [...trail, parent]);
      }
    }
    color[lid] = 2;
  }

  for (final laneId in map.lanes.keys) {
    if ((color[laneId] ?? 0) == 0) {
      dfsCycle(laneId, [laneId]);
    }
  }

  // Pairwise overlap check across all distinct lanes not declared exclusive.
  final laneIds = map.lanes.keys.toList();
  final ancestorsCache = {
    for (final lid in laneIds) lid: _ancestorsOf(map, lid),
  };

  bool declaredExclusive(String lidA, String lidB) {
    final a = map.lanes[lidA]!;
    final b = map.lanes[lidB]!;
    final ancA = ancestorsCache[lidA]!;
    final ancB = ancestorsCache[lidB]!;
    if (ancB.contains(lidA) || ancA.contains(lidB)) return true;
    if (a.spans.contains(lidB) || a.spans.any(ancB.contains)) return true;
    if (b.spans.contains(lidA) || b.spans.any(ancA.contains)) return true;
    if (a.conflictsWith.contains(lidB) || b.conflictsWith.contains(lidA)) {
      return true;
    }
    return false;
  }

  final parsedByLane = {
    for (final lid in laneIds)
      lid: [
        for (final p in map.lanes[lid]!.paths)
          if (!invalidPatterns.contains(p)) _parseLanePattern(p),
      ],
  };

  for (var i = 0; i < laneIds.length; i++) {
    final lidA = laneIds[i];
    final validA = parsedByLane[lidA]!;
    for (var j = i + 1; j < laneIds.length; j++) {
      final lidB = laneIds[j];
      if (declaredExclusive(lidA, lidB)) continue;
      final validB = parsedByLane[lidB]!;
      var found = false;
      for (final pa in validA) {
        for (final pb in validB) {
          final witness = _parsedPatternsOverlap(pa, pb);
          if (witness != null) {
            errors.add(
              "overlapping concurrent lanes '$lidA' and '$lidB': "
              "patterns '${pa.raw}' and '${pb.raw}' both match '$witness'",
            );
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
  }

  return errors;
}

Set<String> _touchedPackages(_LaneMap map, String laneId) {
  final lane = map.lanes[laneId];
  if (lane == null) return const {};
  final pkgs = <String>{};
  map.lanes.forEach((pkgId, pkgLane) {
    if (pkgLane.kind != 'package') return;
    for (final p1 in lane.paths) {
      for (final p2 in pkgLane.paths) {
        if (_patternsOverlap(p1, p2) != null) {
          pkgs.add(pkgId);
          return;
        }
      }
    }
  });
  return pkgs;
}

_SanctionedMultiPackage? _findSanctionedMultiPackage(
  _LaneMap map,
  List<String> laneIds,
) {
  final sorted = [...laneIds]..sort();
  for (final rule in map.sanctionedMultiPackage.values) {
    for (final combo in rule.combinations) {
      if (combo.length != sorted.length) continue;
      var same = true;
      for (var i = 0; i < combo.length; i++) {
        if (combo[i] != sorted[i]) {
          same = false;
          break;
        }
      }
      if (same) return rule;
    }
  }
  return null;
}

_BranchResolution _resolveBranch(_LaneMap map, String branch) {
  final lanePrefix = map.branchRules.lanePrefix;
  final storyPrefix = map.branchRules.storyPrefix;
  final contractsPrefix = map.branchRules.contractsPrefix;

  if (branch.startsWith(lanePrefix)) {
    final after = branch.substring(lanePrefix.length);
    final slash = after.indexOf('/');
    if (slash <= 0 || slash == after.length - 1) {
      return _BranchResolution(
        branch: branch,
        restricted: true,
        error: "branch $branch must match '$lanePrefix<lane>/<id>'",
      );
    }
    final spec = after.substring(0, slash);
    final parts = spec.split('+');
    if (parts.any((p) => p.isEmpty)) {
      return _BranchResolution(
        branch: branch,
        restricted: true,
        error: "branch $branch contains an empty lane name in '$spec'",
      );
    }
    if (parts.toSet().length != parts.length) {
      return _BranchResolution(
        branch: branch,
        restricted: true,
        error: "branch $branch lists duplicate lane in '$spec'",
      );
    }
    for (final p in parts) {
      if (!map.lanes.containsKey(p)) {
        return _BranchResolution(
          branch: branch,
          restricted: true,
          error:
              "branch $branch names unknown lane '$p' (not in tools/lanes.json)",
        );
      }
    }

    final allPkgs = <String>{};
    for (final lid in parts) {
      allPkgs.addAll(_touchedPackages(map, lid));
    }

    final extraPaths = <String>[];
    if (parts.length == 1) {
      final lane = map.lanes[parts.single]!;
      if (allPkgs.length > 1 && !lane.multiPackageOk) {
        final pkgList = (allPkgs.toList()..sort()).join(', ');
        return _BranchResolution(
          branch: branch,
          restricted: true,
          error:
              "branch $branch lane '${lane.id}' touches multiple packages "
              '($pkgList) without multi_package_ok',
        );
      }
    } else if (allPkgs.length > 1) {
      final sanctioned = _findSanctionedMultiPackage(map, parts);
      if (sanctioned == null) {
        final pkgList = (allPkgs.toList()..sort()).join(', ');
        return _BranchResolution(
          branch: branch,
          restricted: true,
          error:
              'branch $branch touches multiple packages ($pkgList) with '
              "unsanctioned lane combination '$spec'",
        );
      }
      extraPaths.addAll(sanctioned.extraPaths);
    }

    final allowed = _dedupeStrings([
      for (final lid in parts) ...map.lanes[lid]!.paths,
      ...extraPaths,
    ]);
    final generated = _dedupeStrings([
      for (final lid in parts) ...map.lanes[lid]!.generatedPaths,
    ]);
    return _BranchResolution(
      branch: branch,
      restricted: true,
      laneIds: parts,
      allowedPaths: allowed,
      generatedPaths: generated,
      sharedPaths: map.sharedPaths,
    );
  }

  if (branch.startsWith(storyPrefix)) {
    final rest = branch.substring(storyPrefix.length);
    if (!_digitsRe.hasMatch(rest)) {
      return _BranchResolution(
        branch: branch,
        restricted: true,
        error: "branch $branch must match '$storyPrefix<number>'",
      );
    }
    final defaultId = map.branchRules.storyDefaultLane;
    final lane = map.lanes[defaultId]!;
    return _BranchResolution(
      branch: branch,
      restricted: true,
      laneIds: [defaultId],
      allowedPaths: lane.paths,
      generatedPaths: lane.generatedPaths,
      sharedPaths: map.sharedPaths,
    );
  }

  if (branch.startsWith(contractsPrefix)) {
    final rest = branch.substring(contractsPrefix.length);
    if (!_digitsRe.hasMatch(rest)) {
      return _BranchResolution(
        branch: branch,
        restricted: true,
        error: "branch $branch must match '$contractsPrefix<number>'",
      );
    }
    final ownerLane = map.lanes[map.branchRules.contractsOwnerLane]!;
    return _BranchResolution(
      branch: branch,
      restricted: true,
      laneIds: [ownerLane.id],
      allowedPaths: _dedupeStrings([
        ...ownerLane.paths,
        ...map.branchRules.contractsConformancePaths,
      ]),
      generatedPaths: ownerLane.generatedPaths,
      sharedPaths: map.sharedPaths,
      requiredOwnerPaths: ownerLane.paths,
    );
  }

  return _BranchResolution(
    branch: branch,
    restricted: false,
    sharedPaths: map.sharedPaths,
  );
}

String _formatAllowedSummary(List<String> patterns) {
  if (patterns.isEmpty) return '(no paths)';
  if (patterns.length == 1) return patterns.single;
  if (patterns.length == 2) return '${patterns[0]} and ${patterns[1]}';
  if (patterns.length <= 6) {
    return '${patterns.sublist(0, patterns.length - 1).join(', ')}, and '
        '${patterns.last}';
  }
  return '${patterns.take(4).join(', ')}, ... (${patterns.length} patterns total)';
}

Directory _findRepoRoot(Directory root) {
  final top = _git(root, ['rev-parse', '--show-toplevel']);
  if (top.ok && top.out.isNotEmpty) {
    return Directory(top.out);
  }
  if (File('${root.path}/tools/lanes.json').existsSync() ||
      File('${root.path}/tools/board.py').existsSync()) {
    return root;
  }
  return root.parent;
}

Future<List<String>> _checkLane(
  Directory root, {
  String? branch,
  String? base,
  File? laneMapFile,
}) async {
  branch ??= _git(root, ['rev-parse', '--abbrev-ref', 'HEAD']).out;
  final repoRoot = _findRepoRoot(root);
  final laneFile = laneMapFile ?? File('${repoRoot.path}/tools/lanes.json');

  if (!laneFile.existsSync()) {
    final isRestrictedBranch =
        branch.startsWith('lane/') ||
        branch.startsWith('story/') ||
        branch.startsWith('contracts/');
    final hasBoard = File('${repoRoot.path}/tools/board.py').existsSync();
    if (laneMapFile != null || isRestrictedBranch || hasBoard) {
      return ['[d] missing lane map ${laneFile.path}'];
    }
    return const [];
  }

  Object? decoded;
  try {
    decoded = jsonDecode(laneFile.readAsStringSync());
  } on FormatException catch (e) {
    return ['[d] invalid JSON in ${laneFile.path}: ${e.message}'];
  }

  final (laneMap, parseErrors) = _parseLaneMap(decoded);
  final mapErrors = <String>[...parseErrors];
  if (laneMap != null) {
    mapErrors.addAll(_validateLaneMap(laneMap));
  }
  if (mapErrors.isNotEmpty) {
    return [for (final e in mapErrors) '[d] lane map error: $e'];
  }

  final resolution = _resolveBranch(laneMap!, branch);
  if (resolution.error != null) {
    return ['[d] ${resolution.error}'];
  }
  if (!resolution.restricted) {
    return const [];
  }

  final mb = _resolveMergeBase(root, base: base);
  if (mb.error != null) {
    return ['[d] branch $branch: ${mb.error}'];
  }
  final diff = _git(root, [
    '-c',
    'core.quotepath=false',
    'diff',
    '--name-only',
    '--no-renames',
    '-z',
    '${mb.commit}..HEAD',
  ]);
  if (!diff.ok) {
    return ['[d] branch $branch: git diff failed: ${diff.err}'];
  }

  final files = [
    for (final f in diff.raw.split('\u0000'))
      if (f.isNotEmpty) f,
  ];
  final allowed = resolution.allAllowedPatterns;
  final allowedSummary = _formatAllowedSummary(allowed);
  final problems = <String>[];
  final allowedFiles = <String>[];
  for (final file in files) {
    if (allowed.any((pat) => _matchLanePattern(pat, file))) {
      allowedFiles.add(file);
      continue;
    }
    problems.add('$file: [d] branch $branch may change only $allowedSummary');
  }
  if (resolution.requiredOwnerPaths.isNotEmpty) {
    final ownerTouched = files.any(
      (file) => resolution.requiredOwnerPaths.any(
        (pat) => _matchLanePattern(pat, file),
      ),
    );
    if (!ownerTouched) {
      final ownerSummary = _formatAllowedSummary(resolution.requiredOwnerPaths);
      final exemptPatterns = [
        ...resolution.sharedPaths,
        ...resolution.generatedPaths,
      ];
      for (final file in allowedFiles) {
        if (exemptPatterns.any((pat) => _matchLanePattern(pat, file))) {
          continue;
        }
        problems.add(
          "$file: [d] branch $branch may edit '$file' for conformance only "
          'alongside changes in $ownerSummary',
        );
      }
    }
  }
  return problems;
}

// --- [h]: new code uses start/end, not left/right (#55) ----------------------

class _DirectRule {
  const _DirectRule(this.pattern, this.suggestion);
  final RegExp pattern;
  final String suggestion;
}

class _NamedArgRule {
  const _NamedArgRule(
    this.pattern,
    this.displayName,
    this.forbiddenArgs,
    this.suggestion,
  );
  final RegExp pattern;
  final String displayName;
  final Set<String> forbiddenArgs;
  final String suggestion;
}

class _DirectionalHit {
  const _DirectionalHit(this.line, this.offset, this.api, this.suggestion);
  final int line;
  final int offset;
  final String api;
  final String suggestion;
}

final _directDirectionalRules = <_DirectRule>[
  _DirectRule(
    RegExp(r'\bEdgeInsets\.fromLTRB\b'),
    'EdgeInsetsDirectional.fromSTEB',
  ),
  _DirectRule(RegExp(r'\bRelativeRect\.fromLTRB\b'), 'PositionedDirectional'),
  _DirectRule(
    RegExp(
      r'\bAlignment\.(?:topLeft|topRight|centerLeft|centerRight|'
      r'bottomLeft|bottomRight)\b',
    ),
    'AlignmentDirectional',
  ),
  _DirectRule(
    RegExp(
      r'\bFractionalOffset\.(?:topLeft|topRight|centerLeft|centerRight|'
      r'bottomLeft|bottomRight)\b',
    ),
    'AlignmentDirectional',
  ),
  _DirectRule(RegExp(r'\bTextAlign\.(?:left|right)\b'), 'TextAlign.start/end'),
];

final _namedArgDirectionalRules = <_NamedArgRule>[
  _NamedArgRule(RegExp(r'\bEdgeInsets\.only\s*\('), 'EdgeInsets.only', const {
    'left',
    'right',
  }, 'EdgeInsetsDirectional.only'),
  _NamedArgRule(RegExp(r'\bPositioned\s*\('), 'Positioned', const {
    'left',
    'right',
  }, 'PositionedDirectional'),
  _NamedArgRule(RegExp(r'\bPositioned\.fill\s*\('), 'Positioned.fill', const {
    'left',
    'right',
  }, 'PositionedDirectional'),
  _NamedArgRule(
    RegExp(r'\bAnimatedPositioned\s*\('),
    'AnimatedPositioned',
    const {'left', 'right'},
    'AnimatedPositionedDirectional',
  ),
  _NamedArgRule(RegExp(r'\bBorder\s*\('), 'Border', const {
    'left',
    'right',
  }, 'BorderDirectional'),
  _NamedArgRule(
    RegExp(r'\bBorderRadius\.horizontal\s*\('),
    'BorderRadius.horizontal',
    const {'left', 'right'},
    'BorderRadiusDirectional.horizontal',
  ),
  _NamedArgRule(
    RegExp(r'\bBorderRadius\.only\s*\('),
    'BorderRadius.only',
    const {'topLeft', 'topRight', 'bottomLeft', 'bottomRight'},
    'BorderRadiusDirectional.only',
  ),
];

bool _isDirectionalCheckedPath(String relPath) {
  if (!relPath.endsWith('.dart')) return false;
  for (final dir in skippedDirs) {
    if (relPath == dir || relPath.startsWith('$dir/')) return false;
  }
  for (final seg in relPath.split('/')) {
    if (seg.startsWith('.') || skippedNames.contains(seg)) return false;
  }
  return relPath.startsWith('packages/core/coqui_ui/') ||
      relPath.startsWith('packages/features/');
}

Future<List<String>> _checkDirectional(Directory root, {String? base}) async {
  if (!_git(root, ['rev-parse', '--is-inside-work-tree']).ok) {
    return const [];
  }
  final mb = _resolveMergeBase(root, base: base);
  if (mb.commit == null) return const [];

  final diff = _git(root, [
    'diff',
    '--name-only',
    '--diff-filter=AM',
    '--no-renames',
    '-z',
    '${mb.commit}..HEAD',
  ]);
  if (!diff.ok) return const [];

  final prefix = _git(root, [
    'rev-parse',
    '--show-prefix',
  ]).out; // "coqui/" or ""
  final problems = <String>[];
  for (final gitPath in diff.raw.split('\u0000')) {
    if (gitPath.isEmpty) continue;
    if (prefix.isNotEmpty && !gitPath.startsWith(prefix)) continue;
    final relPath = prefix.isEmpty ? gitPath : gitPath.substring(prefix.length);
    if (!_isDirectionalCheckedPath(relPath)) continue;

    final patch = _git(root, [
      'diff',
      '--no-ext-diff',
      '-U0',
      '--no-renames',
      '${mb.commit}..HEAD',
      '--',
      relPath,
    ]);
    if (!patch.ok) continue;
    final addedLines = _addedLineNumbers(patch.raw);
    if (addedLines.isEmpty) continue;

    final show = _git(root, ['show', 'HEAD:$gitPath']);
    if (!show.ok) continue;

    for (final hit in _findNonDirectionalCalls(show.raw)) {
      if (!addedLines.contains(hit.line)) continue;
      problems.add(
        '$relPath:${hit.line}: [h] non-directional layout call ${hit.api}: '
        'use ${hit.suggestion} (start/end) instead of left/right',
      );
    }
  }
  return problems;
}

/// Parses unified diff `-U0` hunk headers and returns the 1-based line numbers
/// added in the new file.
Set<int> _addedLineNumbers(String unifiedDiff) {
  final added = <int>{};
  final hunkRe = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@');
  for (final rawLine in unifiedDiff.split('\n')) {
    final m = hunkRe.firstMatch(rawLine);
    if (m == null) continue;
    final start = int.parse(m.group(1)!);
    final count = m.group(2) == null ? 1 : int.parse(m.group(2)!);
    for (var i = 0; i < count; i++) {
      added.add(start + i);
    }
  }
  return added;
}

/// Scans [source] (with comments and string literals masked while preserving
/// newlines) for non-directional Flutter layout calls.
List<_DirectionalHit> _findNonDirectionalCalls(String source) {
  final normalized = source.replaceAll('\r\n', '\n');
  final masked = _stripCommentsAndStrings(normalized);
  final lineStarts = <int>[0];
  for (var i = 0; i < masked.length; i++) {
    if (masked.codeUnitAt(i) == 0x0A) {
      lineStarts.add(i + 1);
    }
  }

  int lineOf(int offset) {
    var lo = 0;
    var hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  final hits = <_DirectionalHit>[];

  for (final rule in _directDirectionalRules) {
    for (final m in rule.pattern.allMatches(masked)) {
      hits.add(
        _DirectionalHit(lineOf(m.start), m.start, m.group(0)!, rule.suggestion),
      );
    }
  }

  for (final rule in _namedArgDirectionalRules) {
    for (final m in rule.pattern.allMatches(masked)) {
      // m.end is immediately after the opening `(`.
      _scanNamedArgs(masked, m.end, rule, lineOf, hits);
    }
  }

  hits.sort((a, b) {
    final byLine = a.line.compareTo(b.line);
    return byLine != 0 ? byLine : a.offset.compareTo(b.offset);
  });
  return hits;
}

void _scanNamedArgs(
  String text,
  int start,
  _NamedArgRule rule,
  int Function(int) lineOf,
  List<_DirectionalHit> hits,
) {
  var depth = 1;
  var expectArgName = true;
  var i = start;
  final n = text.length;

  while (i < n && depth > 0) {
    final c = text.codeUnitAt(i);
    if (depth == 1 && expectArgName) {
      if (_isWhitespace(c)) {
        i++;
        continue;
      }
      if (_isIdentStart(c)) {
        final identStart = i;
        i++;
        while (i < n && _isIdentPart(text.codeUnitAt(i))) {
          i++;
        }
        final ident = text.substring(identStart, i);
        var j = i;
        while (j < n && _isWhitespace(text.codeUnitAt(j))) {
          j++;
        }
        if (j < n && text.codeUnitAt(j) == 0x3A /* : */ ) {
          if (rule.forbiddenArgs.contains(ident)) {
            hits.add(
              _DirectionalHit(
                lineOf(identStart),
                identStart,
                '${rule.displayName}($ident: ...)',
                rule.suggestion,
              ),
            );
          }
          i = j + 1;
        }
        expectArgName = false;
        continue;
      }
      if (c != 0x2C /* , */ && c != 0x29 /* ) */ ) {
        expectArgName = false;
      }
    }

    if (c == 0x28 /* ( */ || c == 0x5B /* [ */ || c == 0x7B /* { */ ) {
      depth++;
    } else if (c == 0x29 /* ) */ || c == 0x5D /* ] */ || c == 0x7D /* } */ ) {
      depth--;
    } else if (depth == 1 && c == 0x2C /* , */ ) {
      expectArgName = true;
    }
    i++;
  }
}

bool _isWhitespace(int c) => c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;

bool _isIdentStart(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    c == 0x5F ||
    c == 0x24;

bool _isIdentPart(int c) => _isIdentStart(c) || (c >= 0x30 && c <= 0x39);

class _InterpFrame {
  _InterpFrame(this.quote, this.triple);
  final int quote;
  final bool triple;
  int braceDepth = 0;
}

/// Replaces comments and string literal bodies with spaces while keeping `\n`
/// intact so line numbers and offsets remain identical to [source].
/// Expressions inside `${...}` string interpolations are preserved.
String _stripCommentsAndStrings(String source) {
  final n = source.length;
  final out = StringBuffer();
  final interpStack = <_InterpFrame>[];
  var i = 0;

  void emitBlank(int c) => out.writeCharCode(c == 0x0A ? 0x0A : 0x20);

  void scanString(int quote, {required bool triple, required bool raw}) {
    while (i < n) {
      final c = source.codeUnitAt(i);
      if (triple) {
        if (c == quote &&
            i + 2 < n &&
            source.codeUnitAt(i + 1) == quote &&
            source.codeUnitAt(i + 2) == quote) {
          out.write('   ');
          i += 3;
          return;
        }
      } else {
        if (c == quote) {
          out.write(' ');
          i++;
          return;
        }
        if (c == 0x0A) {
          out.writeCharCode(0x0A);
          i++;
          return;
        }
      }
      if (!raw && c == 0x5C /* \ */ ) {
        out.write(' ');
        i++;
        if (i < n) {
          emitBlank(source.codeUnitAt(i));
          i++;
        }
        continue;
      }
      if (!raw &&
          c == 0x24 /* $ */ &&
          i + 1 < n &&
          source.codeUnitAt(i + 1) == 0x7B /* { */ ) {
        interpStack.add(_InterpFrame(quote, triple));
        out.write('  ');
        i += 2;
        return;
      }
      emitBlank(c);
      i++;
    }
  }

  while (i < n) {
    final c = source.codeUnitAt(i);

    // Comments.
    if (c == 0x2F /* / */ && i + 1 < n) {
      final next = source.codeUnitAt(i + 1);
      if (next == 0x2F /* // */ ) {
        out.write('  ');
        i += 2;
        while (i < n && source.codeUnitAt(i) != 0x0A) {
          out.write(' ');
          i++;
        }
        continue;
      }
      if (next == 0x2A /* * */ ) {
        var depth = 1;
        out.write('  ');
        i += 2;
        while (i < n && depth > 0) {
          final ch = source.codeUnitAt(i);
          if (ch == 0x2F && i + 1 < n && source.codeUnitAt(i + 1) == 0x2A) {
            depth++;
            out.write('  ');
            i += 2;
          } else if (ch == 0x2A &&
              i + 1 < n &&
              source.codeUnitAt(i + 1) == 0x2F) {
            depth--;
            out.write('  ');
            i += 2;
          } else {
            emitBlank(ch);
            i++;
          }
        }
        continue;
      }
    }

    // String interpolation braces.
    if (interpStack.isNotEmpty) {
      if (c == 0x7B /* { */ ) {
        interpStack.last.braceDepth++;
        out.writeCharCode(c);
        i++;
        continue;
      }
      if (c == 0x7D /* } */ ) {
        if (interpStack.last.braceDepth > 0) {
          interpStack.last.braceDepth--;
          out.writeCharCode(c);
          i++;
        } else {
          final frame = interpStack.removeLast();
          out.write(' ');
          i++;
          scanString(frame.quote, triple: frame.triple, raw: false);
        }
        continue;
      }
    }

    // Raw string literal: r'...' / r"..." / r'''...''' / r"""...""".
    if (c == 0x72 /* r */ &&
        (i == 0 || !_isIdentPart(source.codeUnitAt(i - 1))) &&
        i + 1 < n &&
        (source.codeUnitAt(i + 1) == 0x27 ||
            source.codeUnitAt(i + 1) == 0x22)) {
      final quote = source.codeUnitAt(i + 1);
      final triple =
          i + 3 < n &&
          source.codeUnitAt(i + 2) == quote &&
          source.codeUnitAt(i + 3) == quote;
      out.write(triple ? '    ' : '  ');
      i += triple ? 4 : 2;
      scanString(quote, triple: triple, raw: true);
      continue;
    }

    // Standard string literal.
    if (c == 0x27 /* ' */ || c == 0x22 /* " */ ) {
      final triple =
          i + 2 < n &&
          source.codeUnitAt(i + 1) == c &&
          source.codeUnitAt(i + 2) == c;
      out.write(triple ? '   ' : ' ');
      i += triple ? 3 : 1;
      scanString(c, triple: triple, raw: false);
      continue;
    }

    out.writeCharCode(c);
    i++;
  }

  return out.toString();
}

// --- [i]: package AGENTS.md holds standing rules only (#257) ----------------

final _issueRefPattern = RegExp(r'(?<![&#])#[1-9]\d*(?![A-Za-z0-9_])');

bool _isPackageAgentsPath(String relPath) {
  if (!relPath.endsWith('/AGENTS.md')) return false;
  for (final dir in skippedDirs) {
    if (relPath == dir || relPath.startsWith('$dir/')) return false;
  }
  for (final seg in relPath.split('/')) {
    if (seg.startsWith('.') || skippedNames.contains(seg)) return false;
  }
  return true;
}

Future<List<String>> _checkAgentsIssueRefs(
  Directory root, {
  String? base,
}) async {
  if (!_git(root, ['rev-parse', '--is-inside-work-tree']).ok) {
    return const [];
  }
  final mb = _resolveMergeBase(root, base: base);
  if (mb.commit == null) return const [];

  final diff = _git(root, [
    'diff',
    '--name-only',
    '--diff-filter=AM',
    '--no-renames',
    '-z',
    '${mb.commit}..HEAD',
  ]);
  if (!diff.ok) return const [];

  final prefix = _git(root, [
    'rev-parse',
    '--show-prefix',
  ]).out; // "coqui/" or ""
  final problems = <String>[];
  for (final gitPath in diff.raw.split('\u0000')) {
    if (gitPath.isEmpty) continue;
    if (prefix.isNotEmpty && !gitPath.startsWith(prefix)) continue;
    final relPath = prefix.isEmpty ? gitPath : gitPath.substring(prefix.length);
    if (!_isPackageAgentsPath(relPath)) continue;

    final patch = _git(root, [
      'diff',
      '--no-ext-diff',
      '-U0',
      '--no-renames',
      '${mb.commit}..HEAD',
      '--',
      relPath,
    ]);
    if (!patch.ok) continue;
    final addedLines = _addedLineNumbers(patch.raw);
    if (addedLines.isEmpty) continue;

    final show = _git(root, ['show', 'HEAD:$gitPath']);
    if (!show.ok) continue;

    final lines = show.raw.replaceAll('\r\n', '\n').split('\n');
    final sortedLines = addedLines.toList()..sort();
    for (final lineNo in sortedLines) {
      if (lineNo < 1 || lineNo > lines.length) continue;
      final match = _issueRefPattern.firstMatch(lines[lineNo - 1]);
      if (match == null) continue;
      problems.add(
        '$relPath:$lineNo: [i] issue reference ${match.group(0)} in '
        'package AGENTS.md: AGENTS.md holds standing rules only '
        '(put ticket notes in the PR body and issue)',
      );
    }
  }
  return problems;
}

// --- Git helpers -------------------------------------------------------------

class _MergeBase {
  const _MergeBase({this.commit, this.error});
  final String? commit;
  final String? error;
}

_MergeBase _resolveMergeBase(Directory root, {String? base}) {
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
    return const _MergeBase(
      error: 'neither origin/main nor main exists to compare with',
    );
  }
  final mergeBase = _git(root, ['merge-base', 'HEAD', baseRef]);
  if (!mergeBase.ok) {
    return _MergeBase(error: 'no common ancestor with $baseRef');
  }
  return _MergeBase(commit: mergeBase.out);
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
