import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/story_generator.dart';
import 'package:material_ui/material_ui.dart';

class ReadingHome extends StatefulWidget {
  const ReadingHome({super.key, required this.services, this.controller});
  final Services services;
  final ScrollController? controller;

  @override
  State<ReadingHome> createState() => _ReadingHomeState();
}

class _ReadingHomeState extends State<ReadingHome> {
  Services get _s => widget.services;
  late final _store = ReadingStore(_s.storage(ReadingStore.space));
  late List<ReadingText> _texts = _store.texts();
  StreamSubscription<void>? _changes;
  StoryGenerator? _generator;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _changes = _s.progress.changes.listen((_) => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) _texts = _store.texts();
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  void _open(ReadingText text) {
    _s.haptics.tick();
    unawaited(_s.clips.unlock());
    _s.nav.go(BookRoute(text.id));
  }

  Future<void> _save(
    String title,
    String body, {
    required bool generated,
  }) async {
    final text = await _store.add(
      now: _s.clock.nowMs(),
      title: title,
      body: body,
      generated: generated,
    );
    if (!mounted) return;
    setState(() => _texts = _store.texts());
    _open(text);
  }

  Future<void> _generate() async {
    final input = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => const _ReadingForm(generate: true),
    );
    if (input == null || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final generator = _generator ??= await StoryGenerator.load();
      if (!mounted) return;
      final story = generator.generate(
        vocabulary: ReadingVocabulary(_s.progress.words),
        focus: input.body.split(','),
        due: _s.progress.due(Skill.ear),
        previous: {
          for (final text in _texts.where((t) => t.generated)) text.body,
        },
        rng: _s.rng,
      );
      if (story == null) {
        setState(
          () => _message = input.body.isEmpty
              ? 'There’s no new story that fits your known words yet. You can still add a text to read.'
              : 'There’s no new story that fits both your practice words and your current level.',
        );
      } else {
        await _save(story.title, story.body, generated: true);
      }
    } on Object {
      if (mounted) {
        setState(() => _message = 'The story couldn’t be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final input = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => const _ReadingForm(generate: false),
    );
    if (input == null || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _save(input.title, input.body, generated: false);
    } on Object {
      if (mounted) {
        setState(() => _message = 'The text couldn’t be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ReadingText? _recommendation() {
    final vocabulary = ReadingVocabulary(_s.progress.words);
    for (final text in _texts) {
      if (!text.generated || _s.progress.hasRead(text.id)) continue;
      if (meetsReadingCoverage(readingCoverage(text.body, vocabulary))) {
        return text;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final next = _recommendation();
    final tracked = tracksReading(_s.progress);
    final wordsMet = {
      if (tracked)
        for (final text in _texts) ..._store.place(text.id).words,
    }.length;

    return ColoredBox(
      color: CoquiColors.bg,
      child: TabPage(
        controller: widget.controller,
        children: [
          const ScreenTitle(CoquiLabels.library),
          CoquiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  next == null ? 'A story for your level' : 'Next story',
                  style: CoquiText.smallMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  next?.title ?? 'What do you want to practice?',
                  style: CoquiText.h1,
                ),
                const SizedBox(height: 20),
                CoquiButton(
                  full: true,
                  kind: CoquiButtonKind.go,
                  label: next == null ? 'Generate a story' : 'Read story',
                  onPressed: _busy
                      ? null
                      : next == null
                      ? _generate
                      : () => _open(next),
                ),
              ],
            ),
          ),
          Block(
            top: 12,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (next != null)
                  CoquiButton(
                    kind: CoquiButtonKind.outline,
                    label: 'Generate a story',
                    onPressed: _busy ? null : _generate,
                  ),
                CoquiButton(
                  kind: CoquiButtonKind.outline,
                  label: 'Add text',
                  onPressed: _busy ? null : _import,
                ),
              ],
            ),
          ),
          if (_message case final message?)
            Block(
              top: 16,
              child: Semantics(liveRegion: true, child: Text(message)),
            ),
          const SectionTitle('Your shelf'),
          if (tracked)
            KeyLine(
              '$wordsMet ${wordsMet == 1 ? 'word' : 'words'} met in reading',
            ),
          if (_texts.isEmpty)
            const KeyLine('Stories you generate and texts you add appear here.')
          else
            for (final text in _texts)
              Block(
                bottom: 10,
                child: CoquiCard(
                  padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text.title, style: CoquiText.h2),
                            Text(
                              _s.progress.hasRead(text.id) && tracked
                                  ? 'Finished'
                                  : text.generated
                                  ? 'Generated story'
                                  : 'Added text',
                              style: CoquiText.smallMuted,
                            ),
                          ],
                        ),
                      ),
                      CoquiButton(
                        kind: CoquiButtonKind.outline,
                        label: 'Read',
                        semanticLabel: 'Read ${text.title}',
                        onPressed: _busy ? null : () => _open(text),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ReadingForm extends StatefulWidget {
  const _ReadingForm({required this.generate});

  final bool generate;

  @override
  State<_ReadingForm> createState() => _ReadingFormState();
}

class _ReadingFormState extends State<_ReadingForm> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, (
      title: _title.text.trim(),
      body: _body.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final generate = widget.generate;
    return AlertDialog(
      title: Text(generate ? 'Generate a story' : 'Add text'),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!generate) ...[
              TextFormField(
                controller: _title,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Enter a title.' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _body,
              minLines: generate ? 1 : 4,
              maxLines: generate ? 2 : 7,
              maxLength: generate ? 180 : 30000,
              decoration: InputDecoration(
                alignLabelWithHint: !generate,
                labelText: generate
                    ? 'Practice words (optional)'
                    : 'Paste Spanish text',
                helperText: generate
                    ? 'Separate words or phrases with commas. Leave blank for review.'
                    : null,
                helperMaxLines: 3,
              ),
              validator: (value) => !generate && readingWords(value!).isEmpty
                  ? 'Paste some text to read.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        CoquiButton(
          kind: CoquiButtonKind.outline,
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        CoquiButton(
          kind: CoquiButtonKind.go,
          label: generate ? 'Generate' : 'Add and read',
          onPressed: _submit,
        ),
      ],
    );
  }
}
