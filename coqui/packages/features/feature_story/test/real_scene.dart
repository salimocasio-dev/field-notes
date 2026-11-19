// The real scenes, as the differential test makes them. El frente's is being built by the scenes package (order 14): until it
// is merged and its registry is exported, this throws and the test that needs it is skipped.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';

/// Whether the real scene [id] can be made now.
bool get realScenesReady => false;

/// The real scene [id], drawing its random numbers from [rng]. Once `coqui_scenes` exports `sceneRegistry` this is
/// `sceneRegistry[id]!()` (with [rng] given to the scene as the scenes package says), and [realScenesReady] is true.
Scene realScene(String id, Rng rng) =>
    throw UnimplementedError('coqui_scenes exports no scene registry yet');
