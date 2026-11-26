// The dev entry: feature_words alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart                          (in this package)
//   flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?state=curso"
//
// `?state=` is the stored progress it starts in, one of the seeds of coqui/ref/pantallas/seeds/: vacio (nothing
// played), uno (one word), curso (mid-course, the default), todo (everything built so far played), nivel (after the
// level check). The tab is drawn above the Noche floating tab bar, matching AppShell.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:material_ui/material_ui.dart';

import 'dev_services.dart';

/// The dev entry's root widget: the module on [devServices] in [state].
Widget devApp({String? state, Services? services}) {
  final s = services ?? devServices(state: state);
  final lang = s.course.language;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Coquí dev: feature_words',
    theme: coquiTheme(),
    scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
    home: Scaffold(
      backgroundColor: NocheColors.ground,
      body: Builder(
        builder: (context) => Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: const WordsModule().tab(s)!.builder(context),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: NocheTabBar(
                selectedId: NocheTabs.words,
                tabNames: lang.tabNames,
                script: lang.script,
                languageCode: lang.code,
                onTap: (_) {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() =>
    runApp(devApp(state: Uri.base.queryParameters['state'] ?? 'curso'));
