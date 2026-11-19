// The dev entry: feature_map alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
//   flutter build web -t tool/dev_main.dart --no-web-resources-cdn
//
// What the address says (all optional):
//   ?demo=none|three|all   mapa.html's three states: nothing done / places 1 to 3 done / all ten done (the default
//                          is none). With `demo`, places 4 and up have made-up stories, so they can be done.
//   ?seed=vacio|segunda|uno|curso|casi|todo   the stored progress of a reference picture of v=39
//                          (coqui/ref/pantallas/seeds), on the course v=39 has: places 1 to 3 built.
//   &todo=1                "Open every place" is on.
//   &place=1..10           once the map is up, go to that place as if it had been tapped.
//   &reduce=1              reduceMotion: everything stands still.
//   &review=0              the Today card has no review entry (the screen is given no title for it).
//   &chip=0                no corner chip (for screenshots).
//
// The corner chip shows the bake time and the slowest frame, in ms, as the screen measured them.
//
// The root widget and the fixture it runs on are in test/support/ (map_dev_app.dart, map_fixture.dart, map_seeds.dart),
// so that the tests, which load nothing outside test/ in a browser, can run them too.
import 'package:material_ui/material_ui.dart';

import '../test/support/map_dev_app.dart';

void main() => runApp(devApp(Uri.base.queryParameters));
