import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reading.dart';
import 'package:material_ui/material_ui.dart';

enum ReaderPageTheme { night, sepia, day }

enum ReaderFont { literata, atkinson, lexend }

enum ReaderLineSpacing {
  tight(0.88),
  normal(1.0),
  loose(1.15);

  const ReaderLineSpacing(this.multiplier);
  final double multiplier;
}

class ReaderPalette {
  const ReaderPalette({
    required this.ground,
    required this.body,
    required this.heading,
    required this.label,
    required this.rule,
    required this.lit,
    required this.litText,
    required this.track,
    required this.chromeIcon,
    required this.bubbleFill,
    required this.bubbleText,
    required this.bubbleShadowColor,
    required this.bubbleShadowAlpha,
  });

  final Color ground;
  final Color body;
  final Color heading;
  final Color label;
  final Color rule;
  final Color lit;
  final Color litText;
  final Color track;
  final Color chromeIcon;
  final Color bubbleFill;
  final Color bubbleText;
  final Color bubbleShadowColor;
  final double bubbleShadowAlpha;

  static const night = ReaderPalette(
    ground: NocheColors.lessonGround,
    body: NocheColors.nightText,
    heading: NocheColors.text,
    label: NocheColors.lessonLabel,
    rule: NocheColors.lessonBorder,
    lit: NocheColors.litSentence,
    litText: NocheColors.text,
    track: NocheColors.lessonLine,
    chromeIcon: NocheColors.nightText,
    bubbleFill: NocheColors.text,
    bubbleText: NocheColors.lessonGround,
    bubbleShadowColor: NocheColors.lessonGround,
    bubbleShadowAlpha: 0.45,
  );

  static const sepia = ReaderPalette(
    ground: NocheColors.sepiaPage,
    body: NocheColors.sepiaText,
    heading: NocheColors.sepiaText,
    label: NocheColors.sepiaLabel,
    rule: NocheColors.sepiaRule,
    lit: NocheColors.sepiaLit,
    litText: NocheColors.sepiaText,
    track: NocheColors.sepiaRule,
    chromeIcon: NocheColors.sepiaText,
    bubbleFill: NocheColors.sepiaText,
    bubbleText: NocheColors.sepiaPage,
    bubbleShadowColor: NocheColors.sepiaText,
    bubbleShadowAlpha: 0.25,
  );

  static const day = ReaderPalette(
    ground: NocheColors.dayPage,
    body: NocheColors.dayText,
    heading: NocheColors.dayText,
    label: NocheColors.dayLabel,
    rule: NocheColors.dayRule,
    lit: NocheColors.dayLit,
    litText: NocheColors.dayText,
    track: NocheColors.dayRule,
    chromeIcon: NocheColors.dayText,
    bubbleFill: NocheColors.dayText,
    bubbleText: NocheColors.dayPage,
    bubbleShadowColor: NocheColors.dayText,
    bubbleShadowAlpha: 0.20,
  );

  static ReaderPalette of(ReaderPageTheme theme) => switch (theme) {
    ReaderPageTheme.night => night,
    ReaderPageTheme.sepia => sepia,
    ReaderPageTheme.day => day,
  };
}

class ReaderSettings {
  const ReaderSettings({
    this.step = 4,
    this.page = ReaderPageTheme.night,
    this.font = ReaderFont.literata,
    this.spacing = ReaderLineSpacing.normal,
    this.underlineWords = true,
    this.lightUpSentence = true,
    this.speed = 0.9,
  }) : assert(step >= 1 && step <= 7);

  static const List<(double size, double line)> _sizeSteps = [
    (15, 25),
    (16, 26),
    (17, 28),
    (19, 31),
    (21, 34),
    (23, 38),
    (26, 42),
  ];

  static const List<double> speedValues = [0.75, 0.9, 1.0];

  final int step;
  final ReaderPageTheme page;
  final ReaderFont font;
  final ReaderLineSpacing spacing;
  final bool underlineWords;
  final bool lightUpSentence;
  final double speed;

  double get bodyFontSize => _sizeSteps[(step - 1).clamp(0, 6)].$1;

  double get bodyLineHeight =>
      _sizeSteps[(step - 1).clamp(0, 6)].$2 * spacing.multiplier;

  double get dropCapFontSize => 60.0 * (bodyFontSize / 19.0);

  double get dropCapLineHeight => 52.0 * (bodyFontSize / 19.0);

  String get speedLabel {
    if ((speed - 0.75).abs() < 0.01) return '0.75×';
    if ((speed - 0.9).abs() < 0.01) return '0.9×';
    return '1×';
  }

  ReaderPalette get palette => ReaderPalette.of(page);

  ReaderSettings copyWith({
    int? step,
    ReaderPageTheme? page,
    ReaderFont? font,
    ReaderLineSpacing? spacing,
    bool? underlineWords,
    bool? lightUpSentence,
    double? speed,
  }) => ReaderSettings(
    step: (step ?? this.step).clamp(1, 7),
    page: page ?? this.page,
    font: font ?? this.font,
    spacing: spacing ?? this.spacing,
    underlineWords: underlineWords ?? this.underlineWords,
    lightUpSentence: lightUpSentence ?? this.lightUpSentence,
    speed: speed ?? this.speed,
  );

  ReaderSettings cycleSpeed() {
    if ((speed - 0.75).abs() < 0.01) return copyWith(speed: 0.9);
    if ((speed - 0.9).abs() < 0.01) return copyWith(speed: 1.0);
    return copyWith(speed: 0.75);
  }

  /// Whether `coqui_ui` exposes a `NocheType` Lexend style.
  ///
  /// Pending `coqui/requests/113-feature-library-needs-coqui-ui-reader-font-styles.md`;
  /// while `false`, the Lexend tile stays disabled so learners are never shown
  /// Atkinson mislabelled as Lexend.
  static const bool lexendAvailable = false;

  ReaderFont get effectiveFont => font == ReaderFont.lexend && !lexendAvailable
      ? ReaderFont.literata
      : font;

  bool samePaginationAs(ReaderSettings other) =>
      step == other.step &&
      effectiveFont == other.effectiveFont &&
      spacing == other.spacing;

  static TextStyle previewStyleFor(ReaderFont font, Color color) {
    final base = switch (font) {
      ReaderFont.literata => NocheType.bookTitle,
      ReaderFont.atkinson => NocheType.body,
      // Pending coqui/requests/113-feature-library-needs-coqui-ui-reader-font-styles.md
      // for NocheType.bookBodyLexend.
      ReaderFont.lexend => NocheType.body,
    };
    final weight = switch (font) {
      ReaderFont.literata => FontWeight.w500,
      ReaderFont.atkinson => FontWeight.w500,
      ReaderFont.lexend => FontWeight.w400,
    };
    return base.copyWith(
      fontWeight: weight,
      fontSize: 26,
      height: 1,
      color: color,
    );
  }

  TextStyle bodyStyle(Language language, Color color) {
    final activeFont = effectiveFont;
    final base = switch (activeFont) {
      ReaderFont.literata => NocheType.bookBody,
      ReaderFont.atkinson => NocheType.body,
      ReaderFont.lexend => NocheType.bookBody,
    };
    final adapted = NocheType.forScript(base, language.script);
    final fontSize = language.script == 'Arab'
        ? bodyFontSize + 2
        : bodyFontSize;
    final lineHeight = language.script == 'Arab'
        ? ((fontSize * 1.7) / 4).round() * 4.0 * spacing.multiplier
        : bodyLineHeight;
    final weight =
        activeFont == ReaderFont.literata && language.script != 'Arab'
        ? FontWeight.w400
        : adapted.fontWeight;
    return adapted.copyWith(
      fontSize: fontSize,
      height: lineHeight / fontSize,
      fontWeight: weight,
      color: color,
    );
  }

  Map<String, Object> toJson() => {
    'step': step,
    'page': page.name,
    'font': font.name,
    'spacing': spacing.name,
    'underlineWords': underlineWords,
    'lightUpSentence': lightUpSentence,
    'speed': speed,
  };

  static ReaderSettings fromJson(Object? value) {
    if (value is! Map) return const ReaderSettings();
    final rawStep = value['step'];
    final step = rawStep is num && rawStep.isFinite
        ? rawStep.round().clamp(1, 7)
        : 4;
    final page = ReaderPageTheme.values.firstWhere(
      (e) => e.name == value['page'],
      orElse: () => ReaderPageTheme.night,
    );
    final font = ReaderFont.values.firstWhere(
      (e) => e.name == value['font'],
      orElse: () => ReaderFont.literata,
    );
    final spacing = ReaderLineSpacing.values.firstWhere(
      (e) => e.name == value['spacing'],
      orElse: () => ReaderLineSpacing.normal,
    );
    final underlineWords = value['underlineWords'] is bool
        ? value['underlineWords'] as bool
        : true;
    final lightUpSentence = value['lightUpSentence'] is bool
        ? value['lightUpSentence'] as bool
        : true;
    final rawSpeed = value['speed'];
    var speed = 0.9;
    if (rawSpeed is num) {
      final s = rawSpeed.toDouble();
      if ((s - 0.75).abs() < 0.05) {
        speed = 0.75;
      } else if ((s - 1.0).abs() < 0.05) {
        speed = 1.0;
      }
    }
    return ReaderSettings(
      step: step,
      page: page,
      font: font,
      spacing: spacing,
      underlineWords: underlineWords,
      lightUpSentence: lightUpSentence,
      speed: speed,
    );
  }

  static ReaderSettings loadFrom(KeyValueStore storage) {
    final raw = storage.read('settings');
    if (raw != null) {
      try {
        return fromJson(jsonDecode(raw));
      } on FormatException {
        return const ReaderSettings();
      }
    }
    if (storage.read('tam') == '24') {
      return const ReaderSettings(step: 6);
    }
    return const ReaderSettings();
  }

  Future<void> saveTo(KeyValueStore storage) =>
      storage.write('settings', jsonEncode(toJson()));

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.step == step &&
      other.page == page &&
      other.font == font &&
      other.spacing == spacing &&
      other.underlineWords == underlineWords &&
      other.lightUpSentence == lightUpSentence &&
      other.speed == speed;

  @override
  int get hashCode => Object.hash(
    ReaderSettings,
    step,
    page,
    font,
    spacing,
    underlineWords,
    lightUpSentence,
    speed,
  );
}

class ReaderSentence {
  const ReaderSentence({required this.id, required this.text, this.clipId});

  final String id;
  final String text;
  final String? clipId;
}

class ReaderParagraph {
  const ReaderParagraph(this.sentences);

  final List<ReaderSentence> sentences;

  String get text => sentences.map((s) => s.text).join(' ');

  List<({ReaderSentence sentence, int start, int end})> get sentenceRanges {
    final ranges = <({ReaderSentence sentence, int start, int end})>[];
    var offset = 0;
    for (var i = 0; i < sentences.length; i++) {
      if (i > 0) offset += 1;
      final s = sentences[i];
      final end = offset + s.text.length;
      ranges.add((sentence: s, start: offset, end: end));
      offset = end;
    }
    return ranges;
  }
}

class ReaderChapterDoc {
  const ReaderChapterDoc({
    this.label,
    required this.title,
    required this.paragraphs,
  });

  final String? label;
  final String title;
  final List<ReaderParagraph> paragraphs;
}

class ReaderDocument {
  const ReaderDocument({
    required this.id,
    required this.title,
    required this.chapters,
    required this.hasAudio,
  });

  final String id;
  final String title;
  final List<ReaderChapterDoc> chapters;
  final bool hasAudio;

  static List<ReaderParagraph> _personalParagraphs(List<String> rawParagraphs) {
    final out = <ReaderParagraph>[];
    for (var i = 0; i < rawParagraphs.length; i++) {
      final trimmed = rawParagraphs[i].trim();
      if (trimmed.isEmpty) continue;
      out.add(
        ReaderParagraph([
          ReaderSentence(id: 'p${out.length}_s0', text: trimmed, clipId: null),
        ]),
      );
    }
    return out;
  }

  factory ReaderDocument.fromPersonal(ReadingText saved) {
    final rawChapters = saved.chapters;
    if (rawChapters != null && rawChapters.isNotEmpty) {
      final docs = <ReaderChapterDoc>[];
      for (final chapter in rawChapters) {
        final paragraphs = _personalParagraphs(chapter.paragraphs);
        if (paragraphs.isEmpty && chapter.title.trim().isEmpty) continue;
        docs.add(
          ReaderChapterDoc(
            label: chapter.label,
            title: chapter.title,
            paragraphs: paragraphs,
          ),
        );
      }
      return ReaderDocument(
        id: saved.id,
        title: saved.title,
        chapters: docs,
        hasAudio: false,
      );
    }

    final normalizedBody = saved.body.trim();
    final List<String> parts;
    if (normalizedBody.isEmpty) {
      parts = const [];
    } else if (RegExp(r'\r?\n\s*\r?\n').hasMatch(normalizedBody)) {
      parts = normalizedBody.split(RegExp(r'\r?\n\s*\r?\n'));
    } else if (normalizedBody.contains('\n')) {
      parts = normalizedBody.split(RegExp(r'\r?\n'));
    } else {
      parts = [normalizedBody];
    }

    return ReaderDocument(
      id: saved.id,
      title: saved.title,
      chapters: [
        ReaderChapterDoc(
          label: null,
          title: saved.title,
          paragraphs: _personalParagraphs(parts),
        ),
      ],
      hasAudio: false,
    );
  }

  factory ReaderDocument.fromCourseBook(
    Book book,
    Map<String, dynamic> story,
    CourseCatalog course,
  ) {
    final storyClips = story['clips'];
    final paragraphs = <ReaderParagraph>[];
    if (storyClips is Map) {
      for (final page in book.pages) {
        final sentences = <ReaderSentence>[];
        for (final clipId in page.clips) {
          if (storyClips[clipId] case {'text': final String text}
              when text.trim().isNotEmpty) {
            sentences.add(
              ReaderSentence(
                id: clipId,
                text: text.trim(),
                clipId: course.clip(clipId) != null ? clipId : null,
              ),
            );
          }
        }
        if (sentences.isNotEmpty) {
          paragraphs.add(ReaderParagraph(sentences));
        }
      }
    }
    final hasAudio = paragraphs.any(
      (p) => p.sentences.any((s) => s.clipId != null),
    );
    return ReaderDocument(
      id: book.id,
      title: book.title,
      chapters: [
        ReaderChapterDoc(
          label: null,
          title: book.title,
          paragraphs: paragraphs,
        ),
      ],
      hasAudio: hasAudio,
    );
  }
}

enum WordMarkKind { neverHeard, learning, known, none }

class ReaderEarIndex {
  ReaderEarIndex(
    Iterable<WordRecord> records,
    this.language, {
    this.stageMax = defaultStageMax,
  }) {
    for (final record in records) {
      final key = language.normalize(record.w).trim();
      if (key.isEmpty) continue;
      final prev = _stages[key] ?? 0;
      if (record.ear.etapa > prev) {
        _stages[key] = record.ear.etapa;
      }
    }
  }

  final Language language;
  final int stageMax;
  final Map<String, int> _stages = {};

  static final RegExp _digitsOnly = RegExp(r'^[\p{N}]+$', unicode: true);

  int stageOf(String rawWord) {
    final key = language.normalize(rawWord).trim();
    if (key.isEmpty) return 0;
    return _stages[key] ?? 0;
  }

  WordMarkKind markFor(String rawWord) {
    final key = language.normalize(rawWord).trim();
    if (key.isEmpty || _digitsOnly.hasMatch(key)) {
      return WordMarkKind.none;
    }
    final stage = _stages[key] ?? 0;
    if (stage <= 0) return WordMarkKind.neverHeard;
    if (stage < stageMax) return WordMarkKind.learning;
    return WordMarkKind.known;
  }
}
