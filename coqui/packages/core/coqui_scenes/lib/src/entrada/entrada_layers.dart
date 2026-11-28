// Sprite layer builders for La entrada (`part of 'entrada.dart'`).
part of 'entrada.dart';

extension _EntradaLayers on Entrada {
  ({Sprite s, int ax, int ay}) _personSprite(
    String id,
    Map<String, dynamic> p,
    Map<String, dynamic> w,
    bool open,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final sent = _n(p['sent']) == 1;
    final story = _n(w['story']);
    if (id == 'abuela') {
      if (sent) {
        final abPose = switch (pose) {
          'saluda0' || 'saluda1' || 'mano' => 'saluda0',
          'senala' => 'tu',
          'rie' => 'yo',
          _ => 'idle',
        };
        final s = Entrada._spr(
          'en_abS_${abPose}_$open',
          () => mkAbuelaS(abPose, open, false),
        );
        return (s: s, ax: 17, ay: 36);
      }
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' || 'pasa' => 'saluda0',
        'senala' => 'tu',
        'rie' => 'yo',
        _ => 'idle',
      };
      final s = Entrada._spr(
        'en_ab_${abPose}_$open',
        () => mkAbuela(abPose, open),
      );
      return (s: s, ax: 30, ay: inkBottom(s));
    }

    final Who who;
    final String variant;
    if (id == 'mesera') {
      final pad = story == 86;
      who = mkMeseraWho(pad: pad);
      variant = pad ? 'pad' : 'std';
    } else if (id == 'mesero') {
      final is85 = story == 85;
      final bowtie = _n(w['meseroCorbata']) != 0;
      final bandage = is85;
      final cane = is85;
      who = mkMeseroWho(bowtie: bowtie, bandage: bandage, cane: cane);
      variant = '${bowtie ? 1 : 0}_${bandage ? 1 : 0}_${cane ? 1 : 0}';
    } else {
      who = ENTRADA_PEOPLE[id] ?? ENTRADA_PEOPLE['vecino']!;
      variant = 'std';
    }

    final kp = switch (pose) {
      'saluda0' || 'pasa' => 'wave0',
      'saluda1' => 'wave1',
      'senala' || 'baston' => 'tu',
      'rie' || 'reverencia' => 'yo',
      'mano' || 'lista' => 'offer',
      _ => 'idle',
    };
    final s = Entrada._spr(
      'en_${id}_${variant}_${kp}_${open}_$sent',
      () => mkPersona(who, kp, open, sent),
    );
    final ay = sent ? (16 + 2 * (who.nino ? 7 : 11) + 3) : inkBottom(s);
    return (s: s, ax: PX, ay: ay);
  }

  List<EntradaItem> _entradaItems(Map<String, dynamic> w, int a) {
    final out = <EntradaItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final anim = (F >> 2) + a;
    final story = _n(w['story']);

    // 1. Table cloths (story 85: mesa2 and mesa3)
    for (final (tableId, key) in const [
      ('mesa2', 'mantel2'),
      ('mesa3', 'mantel3'),
    ]) {
      final col = w[key] as String?;
      if (col == null) continue;
      final c = _p.cloth(tableId);
      final wBox = c.box[2], hBox = c.box[3];
      final s = Entrada._spr(
        'en_mantel_${tableId}_$col',
        () => mkMantel(wBox, hBox, c.topRows, col),
      );
      final at = _p.atUv(c.uv[0], c.uv[1], c.uv[2]);
      out.add(
        EntradaItem(s, c.box[0], c.box[1], c.screen[1], at.d, tag: 'cosa:$key'),
      );
    }

    // 2. Mesero's stool under taburete (story 85)
    if (_n(w['tabureteVis']) == 1) {
      final uv = _p.uv('taburete');
      final at = _p.atUv(uv[0], uv[1], uv[2] - 0.6);
      final s = Entrada._spr('en_taburete', mkTaburete);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(EntradaItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:taburete'));
    }

    // 3. People (and items held directly by a person)
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, w, open);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        EntradaItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );

      // Mesero carrying plates or full tray during story 84 crossing (`pasa84`)
      if (en.key == 'mesero' && w['meseroCarry'] != null) {
        final carry = w['meseroCarry'] as String;
        final atCarry = _p.atWorld(
          p['x'] as num,
          p['y'] as num,
          (p['z'] as num) + 0.8,
        );
        final cx = _round(atCarry.sx) + _n(p['dx']);
        final cy = _round(atCarry.sy) + _n(p['dy']);
        if (carry == 'platos') {
          final pl = Entrada._spr('en_platos', mkPlatos);
          out.add(
            EntradaItem(
              pl,
              cx - 8,
              cy - pl.h,
              cy,
              atCarry.d + .02,
              tag: 'fx:platos',
              held: 'mesero',
            ),
          );
        } else {
          // OPEN: full tray held by mesero during pasa84(que=bandeja), placed at z + 0.8 like platos.
          final bd = Entrada._spr('en_bandeja_llena', mkBandejaLlena);
          out.add(
            EntradaItem(
              bd,
              cx - 10,
              cy - bd.h,
              cy,
              atCarry.d + .02,
              tag: 'fx:bandeja_llena',
              held: 'mesero',
            ),
          );
        }
      }

      // Abuelo holding his hat in final84(n=1) when the kitchen swing door flaps
      if (en.key == 'abuelo' && _n(w['abueloSombrero']) == 1) {
        // OPEN: abuelo's hat held at chest/lap level (below his top 14 head rows so heads-clear holds).
        final hat = Entrada._spr('en_sombrero', mkSombrero);
        out.add(
          EntradaItem(
            hat,
            sx - 7,
            sy - 18,
            sy,
            at.d + .03,
            tag: 'fx:sombrero',
            held: 'abuelo',
          ),
        );
      }
    }

    // 4. Story 84 table 3 props: flowers & star card
    if (_n(w['floresVis']) == 1) {
      final atF = _p.at('flores');
      final sf = Entrada._spr('en_flores', mkFlores);
      final fx = _round(atF.sx), fy = _round(atF.sy);
      out.add(
        EntradaItem(sf, fx - 5, fy - sf.h, fy, atF.d, tag: 'cosa:flores'),
      );

      final atT = _p.at('tarjeta');
      final st = Entrada._spr('en_estrella', mkEstrella);
      final tx = _round(atT.sx), ty = _round(atT.sy);
      out.add(
        EntradaItem(st, tx - 4, ty - st.h, ty, atT.d, tag: 'cosa:tarjeta'),
      );
    }

    // 5. Story 85 saucer of sweets (`dulces`) on mesero's knee
    final dulcesN = _n(w['dulces']);
    if (story == 85 && dulcesN >= 0) {
      final at = _p.at('dulces');
      final s = Entrada._spr('en_dulces_$dulcesN', () => mkDulces(dulcesN));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        EntradaItem(
          s,
          sx - 6,
          sy - s.h,
          sy,
          at.d + .05,
          tag: 'cosa:dulces',
          held: 'mesero',
        ),
      );
    }

    // 6. Story 86 props: menu, three candles, mesero's tray & cosa_a / cosa_b, coffees, vasito, panera
    if (_n(w['menuVis']) == 1) {
      final open = _n(w['menuOpen']) == 1;
      final nearFlame = _n(w['menuCloseToFlame']) == 1;
      final at = _p.at('menu');
      final s = Entrada._spr('en_menu_$open', () => mkMenu(open: open));
      // OPEN: in final86(n=1), abuelo holds the menu closer to the remaining candle flame (still below heads & behind frog).
      final sx = _round(at.sx) + (nearFlame ? 16 : 0);
      final sy = _round(at.sy);
      out.add(
        EntradaItem(
          s,
          sx - 7,
          sy - s.h,
          sy,
          at.d + .05,
          tag: 'cosa:menu',
          held: nearFlame ? 'abuelo' : 'abuela',
        ),
      );
    }

    if (story == 86) {
      final velasN = _n(w['velas']);
      final smoke = _n(w['velaSmoke']) == 1;
      final at = _p.at('velas');
      final sx = _round(at.sx), sy = _round(at.sy);
      const offs = [-7, 0, 7];
      for (var i = 0; i < 3; i++) {
        final lit = i < velasN;
        final s = Entrada._spr(
          'en_vela_${lit}_${!lit && smoke}',
          () => mkVela(lit: lit, smoke: !lit && smoke),
        );
        out.add(
          EntradaItem(
            s,
            sx + offs[i] - 3,
            sy - s.h,
            sy,
            at.d,
            tag: 'cosa:vela${i + 1}',
            held: 'velas',
          ),
        );
      }

      if (_n(w['cafesVis']) == 1) {
        // OPEN: coffees from cafes86 placed on table 2's far half (v=5.65, z=0.74, d=5.26 < coqui/velas) clear of heads & menu.
        final atAb = _p.atUv(0.95, 5.65, 0.74);
        final cBlack = Entrada._spr(
          'en_cafe_negro',
          () => mkCafe(conLeche: false),
        );
        final ax = _round(atAb.sx), ay = _round(atAb.sy);
        out.add(
          EntradaItem(
            cBlack,
            ax - 4,
            ay - cBlack.h,
            ay,
            atAb.d,
            tag: 'fx:cafe_abuela',
          ),
        );
        final atAbo = _p.atUv(2.05, 5.65, 0.74);
        final cMilk = Entrada._spr(
          'en_cafe_leche',
          () => mkCafe(conLeche: true),
        );
        final bx = _round(atAbo.sx), by = _round(atAbo.sy);
        out.add(
          EntradaItem(
            cMilk,
            bx - 4,
            by - cMilk.h,
            by,
            atAbo.d,
            tag: 'fx:cafe_abuelo',
          ),
        );
      }

      if (_n(w['vasitoVis']) == 1) {
        // OPEN: Coquí's small glass with lemon (vasito86) placed on table 2 between coqui (x<=166) and velas (x>=175).
        final atV = _p.atUv(1.96, 6.45, 0.74);
        final s = Entrada._spr('en_vasito', mkVasito);
        final vx = _round(atV.sx), vy = _round(atV.sy);
        out.add(EntradaItem(s, vx - 3, vy - s.h, vy, atV.d, tag: 'fx:vasito'));
      }

      if (_n(w['paneraVis']) == 1) {
        // OPEN: bread basket (final86) placed on table 2's far middle (u=1.75, v=5.55, z=0.74), clear of heads, coqui, velas.
        final atP = _p.atUv(1.75, 5.55, 0.74);
        final s = Entrada._spr('en_panera', mkPanera);
        final px = _round(atP.sx), py = _round(atP.sy);
        out.add(EntradaItem(s, px - 7, py - s.h, py, atP.d, tag: 'fx:panera'));
      }

      if (_n(w['trayVis']) == 1) {
        final buv = _p.uv('bandeja');
        final cuv = _p.uv('cosa_a');
        final atT = _p.atUv(buv[0], buv[1], cuv[2]);
        final st = Entrada._spr('en_bandejaT', mkBandejaT);
        final tx = _round(atT.sx), ty = _round(atT.sy);
        out.add(
          EntradaItem(
            st,
            tx - 15,
            ty,
            ty,
            atT.d + .02,
            tag: 'cosa:bandeja_t',
            held: 'mesero',
          ),
        );

        final que = (w['trayQue'] as String?) ?? 'agua';
        final izqCon = w['trayIzq'] != 'sin';
        if (_n(w['cosaAVis']) == 1) {
          final atA = _p.at('cosa_a');
          final sa = que == 'pan'
              ? Entrada._spr('en_pan_$izqCon', () => mkCosaPan(con: izqCon))
              : Entrada._spr('en_agua_$izqCon', () => mkCosaAgua(con: izqCon));
          final ax = _round(atA.sx), ay = _round(atA.sy);
          out.add(
            EntradaItem(
              sa,
              ax - 5,
              ay - sa.h,
              ay,
              atA.d + .02,
              tag: 'cosa:cosa_a',
              held: 'mesero',
            ),
          );
        }
        if (_n(w['cosaBVis']) == 1) {
          final atB = _p.at('cosa_b');
          final bCon = !izqCon;
          final sb = que == 'pan'
              ? Entrada._spr('en_pan_$bCon', () => mkCosaPan(con: bCon))
              : Entrada._spr('en_agua_$bCon', () => mkCosaAgua(con: bCon));
          final bx = _round(atB.sx), by = _round(atB.sy);
          out.add(
            EntradaItem(
              sb,
              bx - 5,
              by - sb.h,
              by,
              atB.d + .02,
              tag: 'cosa:cosa_b',
              held: 'mesero',
            ),
          );
        }
      }

      if (_n(w['splashFx']) == 1) {
        final at = _p.at('velas');
        final sp = Entrada._spr(
          'en_splash_${anim % 2}',
          () => mkSalpicadura(anim % 2),
        );
        out.add(
          EntradaItem(
            sp,
            _round(at.sx) - 6,
            _round(at.sy) - 18,
            _round(at.sy),
            at.d + .04,
            tag: 'fx:splash',
          ),
        );
      }
    }

    // 7. Music notes from vellonera (final85) & celebration heart (3-of-3 endings)
    if (_n(w['musicaFx']) == 1) {
      // OPEN: music notes floating above vellonera [123,33,20,40] in final85, clear of all heads.
      final nt = Entrada._spr(
        'en_notas_${anim % 2}',
        () => mkNotasMusica(anim % 2),
      );
      out.add(
        EntradaItem(nt, 126, 20, 20, 5.0, tag: 'fx:musica', overlay: true),
      );
    }

    if (_n(w['final84']) == 3 ||
        _n(w['final85']) == 3 ||
        _n(w['final86']) == 3) {
      // OPEN: 3-of-3 celebration heart placed high above the room at (161, 22), clear of every character head.
      final cor = Entrada._spr('en_corazon', mkCorazon);
      out.add(
        EntradaItem(cor, 161, 22, 22, 5.0, tag: 'fx:corazon', overlay: true),
      );
    }

    return out;
  }

  List<EntradaItem> _entradaPlaced(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final ox = b.x.toInt() - 16 + dx;
      final oy = b.y.toInt() - 24;
      final fk =
          '${q['s']}_${b.x - (b.x.toInt() - 16)}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + 0.5).floor()}_${host.F % 47 < 2 ? 1 : 0}_${((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0) ? 1 : 0}';
      final spr = Entrada._frogSprites.putIfAbsent(fk, () {
        final px = Uint32List(64 * 64);
        final g = Ctx(px, 64, 64)
          ..translate(-(b.x.toInt() - 16).toDouble(), -oy.toDouble());
        host.frog(g, q, a);
        return Sprite(64, 64, px);
      });
      out.add(EntradaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
      if (_n(w['coquiCorbata']) == 1) {
        final bt = Entrada._spr('en_corbata', mkCorbata);
        final cx = _round(at.sx) + dx;
        final cy = fsy + _n(q['dy']);
        out.add(
          EntradaItem(
            bt,
            cx - 4,
            cy - 11,
            fsy,
            at.d + .01,
            tag: 'fx:corbata',
            held: 'coqui',
          ),
        );
      }
    }
    return out;
  }
}
