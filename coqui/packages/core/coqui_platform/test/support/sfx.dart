import 'package:coqui_contracts/coqui_contracts.dart';

/// juego.js's SFX table (lines 88 to 98), as the scene host calls a [ClipPlayer] for each name (page 12,
/// section 4: "Each calls ClipPlayer.tone, noiseBurst or loop with today's numbers"). A test copy: the
/// host's own is not this package's.
Map<String, void Function()> sfxTable(ClipPlayer p) {
  void t(
    double f0,
    double at,
    double dur,
    String type,
    double vol, [
    double? f1,
  ]) => p.tone(f0, at: at, dur: dur, wave: type, vol: vol, toHz: f1);
  return {
    'right': () {
      t(784, 0, .1, 'triangle', .14);
      t(1047, .09, .1, 'triangle', .14);
      t(1319, .18, .26, 'triangle', .14);
    },
    'toc': () {
      t(950, 0, .07, 'sine', .22, 480);
      t(950, .17, .07, 'sine', .22, 480);
    },
    'blip': () => t(520, 0, .06, 'sine', .07, 640),
    'creak': () {
      t(210, 0, .5, 'sawtooth', .025, 120);
      t(330, .05, .4, 'sawtooth', .012, 170);
    },
    'hop': () => t(320, 0, .07, 'square', .025, 520),
    'coqui': () {
      t(1500, 0, .11, 'sine', .09);
      t(2300, .17, .2, 'sine', .09, 2750);
    },
    'win': () {
      const fs = [523.0, 659.0, 784.0, 1047.0];
      for (var i = 0; i < fs.length; i++) {
        t(fs[i], i * .11, .2, 'square', .04);
      }
    },
    'luz': () {
      t(1320, 0, .09, 'sine', .1);
      t(1760, .08, .22, 'sine', .1);
    },
    'drop': () => t(1400, 0, .05, 'sine', .06, 700),
    'trueno': () => p.noiseBurst(),
    'lluvia': () => p.loop('rain', true),
    'calla': () => p.loop('rain', false),
    'suave': () => t(330, 0, .16, 'sine', .05, 290),
    'pio': () {
      t(2600, 0, .06, 'sine', .07, 3400);
      t(2900, .09, .08, 'sine', .07, 3800);
    },
    'slam': () {
      t(140, 0, .12, 'square', .05, 70);
      t(90, .02, .18, 'sine', .12, 50);
    },
    'bonk': () {
      t(600, 0, .06, 'square', .05, 200);
      t(300, .06, .2, 'triangle', .08, 120);
    },
    'munch': () {
      for (final at in [0, .16, .32]) {
        t(260, at.toDouble(), .06, 'square', .03, 180);
      }
    },
    'swoop': () => t(1800, 0, .35, 'sine', .04, 600),
  };
}
