import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/reading_assets.dart';
import 'package:feature_library/src/reading_audio.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

typedef _Line = ({String text, String? clip});

class TextReader extends StatefulWidget {
  const TextReader({super.key, required this.services, required this.id});

  final Services services;
  final String id;

  @override
  State<TextReader> createState() => _TextReaderState();
}

class _TextReaderState extends State<TextReader> {
  static const _pageSize = 3;

  Services get _s => widget.services;
  late final _store = ReadingStore(_s.storage(ReadingStore.space));
  late final _audio = ReadingAudio(_s.course);
  late final _textSize = _s.storage('leer');
  final _scroll = ScrollController();
  final _met = <String>{};
  List<List<_Line>>? _pages;
  Map<String, String> _labels = const {};
  String _title = '';
  int _index = 0;
  int _playback = 0;
  int? _playingLine;
  bool _large = false;
  bool _missing = false;
  bool _audioUnavailable = false;
  Future<void> _writes = Future.value();
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _large = _textSize.read('tam') == '24';
    _changes = _s.progress.changes.listen((_) => setState(() {}));
    unawaited(_load());
  }

  Future<void> _load() async {
    final id = widget.id;
    try {
      final labels = await loadReadingAsset('reader_labels.json');
      _labels = Map<String, String>.from(jsonDecode(labels) as Map);
    } on Object {
      if (mounted) setState(() => _missing = true);
      return;
    }
    if (!mounted) return;
    final List<List<_Line>> pages;
    if (id.startsWith(personalBookPrefix)) {
      final saved = _store.text(id);
      if (saved == null) {
        setState(() => _missing = true);
        return;
      }
      _title = saved.title;
      final lines = readingLines(saved.body);
      pages = [
        for (var i = 0; i < lines.length; i += _pageSize)
          [
            for (final line in lines.skip(i).take(_pageSize))
              (text: line, clip: _audio.line(line)),
          ],
      ];
    } else {
      // Course transcripts remain addressable from the map and older links.
      final Book? book;
      final Map<String, dynamic> story;
      try {
        book = await _s.course.book(id);
        story = await _s.course.story(id);
      } on Object {
        if (mounted) setState(() => _missing = true);
        return;
      }
      if (!mounted) return;
      if (book == null || !book.readable) {
        setState(() => _missing = true);
        return;
      }
      _title = book.title;
      final storyClips = story['clips'];
      final lines = <String, _Line>{};
      if (storyClips is Map) {
        for (final id in book.pages.expand((page) => page.clips)) {
          if (storyClips[id] case {'text': final String text}
              when text.isNotEmpty) {
            lines[id] = (
              text: text,
              clip: _s.course.clip(id) == null ? null : id,
            );
          }
        }
      }
      pages = [
        for (final page in book.pages)
          [for (final id in page.clips) ?lines[id]],
      ].where((page) => page.isNotEmpty).toList();
    }
    if (pages.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    final place = _store.place(id);
    setState(() {
      _pages = pages;
      _index = place.page.clamp(0, pages.length - 1);
      _met.addAll(place.words);
    });
    _savePlace();
  }

  void _savePlace() {
    if (tracksReading(_s.progress)) {
      for (final line in _pages![_index]) {
        _met.addAll(readingWords(line.text));
      }
    }
    final place = ReadingPlace(page: _index, words: Set.of(_met));
    _writes = _writes
        .then<void>((_) => _store.savePlace(widget.id, place))
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _playback++;
    unawaited(_s.clips.stop());
    unawaited(_changes?.cancel());
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _play(String clip, {int? line, String? word}) async {
    final request = ++_playback;
    setState(() {
      _playingLine = line;
      _audioUnavailable = false;
    });
    var played = false;
    try {
      await _s.clips.unlock();
      if (!mounted || request != _playback) return;
      await _s.clips.stop();
      if (!mounted || request != _playback) return;
      played = await _s.clips.play(clip);
    } on Object {
      // Playback failure must not count as an ear meeting.
    }
    if (!mounted || request != _playback) return;
    setState(() {
      _playingLine = null;
      _audioUnavailable = !played;
    });
    if (!played || _s.clips.muted) return;
    if (word != null) {
      _s.progress.heard(word);
      return;
    }
    final keys = <String>{};
    for (final token in readingWords(_pages![_index][line!].text)) {
      keys.add(_audio.word(token)?.word ?? token);
    }
    for (final key in keys) {
      _s.progress.heard(key);
    }
  }

  Future<void> _tapWord(String token) async {
    final word = _audio.word(token);
    if (word == null) {
      _playback++;
      setState(() {
        _playingLine = null;
        _audioUnavailable = true;
      });
      await _s.clips.stop().catchError((Object _) {});
    } else {
      await _play(word.clip, word: word.word);
    }
  }

  void _turn(int index) {
    _playback++;
    unawaited(_s.clips.stop());
    setState(() {
      _playingLine = null;
      _audioUnavailable = false;
      _index = index;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _savePlace();
  }

  void _finish() {
    if (tracksReading(_s.progress)) _s.progress.markRead(widget.id);
    _turn(0);
    _s.nav.back();
  }

  void _toggleSize() {
    setState(() => _large = !_large);
    unawaited(
      _textSize.write('tam', _large ? '24' : '20').catchError((Object _) {}),
    );
  }

  Widget _page(List<_Line> lines) {
    final vocabulary = ReadingVocabulary(_s.progress.words);
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        Text(_title, style: CoquiText.h1.copyWith(fontSize: 30)),
        const SizedBox(height: 24),
        for (final (index, line) in lines.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _playingLine == index
                  ? const Color(0xFFE1F0E7)
                  : CoquiColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TapWords(
                    key: ValueKey((_index, index)),
                    text: line.text,
                    size: _large ? 24 : 20,
                    vocabulary: vocabulary,
                    onTap: _tapWord,
                  ),
                ),
                if (line.clip case final clip?)
                  IconButton(
                    tooltip: CoquiLabels.again,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => unawaited(_play(clip, line: index)),
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      backgroundColor: CoquiColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: CoquiLabels.library,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => _s.nav.back(),
                        icon: const Icon(Icons.close),
                      ),
                      if (pages != null) ...[
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (_index + 1) / pages.length,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${_index + 1} / ${pages.length}'),
                        Tooltip(
                          message: _labels['textSize']!,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: _toggleSize,
                            child: const Text('Aa'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: pages != null
                      ? _page(pages[_index])
                      : Center(
                          child: _missing
                              ? Text(_labels['textUnavailable'] ?? '')
                              : const CircularProgressIndicator(),
                        ),
                ),
                if (_audioUnavailable)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _labels['audioUnavailable']!,
                      style: CoquiText.smallMuted,
                    ),
                  ),
                if (pages != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: _labels['previousPage'],
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: _index > 0
                              ? () => _turn(_index - 1)
                              : null,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Spacer(),
                        if (_index == pages.length - 1)
                          CoquiButton(
                            kind: CoquiButtonKind.go,
                            label: CoquiLabels.fin,
                            onPressed: _finish,
                          )
                        else
                          IconButton(
                            tooltip: _labels['nextPage'],
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: () => _turn(_index + 1),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TapWords extends StatefulWidget {
  const _TapWords({
    super.key,
    required this.text,
    required this.size,
    required this.vocabulary,
    required this.onTap,
  });

  final String text;
  final double size;
  final ReadingVocabulary vocabulary;
  final Future<void> Function(String) onTap;

  @override
  State<_TapWords> createState() => _TapWordsState();
}

class _TapWordsState extends State<_TapWords> {
  final _taps = <TapGestureRecognizer>[];
  var _matches = <RegExpMatch>[];

  void _setText() {
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
    _matches = readingWordPattern.allMatches(widget.text).toList();
    for (final match in _matches) {
      _taps.add(
        TapGestureRecognizer()
          ..onTap = () =>
              unawaited(widget.onTap(match.group(0)!.toLowerCase())),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _setText();
  }

  @override
  void didUpdateWidget(_TapWords oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) _setText();
  }

  @override
  void dispose() {
    for (final tap in _taps) {
      tap.dispose();
    }
    super.dispose();
  }

  Color _color(int stage) => switch (stage) {
    0 => const Color(0xFF67488C),
    1 => const Color(0xFF315891),
    2 => const Color(0xFF196B72),
    3 => const Color(0xFF30683E),
    _ => CoquiColors.ink,
  };

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var offset = 0;
    for (final (index, match) in _matches.indexed) {
      if (match.start > offset) {
        spans.add(TextSpan(text: widget.text.substring(offset, match.start)));
      }
      final text = match.group(0)!;
      spans.add(
        TextSpan(
          text: text,
          recognizer: _taps[index],
          style: TextStyle(
            color: _color(widget.vocabulary.stage(text.toLowerCase())),
          ),
        ),
      );
      offset = match.end;
    }
    spans.add(TextSpan(text: widget.text.substring(offset)));
    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontSize: widget.size,
        height: 1.75,
        color: CoquiColors.ink,
      ),
    );
  }
}
