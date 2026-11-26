/// Lesson direction gallery page (#49): Spanish (LTR) and Arabic (RTL)
/// side-by-side proof of Noche lesson chrome, LessonSpeechBubble, and
/// unmirrored PixelView.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sample_art.dart';

// NOT CHECKED BY AN ARABIC SPEAKER. Test-only Arabic fixture matching #85 arabicTestLanguage.
final Language lessonDirectionArabicLanguage = Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-SA',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'Tariq',
  callAgentId: 'agent_arabic_test',
  micWords: const {
    'ready': 'اضغط وتكلم',
    'listening': 'أسمعك',
    'thinking': 'لحظة',
    'theySpeak': 'استمع',
    'right': 'ممتاز',
    'notYet': 'مرة أخرى',
  },
  tabNames: const {
    'library': 'المكتبة',
    'words': 'الكلمات',
    'map': 'الخريطة',
    'speak': 'تكلم',
    'me': 'أنا',
  },
);

/// Renders a Noche dark lesson layout with a [LessonSpeechBubble] over an
/// unmirrored [PixelView] scene for [language].
class LessonDirectionGalleryPage extends StatelessWidget {
  const LessonDirectionGalleryPage({super.key, required this.language});

  final Language language;

  bool get _isRtl => language.direction == LanguageDirection.rtl;

  @override
  Widget build(BuildContext context) {
    final caption = _isRtl ? 'انظر إلى بيت جدة.' : 'Mira la casa de abuela.';
    final bubbleText = _isRtl
        ? 'تقول جدة: مرحباً! هل تريد كعكة؟'
        : 'Abuela dice: ¡Hola! ¿Quieres bizcocho?';

    return Directionality(
      textDirection: language.textDirection,
      child: ColoredBox(
        color: NocheColors.lessonGround,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Pressable(
                        onPressed: () {},
                        semanticLabel: 'Close',
                        builder: (context, _) => const SizedBox.square(
                          dimension: NocheSize.touch,
                          child: Center(
                            child: NocheIcon(
                              NocheIcons.close,
                              size: 24,
                              color: NocheColors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: NocheDashes(
                          states: [
                            NocheDashState.done,
                            NocheDashState.done,
                            NocheDashState.current,
                            NocheDashState.notYet,
                            NocheDashState.notYet,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Pressable(
                        onPressed: () {},
                        semanticLabel: 'Sound',
                        builder: (context, _) => const SizedBox.square(
                          dimension: NocheSize.touch,
                          child: Center(
                            child: NocheIcon(
                              NocheIcons.speaker,
                              size: 24,
                              color: NocheColors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            PictureFrame(
                              child: PixelView(
                                pixels: sampleScene(196, 216),
                                width: 196,
                                height: 216,
                              ),
                            ),
                            PositionedDirectional(
                              top: 10,
                              start: 12,
                              end: 12,
                              child: Align(
                                alignment: AlignmentDirectional.topCenter,
                                child: LessonSpeechBubble(
                                  text: bubbleText,
                                  language: language,
                                  tailSide: BubbleTailSide.bottom,
                                  maxWidth: 230,
                                  dark: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          caption,
                          textAlign: TextAlign.center,
                          textDirection: language.textDirection,
                          locale: language.locale,
                          style: NocheType.forScript(
                            NocheType.lessonPrompt.copyWith(
                              color: NocheColors.text,
                            ),
                            language.script,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                NochePlayDisc(onPressed: () {}, semanticLabel: 'Start'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
