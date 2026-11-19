/// Hablar: the call with Danny, the voice test.
library;

export 'package:feature_speaking/src/module.dart';
// What the shell needs to build the voice test's content (`SpeakingModule(voiceTest:)`) from the file it reads.
export 'package:feature_speaking/src/voice_test_controller.dart'
    show VoiceLine, VoiceTarget, VoiceTestContent, VoiceTestLabels;
