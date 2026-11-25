import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

class _LegacyCatalog implements CourseCatalog {
  _LegacyCatalog(this._stories);

  final Map<String, StoryMeta> _stories;

  @override
  StoryMeta? meta(String id) => _stories[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MinAppCatalog extends _LegacyCatalog implements MinAppCatalog {
  _MinAppCatalog(super.stories, this.minApp);

  @override
  final int? minApp;
}

class _BasicAppInfo implements AppInfo {
  const _BasicAppInfo(this.build);

  @override
  final String build;

  @override
  bool get isWeb => false;

  @override
  bool get isIos => false;

  @override
  bool get isAndroid => false;

  @override
  bool get installed => false;

  @override
  bool get callsAllowed => false;
}

class _ExplicitAppInfo extends _BasicAppInfo implements AppNumberInfo {
  const _ExplicitAppInfo(super.build, this.appNumber);

  @override
  final int appNumber;
}

void main() {
  group('StoryMeta.minApp', () {
    test('constructor and toJson omit minApp when null', () {
      final meta = StoryMeta(id: 'el-sol', title: 'El sol', minutes: 4);

      expect(meta.minApp, isNull);
      final json = meta.toJson();
      expect(json, {'t': 'El sol', 'min': 4});
      expect(json.containsKey('minApp'), isFalse);
    });

    test('constructor and toJson include minApp when provided', () {
      final meta = StoryMeta(
        id: 'el-sol',
        title: 'El sol',
        minutes: 4,
        minApp: 17,
      );

      expect(meta.minApp, 17);
      expect(meta.toJson(), {'t': 'El sol', 'min': 4, 'minApp': 17});
    });

    test('fromJson handles missing, null, int, and double minApp', () {
      final missing = StoryMeta.fromJson('s1', {'t': 'Uno', 'min': 3});
      expect(missing.minApp, isNull);

      final explicitNull = StoryMeta.fromJson('s2', {
        't': 'Dos',
        'min': 3,
        'minApp': null,
      });
      expect(explicitNull.minApp, isNull);

      final intVal = StoryMeta.fromJson('s3', {
        't': 'Tres',
        'min': 5,
        'minApp': 17,
      });
      expect(intVal.minApp, 17);

      final doubleVal = StoryMeta.fromJson('s4', {
        't': 'Cuatro',
        'min': 6,
        'minApp': 17.0,
      });
      expect(doubleVal.minApp, 17);
    });

    test(
      'JSON encode/decode round-trip preserves minApp presence and absence',
      () {
        final withoutMin = StoryMeta(id: 'a', title: 'A', minutes: 2);
        final decodedWithout = StoryMeta.fromJson(
          'a',
          jsonDecode(jsonEncode(withoutMin.toJson())) as Map<String, dynamic>,
        );
        expect(decodedWithout.title, 'A');
        expect(decodedWithout.minutes, 2);
        expect(decodedWithout.minApp, isNull);
        expect(decodedWithout.toJson().containsKey('minApp'), isFalse);

        final withMin = StoryMeta(id: 'b', title: 'B', minutes: 5, minApp: 17);
        final decodedWith = StoryMeta.fromJson(
          'b',
          jsonDecode(jsonEncode(withMin.toJson())) as Map<String, dynamic>,
        );
        expect(decodedWith.title, 'B');
        expect(decodedWith.minutes, 5);
        expect(decodedWith.minApp, 17);
        expect(decodedWith.toJson(), {'t': 'B', 'min': 5, 'minApp': 17});
      },
    );
  });

  group('MinAppCatalog and CourseMinApp', () {
    final stories = <String, StoryMeta>{
      'plain': StoryMeta(id: 'plain', title: 'Plain', minutes: 3),
      'low': StoryMeta(id: 'low', title: 'Low', minutes: 3, minApp: 12),
      'same': StoryMeta(id: 'same', title: 'Same', minutes: 3, minApp: 16),
      'high': StoryMeta(id: 'high', title: 'High', minutes: 3, minApp: 20),
    };

    test('legacy catalog defaults minApp to null and uses story minApp', () {
      final course = _LegacyCatalog(stories);

      expect(course.minApp, isNull);
      expect(course.minAppFor('plain'), isNull);
      expect(course.minAppFor('low'), 12);
      expect(course.minAppFor('high'), 20);
      expect(course.minAppFor('unknown'), isNull);
    });

    test('MinAppCatalog with null minApp behaves like any-app course', () {
      final course = _MinAppCatalog(stories, null);

      expect(course.minApp, isNull);
      expect(course.minAppFor('plain'), isNull);
      expect(course.minAppFor('low'), 12);
      expect(course.minAppFor('high'), 20);
      expect(course.minAppFor('unknown'), isNull);
    });

    test('MinAppCatalog with minApp 16 returns higher of course and story', () {
      final course = _MinAppCatalog(stories, 16);

      expect(course.minApp, 16);
      expect(course.minAppFor('plain'), 16);
      expect(course.minAppFor('low'), 16);
      expect(course.minAppFor('same'), 16);
      expect(course.minAppFor('high'), 20);
      expect(course.minAppFor('unknown'), 16);
    });
  });

  group('AppNumberInfo and AppInfoNumber', () {
    test('parses numeric build strings', () {
      expect(const _BasicAppInfo('16').appNumber, 16);
      expect(const _BasicAppInfo('1').appNumber, 1);
      expect(const _BasicAppInfo('0').appNumber, 0);
      expect(const _BasicAppInfo('007').appNumber, 7);
      expect(const _BasicAppInfo('  42  ').appNumber, 42);
    });

    test('parses leading numeric prefix with suffixes', () {
      expect(const _BasicAppInfo('16+2').appNumber, 16);
      expect(const _BasicAppInfo('16-rc1').appNumber, 16);
      expect(const _BasicAppInfo('16.3.1').appNumber, 16);
    });

    test(
      'returns 0 for non-numeric, empty, negative, or letter-prefixed builds',
      () {
        expect(const _BasicAppInfo('dev').appNumber, 0);
        expect(const _BasicAppInfo('fake').appNumber, 0);
        expect(const _BasicAppInfo('').appNumber, 0);
        expect(const _BasicAppInfo('   ').appNumber, 0);
        expect(const _BasicAppInfo('-5').appNumber, 0);
        expect(const _BasicAppInfo('v16').appNumber, 0);
      },
    );

    test('AppNumberInfo overrides build parsing and clamps negatives to 0', () {
      const AppInfo dev20 = _ExplicitAppInfo('dev', 20);
      const AppInfo buildZero = _ExplicitAppInfo('16', 0);
      const AppInfo buildNeg = _ExplicitAppInfo('16', -3);

      expect(dev20.appNumber, 20);
      expect(buildZero.appNumber, 0);
      expect(buildNeg.appNumber, 0);
      expect(buildNeg.supportsMinApp(17), isTrue);
    });

    test(
      'supportsMinApp enforces numbered builds and allows unnumbered/null',
      () {
        const app16 = _BasicAppInfo('16');
        expect(app16.supportsMinApp(null), isTrue);
        expect(app16.supportsMinApp(15), isTrue);
        expect(app16.supportsMinApp(16), isTrue);
        expect(app16.supportsMinApp(17), isFalse);
        expect(app16.supportsMinApp(0), isTrue);

        for (final unnumbered in const <AppInfo>[
          _BasicAppInfo('dev'),
          _BasicAppInfo('fake'),
          _BasicAppInfo(''),
          _ExplicitAppInfo('16', 0),
        ]) {
          expect(unnumbered.supportsMinApp(null), isTrue);
          expect(unnumbered.supportsMinApp(17), isTrue);
          expect(unnumbered.supportsMinApp(999), isTrue);
        }

        const explicit20 = _ExplicitAppInfo('dev', 20);
        expect(explicit20.supportsMinApp(20), isTrue);
        expect(explicit20.supportsMinApp(21), isFalse);
      },
    );

    test(
      'combined course.minAppFor and info.supportsMinApp gating scenarios',
      () {
        final course = _MinAppCatalog({
          'base': StoryMeta(id: 'base', title: 'Base', minutes: 3),
          'newer': StoryMeta(
            id: 'newer',
            title: 'Newer',
            minutes: 4,
            minApp: 20,
          ),
        }, 16);

        const oldApp = _BasicAppInfo('15');
        const midApp = _BasicAppInfo('16');
        const newApp = _BasicAppInfo('20');
        const devApp = _BasicAppInfo('dev');

        // Course minApp (16) blocks app 15 even when story has no minApp.
        expect(oldApp.supportsMinApp(course.minAppFor('base')), isFalse);
        expect(midApp.supportsMinApp(course.minAppFor('base')), isTrue);

        // Story minApp (20) blocks app 16 even when course minApp is 16.
        expect(midApp.supportsMinApp(course.minAppFor('newer')), isFalse);
        expect(newApp.supportsMinApp(course.minAppFor('newer')), isTrue);

        // Dev build passes all minApp checks.
        expect(devApp.supportsMinApp(course.minAppFor('base')), isTrue);
        expect(devApp.supportsMinApp(course.minAppFor('newer')), isTrue);
      },
    );
  });
}
