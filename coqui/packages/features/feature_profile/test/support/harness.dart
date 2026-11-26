// What the tests share: the old page's expected values, a phone-sized screen, and a way to read the text on it.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_profile/src/yo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'dev_app.dart';
import 'old_expected.dart';

/// What the old page (v=39) does, run in node by tool/old_expected.mjs.
final Map<String, dynamic> oldExpected =
    jsonDecode(oldExpectedJson) as Map<String, dynamic>;

/// A phone as wide as the reference ones and tall enough that nothing needs scrolling to reach it. The text
/// is laid out as the platform's default font does; what a test reads is the text, never where it wraps.
void phone(WidgetTester tester, {double height = 3000}) {
  tester.view.physicalSize = Size(412, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(
  theme: coquiTheme(),
  home: Scaffold(backgroundColor: NocheColors.ground, body: home),
);

/// The frames a tap sets going: the page draws, the sheet's slide starts, and the slide ends.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(); // a stream's event arrives
  await tester.pump(); // the page draws
  await tester.pump(const Duration(milliseconds: 300)); // the slide
}

/// Me, from the module's own tab, on [f]'s services.
Future<void> pumpYo(
  WidgetTester tester,
  DevFixture f, {
  int? how,
  bool about = false,
  double Function(DateTime day)? minutesOn,
  int? streakFreezes,
  int? stageMax,
  Entitlements entitlements = const AllowAllEntitlements(),
  String? level,
}) async {
  phone(tester);
  await tester.pumpWidget(
    const SizedBox(),
  ); // a page that is new: nothing is kept from the one before
  final useDefault =
      how == null &&
      !about &&
      minutesOn == null &&
      streakFreezes == null &&
      stageMax == null &&
      entitlements is AllowAllEntitlements &&
      level == null;
  await tester.pumpWidget(
    _app(
      useDefault
          ? Builder(
              builder: (context) =>
                  const ProfileModule().tab(f.services)!.builder(context),
            )
          : YoScreen(
              services: f.services,
              howItWorksStep: how,
              aboutOpen: about,
              minutesOn: minutesOn,
              streakFreezes: streakFreezes,
              stageMax: stageMax,
              entitlements: entitlements,
              level: level,
            ),
    ),
  );
  await settle(tester); // the recogniser's answer arrives
}

/// The welcome gate over a plain page, on [f]'s services. [child] is what is under it.
Future<void> pumpGate(
  WidgetTester tester,
  DevFixture f, {
  Widget child = const ColoredBox(
    key: Key('app'),
    color: NocheColors.ground,
    child: SizedBox.expand(),
  ),
  int step = 0,
}) async {
  phone(tester);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    _app(WelcomeGate(services: f.services, initialStep: step, child: child)),
  );
  await settle(tester); // the first frame is drawn: the sheet slides in
}

/// Every [Text] under [root] in the order they are drawn, without those under a finder of [skip].
List<String> textsOf(
  WidgetTester tester,
  Finder root, {
  List<Finder> skip = const [],
}) {
  final skipped = <Widget>{
    for (final s in skip) ...[
      ...tester.widgetList(s),
      ...tester.widgetList(find.descendant(of: s, matching: find.byType(Text))),
    ],
  };
  return [
    for (final t in tester.widgetList<Text>(
      find.descendant(of: root, matching: find.byType(Text)),
    ))
      if (!skipped.contains(t)) t.data ?? t.textSpan!.toPlainText(),
  ];
}

/// Every text currently visible in the Me scroll view.
List<String> yoTexts(WidgetTester tester) =>
    textsOf(tester, find.byKey(const Key('me-scroll')));

/// A sheet is up: a [NocheSheet], the gate's `CoquiSheetLayer` when open, or a
/// `showCoquiSheet` route above everything.
bool sheetOpen(WidgetTester tester) {
  if (find.byType(NocheSheet).evaluate().isNotEmpty) return true;
  if (tester
      .widgetList<CoquiSheetLayer>(find.byType(CoquiSheetLayer))
      .any((l) => l.open)) {
    return true;
  }
  final inLayers = find
      .descendant(
        of: find.byType(CoquiSheetLayer),
        matching: find.byType(CoquiSheet),
      )
      .evaluate()
      .length;
  return find.byType(CoquiSheet).evaluate().length > inLayers;
}

/// The pills of [SegmentedPills] (welcome sheet) or [NocheSegmented<int>] (Me screen).
List<({String text, bool on})> pillsOf(WidgetTester tester, [Finder? within]) {
  final legacy = within == null
      ? find.byType(SegmentedPills)
      : find.descendant(of: within, matching: find.byType(SegmentedPills));
  if (legacy.evaluate().isNotEmpty) {
    final p = tester.widget<SegmentedPills>(legacy);
    return [
      for (var i = 0; i < p.labels.length; i++)
        (text: p.labels[i], on: i == p.selected),
    ];
  }
  final noche = within == null
      ? find.byType(NocheSegmented<int>)
      : find.descendant(of: within, matching: find.byType(NocheSegmented<int>));
  final seg = tester.widget<NocheSegmented<int>>(noche);
  return [
    for (final option in seg.options)
      (text: option.label, on: option.value == seg.selected),
  ];
}

/// The switches of Me, in the order of the page: Open every place, Speak in stories.
List<bool> switchesOf(WidgetTester tester) => [
  for (final k in const ['yo-todo', 'yo-habla'])
    tester.widget<NocheSwitchRow>(find.byKey(Key(k))).value,
];

/// The dot of the welcome that is lit.
int dotOf(WidgetTester tester) =>
    tester.widget<PageDots>(find.byType(PageDots)).index;

/// The settings the store holds, as the old `AJ()` has them.
Map<String, dynamic> settingsOf(FakeProgressStore p) =>
    (p.raw['ajustes'] as Map).cast<String, dynamic>();

/// Taps the first widget with [text] (a button or a pill).
Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await settle(tester);
}

/// A list of `{text, on}` from the old page's facts.
List<({String text, bool on})> oldPills(Object? j) => [
  for (final p in j as List)
    (text: (p as Map)['text'] as String, on: p['on'] as bool),
];
