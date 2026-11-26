// Pre-flight story compatibility checks (#62): before a story starts, every act
// it names across `beats` and `final` must exist on its scene and the app's
// number must satisfy `course.minAppFor(storyId)`. Otherwise the story does not
// start and shows "Update the app to play this story" with a back button,
// throwing nothing.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/story_check.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/stand_in_scene.dart';
import 'support/screen_harness.dart';

const _updateLine = 'Update the app to play this story';
const _backLabel = 'Back to the map';

Future<void> _noopAct(Map<String, dynamic> o) async {}

StoryScene _strictStoryScene(Map<String, Act> acts) => StoryScene(
  scene: StandInScene(
    lenient: false,
    acts: acts,
    cam: {
      'wide': [0, 0, 196, 216],
      'casa': [0, 0, 196, 216],
      'puerta': [0, 0, 196, 216],
    },
  ),
  frame: SceneFrameSetup(
    engine: ({required still}) => PpEngine(w: 240, h: 216, s: 26, still: still),
    shadows: (W) => const [],
  ),
);

/// Sample course that supports overriding course-wide and per-story `minApp`
/// as well as editing a story JSON.
class _MinAppCourse extends EditedCourse implements MinAppCatalog {
  _MinAppCourse({
    this.courseMinApp,
    this.storyMinApps = const {},
    void Function(String id, Map<String, dynamic> file)? edit,
  }) : super(edit ?? ((_, _) {}));

  final int? courseMinApp;
  final Map<String, int?> storyMinApps;

  @override
  int? get minApp => courseMinApp;

  @override
  StoryMeta? meta(String id) {
    final base = super.meta(id);
    if (base == null) return null;
    if (!storyMinApps.containsKey(id)) return base;
    return StoryMeta(
      id: base.id,
      title: base.title,
      minutes: base.minutes,
      minApp: storyMinApps[id],
    );
  }
}

void main() {
  group('storyNamedActs and missingSceneActs', () {
    test('collects act steps and decide do acts across beats and final', () {
      final story = <String, dynamic>{
        'beats': [
          'line_one',
          {'act': 'abrir'},
          {
            'if': 'ok',
            'then': [
              {'act': 'entrar'},
            ],
            'else': [
              {'act': 'salir'},
            ],
          },
          {
            'ask': 'puerta',
            'lead': [
              {'act': 'asomar'},
            ],
            'after': [
              {'act': 'tocar'},
            ],
            'then': [
              {'act': 'abrir'}, // duplicate ignored
            ],
          },
          {
            'elige': 'say',
            'options': ['si', 'no'],
            'lead': [
              {'act': 'mirar'},
            ],
            'si': [
              {'act': 'saltar'},
            ],
            'no': [
              {'act': 'sentar'},
            ],
          },
          {
            'decide': 'tap',
            'options': ['a', 'b'],
            'do': 'hacer_decide',
            'lead': [
              {'act': 'senal'},
            ],
            'wrong': [
              {'act': 'fallar'},
            ],
            'right': [
              {'act': 'celebrar'},
            ],
            'gratis': {
              'pista': [
                {'act': 'dar_pista'},
              ],
            },
          },
        ],
        'final': [
          {
            'if': 'win',
            'then': [
              {'act': 'despedir'},
            ],
            'else': [
              {
                'decide': 'tap',
                'options': ['x', 'y'],
                'do': 'final_do',
              },
            ],
          },
        ],
      };

      expect(storyNamedActs(story), [
        'abrir',
        'entrar',
        'salir',
        'asomar',
        'tocar',
        'mirar',
        'saltar',
        'sentar',
        'hacer_decide',
        'senal',
        'fallar',
        'celebrar',
        'dar_pista',
        'despedir',
        'final_do',
      ]);

      final partial = StandInScene(
        lenient: false,
        acts: {'abrir': _noopAct, 'hacer_decide': _noopAct},
      );
      expect(missingSceneActs(story, partial), [
        'entrar',
        'salir',
        'asomar',
        'tocar',
        'mirar',
        'saltar',
        'sentar',
        'senal',
        'fallar',
        'celebrar',
        'dar_pista',
        'despedir',
        'final_do',
      ]);

      final complete = StandInScene(
        lenient: false,
        acts: {for (final name in storyNamedActs(story)) name: _noopAct},
      );
      expect(missingSceneActs(story, complete), isEmpty);
    });

    test('storyNeedsAppUpdate checks minApp and missing scene acts', () async {
      final course = _MinAppCourse(
        courseMinApp: 16,
        storyMinApps: {'la-lluvia': 20},
      );
      await course.load();
      final scene = StandInScene(lenient: false, acts: {'existe': _noopAct});
      final okStory = <String, dynamic>{
        'beats': [
          {'act': 'existe'},
        ],
      };
      final badStory = <String, dynamic>{
        'beats': [
          {'act': 'no_existe'},
        ],
      };

      expect(
        storyNeedsAppUpdate(
          course: course,
          storyId: 'la-lluvia',
          info: FakeAppInfo(build: '19'),
          story: okStory,
          scene: scene,
        ),
        isTrue,
      );
      expect(
        storyNeedsAppUpdate(
          course: course,
          storyId: 'la-lluvia',
          info: FakeAppInfo(build: '20'),
          story: okStory,
          scene: scene,
        ),
        isFalse,
      );
      expect(
        storyNeedsAppUpdate(
          course: course,
          storyId: 'la-lluvia',
          info: FakeAppInfo(build: '20'),
          story: badStory,
          scene: scene,
        ),
        isTrue,
      );
      // Unnumbered dev builds satisfy minApp, but missing acts still block.
      expect(
        storyNeedsAppUpdate(
          course: course,
          storyId: 'la-lluvia',
          info: FakeAppInfo(build: 'dev'),
          story: okStory,
          scene: scene,
        ),
        isFalse,
      );
      expect(
        storyNeedsAppUpdate(
          course: course,
          storyId: 'la-lluvia',
          info: FakeAppInfo(build: 'dev'),
          story: badStory,
          scene: scene,
        ),
        isTrue,
      );
    });
  });

  group('StoryScreen pre-flight compatibility screen', () {
    testWidgets(
      'a story naming an act the scene does not have shows the update screen and throws nothing',
      (tester) async {
        final errors = <FlutterErrorDetails>[];
        final oldOnError = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = oldOnError);

        final course = EditedCourse((id, f) {
          if (id == 'la-lluvia') {
            f['beats'] = [
              {'act': 'acto_que_no_existe'},
            ];
            f['final'] = const <Object?>[];
          }
        });

        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          course: course,
          scenes: (_, _) async => _strictStoryScene({'otro_acto': _noopAct}),
        );

        FlutterError.onError = oldOnError;
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty);
        expect(s.opened, isFalse);
        expect(find.text(_updateLine), findsOneWidget);
        expect(find.text(_backLabel), findsOneWidget);
        expect(find.byType(NochePrimaryButton), findsOneWidget);
        expect(find.byType(StoryHeader), findsOneWidget);
        expect(find.byType(StoryCloseButton), findsOneWidget);
        expect(find.byType(NochePlayDisc), findsNothing);
        expect(find.byType(NocheDashes), findsNothing);
        expect(find.byType(StoryTxtToggle), findsNothing);
        expect(find.byType(PixelView), findsNothing);

        await tester.tap(find.text(_backLabel));
        await tester.pump();
        expect(s.nav.backs, 1);
        expect(s.nav.routes, isEmpty);
      },
    );

    testWidgets(
      'a story naming a missing act on a real scene (frente) shows the update screen and throws nothing',
      (tester) async {
        final errors = <FlutterErrorDetails>[];
        final oldOnError = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = oldOnError);

        final course = EditedCourse((id, f) {
          if (id == 'la-lluvia') {
            f['final'] = [
              ...(f['final'] as List? ?? const []),
              {'act': 'volar_a_la_luna'},
            ];
          }
        });

        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          course: course,
          scenes: registryScenes,
        );

        FlutterError.onError = oldOnError;
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty);
        expect(s.opened, isFalse);
        expect(find.text(_updateLine), findsOneWidget);
        expect(find.text(_backLabel), findsOneWidget);
        expect(find.byType(NochePlayDisc), findsNothing);

        await tester.tap(find.byType(StoryCloseButton));
        await tester.pump();
        expect(s.nav.backs, 1);
      },
    );

    testWidgets(
      'a story with a missing decide["do"] act shows the update screen without starting',
      (tester) async {
        final errors = <FlutterErrorDetails>[];
        final oldOnError = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = oldOnError);

        final course = EditedCourse((id, f) {
          if (id == 'la-lluvia') {
            f['beats'] = [
              {
                'decide': 'tap',
                'options': ['puerta', 'ventana'],
                'do': 'accion_nueva',
              },
            ];
            f['final'] = const <Object?>[];
          }
        });

        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          course: course,
          scenes: (_, _) async => _strictStoryScene({}),
        );

        FlutterError.onError = oldOnError;
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty);
        expect(s.opened, isFalse);
        expect(find.text(_updateLine), findsOneWidget);
        expect(find.text(_backLabel), findsOneWidget);
      },
    );

    testWidgets(
      'a story whose minApp is above the app number shows the update screen without loading the scene',
      (tester) async {
        final errors = <FlutterErrorDetails>[];
        final oldOnError = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = oldOnError);

        var sceneCalls = 0;
        final course = _MinAppCourse(storyMinApps: {'la-lluvia': 20});

        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          course: course,
          info: FakeAppInfo(build: '16'),
          scenes: (_, _) async {
            sceneCalls++;
            throw StateError('scene should not be requested');
          },
        );

        FlutterError.onError = oldOnError;
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty);
        expect(sceneCalls, 0);
        expect(s.opened, isFalse);
        expect(find.text(_updateLine), findsOneWidget);
        expect(find.text(_backLabel), findsOneWidget);
        expect(find.byType(NochePlayDisc), findsNothing);

        await tester.tap(find.text(_backLabel));
        await tester.pump();
        expect(s.nav.backs, 1);
      },
    );

    testWidgets(
      'a course-wide minApp above the app number shows the update screen and throws nothing',
      (tester) async {
        final errors = <FlutterErrorDetails>[];
        final oldOnError = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = oldOnError);

        final course = _MinAppCourse(courseMinApp: 25);

        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          course: course,
          info: FakeAppInfo(build: '24'),
        );

        FlutterError.onError = oldOnError;
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty);
        expect(s.opened, isFalse);
        expect(find.text(_updateLine), findsOneWidget);
        expect(find.text(_backLabel), findsOneWidget);
      },
    );

    testWidgets(
      'a story whose minApp is met and whose acts exist opens normally',
      (tester) async {
        final course = _MinAppCourse(
          courseMinApp: 16,
          storyMinApps: {'la-lluvia': 20},
          edit: (id, f) {
            if (id == 'la-lluvia') {
              f['beats'] = [
                {'act': 'hola'},
              ];
              f['final'] = const <Object?>[];
            }
          },
        );

        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          course: course,
          info: FakeAppInfo(build: '20'),
          scenes: (_, _) async => _strictStoryScene({'hola': _noopAct}),
        );

        expect(tester.takeException(), isNull);
        expect(s.opened, isTrue);
        expect(find.text(_updateLine), findsNothing);
        expect(find.byType(NochePlayDisc), findsOneWidget);
      },
    );
  });
}
