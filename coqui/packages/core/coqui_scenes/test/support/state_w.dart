import 'package:coqui_scenes/src/frente/frente.dart';
import 'package:coqui_scenes/src/frente/frente_set.dart';

/// A W that is in the set state [s] (the sheet's setKey table read backwards), and the frame counter its rustle needs.
({Map<String, dynamic> W, int F}) wOfState(Frente scene, FrenteState s) {
  final W = <String, dynamic>{
    'cq': <String, dynamic>{
      'x': 103,
      'y': 168,
      's': 1,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
    },
    'fx': <Map<String, dynamic>>[],
    'heart': 0,
    'lost': 0,
    'resp': null,
    ...scene.fresh(const {}),
  };
  W['door'] = const {'shut': 0, 'half': .5, 'open': 1}[s.door];
  W['win'] = s.win == 'open' ? 1 : 0;
  W['lamp'] = s.lights ? 1 : 0;
  switch (s.sky) {
    case 'storm':
      W['storm'] = 1;
      W['dark'] = .22;
    case 'storm2':
      W['storm'] = 1;
      W['dark'] = .27;
    case 'rain':
      W['storm'] = 1;
      W['dark'] = .33;
      W['rain'] = 1;
    case 'dusk':
      W['dusk'] = 1;
    case 'sunset':
      W['dusk'] = 2;
  }
  if (s.hide) W['escondite'] = 1;
  if (s.rustle != 'none') W['rustle'] = s.rustle;
  return (W: W, F: s.side == 1 ? 2 : 0);
}
