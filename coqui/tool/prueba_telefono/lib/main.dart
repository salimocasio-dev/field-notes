// Coquí phone test (order 00 of the Flutter move). One screen, six tests, "Copy results".
// Thrown away once the answers are in docs/proyecto/08 and order 18.
// Widgets library only: in this Flutter, Material lives in a separate package, and this page may use
// exactly three packages (just_audio, speech_to_text, web).
import 'dart:ui_web' as ui_web;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'src/browser.dart';
import 'src/lab.dart';

const _ink = Color(0xFF1E2A24);
const _muted = Color(0xFF4A564F);
const _paper = Color(0xFFF4F1EA);
const _green = Color(0xFF2E6B4F);
const _white = Color(0xFFFFFFFF);
const _font = 'PixelifySans';

void main() {
  final mainMs = nowMs();
  final session = setAudioSession('play-and-record');
  WidgetsFlutterBinding.ensureInitialized();
  if (Uri.base.queryParameters['sem'] == '1') {
    SemanticsBinding.instance
        .ensureSemantics(); // for scripts: the buttons become DOM nodes
  }
  final lab = Lab(mainMs: mainMs, sessionNote: session);
  _registerBox(lab);
  SchedulerBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) {
      lab.firstFrameDart = nowMs();
    });
  });
  runApp(TestApp(lab: lab));
  lab.start();
}

/// The selectable box is a real <textarea>: the phone's own selection and copy work in it.
web.HTMLTextAreaElement? _box;
void _registerBox(Lab lab) {
  ui_web.platformViewRegistry.registerViewFactory('coqui-results', (int id) {
    final t = web.document.createElement('textarea') as web.HTMLTextAreaElement;
    t.readOnly = true;
    t.value = lab.resultsText();
    t.style
      ..width = '100%'
      ..height = '100%'
      ..boxSizing = 'border-box'
      ..fontSize = '14px'
      ..fontFamily = 'monospace'
      ..padding = '8px'
      ..border = '1px solid #6B756F'
      ..background = '#FFFFFF'
      ..color = '#1E2A24';
    _box = t;
    return t;
  });
  lab.addListener(() => _box?.value = lab.resultsText());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key, required this.lab});
  final Lab lab;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Coquí phone test',
      color: _green,
      debugShowCheckedModeBanner: false,
      textStyle: const TextStyle(
        fontFamily: _font,
        fontSize: 17,
        color: _ink,
        height: 1.25,
      ),
      pageRouteBuilder: <T>(RouteSettings s, WidgetBuilder b) =>
          PageRouteBuilder<T>(settings: s, pageBuilder: (c, _, _) => b(c)),
      home: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerUp: (_) =>
            lab.unlock(), // the first tap anywhere unlocks the audio
        child: ColoredBox(
          color: _paper,
          child: SafeArea(child: TestPage(lab: lab)),
        ),
      ),
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key, required this.lab});
  final Lab lab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: lab,
      // Not a lazy list: every button exists at once (also in the semantics tree that scripts use).
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Coquí phone test',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '$kBuild  ·  ${homeScreen().standalone ? 'opened from the home screen' : 'opened in the browser'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap 1 to 6 in order, then Copy results, and paste them to Salim.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            for (final c in lab.cards) _CardView(lab: lab, card: c),
            const SizedBox(height: 8),
            _BigButton(label: 'Copy results', onTap: lab.copy, color: _ink),
            if (lab.copied.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(lab.copied, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const SizedBox(
                height: 320,
                child: HtmlElementView(viewType: 'coqui-results'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({required this.lab, required this.card});
  final Lab lab;
  final Card card;

  @override
  Widget build(BuildContext context) {
    final busy = lab.running != null;
    final mine = lab.running == card.n;
    final ask = mine ? lab.ask : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BigButton(
            label:
                '${card.n}. ${card.title}${card.status == 'done' ? '  (again)' : ''}',
            onTap: busy ? null : () => lab.run(card.n),
            color: _green,
          ),
          const SizedBox(height: 6),
          Text(card.hint, style: const TextStyle(fontSize: 16, color: _muted)),
          if (mine && lab.micWanted) ...[
            const SizedBox(height: 10),
            _BigButton(
              label: 'MIC: tap, then say "hola"',
              onTap: lab.micTapped,
              color: const Color(0xFFB0412E),
            ),
          ],
          if (ask != null) ...[
            const SizedBox(height: 10),
            Text(
              ask.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final o in ask.options) ...[
                  Expanded(
                    child: _BigButton(
                      label: o,
                      onTap: () => lab.answer(o),
                      color: const Color(0xFF3B5BA0),
                    ),
                  ),
                  if (o != ask.options.last) const SizedBox(width: 12),
                ],
              ],
            ),
          ],
          if (card.lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final l in card.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l, style: const TextStyle(fontSize: 16)),
              ),
          ],
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.onTap,
    required this.color,
  });
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: on ? color : color.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _white,
            ),
          ),
        ),
      ),
    );
  }
}
