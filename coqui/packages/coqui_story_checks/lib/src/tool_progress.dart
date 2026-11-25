// A progress store for the no-screen player: it takes what the story gives it and keeps nothing (the player writes the
// calls down itself). Only what a story calls is implemented; the rest throws. Pure Dart, so `dart run` can use it.
import 'package:coqui_contracts/coqui_contracts.dart';

class ToolProgress implements ProgressStore {
  ToolProgress({this.habla = 1});

  /// The Yo switch "Speak in stories".
  final Object habla;

  /// The words he has said (`mouth.n`), by word: a word with an entry is not new.
  final Map<String, int> said = {};

  @override
  void storyFinished(StoryResult r) {}

  @override
  void listened(String id) {}

  @override
  void addMinutes(double m) {}

  @override
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }) {
    if (skill == Skill.mouth) said[w] = (said[w] ?? 0) + 1;
    return SkillRecord();
  }

  @override
  WordRecord? word(String w) => said.containsKey(w)
      ? WordRecord(w: w, primera: 0, mouth: SkillRecord()..n = said[w]!)
      : null;

  @override
  bool openForSpeaking(String w) => true;

  @override
  Object? setting(String key) => key == 'habla' ? habla : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('ToolProgress: ${invocation.memberName}');
}
