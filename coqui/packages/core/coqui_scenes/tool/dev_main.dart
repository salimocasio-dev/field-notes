// The dev entry of coqui_scenes: El frente on its own, drawn by the Dart scene on the still host.
//
//   flutter run -d chrome -t tool/dev_main.dart          (in this package)
//   flutter build web --release --no-web-resources-cdn -t tool/dev_main.dart
//
// The address says what to show:
//   ?w=<W as JSON>&view=<name>&F=<n>   the scene in that state (W over the fresh world, in today's places), through a view
//                                      of the sheet (wide, casa, puerta, ventana, cuadro, wide@donde-esta-el-pajaro)
//   ?page=pairs                        the 12 review pairs of cual-frente and the level pictures, through ScenePictures
//   ?page=bake[&scene=balcon|sala|patio|camino|campo|lago|banco|estufa|nevera] every baked state of the sheet (El frente's, or the scene given), each baked on a
//                                      fresh engine's cache, one after the other; the times are on the page and in
//                                      `window.coquiBakes` (JSON) for a script
// Every page shows how long each state it baked took, in ms.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/balcon/balcon_set.dart';
import 'package:coqui_scenes/src/camino/camino_set.dart';
import 'package:coqui_scenes/src/campo/campo_set.dart';
import 'package:coqui_scenes/src/frente/frente_set.dart';
import 'package:coqui_scenes/src/lago/lago_set.dart';
import 'package:coqui_scenes/src/banco/banco_set.dart';
import 'package:coqui_scenes/src/estufa/estufa_set.dart';
import 'package:coqui_scenes/src/nevera/nevera_set.dart';
import 'package:coqui_scenes/src/patio/patio_set.dart';
import 'package:coqui_scenes/src/sala/sala_set.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const DevApp());

class DevApp extends StatelessWidget {
  const DevApp({super.key});

  @override
  Widget build(BuildContext context) {
    final q = Uri.base.queryParameters;
    final Widget page = switch (q['page']) {
      'pairs' => const PairsPage(),
      'bake' => const BakePage(),
      _ => ScenePage(
        w: q['w'] == null
            ? const {}
            : jsonDecode(q['w']!) as Map<String, dynamic>,
        view: q['view'] ?? 'wide',
        F: int.tryParse(q['F'] ?? '') ?? 8,
      ),
    };
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(body: SafeArea(child: page)),
    );
  }
}

Widget bakeTimes(Map<String, double> ms) => Text(
  ms.entries
      .map((e) => 'bake ${e.key}: ${e.value.toStringAsFixed(1)} ms')
      .join('\n'),
  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
);

/// The scene in one state, through one view: the screen the game shows (the view, the signs, hud and the hand).
class ScenePage extends StatefulWidget {
  const ScenePage({
    super.key,
    required this.w,
    required this.view,
    required this.F,
  });

  final Map<String, dynamic> w;
  final String view;
  final int F;

  @override
  State<ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends State<ScenePage> {
  StillFrame? _frame;
  Uint32List? _px;
  Object? _error;

  @override
  void initState() {
    super.initState();
    () async {
      try {
        final f = await ScenePictures().frameOf('frente');
        f.host.fresh();
        final W = f.host.W..addAll(widget.w);
        final cam = f.scene.sheet.viewOf(widget.view, f.scene.projection);
        f.draw(W, F: widget.F, cam: cam);
        setState(() {
          _frame = f;
          _px = Uint32List.fromList(f.display);
        });
      } catch (e) {
        setState(() => _error = e);
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Text('$_error');
    final px = _px, f = _frame;
    if (px == null || f == null) return const SizedBox();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SizedBox(
          width: 392,
          child: PixelView(pixels: px, width: displayW, height: displayH),
        ),
        const SizedBox(height: 8),
        Text(
          'set ${f.scene.setKey(f.host.W)}, view ${widget.view} ${f.host.cam}, F ${widget.F}',
        ),
        bakeTimes(f.bakes.bakeMs),
      ],
    );
  }
}

/// The 12 review pairs of cual-frente (the content's states and views, read from the sheet's picture names) and the
/// level pictures, through ScenePictures.
class PairsPage extends StatefulWidget {
  const PairsPage({super.key});

  @override
  State<PairsPage> createState() => _PairsPageState();
}

class _PairsPageState extends State<PairsPage> {
  final source = ScenePictures();
  Sheet? _sheet;
  StillFrame? _frame;

  @override
  void initState() {
    super.initState();
    () async {
      final f = await source.frameOf('frente');
      setState(() {
        _frame = f;
        _sheet = f.scene.sheet;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _sheet;
    if (sheet == null) return const SizedBox();
    // each picture of the sheet, by name; the state of each is the pair's (cual-frente.json), given here as the
    // preview gives it: the page shows how ScenePictures draws a named picture. A level cell is 96 x 106 picture pixels.
    Widget pic(
      String name, {
      String? state,
      int width = 196,
      int height = 104,
    }) => SizedBox(
      width: width.toDouble(),
      child: source.ofPicture(
        PictureRef(
          scene: 'frente',
          set: pairSets[state ?? name] ?? const {},
          cam: const [0, 0, 196, 104],
        ),
        name,
        width: width,
        height: height,
      ),
    );
    final words = <String>{
      for (final k in sheet.pictures.keys) k.split('.').first,
    };
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final w in words)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              children: [pic('$w.si'), pic('$w.no'), Text(w)],
            ),
          ),
        const Divider(),
        for (final l in sheet.level)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              children: [
                pic(
                  'nivel.${l.word}.${l.index}',
                  state: l.picture,
                  width: 96,
                  height: 106,
                ),
                Text('level ${l.word} ${l.index}: ${l.picture}'),
              ],
            ),
          ),
        bakeTimes(_frame?.bakes.bakeMs ?? const {}),
      ],
    );
  }
}

/// The state of each review picture of cual-frente (historia/cuentos/cual-frente.json), for the dev page.
const Map<String, Map<String, dynamic>> pairSets = {
  'abuela.si': {
    'door': 1,
    'ab': {'en': 'puerta', 'pose': 'idle', 'bub': null, 'al': 1},
  },
  'abuela.no': {'door': 0},
  'abre.si': {
    'win': 1,
    'ab': {'en': 'ventana', 'pose': 'idle', 'bub': null, 'al': 1},
  },
  'abre.no': {'win': 0},
  'cierra.si': {'door': .5, 'peek': 1},
  'cierra.no': {
    'door': 1,
    'ab': {'en': 'puerta', 'pose': 'idle', 'bub': null, 'al': 1},
  },
  'hola.si': {
    'door': 1,
    'ab': {'en': 'puerta', 'pose': 'wave', 'bub': null, 'al': 1},
    'cq': {
      'x': 146,
      'y': 86,
      's': .62,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': 'hola',
    },
  },
  'hola.no': {
    'door': .5,
    'peek': 1,
    'dusk': 2,
    'cq': {
      'x': 176,
      'y': 116,
      's': .85,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
    },
    'polvo': 1,
  },
  'adiós.si': {
    'door': .5,
    'peek': 1,
    'dusk': 2,
    'cq': {
      'x': 176,
      'y': 116,
      's': .85,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
    },
    'polvo': 1,
  },
  'adiós.no': {
    'door': 1,
    'ab': {'en': 'puerta', 'pose': 'wave', 'bub': null, 'al': 1},
    'cq': {
      'x': 146,
      'y': 86,
      's': .62,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': 'hola',
    },
  },
  'sí.si': {
    'resp': ['si'],
  },
  'sí.no': {
    'resp': ['no'],
  },
  'no.si': {
    'resp': ['no'],
  },
  'no.no': {
    'resp': ['si'],
  },
  'grande.si': {'escondite': 1},
  'grande.no': {'escondite': 1},
  'pequeña.si': {'escondite': 1},
  'pequeña.no': {'escondite': 1},
};

/// Every baked state of the sheet, baked one after the other on a fresh engine (the first bake also makes the ground
/// and its grass, as the set reference's first bake in a page does), each timed.
class BakePage extends StatefulWidget {
  const BakePage({super.key});

  @override
  State<BakePage> createState() => _BakePageState();
}

class _BakePageState extends State<BakePage> {
  final Map<String, double> _ms = {};
  bool _done = false;

  @override
  void initState() {
    super.initState();
    () async {
      final id = Uri.base.queryParameters['scene'] ?? 'frente';
      final f = await ScenePictures().frameOf(id);
      final bakes = SetBakes(f.scene);
      for (final b in f.scene.sheet.setKey.baked) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final key = switch (id) {
          'balcon' => BalconState.fromQuery(b.query).key,
          'sala' => SalaState.fromQuery(b.query).key,
          'patio' => PatioState.fromQuery(b.query).key,
          'camino' => CaminoState.fromQuery(b.query).key,
          'campo' => CampoState.fromQuery(b.query).key,
          'lago' => LagoState.fromQuery(b.query).key,
          'banco' => BancoState.fromQuery(b.query).key,
          'estufa' => EstufaState.fromQuery(b.query).key,
          'nevera' => NeveraState.fromQuery(b.query).key,
          _ => FrenteState.fromQuery(b.query).key,
        };
        bakes.bakeKey(key);
        setState(() => _ms[key] = bakes.bakeMs[key]!);
      }
      // later bakes: each state again on the same engine (the ground made, the scene's first-bake records kept)
      for (final key in [...bakes.keys]) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final sw = Stopwatch()..start();
        f.scene.buildSetFor(bakes.engine, bakes.build, key);
        final ms = sw.elapsedMicroseconds / 1000;
        setState(() => _ms['$key again'] = ms);
      }
      // a set whose bake leaves glints on its water (El campo's, El lago's): what drawing them costs a frame (drawGlints, the
      // frame recipe's step beside the tufts), over 400 frames of 8 wind steps a second
      final e = bakes.engine;
      if (e.glints.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        const n = 400;
        final sw = Stopwatch()..start();
        for (var k = 0; k < n; k++) {
          drawGlints(e, e.glints, k / e.WIND_FPS, e.bakedZ, e.glintColour);
        }
        setState(
          () => _ms['glints per frame (${e.glints.length} glints)'] =
              sw.elapsedMicroseconds / 1000 / n,
        );
      }
      globalContext['coquiBakes'] = jsonEncode(_ms).toJS;
      setState(() => _done = true);
    }();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [Text(_done ? 'done' : 'baking'), bakeTimes(_ms)],
  );
}
