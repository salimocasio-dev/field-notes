// A story whose scene is not converted yet: the screen says so, centred on
// NocheColors.lessonGround, with one NochePrimaryButton back to the map, and
// shows nothing else in the header but the close X. Any other failure to open
// a story keeps the lessonGround header and its X, as before.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/screen/story_not_ready.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/screen_harness.dart';
import 'support/test_scene.dart';

const _line = 'This story is not in the new app yet.';
const _button = 'Back to the map';

void main() {
  testWidgets(
    'a story at a scene not converted, on the registry: the line and one button centred on lessonGround, and nothing else but the X',
    (tester) async {
      final s = await openScreen(
        tester,
        id: testStoryId,
        course: WithTestScene(),
        scenes: scenesWithTestScene,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(StoryNotReady), findsOneWidget);
      expect(find.text(_line), findsOneWidget);
      expect(find.text(_button), findsOneWidget);
      expect(find.byType(NochePrimaryButton), findsOneWidget);
      expect(find.byType(StoryHeader), findsOneWidget);
      expect(find.byType(StoryCloseButton), findsOneWidget);
      expect(find.byType(NochePlayDisc), findsNothing);
      expect(find.byType(NocheDashes), findsNothing);
      expect(find.byType(StoryTxtToggle), findsNothing);
      expect(find.byType(PixelView), findsNothing);
      // the only words on the screen are the line and the button's label
      expect(
        [
          for (final e in find.byType(Text).evaluate())
            if ((e.widget as Text).data != null &&
                (e.widget as Text).data!.isNotEmpty)
              (e.widget as Text).data,
        ],
        [_line, _button],
      );
      // the line and the button are centred under the 64-high header
      final screen = tester.getRect(find.byType(StoryNotReady));
      final line = tester.getRect(find.text(_line));
      final button = tester.getRect(find.byType(NochePrimaryButton));
      expect(line.bottom, lessThan(button.top));
      final middle = (line.top + button.bottom) / 2;
      expect(
        middle,
        closeTo((screen.top + StoryHeader.height + screen.bottom) / 2, 1),
      );
      expect(line.center.dx, closeTo(screen.center.dx, 0.5));
      expect(button.center.dx, closeTo(screen.center.dx, 0.5));
      expect(s.nav.backs, 0);
    },
  );

  testWidgets('the button closes the lesson as the X does', (tester) async {
    final viaButton = await openScreen(
      tester,
      id: testStoryId,
      course: WithTestScene(),
      scenes: scenesWithTestScene,
    );
    await tester.tap(find.text(_button));
    await tester.pump();
    expect(viaButton.nav.backs, 1);
    expect(viaButton.nav.routes, isEmpty); // back(), not go()
  });

  testWidgets('the X still closes it', (tester) async {
    final s = await openScreen(
      tester,
      id: testStoryId,
      course: WithTestScene(),
      scenes: scenesWithTestScene,
    );
    await tester.tap(find.byType(StoryCloseButton));
    await tester.pump();
    expect(s.nav.backs, 1);
  });

  testWidgets(
    'a scene that is not converted, found at the scene factory of any story: the same line and button',
    (tester) async {
      final s = await openScreen(
        tester,
        id: 'la-lluvia',
        scenes: (id, rng) => scenesWithTestScene(testSceneId, rng),
      );
      expect(find.text(_line), findsOneWidget);
      await tester.tap(find.text(_button));
      await tester.pump();
      expect(s.nav.backs, 1);
    },
  );

  testWidgets(
    'any other failure to open a story keeps the lesson header and its X, nothing else, and reports the error',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final old = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = old);
      await openScreen(
        tester,
        id: 'la-lluvia',
        scenes: (id, rng) => throw StateError('not a scene with a set'),
      );
      FlutterError.onError =
          old; // before any expect: a failure is the framework's to hear
      expect(find.byType(StoryHeader), findsOneWidget);
      expect(find.byType(StoryCloseButton), findsOneWidget);
      expect(find.byType(NochePlayDisc), findsNothing);
      expect(find.text(_line), findsNothing);
      expect(find.text(_button), findsNothing);
      expect(errors.single.exception, isA<StateError>());
    },
  );

  testWidgets(
    'a story the course does not have: the same, the lesson header and its X, and the error is reported',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final old = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = old);
      await openScreen(tester, id: 'no-hay-tal-cuento');
      FlutterError.onError =
          old; // before any expect: a failure is the framework's to hear
      expect(find.byType(StoryHeader), findsOneWidget);
      expect(find.byType(StoryCloseButton), findsOneWidget);
      expect(find.text(_line), findsNothing);
      expect(find.text(_button), findsNothing);
      expect(errors.single.exception, isA<StateError>());
    },
  );
}
