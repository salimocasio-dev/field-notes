/// The coqui_ui gallery: Noche shared pieces, Noche mic states, and lesson
/// direction proofs.
///
///   flutter run -d chrome -t tool/dev_main.dart
///   flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?section=noche-ltr"
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'gallery/lesson_direction.dart';
import 'gallery/noche_mic.dart';
import 'gallery/noche_pieces.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final name = Uri.base.queryParameters['section'];
    if (name == 'noche-ltr') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coqui UI · Noche LTR',
        theme: coquiTheme(),
        home: const Scaffold(
          backgroundColor: NocheColors.ground,
          body: NochePiecesDevPage(textDirection: TextDirection.ltr),
        ),
      );
    }
    if (name == 'noche-rtl') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coqui UI · Noche RTL',
        theme: coquiTheme(),
        home: const Scaffold(
          backgroundColor: NocheColors.ground,
          body: NochePiecesDevPage(textDirection: TextDirection.rtl),
        ),
      );
    }
    if (name == 'noche-mic') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coqui UI · Noche Mic LTR',
        theme: coquiTheme(),
        home: const Scaffold(
          backgroundColor: NocheColors.ground,
          body: NocheMicDevPage(textDirection: TextDirection.ltr),
        ),
      );
    }
    if (name == 'noche-mic-rtl') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coqui UI · Noche Mic RTL',
        theme: coquiTheme(),
        home: const Scaffold(
          backgroundColor: NocheColors.ground,
          body: NocheMicDevPage(textDirection: TextDirection.rtl),
        ),
      );
    }
    if (name == 'lesson-direction-es') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coqui UI · Lesson Direction ES',
        theme: coquiTheme(),
        home: Scaffold(
          backgroundColor: NocheColors.lessonGround,
          body: LessonDirectionGalleryPage(language: Language.spanish),
        ),
      );
    }
    if (name == 'lesson-direction-ar') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coqui UI · Lesson Direction AR',
        theme: coquiTheme(),
        home: Scaffold(
          backgroundColor: NocheColors.lessonGround,
          body: LessonDirectionGalleryPage(
            language: lessonDirectionArabicLanguage,
          ),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coqui UI gallery',
      theme: coquiTheme(),
      home: const _Index(),
    );
  }
}

class _Index extends StatelessWidget {
  const _Index();

  @override
  Widget build(BuildContext context) {
    final base = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: NocheColors.ground,
      body: ListView(
        padding: const EdgeInsetsDirectional.all(24),
        children: [
          Text(
            'coqui_ui gallery',
            style: NocheType.pageTitle.copyWith(color: NocheColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Noche shared pieces (?section=noche-ltr, ?section=noche-rtl), '
            'Noche mic (?section=noche-mic, ?section=noche-mic-rtl), and '
            'lesson direction (?section=lesson-direction-es, ?section=lesson-direction-ar).',
            style: NocheType.body.copyWith(color: NocheColors.label),
          ),
          for (final entry in <(String, String, Widget)>[
            (
              'noche-ltr',
              'Noche shared pieces (LTR)',
              const NochePiecesDevPage(textDirection: TextDirection.ltr),
            ),
            (
              'noche-rtl',
              'Noche shared pieces (RTL)',
              const NochePiecesDevPage(textDirection: TextDirection.rtl),
            ),
            (
              'noche-mic',
              'Noche mic · six states (LTR)',
              const NocheMicDevPage(textDirection: TextDirection.ltr),
            ),
            (
              'noche-mic-rtl',
              'Noche mic · six states (RTL)',
              const NocheMicDevPage(textDirection: TextDirection.rtl),
            ),
            (
              'lesson-direction-es',
              'Lesson direction · Spanish (LTR)',
              LessonDirectionGalleryPage(language: Language.spanish),
            ),
            (
              'lesson-direction-ar',
              'Lesson direction · Arabic (RTL)',
              LessonDirectionGalleryPage(
                language: lessonDirectionArabicLanguage,
              ),
            ),
          ]) ...[
            const SizedBox(height: 32),
            Text(
              entry.$2,
              style: NocheType.sheetTitle.copyWith(color: NocheColors.text),
            ),
            Text(
              'section=${entry.$1}',
              style: NocheType.bodySmall.copyWith(color: NocheColors.label),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 390,
                height: 844,
                decoration: BoxDecoration(
                  border: Border.all(color: NocheColors.line),
                ),
                clipBehavior: Clip.hardEdge,
                child: MediaQuery(
                  data: base.copyWith(
                    size: const Size(390, 844),
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                    viewInsets: EdgeInsets.zero,
                  ),
                  child: entry.$3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
