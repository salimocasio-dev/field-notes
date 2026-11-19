// A progress store (the fake) that writes down the calls the lesson makes, with the virtual time of each, in the
// shape old_harness.mjs writes the calls of PAL: {t, op, args}.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';

import 'virtual_time.dart';

class RecordingStore extends FakeProgressStore {
  RecordingStore(this.vt, {required Clock super.clock, super.json});
  final VirtualTime vt;
  final List<Map<String, Object?>> calls = [];

  @override
  List<String> due(Skill skill, {int? at}) {
    final r = super.due(skill, at: at);
    calls.add({
      't': vt.now,
      'op': 'vence',
      'args': [skill.name],
    });
    return r;
  }

  @override
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }) {
    final r = super.answer(w, skill, ok: ok, ms: ms, intro: intro);
    calls.add({
      't': vt.now,
      'op': 'responde',
      'args': [w, skill.name, ok, ms, intro],
    });
    return r;
  }

  @override
  void presume(List<String> words, List<String> stories, List<Object?> log) {
    super.presume(words, stories, log);
    calls.add({
      't': vt.now,
      'op': 'presume',
      'args': [words, stories, log],
    });
  }
}
