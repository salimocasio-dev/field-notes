/// Noche mic showcase and dev page (story N1.3, board `Noche-Mic.dc.html`).
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

// NOT CHECKED BY AN ARABIC SPEAKER. Sample Arabic language for RTL dev
// preview only; not course data.
final Language nocheDevArabicLanguage = Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-SA',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'سالم',
  callAgentId: 'sample_dev_agent',
  micWords: const {
    'ready': 'المس وتحدث',
    'listening': 'أسمعك',
    'thinking': 'لحظة واحدة',
    'theySpeak': 'استمع',
    'right': 'أحسنت!',
    'notYet': 'مرة أخرى',
  },
  tabNames: const {
    'library': 'المكتبة',
    'words': 'الكلمات',
    'map': 'الخريطة',
    'speak': 'التحدث',
    'me': 'أنا',
  },
);

typedef _BoardEntry = ({NocheMicState state, String caption, double level});

const List<_BoardEntry> _boardEntries = [
  (
    state: NocheMicState.ready,
    caption: '1 · READY\nyour turn, tap to talk',
    level: 0.0,
  ),
  (
    state: NocheMicState.listening,
    caption: '2 · LISTENING\nbars move with your voice',
    level: 1.0,
  ),
  (
    state: NocheMicState.thinking,
    caption: '3 · THINKING\nshows at once when you stop',
    level: 0.0,
  ),
  (
    state: NocheMicState.theySpeak,
    caption: '4 · THEY SPEAK\nmic rests, their colour',
    level: 1.0,
  ),
  (
    state: NocheMicState.right,
    caption: '5 · HEARD RIGHT\nshort praise, story moves on',
    level: 0.0,
  ),
  (
    state: NocheMicState.notYet,
    caption: '6 · NOT YET\nno red, the line plays again',
    level: 0.0,
  ),
];

/// Exact 808 x 568 3x2 board showcase matching `Noche-Mic.dc.html`.
class NocheMicBoardShowcase extends StatelessWidget {
  const NocheMicBoardShowcase({
    super.key,
    required this.language,
    this.onStatePressed,
  });

  final Language language;
  final ValueChanged<NocheMicState>? onStatePressed;

  static const double boardWidth = 808;
  static const double boardHeight = 568;
  static const double cardHeight = 260;
  static const double gridGap = 16;

  Widget _buildCard(_BoardEntry entry) {
    return Container(
      height: cardHeight,
      padding: const EdgeInsetsDirectional.all(gridGap),
      decoration: BoxDecoration(
        color: NocheColors.lessonGround,
        borderRadius: BorderRadius.circular(NocheSize.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              entry.caption,
              style: NocheType.label.copyWith(
                height: 16 / 12,
                color: NocheColors.label,
              ),
            ),
          ),
          const Spacer(),
          NocheMic(
            state: entry.state,
            language: language,
            level: entry.level,
            labelGap: 38,
            onPressed: onStatePressed == null
                ? null
                : () => onStatePressed!(entry.state),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<_BoardEntry> entries) {
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: gridGap),
          Expanded(child: _buildCard(entries[i])),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boardWidth,
      height: boardHeight,
      color: NocheColors.ground,
      padding: const EdgeInsetsDirectional.all(gridGap),
      child: Column(
        children: [
          _buildRow(_boardEntries.sublist(0, 3)),
          const SizedBox(height: gridGap),
          _buildRow(_boardEntries.sublist(3, 6)),
        ],
      ),
    );
  }
}

/// Phone-sized dev preview of all six [NocheMic] states in LTR or RTL.
class NocheMicDevPage extends StatefulWidget {
  const NocheMicDevPage({super.key, required this.textDirection});

  final TextDirection textDirection;

  @override
  State<NocheMicDevPage> createState() => _NocheMicDevPageState();
}

class _NocheMicDevPageState extends State<NocheMicDevPage> {
  NocheMicState _lastTapped = NocheMicState.ready;

  bool get _isRtl => widget.textDirection == TextDirection.rtl;
  Language get _language => _isRtl ? nocheDevArabicLanguage : Language.spanish;

  @override
  Widget build(BuildContext context) {
    final language = _language;
    return Directionality(
      textDirection: widget.textDirection,
      child: NocheScreen(
        backgroundColor: NocheColors.ground,
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 32),
          children: [
            Text(
              _isRtl ? 'Noche mic · RTL' : 'Noche mic · LTR',
              style: NocheType.pageTitle.copyWith(color: NocheColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Language: ${language.englishName} (${language.code}, '
              '${language.script}) · last tapped: ${_lastTapped.wordKey}',
              style: NocheType.bodySmall.copyWith(color: NocheColors.label),
            ),
            const SizedBox(height: 16),
            for (final entry in _boardEntries) ...[
              Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                  color: NocheColors.lessonGround,
                  borderRadius: BorderRadius.circular(NocheSize.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        entry.caption,
                        style: NocheType.label.copyWith(
                          height: 16 / 12,
                          color: NocheColors.label,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    NocheMic(
                      state: entry.state,
                      language: language,
                      level: entry.level,
                      onPressed: () =>
                          setState(() => _lastTapped = entry.state),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsetsDirectional.all(16),
              decoration: BoxDecoration(
                color: NocheColors.lessonGround,
                borderRadius: BorderRadius.circular(NocheSize.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'COMPACT LABEL\n14/14 buttonStrong for Cuento',
                      style: NocheType.label.copyWith(
                        height: 16 / 12,
                        color: NocheColors.label,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  NocheMic(
                    state: NocheMicState.listening,
                    language: language,
                    level: 0.75,
                    compactLabel: true,
                    onPressed: () =>
                        setState(() => _lastTapped = NocheMicState.listening),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
