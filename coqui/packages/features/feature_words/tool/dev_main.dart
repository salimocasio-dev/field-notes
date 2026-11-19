// The dev entry: feature_words alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart                          (in this package)
//   flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?state=curso"
//
// `?state=` is the stored progress it starts in, one of the seeds of coqui/ref/pantallas/seeds/: vacio (nothing
// played), uno (one word), curso (mid-course, the default), todo (everything built so far played), nivel (after the
// level check). The tab is drawn above a stand-in for the shell's tab bar, so that the sheet's scrim and its place
// above the bar are as in the old pictures.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:material_ui/material_ui.dart';

import 'dev_services.dart';

/// The dev entry's root widget: the module on [devServices] in [state].
Widget devApp({String? state, Services? services}) {
  final s = services ?? devServices(state: state);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Coquí dev: feature_words',
    theme: coquiTheme(),
    // the old page shows no scroll bar on a phone
    scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
    home: Scaffold(
      body: Builder(
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: const WordsModule().tab(s)!.builder(context),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: CoquiTabBar(selectedId: CoquiTabs.wordsId, onTap: (_) {}),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() =>
    runApp(devApp(state: Uri.base.queryParameters['state'] ?? 'curso'));
