// The dev entry: feature_profile alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
//   flutter build web -t tool/dev_main.dart --no-web-resources-cdn
//
// What the address says (all optional):
//   ?screen=yo|welcome        the Yo tab (the default), or the welcome over a plain backdrop (a first start)
//   &seed=vacio|segunda|uno|curso|casi|todo|nivel|nivel1   the stored progress of a reference picture of v=39
//                             (coqui/ref/pantallas/seeds); the default is `vacio` for yo, none for welcome
//   &step=0|1|2               the welcome's step
//   &how=0|1|2                Yo with "How it works" open at that step
//   &about=1                  Yo with the About sheet open
//   &do=min:120,todo,habla    what the learner touched first, written as the handlers write it
//   &mic=off                  the recogniser is not available (the speaking note shows)
//   &ios=1                    an iPhone in the browser, not installed (the install hint shows)
//   &installed=1              ... opened from the home screen
//   &build=39                 the build number Yo shows
//
// The root widget and the fixture it runs on are in test/support/ (dev_app.dart, seeds.dart, course_places.dart),
// so that the tests run the same thing.
import 'package:material_ui/material_ui.dart';

import '../test/support/dev_app.dart';

void main() => runApp(devApp(Uri.base.queryParameters));
