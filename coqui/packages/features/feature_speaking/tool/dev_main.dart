// The dev entry: feature_speaking alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
//   flutter build web -t tool/dev_main.dart --no-web-resources-cdn
//
// What the address says (all optional), as in the old page's own test addresses (?callstub=1&stub=..., habla-prueba.html?mic=...):
//   ?screen=hablar|call|voice            what opens first (default hablar)
//   &seed=vacio|curso|casi|todo|nivel    the stored progress of a reference picture of v=39 (default todo)
//   &stub=manual,nofin,mic,fail,hasta,dannybye,loop    the scripted call's options
//   &steps=connect@0,danny1@100,...      with stub=manual: the scripted call's steps, ms after the call starts
//   &later=1   &entry=1   &mic=stub:...|off   &reduce=1   &bar=0
// The full list is at the head of test/support/dev_app.dart, so that the tests, which load nothing outside test/ in a
// browser, can run the same root widget.
import 'package:material_ui/material_ui.dart';

import '../test/support/dev_app.dart';

void main() => runApp(devApp(Uri.base.queryParameters));
