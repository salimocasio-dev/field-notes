/// Noche shared pieces dev page (story N1.2): every piece in every state,
/// rendered in LTR or RTL.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Spanish tab names sourced from [CoquiLabels] until N2.1 (`Language.tabNames`) lands.
const Map<String, String> nocheDevSpanishTabNames = {
  NocheTabs.library: CoquiLabels.library,
  NocheTabs.words: CoquiLabels.words,
  NocheTabs.map: CoquiLabels.map,
  NocheTabs.speak: CoquiLabels.speak,
  NocheTabs.me: CoquiLabels.me,
};

/// Sample Arabic tab names (for RTL dev preview only; not course data).
const Map<String, String> nocheDevArabicTabNames = {
  NocheTabs.library: 'المكتبة',
  NocheTabs.words: 'الكلمات',
  NocheTabs.map: 'الخريطة',
  NocheTabs.speak: 'التحدث',
  NocheTabs.me: 'أنا',
};

/// Full showcase of every N1.2 Noche shared piece in every state, in
/// [textDirection] (`TextDirection.ltr` or `TextDirection.rtl`).
class NochePiecesDevPage extends StatefulWidget {
  const NochePiecesDevPage({
    super.key,
    required this.textDirection,
    this.scrollable = true,
  });

  final TextDirection textDirection;

  /// When `true` (default), renders inside a [NocheScreen] with a [ListView]
  /// ending 104 above the bottom and a live [NocheTabBar] at the foot.
  /// When `false`, lays out all sections unclipped in a single column (for
  /// full-page goldens and walking every touch target at once).
  final bool scrollable;

  @override
  State<NochePiecesDevPage> createState() => _NochePiecesDevPageState();
}

class _NochePiecesDevPageState extends State<NochePiecesDevPage> {
  String _selectedTab = NocheTabs.map;
  String _skill = 'listening';
  int _minutes = 30;
  String _lineSpacing = 'normal';
  bool _underline = true;
  bool _lightSentence = false;

  bool get _isRtl => widget.textDirection == TextDirection.rtl;
  String get _script => _isRtl ? 'Arab' : 'Latn';
  String get _langCode => _isRtl ? 'ar' : 'es';
  Map<String, String> get _tabNames =>
      _isRtl ? nocheDevArabicTabNames : nocheDevSpanishTabNames;

  // Deterministic book ids: verify even -> coverBlue, odd -> coverPlum.
  static const _blueBookId = 'book-blue-0';
  static const _plumBookId = 'book-plum-1';

  String _pickBookId({required bool wantBlue}) {
    for (var i = 0; i < 64; i++) {
      final candidate = '${wantBlue ? _blueBookId : _plumBookId}-$i';
      final isBlue = NocheCover.colorsFor(candidate) == NocheColors.coverBlue;
      if (isBlue == wantBlue) return candidate;
    }
    return wantBlue ? _blueBookId : _plumBookId;
  }

  List<Widget> _sections() {
    final blueId = _pickBookId(wantBlue: true);
    final plumId = _pickBookId(wantBlue: false);

    return [
      Text(
        _isRtl ? 'Noche pieces · RTL' : 'Noche pieces · LTR',
        style: NocheType.pageTitle.copyWith(color: NocheColors.text),
      ),
      const SizedBox(height: 8),
      Text(
        'NocheA11y.lessonLabelsInCourseLanguage = '
        '${NocheA11y.lessonLabelsInCourseLanguage} · '
        '${NocheA11y.label(NocheA11y.close)} / '
        '${NocheA11y.label(NocheA11y.hearAgain)}',
        style: NocheType.bodySmall.copyWith(color: NocheColors.label),
      ),
      const SizedBox(height: 24),

      // 1. Section label + Pills (all 4 kinds)
      const NocheSectionLabel(
        'Pills and plan tag',
        trailing: NochePill.planTag(label: 'Course + Calls'),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          NochePill.selected(
            label: _isRtl ? 'المطبخ' : 'La cocina',
            script: _script,
            onPressed: () {},
          ),
          NochePill.outline(
            label: _isRtl ? 'الحديقة' : 'El parque',
            script: _script,
            onPressed: () {},
          ),
          NochePill.outline(
            label: 'Muted',
            foregroundColor: NocheColors.label,
            onPressed: () {},
          ),
          const NochePill.dashedLocked(semanticLabel: 'Locked place'),
        ],
      ),
      const SizedBox(height: 24),

      // 2. Chips
      const NocheSectionLabel('Chips (not touchable)'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final w
              in _isRtl
                  ? const ['ماء', 'عصير', 'حليب', 'من فضلك']
                  : const ['quiero', 'jugo', 'agua', 'leche', 'por favor'])
            NocheChip(label: w, script: _script),
        ],
      ),
      const SizedBox(height: 24),

      // 3. Cards (standard, highlight, dashed)
      const NocheSectionLabel('Cards'),
      NocheCard(
        onPressed: () {},
        semanticLabel: 'Standard tappable card',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Standard card (padding 16)',
              style: NocheType.rowTitle.copyWith(color: NocheColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              'Panel fill, 1 px line border, radius 24.',
              style: NocheType.body.copyWith(color: NocheColors.label),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      NocheCard(
        variant: NocheCardVariant.highlight,
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Highlight card (padding 24)',
              style: NocheType.sheetTitle.copyWith(color: NocheColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              '2 px next border on panel fill.',
              style: NocheType.body.copyWith(color: NocheColors.label),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      NocheCard(
        variant: NocheCardVariant.dashed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashed card',
              style: NocheType.rowTitle.copyWith(color: NocheColors.label),
            ),
            const SizedBox(height: 4),
            const Text('No fill, dashed line border, label text.'),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // 4. Primary & Outline buttons
      const NocheSectionLabel('Buttons'),
      NochePrimaryButton(label: 'Start review', onPressed: () {}),
      const SizedBox(height: 12),
      NochePrimaryButton(
        label: 'Continue reading',
        small: true,
        onPressed: () {},
      ),
      const SizedBox(height: 12),
      const NochePrimaryButton(label: 'Disabled action', onPressed: null),
      const SizedBox(height: 12),
      NocheOutlineButton(label: 'Write my story', onPressed: () {}),
      const SizedBox(height: 12),
      const NocheOutlineButton(label: 'Outline disabled', onPressed: null),
      const SizedBox(height: 24),

      // 5. Play bar & Play discs
      const NocheSectionLabel('Play bar and play discs'),
      NochePlayBar(
        eyebrow: 'Play next · Story 3',
        title: _isRtl ? 'أنا جائع' : 'Tengo hambre',
        meta: '5 min',
        script: _script,
        onPressed: () {},
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NochePlayDisc(
            size: NocheSize.disc,
            semanticLabel: 'Play story',
            onPressed: () {},
          ),
          NochePlayDisc(
            size: NocheSize.mic,
            icon: NocheIcons.mic,
            halo: true,
            semanticLabel: 'Call partner',
            onPressed: () {},
          ),
        ],
      ),
      const SizedBox(height: 24),

      // 6. Segmented controls (tabList + radioGroup)
      const NocheSectionLabel('Segmented controls'),
      NocheSegmented<String>(
        role: NocheSegmentedRole.tabList,
        semanticLabel: 'Skill',
        selected: _skill,
        onChanged: (v) => setState(() => _skill = v),
        options: const [
          NocheSegmentOption(value: 'listening', label: 'Listening · 41'),
          NocheSegmentOption(value: 'speaking', label: 'Speaking · 17'),
          NocheSegmentOption(
            value: 'reading',
            label: 'Reading · A2',
            muted: true,
          ),
        ],
      ),
      const SizedBox(height: 12),
      NocheSegmented<int>(
        role: NocheSegmentedRole.radioGroup,
        semanticLabel: 'Minutes a day',
        selected: _minutes,
        large: true,
        onChanged: (v) => setState(() => _minutes = v),
        options: const [
          NocheSegmentOption(value: 15, label: '15'),
          NocheSegmentOption(value: 30, label: '30'),
          NocheSegmentOption(value: 60, label: '60'),
          NocheSegmentOption(value: 120, label: '120'),
        ],
      ),
      const SizedBox(height: 24),

      // 7. Dashes, Stage bars, Progress bars
      const NocheSectionLabel('Dashes, stage bar and progress bars'),
      NocheCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NocheDashes.progress(
              count: 10,
              done: 2,
              currentIndex: 2,
              gap: 8,
              semanticLabel: 'Places: 2 done, on place 3, 7 to go',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: NocheColors.lessonGround,
                borderRadius: BorderRadius.circular(12),
              ),
              child: NocheDashes.progress(
                count: 7,
                done: 3,
                onLessonGround: true,
                semanticLabel: 'Part 3 of 7',
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NocheStageBar(stage: 1, max: 4),
                NocheStageBar(stage: 2, max: 4),
                NocheStageBar(stage: 4, max: 4),
              ],
            ),
            const SizedBox(height: 16),
            const NocheProgressBar(
              value: 0.16,
              color: NocheColors.next,
              semanticLabel: 'Page 14 of 86',
            ),
            const SizedBox(height: 12),
            const NocheProgressBar(
              value: 0.71,
              color: NocheColors.listening,
              semanticLabel: '71 percent heard',
            ),
            const SizedBox(height: 12),
            const NocheProgressBar(
              value: 0.45,
              height: 4,
              trackColor: NocheColors.lessonLine,
              color: NocheColors.lessonLabel,
              semanticLabel: 'Reader page progress',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // 8. Bar charts (Palabras with values + Yo with dashed goal line)
      const NocheSectionLabel('Bar charts'),
      const NocheBarChart(
        semanticLabel: 'Words coming back',
        items: [
          NocheBarItem(label: 'Today', value: 14, highlighted: true),
          NocheBarItem(label: 'Tomorrow', value: 9),
          NocheBarItem(label: '3 days', value: 21),
          NocheBarItem(label: 'This week', value: 30),
          NocheBarItem(label: 'Later', value: 22),
        ],
      ),
      const SizedBox(height: 16),
      const NocheCard(
        child: NocheBarChart(
          showValues: false,
          goal: 30,
          semanticLabel: 'Minutes in the last 7 days, goal 30',
          items: [
            NocheBarItem(label: 'T', value: 28),
            NocheBarItem(label: 'W', value: 35),
            NocheBarItem(label: 'T', value: 30),
            NocheBarItem(label: 'F', value: 41),
            NocheBarItem(label: 'S', value: 36),
            NocheBarItem(label: 'S', value: 30),
            NocheBarItem(label: 'Today', value: 12, highlighted: true),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // 9. Switch rows
      const NocheSectionLabel('Switch rows'),
      NocheCard(
        child: Column(
          children: [
            NocheSwitchRow(
              label: "Underline words I'm still learning",
              value: _underline,
              showTopBorder: false,
              onChanged: (v) => setState(() => _underline = v),
            ),
            NocheSwitchRow(
              label: 'Light up the sentence being read',
              value: _lightSentence,
              onChanged: (v) => setState(() => _lightSentence = v),
            ),
            NocheSwitchRow(
              label: 'Subtitles',
              subtitle: 'Shown inside the player',
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // 10. Book covers (regular + small, blue + plum)
      const NocheSectionLabel('Book covers'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NocheCover(
            bookId: plumId,
            title: _isRtl ? 'قصص الجزيرة' : 'Cuentos de la isla',
            script: _script,
          ),
          NocheCover(
            bookId: blueId,
            title: _isRtl ? 'صيف في كابو روخو' : 'Un verano en Cabo Rojo',
            script: _script,
          ),
          NocheCover(
            bookId: blueId,
            size: NocheCoverSize.small,
            title: _isRtl ? 'صيف في كابو روخو' : 'Un verano en Cabo Rojo',
            script: _script,
          ),
          NocheCover(
            bookId: plumId,
            size: NocheCoverSize.small,
            title: _isRtl ? 'قصص الجزيرة' : 'Cuentos de la isla',
            script: _script,
          ),
        ],
      ),
      const SizedBox(height: 24),

      // 11. Board icons
      const NocheSectionLabel('Board icons'),
      NocheCard(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final entry in NocheIcons.all.entries)
              NocheIcon(entry.value, size: 22, color: NocheColors.text),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // 12. Bottom sheet over scrim
      const NocheSectionLabel('Sheet over scrim'),
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 216,
          child: NocheSheetOverlay(
            onScrimTap: () {},
            sheet: NocheSheet(
              title: 'Your languages',
              respectSafeArea: false,
              scrollable: false,
              onClose: () {},
              child: Text(
                'Sheet content sits inside panel fill with a 40 by 4 handle 12 from the top.',
                style: NocheType.body.copyWith(color: NocheColors.label),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),

      // 12b. Text-filled primary buttons, compact icon segmented, quick-fade dashes, reader fonts
      const NocheSectionLabel('Reader and sheet variants'),
      NochePrimaryButton.text(label: 'Write my story', onPressed: () {}),
      const SizedBox(height: 12),
      const NochePrimaryButton.text(
        label: 'Text button disabled',
        onPressed: null,
      ),
      const SizedBox(height: 12),
      NocheSegmented<String>(
        role: NocheSegmentedRole.radioGroup,
        semanticLabel: NocheA11y.label(NocheA11y.lineSpacing),
        padding: EdgeInsetsDirectional.zero,
        backgroundColor: NocheColors.ground,
        selected: _lineSpacing,
        onChanged: (v) => setState(() => _lineSpacing = v),
        options: [
          NocheSegmentOption(
            value: 'tight',
            icon: NocheIcons.lineSpacingTight,
            semanticLabel: NocheA11y.label(NocheA11y.lineSpacingTight),
          ),
          NocheSegmentOption(
            value: 'normal',
            icon: NocheIcons.lineSpacingNormal,
            semanticLabel: NocheA11y.label(NocheA11y.lineSpacingNormal),
          ),
          NocheSegmentOption(
            value: 'loose',
            icon: NocheIcons.lineSpacingLoose,
            semanticLabel: NocheA11y.label(NocheA11y.lineSpacingLoose),
          ),
        ],
      ),
      const SizedBox(height: 12),
      NocheCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NocheDashes.progress(
              count: 7,
              done: 4,
              quickColorFade: true,
              semanticLabel: 'Text size 4 of 7',
            ),
            const SizedBox(height: 16),
            Text(
              'Literata reader body',
              style: NocheType.bookBody.copyWith(color: NocheColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Atkinson reader body',
              style: NocheType.bookBodyAtkinson.copyWith(
                color: NocheColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lexend reader body',
              style: NocheType.bookBodyLexend.copyWith(color: NocheColors.text),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // 13. Tab bars (non-map active + map active)
      const NocheSectionLabel('Tab bar (non-map active, fixed order)'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final wordsActiveTabBar = NocheTabBar(
      selectedId: NocheTabs.words,
      tabNames: _tabNames,
      script: _script,
      languageCode: _langCode,
      respectSafeArea: false,
      onTap: (id) => setState(() => _selectedTab = id),
    );
    final tabBar = NocheTabBar(
      selectedId: _selectedTab,
      tabNames: _tabNames,
      script: _script,
      languageCode: _langCode,
      respectSafeArea: widget.scrollable,
      onTap: (id) => setState(() => _selectedTab = id),
    );

    final sections = _sections();

    return Directionality(
      textDirection: widget.textDirection,
      child: widget.scrollable
          ? NocheScreen(
              tabBar: tabBar,
              body: ListView(
                padding: const EdgeInsetsDirectional.only(top: 16, bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: sections,
                    ),
                  ),
                  wordsActiveTabBar,
                ],
              ),
            )
          : ColoredBox(
              color: NocheColors.ground,
              child: DefaultTextStyle.merge(
                style: NocheType.body.copyWith(color: NocheColors.text),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: sections,
                      ),
                    ),
                    wordsActiveTabBar,
                    tabBar,
                  ],
                ),
              ),
            ),
    );
  }
}

/// Interactive dev gallery for all 16 N8.2 shared motion pieces:
/// [NocheTabBar], [NocheSegmented], [NochePillGroup], [NocheSwitchRow],
/// [NocheSheet] / [showNocheSheet] / [NocheSheetSwap], [NocheDashes],
/// [NocheStageBar], [NocheProgressBar], [NocheBarChart], [NocheMic],
/// [NocheOutlineGroup], [TouchSign], [NocheArrive], [NocheFollow],
/// [NocheWindow] (single-screen and cross-route), [NocheQuietLock], and
/// [NocheLtr].
class NocheMotionDevPage extends StatefulWidget {
  const NocheMotionDevPage({super.key, this.textDirection = TextDirection.ltr});

  final TextDirection textDirection;

  @override
  State<NocheMotionDevPage> createState() => _NocheMotionDevPageState();
}

class _NocheMotionDevPageState extends State<NocheMotionDevPage> {
  static final Map<String, String> _devMicWords = {
    NocheMicState.values[0].wordKey: 'Tap to talk',
    NocheMicState.values[1].wordKey: 'Listening',
    NocheMicState.values[2].wordKey: 'Thinking',
    NocheMicState.values[3].wordKey: 'Listen',
    NocheMicState.values[4].wordKey: 'Well done',
    NocheMicState.values[5].wordKey: 'Try again',
  };

  static const List<String> _micStateLabels = [
    'Ready',
    'Listening',
    'Thinking',
    'They speak',
    'Heard',
    'Not yet',
  ];

  String _selectedTab = NocheTabs.words;
  String _segment = 'listening';
  String _place = 'kitchen';
  String _languageChoice = 'es';
  String _fontChoice = 'sans';
  bool _switchOn = true;
  int _dashesDone = 2;
  int _replayTick = 0;
  int _followIndex = 0;
  NocheFollowSide _followSide = NocheFollowSide.end;
  NocheMicState _micState = NocheMicState.ready;
  bool _windowExpanded = false;
  int _lockTaps = 0;
  int _sheetStep = 0;
  bool _playing = false;
  String _lineSpacing = 'normal';
  int _textSizeDashes = 4;

  bool get _isRtl => widget.textDirection == TextDirection.rtl;
  String get _script => _isRtl ? 'Arab' : 'Latn';
  String get _langCode => _isRtl ? 'ar' : 'es';
  Map<String, String> get _tabNames =>
      _isRtl ? nocheDevArabicTabNames : nocheDevSpanishTabNames;

  void _openAnimatedSheet() {
    showNocheSheet<void>(
      context,
      title: 'Sheet motion',
      builder: (context, close) {
        var step = _sheetStep;
        return StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NocheSheetSwap(
                contentKey: step,
                child: step.isEven
                    ? NocheArrive(
                        delay: NocheMotion.rowsAfter,
                        spacing: 8,
                        next: NocheOutlineButton(
                          label: 'Swap in place',
                          onPressed: () {
                            setSheetState(() => step++);
                            setState(() => _sheetStep = step);
                          },
                        ),
                        children: [
                          Text(
                            'Row 1 arrives first',
                            style: NocheType.rowTitle.copyWith(
                              color: NocheColors.text,
                            ),
                          ),
                          Text(
                            'Row 2 follows by stagger',
                            style: NocheType.body.copyWith(
                              color: NocheColors.label,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Swapped view keeps the exact sheet height.',
                            style: NocheType.body.copyWith(
                              color: NocheColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          NocheOutlineButton(
                            label: 'Swap back',
                            onPressed: () {
                              setSheetState(() => step++);
                              setState(() => _sheetStep = step);
                            },
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              NochePrimaryButton(label: 'Done', onPressed: close),
            ],
          ),
        );
      },
    );
  }

  void _openScrimlessSheet() {
    showNocheSheet<void>(
      context,
      scrim: false,
      showCloseButton: false,
      closeLabel: NocheA11y.label(NocheA11y.closeTextAndPage),
      builder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Scrimless headerless sheet — tap above or drag down to close.',
            style: NocheType.body.copyWith(color: NocheColors.text),
          ),
          const SizedBox(height: 12),
          NochePrimaryButton.text(label: 'Close', onPressed: close),
        ],
      ),
    );
  }

  void _openLockableSheet() {
    final canDismiss = ValueNotifier<bool>(true);
    showNocheSheet<void>(
      context,
      title: 'Dynamic lock sheet',
      dismissibleListenable: canDismiss,
      builder: (context, close) => ValueListenableBuilder<bool>(
        valueListenable: canDismiss,
        builder: (context, unlocked, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NocheSwitchRow(
              label: 'Allow user dismiss',
              value: unlocked,
              showTopBorder: false,
              onChanged: (v) => canDismiss.value = v,
            ),
            const SizedBox(height: 12),
            NochePrimaryButton.text(
              label: 'Close programmatically',
              onPressed: close,
            ),
          ],
        ),
      ),
    ).whenComplete(canDismiss.dispose);
  }

  void _openWindowRoute() {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: NocheMotion.of(context).pageIn,
        reverseTransitionDuration: NocheMotion.of(context).pageOut,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _NocheWindowDetailRoute(tag: 'motion_demo_window'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _samplePicture() => SizedBox(
    width: 320,
    height: 180,
    child: DecoratedBox(
      decoration: BoxDecoration(color: NocheColors.coverBlue.face),
      child: Center(
        child: Text(
          'UNSCALED PICTURE',
          style: NocheType.labelStrong.copyWith(color: NocheColors.next),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tabBar = NocheTabBar(
      selectedId: _selectedTab,
      tabNames: _tabNames,
      script: _script,
      languageCode: _langCode,
      onTap: (id) => setState(() => _selectedTab = id),
    );

    return Directionality(
      textDirection: widget.textDirection,
      child: NocheScreen(
        tabBar: tabBar,
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
          children: [
            Text(
              'Noche motion pieces',
              style: NocheType.pageTitle.copyWith(color: NocheColors.text),
            ),
            const SizedBox(height: 16),

            // 1. NocheSegmented + NocheFollow
            const NocheSectionLabel('Segmented + Follow'),
            NocheSegmented<String>(
              role: NocheSegmentedRole.tabList,
              semanticLabel: 'Skill',
              selected: _segment,
              onChanged: (v) {
                final oldIdx = [
                  'listening',
                  'speaking',
                  'reading',
                ].indexOf(_segment);
                final newIdx = ['listening', 'speaking', 'reading'].indexOf(v);
                setState(() {
                  _segment = v;
                  _followSide = newIdx >= oldIdx
                      ? NocheFollowSide.end
                      : NocheFollowSide.start;
                  _followIndex++;
                });
              },
              options: const [
                NocheSegmentOption(value: 'listening', label: 'Listening'),
                NocheSegmentOption(value: 'speaking', label: 'Speaking'),
                NocheSegmentOption(value: 'reading', label: 'Reading'),
              ],
            ),
            const SizedBox(height: 12),
            NocheFollow(
              contentKey: '$_segment-$_followIndex',
              side: _followSide,
              child: NocheCard(
                child: Text(
                  'Active panel: $_segment',
                  style: NocheType.rowTitle.copyWith(color: NocheColors.text),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. NochePillGroup
            const NocheSectionLabel('Pill group'),
            NochePillGroup<String>(
              semanticLabel: 'Places',
              selected: _place,
              onChanged: (v) => setState(() => _place = v),
              options: const [
                NochePillOption(value: 'kitchen', label: 'La cocina'),
                NochePillOption(value: 'park', label: 'El parque'),
                NochePillOption(value: 'home', label: 'Casa'),
              ],
              trailing: const NochePill.dashedLocked(
                semanticLabel: 'Locked place',
              ),
            ),
            const SizedBox(height: 24),

            // 3. NocheOutlineGroup (vertical + horizontal)
            const NocheSectionLabel('Outline group (vertical & horizontal)'),
            NocheOutlineGroup<String>(
              axis: Axis.vertical,
              selected: _languageChoice,
              onChanged: (v) => setState(() => _languageChoice = v),
              options: [
                NocheOutlineOption(
                  value: 'es',
                  semanticLabel: 'Spanish',
                  child: NocheCard(
                    child: Text(
                      'Español',
                      style: NocheType.rowTitle.copyWith(
                        color: NocheColors.text,
                      ),
                    ),
                  ),
                ),
                NocheOutlineOption(
                  value: 'ar',
                  semanticLabel: 'Arabic',
                  child: NocheCard(
                    child: Text(
                      'العربية',
                      style: NocheType.rowTitle.copyWith(
                        color: NocheColors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NocheOutlineGroup<String>(
              axis: Axis.horizontal,
              selected: _fontChoice,
              onChanged: (v) => setState(() => _fontChoice = v),
              options: [
                NocheOutlineOption(
                  value: 'sans',
                  semanticLabel: 'Sans',
                  child: NocheCard(
                    child: Center(
                      child: Text(
                        'Aa',
                        style: NocheType.cardTitle.copyWith(
                          color: NocheColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
                NocheOutlineOption(
                  value: 'serif',
                  semanticLabel: 'Serif',
                  child: NocheCard(
                    child: Center(
                      child: Text(
                        'Aa',
                        style: NocheType.cardTitle.copyWith(
                          color: NocheColors.label,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. NocheSwitchRow
            const NocheSectionLabel('Switch row'),
            NocheCard(
              child: NocheSwitchRow(
                label: 'Highlight active line',
                value: _switchOn,
                showTopBorder: false,
                onChanged: (v) => setState(() => _switchOn = v),
              ),
            ),
            const SizedBox(height: 24),

            // 5. NocheSheet & NocheSheetSwap
            const NocheSectionLabel('Sheet & in-place swap'),
            NocheOutlineButton(
              label: 'Open animated sheet',
              onPressed: _openAnimatedSheet,
            ),
            const SizedBox(height: 24),

            // 6. NocheDashes, NocheStageBar, NocheProgressBar, NocheBarChart, NocheArrive
            const NocheSectionLabel('Dashes, bars, chart & arrive'),
            NocheCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NocheDashes.progress(
                    count: 5,
                    done: _dashesDone,
                    currentIndex: _dashesDone < 5 ? _dashesDone : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: NocheOutlineButton(
                          label: 'Advance dash',
                          onPressed: () => setState(
                            () => _dashesDone = (_dashesDone + 1) % 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NocheOutlineButton(
                          label: 'Replay bars',
                          onPressed: () => setState(() => _replayTick++),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  NocheStageBar(
                    key: ValueKey('motion_stage_$_replayTick'),
                    stage: 3,
                    max: 4,
                    animateFrom: 0.25,
                  ),
                  const SizedBox(height: 12),
                  NocheProgressBar(
                    key: ValueKey('motion_progress_$_replayTick'),
                    value: 0.72,
                    color: NocheColors.next,
                    animateFrom: 0.1,
                  ),
                  const SizedBox(height: 16),
                  NocheBarChart(
                    key: ValueKey('motion_chart_$_replayTick'),
                    items: const [
                      NocheBarItem(label: '1', value: 12, highlighted: true),
                      NocheBarItem(label: '2', value: 18),
                      NocheBarItem(label: '3', value: 26),
                      NocheBarItem(label: '4', value: 20),
                      NocheBarItem(label: '5', value: 30),
                      NocheBarItem(label: '6', value: 15),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NocheArrive(
              key: ValueKey('motion_arrive_$_replayTick'),
              spacing: 8,
              next: Text(
                'Arrived after nextDelay',
                style: NocheType.bodySmall.copyWith(color: NocheColors.label),
              ),
              children: const [
                NocheChip(label: 'First'),
                NocheChip(label: 'Second'),
                NocheChip(label: 'Third'),
              ],
            ),
            const SizedBox(height: 24),

            // 7. NocheMic (all 6 states via NocheMic.custom)
            const NocheSectionLabel('Mic motion (6 states)'),
            NocheCard(
              child: Column(
                children: [
                  NocheMic.custom(
                    state: _micState,
                    micWords: _devMicWords,
                    level: 0.75,
                    onPressed: () {
                      final nextIdx =
                          (NocheMicState.values.indexOf(_micState) + 1) %
                          NocheMicState.values.length;
                      setState(() => _micState = NocheMicState.values[nextIdx]);
                    },
                  ),
                  const SizedBox(height: 16),
                  NochePillGroup<NocheMicState>(
                    selected: _micState,
                    onChanged: (s) => setState(() => _micState = s),
                    options: [
                      for (var i = 0; i < NocheMicState.values.length; i++)
                        NochePillOption(
                          value: NocheMicState.values[i],
                          label: _micStateLabels[i],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 8. NocheWindow (single-screen + cross-route)
            const NocheSectionLabel('Window (single-screen & route)'),
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  NocheWindow(
                    rect: _windowExpanded
                        ? const Rect.fromLTWH(0, 0, 320, 152)
                        : const Rect.fromLTWH(0, 16, 160, 120),
                    borderRadius: _windowExpanded ? 8 : 24,
                    pictureOffset: _windowExpanded
                        ? Offset.zero
                        : const Offset(-40, -16),
                    pictureSize: const Size(320, 180),
                    leaving: !_windowExpanded,
                    onPressed: () =>
                        setState(() => _windowExpanded = !_windowExpanded),
                    semanticLabel: 'Toggle window size',
                    child: _samplePicture(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              height: 96,
              child: NocheWindow(
                tag: 'motion_demo_window',
                borderRadius: 20,
                pictureOffset: const Offset(-40, -24),
                pictureSize: const Size(320, 180),
                onPressed: _openWindowRoute,
                semanticLabel: 'Open window route',
                child: _samplePicture(),
              ),
            ),
            const SizedBox(height: 24),

            // 9. NocheQuietLock, TouchSign, NocheLtr
            const NocheSectionLabel('Quiet lock, TouchSign & NocheLtr'),
            NocheQuietLock(
              semanticLabel: 'Locked chapter',
              onTap: () => setState(() => _lockTaps++),
              builder: (context, reasonColor) => Row(
                children: [
                  NocheIcon(NocheIcons.lock, size: 20, color: reasonColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Finish Story 1 first (taps: $_lockTaps)',
                      style: NocheType.body.copyWith(color: reasonColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TouchSign(),
                NocheLtr(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NocheChip(label: '1'),
                      SizedBox(width: 8),
                      NocheChip(label: '2'),
                      SizedBox(width: 8),
                      NocheChip(label: '3'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 10. Play disc cross-fade, compact icon segmented, quick-fade dashes, scrimless/lockable sheets
            const NocheSectionLabel(
              'Play disc fade, icon segmented & sheet modes',
            ),
            Center(
              child: NochePlayDisc(
                icon: _playing ? NocheIcons.pause : NocheIcons.play,
                semanticLabel: _playing
                    ? NocheA11y.label(NocheA11y.pause)
                    : NocheA11y.label(NocheA11y.listen),
                onPressed: () => setState(() => _playing = !_playing),
              ),
            ),
            const SizedBox(height: 16),
            NocheSegmented<String>(
              role: NocheSegmentedRole.radioGroup,
              semanticLabel: NocheA11y.label(NocheA11y.lineSpacing),
              padding: EdgeInsetsDirectional.zero,
              backgroundColor: NocheColors.ground,
              selected: _lineSpacing,
              onChanged: (v) => setState(() => _lineSpacing = v),
              options: [
                NocheSegmentOption(
                  value: 'tight',
                  icon: NocheIcons.lineSpacingTight,
                  semanticLabel: NocheA11y.label(NocheA11y.lineSpacingTight),
                ),
                NocheSegmentOption(
                  value: 'normal',
                  icon: NocheIcons.lineSpacingNormal,
                  semanticLabel: NocheA11y.label(NocheA11y.lineSpacingNormal),
                ),
                NocheSegmentOption(
                  value: 'loose',
                  icon: NocheIcons.lineSpacingLoose,
                  semanticLabel: NocheA11y.label(NocheA11y.lineSpacingLoose),
                ),
              ],
            ),
            const SizedBox(height: 16),
            NocheCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NocheDashes.progress(
                    count: 7,
                    done: _textSizeDashes,
                    quickColorFade: true,
                    semanticLabel: 'Text size $_textSizeDashes of 7',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: NocheOutlineButton(
                          label: 'Smaller A',
                          onPressed: _textSizeDashes > 1
                              ? () => setState(() => _textSizeDashes--)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NocheOutlineButton(
                          label: 'Larger A',
                          onPressed: _textSizeDashes < 7
                              ? () => setState(() => _textSizeDashes++)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NocheOutlineButton(
                    label: 'Scrimless sheet',
                    onPressed: _openScrimlessSheet,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NocheOutlineButton(
                    label: 'Lockable sheet',
                    onPressed: _openLockableSheet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NocheWindowDetailRoute extends StatelessWidget {
  const _NocheWindowDetailRoute({required this.tag});

  final Object tag;

  @override
  Widget build(BuildContext context) {
    return NocheScreen(
      body: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 180,
              child: NocheWindow(
                tag: tag,
                borderRadius: 8,
                pictureOffset: Offset.zero,
                pictureSize: const Size(320, 180),
                child: SizedBox(
                  width: 320,
                  height: 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: NocheColors.coverBlue.face,
                    ),
                    child: Center(
                      child: Text(
                        'UNSCALED PICTURE',
                        style: NocheType.labelStrong.copyWith(
                          color: NocheColors.next,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            NochePrimaryButton(
              label: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
