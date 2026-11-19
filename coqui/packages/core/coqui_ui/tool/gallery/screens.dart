/// The gallery's screens: each is the shared widgets arranged the way one screen of
/// v=39 arranges them, so that it can be held against the reference picture it
/// comes from. Words, titles and place names are placeholders (the real ones are
/// course content); the labels the old page hard-codes are copied.
library;

import 'dart:typed_data';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sample_art.dart';

/// A phone screen in CSS pixels: the Android reference size.
const screenSize = Size(412, 915);

/// One gallery section.
class GallerySection {
  const GallerySection(this.name, this.title, this.refs, this.builder);

  /// The `?section=` name.
  final String name;
  final String title;

  /// Reference pictures under `coqui/ref/pantallas/android-412x915/` that this
  /// section is to be compared with ("-" for none).
  final List<String> refs;
  final WidgetBuilder builder;
}

final _scene = sampleScene(196, 104);
final _scene2 = sampleScene(196, 104, variant: 2);
final _scene3 = sampleScene(196, 104, variant: 4);
final _story = sampleScene(196, 216);
final _map = sampleMap();

Widget _pic(Uint32List p, {int w = 196, int h = 104}) =>
    PixelView(pixels: p, width: w, height: h);

/// The gallery's screens, in order.
final List<GallerySection> gallerySections = [
  GallerySection(
    'tokens-colours',
    'Colours',
    const [],
    (c) => const _Colours(),
  ),
  GallerySection('tokens-type', 'Type', const [], (c) => const _Types()),
  GallerySection(
    'map',
    'Map: chips, Today card, tab bar with the Mapa disc active',
    const ['012-mapa-a-medio-curso.png', '009-mapa-nada-jugado.png'],
    (c) => const _MapScreen(),
  ),
  GallerySection(
    'tabbar',
    'Tab bar: each tab active, the Mapa disc inactive',
    const [
      '030-palabras-a-medio-curso.png',
      '047-biblioteca-a-medio-curso.png',
      '069-yo-nada-jugado.png',
      '063-hablar-nada-jugado.png',
    ],
    (c) => const _TabBars(),
  ),
  GallerySection(
    'palabras',
    'Palabras: Repaso card, word cards, meters, fade under the list',
    const ['030-palabras-a-medio-curso.png'],
    (c) => const _PalabrasScreen(),
  ),
  GallerySection('biblioteca', 'Biblioteca: shelf rows in a card', const [
    '047-biblioteca-a-medio-curso.png',
  ], (c) => const _BibliotecaScreen()),
  GallerySection('yo', 'Yo: stat cards, a card, pills, switches', const [
    '069-yo-nada-jugado.png',
  ], (c) => const _YoScreen()),
  GallerySection(
    'sheet-place',
    'Bottom sheet: the place sheet, over its scrim',
    const ['015-lugar-abierto-1-nada-jugado.png'],
    (c) => const _PlaceSheetScreen(),
  ),
  GallerySection(
    'sheet-word',
    'Bottom sheet: the word sheet (big picture, meters, rows)',
    const ['038-palabra-con-imagen-oido-3-vuelve-en-dias.png'],
    (c) => const _WordSheetScreen(),
  ),
  GallerySection('lesson-start', 'Lesson frame: the start screen', const [
    '130-cuento-inicio.png',
  ], (c) => const _LessonStart()),
  GallerySection(
    'lesson-answer',
    'Lesson frame: two pictures, a caption, a right answer',
    const ['086-repaso-toque-bien.png'],
    (c) => const _LessonAnswer(),
  ),
  GallerySection(
    'lesson-end',
    'Lesson frame: an end screen with a list, the fade, the 56 px button',
    const ['090-repaso-fin-a-subir-y-a-repasar.png'],
    (c) => const _LessonEnd(),
  ),
  GallerySection(
    'sheet-modal',
    'Bottom sheet: the welcome (modal: no header, a footer with dots and a button)',
    const ['002-bienvenida-paso-2.png', '001-bienvenida-paso-1.png'],
    (c) => const _ModalSheetScreen(),
  ),
  GallerySection(
    'words-states',
    'Meters 0 to 4, word cards: picture, plain tile, a long word, the fades',
    const [
      '030-palabras-a-medio-curso.png',
      '038-palabra-con-imagen-oido-3-vuelve-en-dias.png',
    ],
    (c) => const _WordStates(),
  ),
  GallerySection(
    'buttons',
    'Buttons on the light screens: every kind, every state',
    const [
      '030-palabras-a-medio-curso.png',
      '047-biblioteca-a-medio-curso.png',
      '069-yo-nada-jugado.png',
      '015-lugar-abierto-1-nada-jugado.png',
    ],
    (c) => const _Buttons(),
  ),
  GallerySection(
    'buttons-lesson',
    'Buttons on the lesson frame: icon buttons, start disc, 56 px and 48 px buttons',
    const [
      '130-cuento-inicio.png',
      '090-repaso-fin-a-subir-y-a-repasar.png',
      '053-libro-primera-pagina-linea-1-luce.png',
    ],
    (c) => const _LessonButtons(),
  ),
  GallerySection(
    'pixelview',
    'PixelView: 196 x 216 at 5 device pixels a pixel',
    const ['130-cuento-inicio.png'],
    (c) => const _PixelViewDemo(),
  ),
];

// ---------------------------------------------------------------------------

class _TabScreen extends StatelessWidget {
  const _TabScreen({required this.selected, required this.body});
  final String selected;
  final Widget body;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.bg,
    child: Stack(
      children: [
        Positioned.fill(child: body),
        Positioned(
          left: 0,
          right: 0,
          bottom: CoquiLayout.tabBarHeight(context),
          child: const ListFade(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: CoquiTabBar(selectedId: selected, onTap: (_) {}),
        ),
      ],
    ),
  );
}

class _MapScreen extends StatelessWidget {
  const _MapScreen();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.mapWater,
    child: Stack(
      children: [
        Column(
          children: [
            MapChips(
              streak: MapChips.streakLabel(5),
              place: MapChips.placeLabel(2, 'Place two'),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 118),
                  child: _pic(_map, w: 240, h: 352),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: CoquiLayout.tabBarHeight(context) + CoquiMetrics.rise + 16,
          child: TodayCard(
            eyebrow: 'Today · 1 of 6',
            title: 'Review',
            subtitle: '10 words coming back · 6 min',
            onPressed: () {},
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: CoquiTabBar(selectedId: CoquiTabs.mapId, onTap: (_) {}),
        ),
      ],
    ),
  );
}

class _TabBars extends StatelessWidget {
  const _TabBars();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.bg,
    child: Column(
      children: [
        const SizedBox(height: 24),
        for (final t in CoquiTabs.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16),
                  child: Text('${t.label} active', style: CoquiText.smallMuted),
                ),
                CoquiTabBar(selectedId: t.id, onTap: (_) {}),
              ],
            ),
          ),
      ],
    ),
  );
}

class _PalabrasScreen extends StatelessWidget {
  const _PalabrasScreen();

  @override
  Widget build(BuildContext context) => _TabScreen(
    selected: CoquiTabs.wordsId,
    body: TabPage(
      children: [
        const ScreenTitle('Palabras'),
        CoquiCard(
          child: CoquiRow(
            minHeight: 0,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Repaso', style: CoquiText.rowBold),
                    Text(
                      '10 words today · about 2 min',
                      style: CoquiText.smallMuted,
                    ),
                  ],
                ),
              ),
              CoquiButton(
                label: 'Start',
                kind: CoquiButtonKind.go,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SectionTitle('Place one'),
        const KeyLine(
          'Ear: you know it when you hear it. Mouth: you can say it.',
        ),
        WordGrid(
          children: [
            WordCard(word: 'first', picture: _pic(_scene), ear: 3, mouth: 0),
            WordCard(word: 'second', picture: _pic(_scene2), ear: 3, mouth: 0),
            WordCard(word: 'third', picture: _pic(_scene3), ear: 3, mouth: 0),
            WordCard(word: 'fourth', picture: _pic(_scene), ear: 3, mouth: 0),
            WordCard(word: 'fifth', picture: _pic(_scene2), ear: 3, mouth: 3),
            const WordCard(word: 'plain', ear: 3, mouth: 0),
          ],
        ),
      ],
    ),
  );
}

class _BibliotecaScreen extends StatelessWidget {
  const _BibliotecaScreen();

  @override
  Widget build(BuildContext context) {
    Widget row(
      String title,
      String sub, {
      bool read = false,
      bool cover = false,
    }) => ShelfRow(
      title: title,
      subtitle: sub,
      cover: cover ? _pic(_scene, w: 196, h: 104) : null,
      actions: [
        CoquiButton(
          label: 'Listen',
          icon: CoquiIcons.play,
          kind: CoquiButtonKind.go,
          padX: 16,
          onPressed: () {},
        ),
        if (read)
          CoquiButton(
            label: 'Read',
            icon: CoquiIcons.read,
            kind: CoquiButtonKind.outline,
            padX: 16,
            onPressed: () {},
          ),
      ],
    );
    return _TabScreen(
      selected: CoquiTabs.libraryId,
      body: TabPage(
        children: [
          const ScreenTitle('Biblioteca'),
          const SectionTitle('Place one'),
          CoquiCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DividedRows(
              rows: [
                row('Story one', 'about 2 min'),
                row('Story two', 'about 3 min'),
                row('Story three', 'about 3 min'),
                row('Story four', 'Heard 1× · about 4 min'),
                row('Story five', 'about 3 min'),
                row('Story six', 'about 4 min', read: true, cover: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YoScreen extends StatelessWidget {
  const _YoScreen();

  @override
  Widget build(BuildContext context) => _TabScreen(
    selected: CoquiTabs.meId,
    body: TabPage(
      children: [
        const ScreenTitle('Yo'),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(value: '\u{1F525} 0', label: 'day streak'),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: StatCard(value: '0', label: 'minutes listened'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: StatCard(value: '0', label: 'words heard'),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatCard(value: '0', label: 'words good'),
                  ),
                ],
              ),
            ],
          ),
        ),
        CoquiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EyebrowLabel('Where you are'),
              const SizedBox(height: 4),
              Text('A1 · place 1 of 10 · Place one', style: CoquiText.h2),
            ],
          ),
        ),
        const SectionTitle('Minutes a day'),
        SegmentedPills(
          labels: const ['15', '30', '60', '120'],
          selected: 1,
          onSelected: (_) {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Today\'s plan is sized to this.',
            style: CoquiText.smallMuted,
          ),
        ),
        CoquiCard(
          child: CoquiRow(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Open every place', style: CoquiText.rowBold),
                    Text(
                      'To look ahead. Places not built yet stay empty.',
                      style: CoquiText.smallMuted,
                    ),
                  ],
                ),
              ),
              CoquiSwitch(value: false, onChanged: (_) {}),
            ],
          ),
        ),
        CoquiCard(
          child: CoquiRow(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Speak in stories', style: CoquiText.rowBold),
                    Text(
                      'Some of the coquí\'s lines become your turn: you say them and the app listens.',
                      style: CoquiText.smallMuted,
                    ),
                  ],
                ),
              ),
              CoquiSwitch(value: true, onChanged: (_) {}),
            ],
          ),
        ),
        CoquiCard(
          child: CoquiRow(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level check', style: CoquiText.rowBold),
                    Text(
                      'For people who already understand some Spanish. About 3 minutes, touch only.',
                      style: CoquiText.smallMuted,
                    ),
                  ],
                ),
              ),
              CoquiButton(
                label: 'Start',
                kind: CoquiButtonKind.outline,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _placeRows() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('Place 1 · Grandma\'s house', style: CoquiText.smallMuted),
    ),
    DividedRows(
      rows: [
        for (var i = 0; i < 9; i++)
          ListRow(
            title: ListRowTitle('Story number ${i + 1}'),
            subtitle: const Text('New · about 3 min'),
            trailing: PlayButton(
              quiet: i != 0,
              semanticLabel: 'Play',
              onPressed: () {},
            ),
          ),
      ],
    ),
  ],
);

class _PlaceSheetScreen extends StatelessWidget {
  const _PlaceSheetScreen();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.mapWater,
    child: Stack(
      children: [
        Column(
          children: [
            MapChips(
              streak: MapChips.streakLabel(0),
              place: MapChips.placeLabel(1, 'Place one'),
            ),
            Expanded(child: Center(child: _pic(_map, w: 240, h: 352))),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: CoquiTabBar(selectedId: CoquiTabs.mapId, onTap: (_) {}),
        ),
        CoquiSheetLayer(
          open: true,
          sheet: CoquiSheet(
            title: 'Place one',
            onClose: () {},
            child: _placeRows(),
          ),
        ),
      ],
    ),
  );
}

class _WordSheetScreen extends StatelessWidget {
  const _WordSheetScreen();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const _PalabrasScreen(),
      CoquiSheetLayer(
        open: true,
        sheet: CoquiSheet(
          title: 'sample',
          onClose: () {},
          titleVisible: false,
          child: CollapsingColumn(
            children: [
              Block(
                bottom: 16,
                child: Center(
                  child: PictureFrame(
                    radius: CoquiMetrics.radiusWordPicture,
                    child: _pic(_scene2),
                  ),
                ),
              ),
              Block(
                bottom: 8,
                child: Text(
                  'sample',
                  textAlign: TextAlign.center,
                  style: CoquiText.h1,
                ),
              ),
              const Center(
                child: EarMouthMeters(ear: 3, mouth: 0, centered: true),
              ),
              Block(
                top: 16,
                child: Text(
                  'Comes back in 1 day',
                  textAlign: TextAlign.center,
                  style: CoquiText.smallMuted,
                ),
              ),
              const SectionTitle('Heard in'),
              CoquiCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DividedRows(
                  rows: [
                    for (final s in ['Story one', 'Story two', 'Story three'])
                      ListRow(
                        title: Text.rich(
                          TextSpan(
                            style: CoquiText.body,
                            children: [
                              const TextSpan(text: 'A line with the '),
                              TextSpan(
                                text: 'sample',
                                style: CoquiText.rowBold,
                              ),
                              const TextSpan(text: ' word.'),
                            ],
                          ),
                        ),
                        subtitle: Text(s),
                        trailing: PlayButton(onPressed: () {}),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _LessonStart extends StatelessWidget {
  const _LessonStart();

  @override
  Widget build(BuildContext context) => LessonFrame(
    onClose: () {},
    onSound: () {},
    progress: const LessonProgressDashes(segments: 5, done: 0),
    picture: PictureFrame(child: _pic(_story, w: 196, h: 216)),
    bottom: [LessonStartButton(onPressed: () {})],
    startState: true,
  );
}

class _LessonAnswer extends StatelessWidget {
  const _LessonAnswer();

  Widget _opt(
    Uint32List p, {
    Color ring = CoquiColors.lessonLine,
    double w = 1.5,
    bool check = false,
  }) => Stack(
    clipBehavior: Clip.none,
    children: [
      DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(
            color: ring,
            width: w,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: _pic(p),
      ),
      if (check)
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CoquiColors.lessonGreen,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const CoquiIcon(
              CoquiIcons.badgeCheck,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => LessonFrame(
    onClose: () {},
    onSound: () {},
    progress: const LessonProgressDashes(segments: 10, done: 0),
    caption: 'A sample caption.',
    picture: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _opt(_scene3),
        const SizedBox(height: 24),
        _opt(_scene, ring: CoquiColors.lessonGreen, w: 3, check: true),
      ],
    ),
  );
}

class _LessonEnd extends StatelessWidget {
  const _LessonEnd();

  /// cual.js draws these at 1 device pixel a picture pixel on this phone: 196 / 2.625 css px.
  static const _pw = 196 / 2.625;

  Widget _group(String title, String sub, List<String> words) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      Text(title, style: CoquiText.lessonH2),
      const SizedBox(height: 4),
      Text(sub, style: CoquiText.lessonSub),
      const SizedBox(height: 12),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final w in words)
            SizedBox(
              width: _pw,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CoquiColors.lessonLine,
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: SizedBox(width: _pw, child: _pic(_scene2)),
                  ),
                  const SizedBox(height: 8),
                  Text(w, style: CoquiText.lessonWord),
                ],
              ),
            ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => LessonFrame(
    showClose: false,
    showSound: false,
    progress: const LessonProgressDashes(segments: 10, done: 10),
    overlay: Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 96 - 24 - 24,
      child: FadingEdges(
        top: 16,
        bottom: 16,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 3 * _pw + 2 * 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Done', style: CoquiText.lessonH1),
                  const SizedBox(height: 8),
                  Text(
                    '8 moving up · 2 coming back soon',
                    style: CoquiText.lessonBody,
                  ),
                  _group('Moving up', 'You\'ll see these less often', [
                    'one',
                    'two',
                    'three',
                    'four',
                    'five',
                    'six',
                    'seven',
                    'eight',
                  ]),
                  _group('Coming back soon', 'You\'ll see these again soon', [
                    'nine',
                    'ten',
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    bottom: [LessonButton(label: 'Back to Palabras', onPressed: () {})],
  );
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  Widget _h(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(t, style: CoquiText.smallMuted),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.bg,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _h('.btn blue (primary), .btn.go green, .btn.out outline, disabled'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            CoquiButton(label: 'Next', onPressed: () {}),
            CoquiButton(
              label: 'Start',
              kind: CoquiButtonKind.go,
              onPressed: () {},
            ),
            CoquiButton(
              label: 'Start',
              kind: CoquiButtonKind.outline,
              onPressed: () {},
            ),
            const CoquiButton(
              label: 'Start',
              kind: CoquiButtonKind.go,
              onPressed: null,
            ),
            const CoquiButton(
              label: 'Start',
              kind: CoquiButtonKind.outline,
              onPressed: null,
            ),
          ],
        ),
        _h('with an icon (Listen, Read)'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            CoquiButton(
              label: 'Listen',
              icon: CoquiIcons.play,
              kind: CoquiButtonKind.go,
              padX: 16,
              onPressed: () {},
            ),
            CoquiButton(
              label: 'Read',
              icon: CoquiIcons.read,
              kind: CoquiButtonKind.outline,
              padX: 16,
              onPressed: () {},
            ),
          ],
        ),
        _h('.btn.full'),
        CoquiButton(label: 'Next', full: true, onPressed: () {}),
        const SizedBox(height: 16),
        CoquiButton(
          label: 'How it works',
          full: true,
          kind: CoquiButtonKind.outline,
          onPressed: () {},
        ),
        _h('.pb: play, stop, phone, the quiet one'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            PlayButton(onPressed: () {}),
            PlayButton(icon: CoquiIcons.stop, onPressed: () {}),
            PlayButton(icon: CoquiIcons.phone, onPressed: () {}),
            PlayButton(quiet: true, onPressed: () {}),
          ],
        ),
        _h('sheet close X'),
        CoquiCloseButton(onPressed: () {}),
      ],
    ),
  );
}

class _LessonButtons extends StatelessWidget {
  const _LessonButtons();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.lessonBg,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LessonCloseButton(onPressed: () {}),
              LessonSoundButton(onPressed: () {}),
              LessonSoundButton(muted: true, onPressed: () {}),
              LessonTextSizeButton(onPressed: () {}),
              LessonTextSizeButton(big: true, onPressed: () {}),
            ],
          ),
          const SizedBox(height: 16),
          LessonStartButton(onPressed: () {}),
          LessonButton(label: 'Next story', onPressed: () {}),
          const SizedBox(height: 16),
          LessonButton(
            label: 'Map',
            kind: LessonButtonKind.blue,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          LessonButtonRow(
            children: [
              LessonButton(
                label: 'Play again',
                kind: LessonButtonKind.outline,
                fillWidth: false,
                onPressed: () {},
              ),
              LessonButton(
                label: 'Map',
                kind: LessonButtonKind.outline,
                fillWidth: false,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          const LessonButton(label: 'Disabled', onPressed: null),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: LessonButton(
                  height: 56,
                  kind: LessonButtonKind.outline,
                  fillWidth: false,
                  onPressed: () {},
                  child: const CoquiIcon(
                    CoquiIcons.left,
                    size: 28,
                    color: CoquiColors.lessonInk2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LessonButton(
                  height: 56,
                  fillWidth: false,
                  onPressed: () {},
                  child: const CoquiIcon(
                    CoquiIcons.right,
                    size: 28,
                    color: CoquiColors.lessonInk,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PixelViewDemo extends StatelessWidget {
  const _PixelViewDemo();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.lessonBg,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: PixelView(
          pixels: sampleGrid(196, 216),
          width: 196,
          height: 216,
          onTapPixel: (x, y) {},
        ),
      ),
    ),
  );
}

class _Colours extends StatelessWidget {
  const _Colours();

  static const _light = <(String, Color, String)>[
    ('--bg', CoquiColors.bg, 'app.html:11'),
    ('--card', CoquiColors.card, 'app.html:11'),
    ('--ink', CoquiColors.ink, 'app.html:11'),
    ('--mut', CoquiColors.mut, 'app.html:11'),
    ('--line', CoquiColors.line, 'app.html:11'),
    ('--line2', CoquiColors.line2, 'app.html:11'),
    ('--tint', CoquiColors.tint, 'app.html:11'),
    ('--ok', CoquiColors.ok, 'app.html:11'),
    ('--bad', CoquiColors.bad, 'app.html:11'),
    ('--info', CoquiColors.info, 'app.html:11'),
    ('disabledFill', CoquiColors.disabledFill, 'app.html:25'),
    ('coverFill', CoquiColors.coverFill, 'app.html:98'),
    ('pictureBack', CoquiColors.pictureBack, 'app.html:89'),
    ('switchOff', CoquiColors.switchOff, 'app.html:33'),
    ('grab', CoquiColors.grab, 'app.html:77'),
    ('dotOutline', CoquiColors.dotOutline, 'app.html:94'),
    ('mapWater', CoquiColors.mapWater, 'app.html:35'),
  ];
  static const _dark = <(String, Color, String)>[
    ('lessonBg', CoquiColors.lessonBg, 'cual.html:9'),
    ('lessonInk', CoquiColors.lessonInk, 'cual.html:9'),
    ('lessonInk2', CoquiColors.lessonInk2, 'cual.html:9'),
    ('lessonLine', CoquiColors.lessonLine, 'cual.html:9'),
    ('lessonGreen', CoquiColors.lessonGreen, 'cual.html:9'),
    ('lessonBlue', CoquiColors.lessonBlue, 'cual.html:9'),
    ('lessonBad', CoquiColors.lessonBad, 'cual.html:9'),
    ('dotOff', CoquiColors.dotOff, 'cual.html:20'),
    ('lessonInk3', CoquiColors.lessonInk3, 'habla-prueba:9'),
    ('heard', CoquiColors.heard, 'habla-prueba:9'),
    ('bookLineLit', CoquiColors.bookLineLit, 'app.html:117'),
    ('bookLineLitBar', CoquiColors.bookLineLitBar, 'app.html:117'),
  ];

  Widget _swatch((String, Color, String) s, Color text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 28,
          decoration: BoxDecoration(
            color: s.$2,
            border: Border.all(color: const Color(0x33888888)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${s.$1}  #${(s.$2.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}  ${s.$3}',
          style: CoquiText.small.copyWith(
            color: text,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.bg,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in _light) _swatch(s, CoquiColors.ink),
        const SizedBox(height: 12),
        ColoredBox(
          color: CoquiColors.lessonBg,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [for (final s in _dark) _swatch(s, Colors.white)],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Types extends StatelessWidget {
  const _Types();

  @override
  Widget build(BuildContext context) {
    final light = <(String, TextStyle)>[
      ('h1 24/32 600', CoquiText.h1),
      ('h2 18/24 500', CoquiText.h2),
      ('body 16/24 400', CoquiText.body),
      ('small 14/21 400 mut', CoquiText.smallMuted),
      ('LAB 12/18 500 .02em', CoquiText.label),
      ('chip 14/20 600', CoquiText.chip),
      ('card word 18/24 600', CoquiText.cardWord),
      ('plain tile word 24/32 600', CoquiText.cardWordLarge),
      ('meter label 12/16 500', CoquiText.meterLabel),
      ('tab 12/16 500', CoquiText.tab),
      ('tab on 12/16 500 blue', CoquiText.tabOn),
      ('Today title 18/24 600', CoquiText.todayTitle),
      ('Today sub 14/20', CoquiText.todaySub),
      ('sheet title 24/32 600', CoquiText.sheetTitle),
    ];
    final dark = <(String, TextStyle)>[
      ('lesson caption 18/24 500', CoquiText.lessonCaption),
      ('lesson h1 24/32 600', CoquiText.lessonH1),
      ('lesson body 16/24 ink2', CoquiText.lessonBody),
      ('lesson h2 18/24 600', CoquiText.lessonH2),
      ('lesson sub 14/20', CoquiText.lessonSub),
      ('lesson button 16/24 600', CoquiText.lessonButton),
      ('book line 20/30', CoquiText.bookLine),
      ('page count 3 / 9', CoquiText.lessonCount),
    ];
    return ColoredBox(
      color: CoquiColors.bg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final t in light) Text(t.$1, style: t.$2),
          const SizedBox(height: 8),
          ColoredBox(
            color: CoquiColors.lessonBg,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final t in dark) Text(t.$1, style: t.$2)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pixelify Sans, ligatures off: office find fi',
            style: pixelifyStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _ModalSheetScreen extends StatelessWidget {
  const _ModalSheetScreen();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.mapWater,
    child: Stack(
      children: [
        Column(
          children: [
            MapChips(
              streak: MapChips.streakLabel(0),
              place: MapChips.placeLabel(1, 'Place one'),
            ),
            Expanded(child: Center(child: _pic(_map, w: 240, h: 352))),
          ],
        ),
        CoquiSheetLayer(
          open: true,
          modal: true,
          sheet: CoquiSheet(
            modal: true,
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageDots(count: 3, index: 1),
                CoquiButton(label: 'Next', full: true, onPressed: () {}),
              ],
            ),
            child: CollapsingColumn(
              children: [
                Block(
                  bottom: 16,
                  child: Text('How much time a day?', style: CoquiText.h1),
                ),
                Block(
                  bottom: 16,
                  child: Text(
                    'Today\'s plan is sized to it. You can change it in Yo.',
                    style: CoquiText.bodyMuted,
                  ),
                ),
                SegmentedPills(
                  labels: const ['15 min', '30 min', '60 min', '120 min'],
                  selected: 1,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _WordStates extends StatelessWidget {
  const _WordStates();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.bg,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CollapsingColumn(
        children: [
          const SectionTitle('Meters, 0 to 4 (Ear on top, Mouth under)'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (var n = 0; n <= 4; n++)
                SizedBox(
                  width: 128,
                  child: CoquiCard(
                    marginBottom: 0,
                    padding: const EdgeInsets.all(8),
                    child: EarMouthMeters(ear: n, mouth: 4 - n),
                  ),
                ),
            ],
          ),
          const SectionTitle('The word sheet\'s meters (centred)'),
          const Center(child: EarMouthMeters(ear: 3, mouth: 1, centered: true)),
          const SectionTitle('Cards: a picture, a plain tile, a long word'),
          WordGrid(
            children: [
              WordCard(word: 'word', picture: _pic(_scene), ear: 2, mouth: 1),
              const WordCard(word: 'tile', ear: 4, mouth: 4),
              WordCard(
                word: 'a rather long word here',
                picture: _pic(_scene3),
                ear: 1,
                mouth: 0,
              ),
              const WordCard(
                word: 'anextraordinarilylongwordwithnobreaks',
                ear: 0,
                mouth: 0,
              ),
            ],
          ),
          const SectionTitle('Fades'),
          const SizedBox(
            height: 16,
            child: ColoredBox(
              color: CoquiColors.card,
              child: ListFade(edge: FadeEdge.top),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            height: 16,
            child: ColoredBox(color: CoquiColors.card, child: ListFade()),
          ),
        ],
      ),
    ),
  );
}
