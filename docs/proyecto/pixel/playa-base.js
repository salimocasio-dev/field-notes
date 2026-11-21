'use strict';
/* La playa (place 7): what its four scene sets share (orilla, sombrilla, ropa, cielo).
   Each <id>-set.html sets PP_SCENE, loads pp-engine.js, mapa.js, set-kit.js, calle-base.js, plaza-base.js (the painters that draw square to the
   picture: PZ.box, PZ.wall, PZ.flat, PZ.slope, PZ.post, PZ.ball) and this file.
   Laid out, like La plaza, in u, v: u across the picture, v down it towards the camera. The sea is at the top: the water's edge is a line of
   constant v, the wet sand a strip below it, the dry sand below that; beyond the horizon's v there is no ground, and the sky shows.
   Everything that moves is a sprite: people, the dog, the waves that run up the sand, boats, what is carried. */
const PL = (() => {
  const SAND = [[206, 186, 140], [222, 204, 160], [234, 218, 178], [244, 232, 198]], WET = [[150, 132, 104], [166, 148, 116], [180, 162, 128], [194, 176, 142]];
  const SHALLOW = [130, 218, 208], MID = [78, 182, 210], DEEP = [44, 122, 196], FOAM = [252, 252, 250];
  const mix = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
  // the ground of a beach. B: { edge: the water's edge (v), wet: how wide the wet strip is, deep: the v beyond which the sea is dark, hor: the horizon's v }
  // returns [colour, kind]; kind 'mar', 'mojada' (wet sand), 'arena'; 0 beyond the horizon
  function ground(u, v, ix, iy, B) {
    if (v < B.hor) return 0;
    const wob = Math.sin(u * 1.7) * .12 + Math.sin(u * 4.1 + 1) * .05;                    // the edge wanders a little
    if (v < B.edge + wob) {
      const d = (B.edge + wob) - v;                                                       // how far out
      if (d < .13) return [rgb(...FOAM), 'mar'];                                          // foam at the edge
      const crest = ((v * 1.0 + Math.sin(u * 1.3 + Math.floor(v * 1.0) * 2.1) * .22 + 80) % 1.0);
      if (d > .5 && crest < .09 && hash(ix >> 1, Math.floor(v * 6)) < .8) return [rgb(...(d > (B.edge - B.deep) ? [176, 214, 240] : FOAM)), 'mar'];   // lines of small waves
      const t = clamp(d / Math.max(.01, B.edge - B.deep), 0, 1.6), c = t < 1 ? mix(SHALLOW, MID, t) : mix(MID, DEEP, clamp((t - 1) / .35, 0, 1));
      const dth = (bayerAt(ix, iy) - .5) * 14;
      return [rgb(c[0] + dth, c[1] + dth, c[2] + dth * .6), 'mar'];
    }
    if (v < B.edge + wob + B.wet) { const t = (v - B.edge - wob) / B.wet; return [toneOf(WET, .3 + t * .5 + noise(u * 2, v * 2) * .2, ix, iy), 'mojada']; }
    const rip = Math.sin(v * 9 + Math.sin(u * 1.1) * 2.5) > .93 ? -.18 : 0;               // ripples in the dry sand
    return [toneOf(SAND, .5 + noise(u * 1.3, v * 1.3) * .5 + rip + (hash(ix, iy) < .02 ? -.3 : 0), ix, iy), 'arena'];
  }
  // a palm at (u, v): h high, leaning by lean (set-kit's swayPalm; its fronds sway: the set's frame() calls drawLeaves)
  function palm(u, v, h, lean, seed, size = 1, L = null) { const [x, y] = PZ.xy(u, v); return swayPalm(x, y, h, lean, seed, size, L); }
  // a blanket or a towel flat on the sand: stripes across
  function blanket(u0, v0, u1, v1, a = [214, 62, 54], b = [250, 246, 236]) {
    PZ.flat(u0, v0, u1, v1, .03, (u, v) => (u - u0 < .08 || u1 - u < .08) ? rgb(...b) : (Math.floor((u - u0) / .32) % 2) ? shade(a, 3.2, u * 4, v * 4, .2) : shade(b, 3.2, u * 4, v * 4, .2));
  }
  // a beach umbrella stuck in the sand: a pole and a striped canopy (eight panels seen from in front and above), open or shut
  function umbrella(u, v, h = 2.6, r = 1.5, open = true, a = [226, 60, 50], b = [250, 246, 236]) {
    const [x, y] = PZ.xy(u, v);
    PZ.post(u, v, 0, h, .045, [230, 226, 214]);
    if (!open) { for (let z = h - 1.5; z <= h; z += .02) { const rr = .05 + (h - z) * .09; for (let t = 0; t < 6.3; t += .2) plot(x + Math.cos(t) * rr, y + Math.sin(t) * rr, z, shade((Math.floor(t / .79) % 2) ? a : b, 1.6 + Math.cos(t - .8), t, z)); } return; }
    for (let k = 0; k <= 1; k += .012) {                                                  // the canopy: rings from the tip out and down
      const rr = r * k, z = h + .28 - .5 * k * k;
      for (let t = 0; t < 6.3; t += .012 / Math.max(.08, k)) plot(x + Math.cos(t) * rr, y + Math.sin(t) * rr, z, shade((Math.floor((t + .39) / .785) % 2) ? a : b, 2.2 + Math.cos(t - .9) * 1.1, t * 3, k * 6, .25));
    }
    PZ.ball(u, v, h + .32, .07, [250, 206, 70]);
    for (let t = 0; t < 6.3; t += .4) for (const k of [.4, .8]) castShadow(x + Math.cos(t) * r * k, y + Math.sin(t) * r * k, h - .3, r * .3, 1, .25);
    castShadow(x, y, h - .3, r * .5, 1, .25);
  }
  // a heap of sand, a shell, a bucket
  function heap(u, v, r = .6, h = .34) { const [x, y] = PZ.xy(u, v); for (let k = 0; k < 14; k++) { const a = k * 2.4, d = r * .55 * Math.sqrt(k / 14); sphere(x + Math.cos(a) * d, y + Math.sin(a) * d, h * (1 - d / r) * .6, r * (.55 - d / r * .25), [240, 226, 190], 'rough'); } castShadow(x, y, .2, r * .8); }
  function bucket(u, v, c = [226, 60, 70]) { const [x, y] = PZ.xy(u, v); drum(x, y, 0, .34, .17, c, (a, b) => Math.hypot(a, b) < .13 ? rgb(60, 40, 40) : 0); castShadow(x, y, .2, .2); }
  // the sky by the hour with a sun; hora: manana, mediodia, tarde, ocaso, gris, noche. sun: [sx, sy, r] or null
  function sky(hora, sun = null) { return CL.sky({ manana: 'manana', mediodia: 'manana', sol: 'manana', tarde: 'manana', ocaso: 'tarde', gris: 'gris', noche: 'noche' }[hora] || 'manana', sun); }
  function light(hora) {
    const L = { tarde: [[1.0, .95, .86], [8, 3, -6]], ocaso: [[1.0, .86, .74], [16, 0, -12]], sol: [[1.06, 1.04, .98], [6, 6, 2]], gris: [[.8, .82, .88], [0, 0, 6]], noche: [[.55, .58, .82], [-6, -4, 16]] }[hora];
    if (L) lightPass(L[0], L[1], false);
    return L ? { m: L[0], a: L[1] } : null;
  }
  return { SAND, WET, ground, palm, blanket, umbrella, heap, bucket, sky, light };
})();
