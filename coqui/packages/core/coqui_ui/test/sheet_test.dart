import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The shell: a tab page and, over it, the tab bar, both one page of the root navigator.
class _Shell extends StatelessWidget {
  const _Shell({required this.onTab, required this.onOpen});
  final void Function(String id) onTab;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ColoredBox(
          color: CoquiColors.bg,
          child: Center(
            child: GestureDetector(
              onTap: onOpen,
              child: const Text('open the sheet'),
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: CoquiTabBar(selectedId: 'map', onTap: onTab),
      ),
    ],
  );
}

Widget _app({
  required void Function(String id) onTab,
  required VoidCallback onOpen,
  GlobalKey<NavigatorState>? navigatorKey,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: coquiTheme(),
  navigatorKey: navigatorKey,
  home: Scaffold(
    body: _Shell(onTab: onTab, onOpen: onOpen),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
}

/// A sheet over a context of the app: a plain one with a title, a body and a footer button.
CoquiSheet _sheet(BuildContext context, VoidCallback close) => CoquiSheet(
  title: 'A title',
  footer: CoquiButton(label: 'Done', onPressed: close),
  child: const SizedBox(height: 300, child: Text('the body')),
);

void main() {
  group('showCoquiSheet', () {
    late List<String> tabs;
    late Future<void>? future;
    var closed = false;

    Future<void> open(
      WidgetTester tester, {
      bool modal = false,
      CoquiSheet Function(BuildContext, VoidCallback) builder = _sheet,
    }) async {
      closed = false;
      future = showCoquiSheet(
        tester.element(find.byType(Scaffold).first),
        builder: builder,
        modal: modal,
      )..then((_) => closed = true);
      await tester.pumpAndSettle();
    }

    Future<void> pumpShell(WidgetTester tester) async {
      _phone(tester);
      tabs = [];
      future = null;
      await tester.pumpWidget(_app(onTab: tabs.add, onOpen: () {}));
    }

    testWidgets('the sheet and its scrim cover the shell\'s tab bar', (
      tester,
    ) async {
      await pumpShell(tester);
      expect(find.byType(CoquiSheet), findsNothing);
      await open(tester);
      expect(find.byType(CoquiSheet), findsOneWidget);
      expect(find.text('A title'), findsOneWidget);
      expect(find.text('the body'), findsOneWidget);

      // The scrim is the whole screen, rgba(0,0,0,.35), over the page and the tab bar.
      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier).last,
      );
      expect(barrier.color.value, CoquiColors.scrim);
      expect(
        tester.getRect(find.byType(AnimatedModalBarrier).last),
        const Rect.fromLTWH(0, 0, 412, 915),
      );

      // The sheet stands above the tab bar and the raised Mapa disc: its foot is 72 + 14 px from the
      // screen's foot (`bottom: navh + rise`).
      final sheet = tester.getRect(find.byType(CoquiSheet));
      expect(915 - sheet.bottom, 72 + 14);

      // A touch on the tab bar does not reach it: the scrim takes it (and, being tappable, closes).
      final tab = tester.getCenter(find.text('Palabras'));
      expect(tab.dy, greaterThan(sheet.bottom));
      await tester.tapAt(tab);
      await tester.pumpAndSettle();
      expect(tabs, isEmpty);
      expect(find.byType(CoquiSheet), findsNothing);
      await tester.tap(find.text('Palabras'));
      expect(tabs, [
        'words',
      ], reason: 'the tab bar works again once it is closed');
    });

    testWidgets('the future completes when the sheet closes, not before', (
      tester,
    ) async {
      await pumpShell(tester);
      await open(tester);
      expect(closed, isFalse);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });

    testWidgets('the X closes it', (tester) async {
      await pumpShell(tester);
      await open(tester);
      await tester.tap(find.byType(CoquiCloseButton));
      await tester.pumpAndSettle();
      expect(find.byType(CoquiSheet), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets(
      'a drag of the header down past 72 px closes it; less does not',
      (tester) async {
        await pumpShell(tester);
        await open(tester);
        final header = tester.getCenter(find.text('A title'));
        await tester.dragFrom(header, const Offset(0, 60));
        await tester.pumpAndSettle();
        expect(
          find.byType(CoquiSheet),
          findsOneWidget,
          reason: '60 px is not enough',
        );
        await tester.dragFrom(header, const Offset(0, 120));
        await tester.pumpAndSettle();
        expect(find.byType(CoquiSheet), findsNothing);
        expect(closed, isTrue);
      },
    );

    testWidgets('a tap on the scrim closes it', (tester) async {
      await pumpShell(tester);
      await open(tester);
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();
      expect(find.byType(CoquiSheet), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('the system back button closes it', (tester) async {
      await pumpShell(tester);
      await open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CoquiSheet), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('the close callback closes it from inside', (tester) async {
      await pumpShell(tester);
      await open(tester);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(CoquiSheet), findsNothing);
    });

    testWidgets(
      'a second call while one is open does not stack a second sheet',
      (tester) async {
        await pumpShell(tester);
        await open(tester);
        final first = future!;
        var built = 0;
        final second = showCoquiSheet(
          tester.element(find.byType(Scaffold).first),
          builder: (context, close) {
            built++;
            return CoquiSheet(
              title: 'Another',
              child: const Text('another body'),
            );
          },
        );
        await tester.pumpAndSettle();
        expect(built, 0, reason: 'ignored: the second sheet is never built');
        expect(find.byType(CoquiSheet), findsOneWidget);
        expect(find.text('Another'), findsNothing);
        expect(second, same(first), reason: 'it joins the open one');
        // One close and nothing is left under it.
        await tester.tap(find.byType(CoquiCloseButton));
        await tester.pumpAndSettle();
        expect(find.byType(CoquiSheet), findsNothing);
        expect(find.byType(AnimatedModalBarrier), findsNothing);
        // And once it is closed a new one opens.
        await open(tester);
        expect(find.byType(CoquiSheet), findsOneWidget);
      },
    );

    testWidgets(
      'a modal sheet (the welcome): at the screen\'s foot, no X, no drag, scrim and back ignored',
      (tester) async {
        await pumpShell(tester);
        await open(
          tester,
          modal: true,
          builder: (context, close) => CoquiSheet(
            footer: CoquiButton(label: 'Start', onPressed: close),
            child: const SizedBox(height: 200, child: Text('welcome')),
          ),
        );
        final sheet = tester.getRect(find.byType(CoquiSheet));
        expect(sheet.bottom, 915, reason: 'a modal sheet covers the tab bar');
        expect(find.byType(CoquiCloseButton), findsNothing);
        // A tap on the scrim: ignored.
        await tester.tapAt(const Offset(200, 40));
        await tester.pumpAndSettle();
        expect(find.byType(CoquiSheet), findsOneWidget);
        // The system back button: ignored.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(CoquiSheet), findsOneWidget);
        expect(closed, isFalse);
        // Its own button closes it.
        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        expect(find.byType(CoquiSheet), findsNothing);
        expect(closed, isTrue);
      },
    );

    testWidgets('the sheet slides up in 200 ms and out in 200 ms', (
      tester,
    ) async {
      await pumpShell(tester);
      future = showCoquiSheet(
        tester.element(find.byType(Scaffold).first),
        builder: _sheet,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final early = tester.getRect(find.byType(CoquiSheet));
      await tester.pump(const Duration(milliseconds: 200));
      final end = tester.getRect(find.byType(CoquiSheet));
      expect(early.top, greaterThan(end.top), reason: 'on its way up');
      await tester.tap(find.byType(CoquiCloseButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byType(CoquiSheet),
        findsOneWidget,
        reason: 'still sliding out',
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(CoquiSheet), findsNothing);
    });
  });
}
