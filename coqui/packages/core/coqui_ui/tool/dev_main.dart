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

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'gallery/screens.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final name = Uri.base.queryParameters['section'];
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
            'Each section is built from the shared widgets and arranged like the '
            'reference picture named under its title (coqui/ref/pantallas/android-412x915/).',
            style: CoquiText.smallMuted,
          ),
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
