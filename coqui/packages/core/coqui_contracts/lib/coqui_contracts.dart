/// Models, interfaces and routes shared by every Coquí package. Pure Dart.
///
/// Page 12, section 2 (docs/proyecto/12-flutter-contracts.md). The names and
/// shapes are binding; after order 02 only the orchestrator changes them.
///
/// Where this differs from page 12 (orchestrator's decision, Nov 19 2026):
/// - `SkillRecord.due` is a `num`, not an int: palabras.js line 33 (`e.due=t+e.gap*DAY`) can store a
///   fraction of a ms (six rights, five misses, then a right does it). It is read and written unrounded; a
///   whole value is written as an integer, as JSON.stringify does. `ProgressStore.due(skill, at:)` keeps
///   `at` an int. Every other SkillRecord field stays as page 12 types it (`gap` was already a double).
library;

export 'package:coqui_contracts/src/audio.dart';
export 'package:coqui_contracts/src/call.dart';
export 'package:coqui_contracts/src/course.dart';
export 'package:coqui_contracts/src/mulberry32.dart';
export 'package:coqui_contracts/src/normalize.dart';
export 'package:coqui_contracts/src/platform.dart';
export 'package:coqui_contracts/src/progress.dart';
export 'package:coqui_contracts/src/repaso.dart';
export 'package:coqui_contracts/src/routes.dart';
export 'package:coqui_contracts/src/speech.dart';
