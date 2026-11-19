// What is drawn over the picture during a story lets every touch through to what is under it, as the old page does
// (index.html: `#bub{pointer-events:none}`, `#fin` at the end of a story `pointer-events:none`, `#mic[data-s=ok]`
// `pointer-events:none`). A thing that stands under a speech bubble can be touched.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_bubble.dart';
import 'package:feature_story/src/screen/story_end.dart';
import 'package:feature_story/src/screen/story_mic.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/screen_harness.dart';

/// [over] drawn over a full-size widget that counts the touches that reach it.
Widget _over(Widget over, List<int> touches) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: 300,
      height: 400,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => touches.add(1),
              child: const ColoredBox(color: Color(0xFF123456)),
            ),
          ),
          over,
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'a touch on a speech bubble goes through to the picture under it',
    (tester) async {
      final touches = <int>[];
      await tester.pumpWidget(
        _over(
          Positioned.fill(
            child: StoryBubbleLayer(
              visible: true,
              kind: BubbleKind.words,
              text: 'Está en la casa grande.',
              estate: '',
              placementFor: (_) => const BubblePlacement(
                left: 150,
                top: 200,
                mode: BubbleSideMode.above,
              ),
            ),
          ),
          touches,
        ),
      );
      final bubble = find.byType(StoryBubbleBody);
      expect(bubble, findsOneWidget);
      await tester.tapAt(tester.getCenter(bubble));
      expect(touches, [1]);
    },
  );

  testWidgets(
    'on the real El frente, a touch on abuela\'s bubble "Está en la casa grande." reaches the picture (donde-esta-el-pajaro)',
    (tester) async {
      final s = await openScreen(
        tester,
        id: 'donde-esta-el-pajaro',
        scenes: registryScenes,
      );
      await tester.tap(find.byType(LessonStartButton));
      await s.answerUntil(
        () => s.runner.bubText == 'Está en la casa grande.',
        what: 'abuela\'s bubble',
      );
      expect(s.runner.view.bubbleWho, 'abuela');
      final bubble = find.byType(StoryBubbleBody);
      expect(bubble, findsOneWidget);
      final pictureRect = tester.getRect(find.byType(PixelView));
      final at = tester.getCenter(bubble);
      expect(pictureRect.contains(at), isTrue);
      final hit = tester.hitTestOnBinding(at);
      expect(
        [for (final e in hit.path) e.target.runtimeType.toString()],
        contains('RenderPixelView'),
        reason: 'a finger on the bubble meets the picture, not the bubble',
      );
    },
  );

  testWidgets(
    'the corner chip of ?perf=1 takes no touch (it is not in the old page)',
    (tester) async {
      final touches = <int>[];
      await tester.pumpWidget(
        _over(
          const Positioned(
            left: 100,
            top: 100,
            child: StoryPerfChip(bakeMs: 3),
          ),
          touches,
        ),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('story-perf-chip'))),
      );
      expect(touches, [1]);
    },
  );

  testWidgets(
    'the end title takes no touch (index.html: #fin pointer-events:none)',
    (tester) async {
      final touches = <int>[];
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => touches.add(1),
                ),
              ),
              const Positioned.fill(child: StoryEndTitle(title: 'La lluvia')),
            ],
          ),
        ),
      );
      final title = find.text('La lluvia');
      expect(title, findsOneWidget);
      await tester.tapAt(tester.getCenter(title));
      expect(touches, [1]);
    },
  );

  testWidgets(
    'the mic: the tick (index.html #mic[data-s=ok]: pointer-events:none) takes no touch; a mic that waits for a tap (ready) does',
    (tester) async {
      final touches = <int>[], taps = <int>[];
      Widget mic(StoryMicState state) => _over(
        Center(
          child: StoryMicButton(state: state, onPressed: () => taps.add(1)),
        ),
        touches,
      );
      await tester.pumpWidget(mic(StoryMicState.ok));
      await tester.tapAt(tester.getCenter(find.byType(StoryMicButton)));
      expect(touches, [1]);
      expect(taps, isEmpty);
      touches.clear();
      await tester.pumpWidget(mic(StoryMicState.ready));
      await tester.tapAt(tester.getCenter(find.byType(StoryMicButton)));
      expect(touches, isEmpty);
      expect(taps, [1]);
    },
  );
}
