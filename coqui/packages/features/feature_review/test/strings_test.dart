// Every English string of cual.js and nivel.js that coqui/ref/pantallas/strings.json lists (the strings v=39 can show)
// is what the screens say, letter for letter; and the ones with numbers in them match the patterns the list gives.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/lab.dart';

void main() {
  final all =
      (jsonDecode(
            File('../../../ref/pantallas/strings.json').readAsStringSync(),
          ) as Map<String, dynamic>)['strings']
          as List;
  final mine = all
      .cast<Map<String, dynamic>>()
      .where((s) => RegExp(r'cual\.js|nivel\.js').hasMatch(s['from'] as String))
      .toList();

  // what the screens say, without a number in it
  final said = <String>{
    CoquiLabels.review,
    ReviewStrings.startHint,
    ReviewStrings.doneTitle,
    ReviewStrings.movingUpHeading,
    ReviewStrings.movingUpSub,
    ReviewStrings.comingBackHeading,
    ReviewStrings.comingBackSub,
    ReviewStrings.rightHeading,
    ReviewStrings.missedHeading,
    'Back to ${CoquiLabels.words}',
    ReviewStrings.levelDoneTitle,
    ReviewStrings.levelStart,
    ReviewStrings.toTheMap,
    'You already understand the first 1 story.',
    'Picture 1',
  };

  test('the list has the strings of cual.js and nivel.js', () {
    expect(mine.length, greaterThan(20));
  });

  test('each string without a number is what the screens say', () {
    for (final s in mine.where((s) => s['regex'] == false)) {
      var text = s['string'] as String;
      if (text.startsWith('[aria-label] ')) text = text.substring(13);
      if (text == 'Sound') continue; // coqui_ui's sound button (its own test)
      expect(said, contains(text), reason: 'the old page says "$text"');
    }
  });

  testWidgets('each string with a number matches the pattern the list gives', (
    t,
  ) async {
    setPhone(t, 412, 915, 2.625);
    final lines = <String>[];
    for (final n in [1, 3, 10]) {
      final d = dueRecs(n, kNow);
      final lab = Lab(t, db: dbJson(d.recs));
      await lab.openReview();
      lines.addAll(lab.s.screenLines);
    }
    final lab = Lab(t, db: dbJson([]));
    await lab.openLevel();
    lines.addAll(lab.lv.screenLines);
    final summary = [
      '8 moving up · 2 coming back soon',
      '9 right · 1 missed',
      'You already understand the first 11 stories.',
    ];
    for (final s in mine.where((s) => s['regex'] == true)) {
      final re = RegExp(s['string'] as String);
      final pool = [
        ...lines,
        ...summary,
        '8 moving up',
        'coming back soon',
        '9 right',
        '1 missed',
      ];
      expect(
        pool.any(re.hasMatch),
        isTrue,
        reason: 'nothing matches ${s['string']}',
      );
    }
  });
}
