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
