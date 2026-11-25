// The dev entry's root widget and the fixture it runs on (tool/dev_main.dart runs it). It lives here so that the
// tests can run the same thing: the fakes of coqui_testing, the ten places of the old course, and the progress
// states of the reference pictures. This is test data, not feature code: the feature reads every name from the
// catalog.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_profile/src/yo_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'course_places.dart';
import 'seeds.dart';

/// 19 Nov 2026, 12:00 in Puerto Rico: the moment every reference picture of v=39 is taken at.
const int referenceNowMs = 1795104000000;

/// The fake course with the ten places of curso.js (the sample course holds only La casa).
class DevCourse extends FakeCourseCatalog {
  DevCourse()
    : _places = [
        for (final j in jsonDecode(coursePlacesJson) as List)
          Place.fromJson(j as Map<String, dynamic>),
      ];

  final List<Place> _places;

  @override
  List<Place> get places => _places;
}

/// What a screen or a test runs on: [Services] from the fakes, and the fakes themselves.
class DevFixture {
  DevFixture._(
    this.services,
    this.progress,
    this.nav,
    this.haptics,
    this.speech,
    this.info,
    this.clock,
    this.spaces,
  );

  final Services services;
  final FakeProgressStore progress;
  final FakeNavigator nav;
  final FakeHaptics haptics;
  final FakeSpeechListener speech;
  final FakeAppInfo info;
  final FakeClock clock;

  /// The storage spaces features keep their own things in, by name (`Services.storage(space)`).
  final Map<String, FakeKeyValueStore> spaces;

  /// The same store and clock under new [Services]: what a reload of the page is (a store that kept what it
  /// held, and a page that remembers nothing). [mic] is whether the recogniser is there this time.
  DevFixture reload({bool mic = true}) {
    final speech = FakeSpeechListener(isAvailable: mic);
    final nav = FakeNavigator();
    final haptics = FakeHaptics();
    final fresh = fakeServices(
      progress: progress,
      course: services.course,
      clock: clock,
      nav: nav,
      haptics: haptics,
      speech: speech,
      info: info,
      storage: (space) => spaces.putIfAbsent(space, FakeKeyValueStore.new),
    );
    return DevFixture._(
      fresh,
      progress,
      nav,
      haptics,
      speech,
      info,
      clock,
      spaces,
    );
  }
}

/// The fixture: the progress of seed [seed] (a name of `seeds`, or none for a first start), the recogniser
/// [mic] (false: `?mic=off`), the build facts.
DevFixture fixture({
  String? seed,
  String? json,
  bool mic = true,
  bool ios = false,
  bool installed = false,
  bool web = true,
  String build = 'dev',
  int? nowMs,
}) {
  final clock = FakeClock(nowMs ?? referenceNowMs);
  final progress = FakeProgressStore(
    clock: clock,
    json: json ?? (seed == null ? null : seeds[seed]),
  );
  final nav = FakeNavigator();
  final haptics = FakeHaptics();
  final speech = FakeSpeechListener(isAvailable: mic);
  final info = FakeAppInfo(
    build: build,
    isWeb: web,
    isIos: ios,
    installed: installed,
  );
  final spaces = <String, FakeKeyValueStore>{};
  final services = fakeServices(
    progress: progress,
    course: DevCourse(),
    clock: clock,
    nav: nav,
    haptics: haptics,
    speech: speech,
    info: info,
    storage: (space) => spaces.putIfAbsent(space, FakeKeyValueStore.new),
  );
  return DevFixture._(
    services,
    progress,
    nav,
    haptics,
    speech,
    info,
    clock,
    spaces,
  );
}

/// The dev entry's root widget, for the address [query].
Widget devApp([Map<String, String> query = const {}]) => YoDevApp(query: query);

/// What the address says (all optional):
///   ?screen=yo|welcome        the Yo tab (the default), or the welcome over a plain backdrop (a first start)
///   &seed=vacio|segunda|uno|curso|casi|todo|nivel|nivel1   the stored progress of a reference picture
///                             (coqui/ref/pantallas/seeds); the default is `vacio` for yo, none for welcome
///   &step=0|1|2               the welcome's step
///   &how=0|1|2                Yo with "How it works" open at that step
///   &about=1                  Yo with the About sheet open
///   &do=min:120,todo,habla    what the learner touched first, written as the handlers write it
///   &mic=off                  the recogniser is not available (the speaking note shows)
///   &ios=1                    an iPhone in the browser, not installed (the install hint shows)
///   &installed=1              ... opened from the home screen
///   &build=39                 the build number Yo shows
class YoDevApp extends StatefulWidget {
  const YoDevApp({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  State<YoDevApp> createState() => _YoDevAppState();
}

class _YoDevAppState extends State<YoDevApp> {
  late final DevFixture f;

  @override
  void initState() {
    super.initState();
    final q = widget.query;
    final welcome = q['screen'] == 'welcome';
    f = fixture(
      seed: q['seed'] ?? (welcome ? null : 'vacio'),
      mic: q['mic'] != 'off',
      ios: q['ios'] == '1',
      installed: q['installed'] == '1',
      build: q['build'] ?? 'dev',
    );
    for (final d in (q['do'] ?? '').split(',').where((x) => x.isNotEmpty)) {
      final p = f.progress;
      if (d.startsWith('min:')) {
        p.setSetting('min', int.parse(d.substring(4)));
      } else if (d == 'todo') {
        p.setSetting('todo', (p.setting('todo') == 0) ? 1 : 0);
      } else if (d == 'habla') {
        p.setSetting('habla', p.setting('habla') == 0 ? 1 : 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final step = int.tryParse(q['step'] ?? '') ?? 0;
    final how = int.tryParse(q['how'] ?? '');
    final lang = f.services.course.language;
    final yo = Stack(
      fit: StackFit.expand,
      children: [
        if (q['screen'] == 'welcome')
          const ColoredBox(color: NocheColors.ground)
        else
          YoScreen(
            services: f.services,
            howItWorksStep: how,
            aboutOpen: q['about'] == '1',
          ),
        Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: NocheTabBar(
            selectedId: NocheTabs.me,
            tabNames: lang.tabNames,
            script: lang.script,
            languageCode: lang.code,
            onTap: (_) {},
          ),
        ),
      ],
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coqui Me',
      theme: coquiTheme(),
      home: Scaffold(
        backgroundColor: NocheColors.ground,
        body: WelcomeGate(services: f.services, initialStep: step, child: yo),
      ),
    );
  }
}
