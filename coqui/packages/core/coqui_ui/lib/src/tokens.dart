/// The look's numbers, every one copied from the old web app (v=39).
///
/// Each constant is named after the CSS variable or class it comes from and
/// carries its source: file and line of the `<style>` block. The old app has
/// one light theme in app.html and one dark "lesson" theme in cual.html and
/// index.html (and nivel.html, habla-prueba.html); it has no `prefers-color-scheme`
/// rule and no other dark variant, so there is nothing to port besides those two.
library;

import 'package:material_ui/material_ui.dart';

/// Colours. Light screens: `:root` of historia/app.html line 11. Lesson screens
/// (dark grey, full screen): `:root` of historia/cual.html line 9 (the same in
/// index.html line 9 and nivel.html line 9).
abstract final class CoquiColors {
  // ---- app.html:11 :root (the light screens) ----

  /// `--bg` the page. app.html:11
  static const bg = Color(0xFFF6F5F1);

  /// `--card` cards, sheets' surfaces. app.html:11
  static const card = Color(0xFFFFFFFF);

  /// `--ink` titles and body text. app.html:11
  static const ink = Color(0xFF16181D);

  /// `--mut` secondary text, inactive tab. app.html:11
  static const mut = Color(0xFF636A75);

  /// `--line` hairlines and card rings. app.html:11
  static const line = Color(0xFFE3E1DA);

  /// `--line2` the outline button's border, the quiet play disc's ring. app.html:11
  static const line2 = Color(0xFFC9C6BB);

  /// `--tint` the pressed fill of a tappable line. app.html:11
  static const tint = Color(0xFFEEF1FF);

  /// `--ok` green: anything that starts or continues learning, right, done. app.html:11
  static const ok = Color(0xFF17803F);

  /// `--bad` red-orange: wrong. app.html:11
  static const bad = Color(0xFFD9480F);

  /// `--info` blue: every other primary action, the active tab. app.html:11
  static const info = Color(0xFF3B5BDB);

  // ---- app.html, other colours written in rules ----

  /// `nav` and `#topchips` background `#fff`. app.html:38, 60
  static const white = Color(0xFFFFFFFF);

  /// `.btn:disabled` fill. app.html:25 (also `.cc.lk` app.html:132)
  static const disabledFill = Color(0xFFF2F1EC);

  /// `.cov` cover placeholder. app.html:98
  static const coverFill = Color(0xFFECEAE3);

  /// `.wc canvas{background:#222}` and `.wsp{background:#222}`: the colour behind a picture that
  /// fills its box edge to edge (the word sheet's big picture, [PictureFrame]). A word card's
  /// picture area is the card's own surface instead ([card]). app.html:89, 95
  static const pictureBack = Color(0xFF222222);

  /// `.sw::before` switch track, off. app.html:33
  static const switchOff = Color(0xFFD5D3CC);

  /// `#shead .grab` the sheet's drag handle. app.html:77
  static const grab = Color(0xFFC9C7C0);

  /// `.dts i` the empty meter dot's outline (3:1 on white). app.html:94
  static const dotOutline = Color(0xFF8A8F99);

  /// `#sheetbg` scrim, `rgba(0,0,0,.35)`. app.html:68
  static const scrim = Color(0x59000000);

  /// `#t-mapa` background, the map's water behind everything. app.html:35
  static const mapWater = Color(0xFF5C94FC);

  /// `.tb.mid.on .disc` shadow, `rgba(59,91,219,.4)`. app.html:66
  static const mapDiscGlow = Color(0x663B5BDB);

  /// `.card`, `.wc` drop shadow, `rgba(0,0,0,.06)`. app.html:20, 88
  static const cardShadow = Color(0x0F000000);

  /// `.play` (the Today card) drop shadow, `rgba(0,0,0,.22)`. app.html:54
  static const todayShadow = Color(0x38000000);

  // ---- cual.html:9 :root (the dark lesson screens) ----

  /// `--bg` of the lesson frame. cual.html:9
  static const lessonBg = Color(0xFF1B1B1F);

  /// `--ink` on the lesson frame. cual.html:9
  static const lessonInk = Color(0xFFFFFFFF);

  /// `--ink2` secondary text and icons on the lesson frame. cual.html:9
  static const lessonInk2 = Color(0xFFC9C9D1);

  /// `--line` the lesson's outline button border, option frames. cual.html:9
  static const lessonLine = Color(0xFF4A4A52);

  /// `--grn` the lesson's green (the same as [ok]). cual.html:9
  static const lessonGreen = Color(0xFF17803F);

  /// `--blu` the lesson's blue (the same as [info]). cual.html:9
  static const lessonBlue = Color(0xFF3B5BDB);

  /// `--bad` a wrong option's ring. cual.html:9
  static const lessonBad = Color(0xFFD9480F);

  /// `.dot` a progress dash not yet reached. cual.html:20 (app.html `.lbbar` line 109)
  static const dotOff = Color(0xFF3A3A42);

  /// A Repaso dash that was skipped (the speaking item the learner said he cannot do now): a neutral grey, lighter than
  /// [dotOff] (not reached) and neither green nor red-orange. Not in v=39: chosen for the games.
  static const dotSkipped = Color(0xFF74747E);

  /// `.ib:active` pressed icon button, `rgba(255,255,255,.1)`. cual.html:18
  static const iconPressed = Color(0x1AFFFFFF);

  /// `.sec:active` pressed outline button, `rgba(255,255,255,.08)`. cual.html:59
  static const secondaryPressed = Color(0x14FFFFFF);

  /// `#go` start disc shadow, `rgba(0,0,0,.35)`. cual.html:53
  static const discShadow = Color(0x59000000);

  /// The dim laid over a picture that is not the answer: `rgba(6,14,28,.55)`. cual.js:39
  static const optionDimUnchosen = Color(0x8C060E1C);

  /// The dim over both pictures while the sentence plays: `rgba(6,14,28,.5)`. cual.js:39
  static const optionDimWhileSentence = Color(0x80060E1C);

  /// `--ink3` the faintest text on a lesson screen. habla-prueba.html:9
  static const lessonInk3 = Color(0xFF8E8E98);

  /// `--heard` what the app heard the learner say. habla-prueba.html:9
  static const heard = Color(0xFF9AD5A8);

  /// `.opt.sel` the touched option's ring in the level check (white). cual.html:69
  static const optionSelected = Color(0xFFFFFFFF);

  /// `.lbl.now` the lit line of a book. app.html:117
  static const bookLineLit = Color(0xFF245A3B);

  /// `.lbl.now` the lit line's left bar and speaker. app.html:117
  static const bookLineLitBar = Color(0xFF3DDC84);

  /// `.lbl:active` a pressed book line. app.html:117
  static const bookLinePressed = Color(0xFF2A2A32);

  /// `.lbl .spk` the speaker glyph beside a book line. app.html:116
  static const bookSpeaker = Color(0xFF9A9AA6);

  // ---- Repaso's games (order 27): the tiles on the lesson frame. Not in v=39; chosen to sit between the frame
  // (`--bg`) and its lines (`--line`), so a tile reads as a thing to touch and a ring still shows round it.

  /// A word or speaker tile's face.
  static const lessonTile = Color(0xFF2A2A31);

  /// A tile while the finger is down on it.
  static const lessonTilePressed = Color(0xFF34343D);

  /// The "N in a row" chip.
  static const lessonChip = Color(0xFF2A2A31);

  /// The streak's flame, its body: the median colour of the inside of the fire emoji glyph the old chip shows
  /// (`hud()`, app.html:286), measured on references 012 (both phones): `#FF7003`.
  static const flameBody = Color(0xFFFF7003);

  /// The streak's flame, its core: the median of the glyph's yellow part, `#FFF293`. Same measure.
  static const flameCore = Color(0xFFFFF293);
}

/// Sizes in logical pixels (CSS px). The old app uses an 8-point grid.
abstract final class CoquiMetrics {
  // ---- spacing: the 8-point grid (ui-decisiones-2: 16 between targets and cards,
  // 24 between sections, 16 side margins) ----
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;

  /// `--r` the card radius. app.html:11
  static const double radiusCard = 16;

  /// `.btn` and `.seg button` radius. app.html:22, 31
  static const double radiusButton = 12;

  /// `#sheet` top corners. app.html:70
  static const double radiusSheet = 24;

  /// `.cov`, `.lbpic img`, lesson `canvas` radius. app.html:98, 112; cual.html:30
  static const double radiusPicture = 8;

  /// `.wsp` the word sheet's big picture. app.html:95
  static const double radiusWordPicture = 12;

  /// `.btn` minimum height, every target is 48 or more. app.html:22
  static const double targetMin = 48;

  /// `.btn` side padding. app.html:22
  static const double buttonPadX = 24;

  /// `.btn` and `.sec` border. app.html:22; cual.html:58
  static const double borderButton = 1.5;

  /// `.pb` the round play control. app.html:26
  static const double playDisc = 48;

  /// `#go` the lesson's start disc. cual.html:53
  static const double startDisc = 72;

  /// `.ib` icon button. cual.html:17
  static const double iconButton = 48;

  /// `--navh` the tab bar's height. app.html:11
  static const double navHeight = 72;

  /// `--rise` how far the Mapa disc stands above the tab bar. app.html:11
  static const double rise = 14;

  /// `--navh` / `--rise` on a phone on its side. app.html:50
  static const double navHeightLandscape = 56;
  static const double riseLandscape = 18;

  /// `.tb.mid .disc` 56 px, 44 px on its side. app.html:64, 137
  static const double mapDisc = 56;
  static const double mapDiscLandscape = 44;

  /// `.tab` extra padding at the foot so the raised disc never covers content: `--navh` + 68. app.html:15
  static const double tabPageFootExtra = 68;

  /// `.tab` and `#hoy` and `#sheet` and `nav .in` width cap. app.html:15, 48, 61, 70
  static const double columnMax = 560;

  /// `#topchips` height (+ the safe area at the top). app.html:38
  static const double chipsHeight = 48;

  /// `#shead` the sheet's header bar. app.html:74
  static const double sheetHeader = 56;

  /// `#sheet` at most 70% of the screen high (85% for the welcome). app.html:70, 73
  static const double sheetMaxFraction = 0.70;
  static const double sheetModalMaxFraction = 0.85;

  /// `#top` the lesson's top bar (+ the safe area). cual.html:16
  static const double lessonTopBar = 56;

  /// `#bar` the progress dashes' longest width. cual.html:19
  static const double lessonBarMax = 480;

  /// `.dot` height. cual.html:20
  static const double dotHeight = 6;

  /// The reader's foot row and column: `.lbfoot{max-width:560px;padding:8px 16px 16px}`, its buttons 56 px
  /// high, the back arrow on the last page 72 wide (`.lbb.ar`). app.html:120, 122-123
  static const double readerColumnMax = 560;
  static const double readerBackWidth = 72;

  /// `.opt.chk::after` the check badge: 28 px, 8 px from the picture's top and right, a 2 px white ring
  /// outside it. cual.html:49
  static const double badgeSize = 28;
  static const double badgeInset = 8;
  static const double badgeRing = 2;

  /// `#main` padding at the foot: the start disc (72) and the 40 px under it. cual.html:27
  static const double lessonFootReserve = 112;

  /// `.pri` height. cual.html:55
  static const double primaryHeight = 56;

  /// `.sec` height. cual.html:58
  static const double secondaryHeight = 48;

  /// `.pri`, `.sec`, `#fin>*` width cap. cual.html:35, 55, 58
  static const double lessonColumnMax = 480;

  /// `.fade` and `#fadeTab` height. app.html:42, 134
  static const double fadeList = 16;

  /// `#sbody` mask at the foot. app.html:82
  static const double fadeSheet = 24;

  /// `.wc canvas` the word card picture's aspect, 196 x 104. app.html:89
  static const double wordPictureAspect = 196 / 104;

  /// `.dts i` a meter dot, its border, its gap. app.html:94
  static const double dotSize = 10;
  static const double dotBorder = 1.5;
  static const double dotGap = 4;

  /// `.ml` the meter label's width. app.html:93
  static const double meterLabelWidth = 44;

  /// `.row` and `.cc` minimum heights, `.li`, `.play`. app.html:21, 29, 54, 130
  static const double rowMin = 56;
  static const double listRowMin = 64;
  static const double todayMin = 80;

  /// `.cov` the cover on a shelf row (64 px on a 360 px phone). app.html:98, 101
  static const double cover = 72;
  static const double coverSmall = 64;

  /// `.sw` the switch: the 48 px touch target holding a 52 x 32 track. app.html:32, 33
  static const double switchWidth = 52;
  static const double switchTrackHeight = 32;
}

/// Shadows and rings. Flutter paints a shadow list first to last, bottom to top;
/// CSS paints it first on top, so each list below is in Flutter's order.
abstract final class CoquiShadows {
  /// `.card`, `.wc`: `0 1px 2px rgba(0,0,0,.06), 0 0 0 1px var(--line)`. app.html:20, 88
  static const card = <BoxShadow>[
    BoxShadow(color: CoquiColors.line, spreadRadius: 1),
    BoxShadow(
      color: CoquiColors.cardShadow,
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// `.play` the Today card: `0 4px 16px rgba(0,0,0,.22)`. app.html:54
  static const today = <BoxShadow>[
    BoxShadow(
      color: CoquiColors.todayShadow,
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// `#go` the start disc: `0 4px 16px rgba(0,0,0,.35)`. cual.html:53
  static const startDisc = <BoxShadow>[
    BoxShadow(
      color: CoquiColors.discShadow,
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// `.tb.mid.on .disc`: `0 4px 12px rgba(59,91,219,.4)`. app.html:66
  static const mapDiscActive = <BoxShadow>[
    BoxShadow(
      color: CoquiColors.mapDiscGlow,
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// `nav`: `0 -1px 0 var(--line)`, a hairline over the bar. app.html:60
  static const navTop = <BoxShadow>[
    BoxShadow(color: CoquiColors.line, offset: Offset(0, -1)),
  ];

  /// `#shead.sc`: `0 1px 0 var(--line)`, a hairline under the header once rows scroll. app.html:75
  static const sheetHeader = <BoxShadow>[
    BoxShadow(color: CoquiColors.line, offset: Offset(0, 1)),
  ];
}
