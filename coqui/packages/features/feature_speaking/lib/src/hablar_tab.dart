/// The Hablar tab (app.html: `hablar`): a "Call Danny" card for each place, and the words open for speaking.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/hablar_model.dart';
import 'package:feature_speaking/src/speech_note.dart';
import 'package:material_ui/material_ui.dart';

class HablarTab extends StatefulWidget {
  const HablarTab({
    super.key,
    required this.services,
    this.callsLater,
    this.voiceTestLabel,
    this.showSpeechNote = false,
  });

  final Services services;

  /// The grey line on the card of a call this build cannot place (`call.available` is false): calls come later on
  /// this build. With none given it is `CallTexts.callsLater`, "Calls with Danny open later."; a line given here
  /// (an empty one too) is what the card says.
  final String? callsLater;

  /// The title of an entry to the voice test (`nav.go(VoiceTestRoute())`); null: no entry. v=39 links the test
  /// page from nowhere, so there is no label to copy. (Order 24, STOP: the label and its place are not settled.)
  final String? voiceTestLabel;

  /// Shows app.html's `notaHabla` here. In v=39 it is Yo's, not Hablar's. (Order 24, STOP: where it goes.)
  final bool showSpeechNote;

  @override
  State<HablarTab> createState() => _HablarTabState();
}

class _HablarTabState extends State<HablarTab> {
  StreamSubscription<void>? _sub;
  String? _note;

  @override
  void initState() {
    super.initState();
    _sub = widget.services.progress.changes.listen((_) {
      if (mounted) setState(() {});
    });
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (!widget.showSpeechNote) return;
    final s = widget.services;
    final note = await speechNote(
      speech: s.speech,
      progress: s.progress,
      clock: s.clock,
    );
    if (mounted && note != _note) setState(() => _note = note);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _call(Place place) {
    widget.services.haptics.tick();
    widget.services.nav.go(CallRoute(place.id));
  }

  /// `.cc`: a card in a row, at least 80 high; locked ones are grey.
  Widget _card(HablarCard k) {
    final open = k.kind == HablarCardKind.open;
    final title = open
        ? CoquiText.rowTitle
        : CoquiText.rowTitle.copyWith(color: CoquiColors.mut);
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(CallTexts.callDanny, style: title),
                if (k.subtitle.isNotEmpty)
                  Text(k.subtitle, style: CoquiText.smallMuted),
              ],
            ),
          ),
          if (open) ...[
            const SizedBox(width: 16),
            PlayButton(
              icon: CoquiIcons.phone,
              semanticLabel: '${CallTexts.callDanny}: ${k.place.name}',
              onPressed: () => _call(k.place),
            ),
          ],
        ],
      ),
    );
    return CoquiCard(
      disabled: !open,
      child: open
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _call(k.place),
              child: body,
            )
          : Semantics(enabled: false, child: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    final cards = hablarCards(
      course: s.course,
      progress: s.progress,
      callsAvailable: () => s.call.available,
      callsLater: widget.callsLater ?? CallTexts.callsLater,
    );
    final open = wordsOpenForSpeaking(s.progress);
    final voiceTest = widget.voiceTestLabel;
    return TabPage(
      children: [
        ScreenTitle(CoquiLabels.speak),
        if (_note != null) KeyLine(_note!),
        for (final k in cards) _card(k),
        const SectionTitle(HablarTexts.wordsTitle),
        Block(
          child: Text(
            open.isEmpty ? HablarTexts.wordsNone : open.join(', '),
            style: CoquiText.bodyMuted,
          ),
        ),
        if (voiceTest != null)
          Block(
            top: 24,
            child: CoquiCard(
              marginBottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => s.nav.go(const VoiceTestRoute()),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(voiceTest, style: CoquiText.rowTitle),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
