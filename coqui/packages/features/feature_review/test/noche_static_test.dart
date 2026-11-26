// Static Noche migration checks for feature_review lib/ files.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repaso_course.dart';

void main() {
  final libDir = Directory(
    '${repoRoot.path}/coqui/packages/features/feature_review/lib',
  );
  final uiDir = Directory('${libDir.path}/src/ui');

  List<File> dartFiles(Directory dir) =>
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  String stripComments(String src) => src
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//.*$', multiLine: true), '');

  test(
    'lib/ has zero raw Color(0x...), fontFamily, or flutter/material.dart',
    () {
      for (final f in dartFiles(libDir)) {
        final src = stripComments(f.readAsStringSync());
        expect(src, isNot(contains('Color(0x')), reason: f.path);
        expect(src, isNot(contains('fontFamily')), reason: f.path);
        expect(
          src,
          isNot(contains('package:flutter/material.dart')),
          reason: f.path,
        );
      }
    },
  );

  test('lib/src/ui/ has zero CoquiColors or CoquiText', () {
    for (final f in dartFiles(uiDir)) {
      final src = stripComments(f.readAsStringSync());
      expect(src, isNot(contains('CoquiColors')), reason: f.path);
      expect(src, isNot(contains('CoquiText')), reason: f.path);
    }
  });

  test('lib/ has zero legacy lesson/game widgets', () {
    const legacy = [
      'LessonFrame',
      'LessonProgressDashes',
      'LessonButton',
      'LessonStartButton',
      'PictureChoice',
      'WordTile',
      'SpeakerTile',
      'TileTray',
      'WrongBadge',
      'RepasoMic',
    ];
    for (final f in dartFiles(libDir)) {
      final src = stripComments(f.readAsStringSync());
      for (final symbol in legacy) {
        expect(
          RegExp('\\b$symbol\\b').hasMatch(src),
          isFalse,
          reason: '${f.path} still references $symbol',
        );
      }
    }
  });
}
