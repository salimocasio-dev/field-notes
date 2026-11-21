// A story whose scene is not converted yet (every story from las-flores on, at the patio and the scenes after it): the
// screen says so, in the middle of the lesson frame, with one button back to the map, and shows nothing else but the X.
// Any other failure to open a story keeps the lesson frame and its X, as before.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/screen_harness.dart';

/// The sample course, and the real `las-flores` of historia/ (a story at the patio, which is not converted yet; El balcón's
/// el-jugo was this test's story until order 30b converted it, La sala's la-familia until order 31b).
class _WithFlores extends EditedCourse {
  _WithFlores() : super((id, f) {});

  @override
  Future<Map<String, dynamic>> story(String id) => id == 'las-flores'
      ? Future.value(
          jsonDecode(
            File(
              '${Directory.current.path}/../../../../historia/cuentos/las-flores.json',
            ).readAsStringSync(),
          ) as Map<String, dynamic>,
        )
      : super.story(id);
}

const _line = 'This story is not in the new app yet.';
const _button = 'Back to the map';

void main() {
  testWidgets(
    'las-flores on the real registry: the line and one button in the middle of the frame, and nothing else but the X',
    (tester) async {
      final s = await openScreen(
        tester,
        id: 'las-flores',
        course: _WithFlores(),
        scenes: registryScenes,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(_line), findsOneWidget);
      expect(find.text(_button), findsOneWidget);
      expect(find.byType(LessonButton), findsOneWidget);
      // the frame and its X, no start disc, no dashes, no picture, no sound button, no caption
      expect(find.byType(LessonFrame), findsOneWidget);
      expect(find.byType(LessonCloseButton), findsOneWidget);
      expect(find.byType(LessonStartButton), findsNothing);
      expect(find.byType(LessonProgressDashes), findsNothing);
      expect(find.byType(PixelView), findsNothing);
      final frame = tester.widget<LessonFrame>(find.byType(LessonFrame));
      expect(frame.showSound, isFalse);
      expect(frame.picture, isNull);
      expect(frame.caption, isNull);
      expect(frame.bottom, isEmpty);
      // the only words on the screen are the line and the button's label (the frame's empty caption is a Text with no words)
      expect(
        [
          for (final e in find.byType(Text).evaluate())
            if ((e.widget as Text).data!.isNotEmpty) (e.widget as Text).data,
        ],
        [_line, _button],
      );
      // the line and the button are centred in the frame under the top bar, one over the other
      final screen = tester.getRect(find.byType(LessonFrame));
      final line = tester.getRect(find.text(_line));
      final button = tester.getRect(find.byType(LessonButton));
      expect(line.bottom, lessThan(button.top));
      final middle = (line.top + button.bottom) / 2;
      final under = CoquiMetrics.lessonTopBar;
      expect(middle, closeTo((screen.top + under + screen.bottom) / 2, 1));
      expect(line.center.dx, closeTo(screen.center.dx, 0.01));
      expect(button.center.dx, closeTo(screen.center.dx, 0.01));
      expect(s.nav.backs, 0);
    },
  );

  testWidgets('the button closes the lesson as the X does', (tester) async {
    final viaButton = await openScreen(
      tester,
      id: 'las-flores',
      course: _WithFlores(),
      scenes: registryScenes,
    );
    await tester.tap(find.text(_button));
    await tester.pump();
    expect(viaButton.nav.backs, 1);
    expect(viaButton.nav.routes, isEmpty); // back(), not go()
  });

  testWidgets('the X still closes it', (tester) async {
    final s = await openScreen(
      tester,
      id: 'las-flores',
      course: _WithFlores(),
      scenes: registryScenes,
    );
    await tester.tap(find.byType(LessonCloseButton));
    await tester.pump();
    expect(s.nav.backs, 1);
  });

  testWidgets(
    'a scene that is not converted, found at the scene factory of any story: the same line and button',
    (tester) async {
      final s = await openScreen(
        tester,
        id: 'la-lluvia',
        scenes: (id, rng) => registryScenes('patio', rng),
      );
      expect(find.text(_line), findsOneWidget);
      await tester.tap(find.text(_button));
      await tester.pump();
      expect(s.nav.backs, 1);
    },
  );

  testWidgets(
    'any other failure to open a story keeps what it did: a scene that fails in another way leaves the lesson frame and its X, nothing else, and the error is reported',
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
      expect(find.byType(LessonFrame), findsOneWidget);
      expect(find.byType(LessonCloseButton), findsOneWidget);
      expect(find.byType(LessonStartButton), findsNothing);
      expect(find.text(_line), findsNothing);
      expect(find.text(_button), findsNothing);
      expect(errors.single.exception, isA<StateError>());
    },
  );

  testWidgets(
    'a story the course does not have: the same, the lesson frame and its X, and the error is reported',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final old = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = old);
      await openScreen(tester, id: 'no-hay-tal-cuento');
      FlutterError.onError =
          old; // before any expect: a failure is the framework's to hear
      expect(find.byType(LessonFrame), findsOneWidget);
      expect(find.byType(LessonCloseButton), findsOneWidget);
      expect(find.text(_line), findsNothing);
      expect(find.text(_button), findsNothing);
      expect(errors.single.exception, isA<StateError>());
    },
  );
}
