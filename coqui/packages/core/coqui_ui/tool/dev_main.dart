/// The gallery: every token and every widget of the shared look, each section
/// arranged to be held against the reference picture it comes from.
///
///   flutter run -d chrome -t tool/dev_main.dart
///   flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?section=palabras"
///
/// Without `?section=` all sections are listed, each at the phone size (412 x 915)
/// under its name and the reference file to compare with. With `?section=<name>`
/// one section fills the page, as a phone screen, for the screenshot script
/// (`tool/shots.mjs`). Section names: see [gallerySections].
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'gallery/lesson_direction.dart';
import 'gallery/noche_mic.dart';
import 'gallery/noche_pieces.dart';
import 'gallery/screens.dart';

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
          body: LessonDirectionGalleryPage(
            language: lessonDirectionArabicLanguage,
          ),
        ),
      );
    }
    GallerySection? one;
    for (final s in gallerySections) {
      if (s.name == name) one = s;
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coqui UI gallery',
      theme: coquiTheme(),
      home: one != null
          ? Scaffold(body: Builder(builder: one.builder))
          : const _Index(),
    );
  }
}

class _Index extends StatelessWidget {
  const _Index();

  @override
  Widget build(BuildContext context) {
    final base = MediaQuery.of(context);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('coqui_ui gallery', style: CoquiText.h1),
          const SizedBox(height: 8),
          Text(
            'Noche shared pieces (?section=noche-ltr, ?section=noche-rtl), '
            'Noche mic (?section=noche-mic, ?section=noche-mic-rtl), and '
            'lesson direction (?section=lesson-direction-es, ?section=lesson-direction-ar), '
            'followed by the v=39 reference sections.',
            style: CoquiText.smallMuted,
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
            Text(entry.$2, style: CoquiText.h2),
            Text('section=${entry.$1}', style: CoquiText.smallMuted),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 390,
                height: 844,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x33000000)),
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
          for (final s in gallerySections) ...[
            const SizedBox(height: 32),
            Text(s.title, style: CoquiText.h2),
            Text(
              'section=${s.name}   reference: ${s.refs.isEmpty ? '-' : s.refs.join(', ')}',
              style: CoquiText.smallMuted,
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: screenSize.width,
                height: screenSize.height,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x33000000)),
                ),
                clipBehavior: Clip.hardEdge,
                child: MediaQuery(
                  data: base.copyWith(
                    size: screenSize,
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                    viewInsets: EdgeInsets.zero,
                  ),
                  child: Builder(builder: s.builder),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
