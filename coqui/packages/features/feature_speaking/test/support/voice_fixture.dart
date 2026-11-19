// The voice test's twelve lines and the Spanish words around them, as habla-prueba.html writes them (its `LINES`,
// `state()`, `showEnd()` and the aria-labels). This is test data: the feature takes its lines and labels from a
// `VoiceTestContent` it is given, and nothing in `lib/` writes them (order 24, "STOP": where they come from is
// the orchestrator's to say).
import 'package:feature_speaking/src/voice_test_controller.dart';

const voiceFixture = VoiceTestContent(
  lines: [
    VoiceLine('Hola, abuela', [
      VoiceTarget('hola', ['hola']),
      VoiceTarget('abuela', ['abuela']),
    ]),
    VoiceLine('Sí', [
      VoiceTarget('sí', ['si']),
    ]),
    VoiceLine('No', [
      VoiceTarget('no', ['no']),
    ]),
    VoiceLine('Gracias', [
      VoiceTarget('gracias', ['gracias']),
    ]),
    VoiceLine('Adiós', [
      VoiceTarget('adiós', ['adios']),
    ]),
    VoiceLine('La casa', [
      VoiceTarget('casa', ['casa']),
    ]),
    VoiceLine('La puerta', [
      VoiceTarget('puerta', ['puerta']),
    ]),
    VoiceLine('La ventana', [
      VoiceTarget('ventana', ['ventana']),
    ]),
    VoiceLine('Quiero jugo, por favor', [
      VoiceTarget('quiero', ['quiero']),
      VoiceTarget('jugo', ['jugo']),
    ]),
    VoiceLine('Me llamo…', [
      VoiceTarget('me llamo', ['me llamo']),
    ], hint: 'tu nombre'),
    VoiceLine('¿Cómo estás?', [
      VoiceTarget('¿cómo estás?', ['como estas']),
    ]),
    VoiceLine('Uno, dos, tres', [
      VoiceTarget('uno', ['uno', '1']),
      VoiceTarget('tres', ['tres', '3']),
    ]),
  ],
  labels: VoiceTestLabels(
    listening: 'Escuchando…',
    processing: 'Un momento…',
    unavailable: 'El micrófono no está disponible.',
    again: 'Otra vez',
    mic: 'Micrófono',
    next: 'Siguiente',
    progress: 'Progreso',
  ),
);

/// habla-prueba.html's `?mic=stub:` of the reference pictures.
const voiceStubOfPictures =
    'hola abuela|none|no/nó|gracias|adios|la caza|puerta|ventana|quiero jugo por favor|me llamo Ana|como estas|uno dos tres';
