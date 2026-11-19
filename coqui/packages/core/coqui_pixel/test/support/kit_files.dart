// What the kit's sprite test reads of coqui/ref/sprites/kit/: on the vm the files themselves, in a browser the fixture
// made from them (tool/make_sprite_fixtures.dart). Kept apart from ref_files.dart so that only the tests that need the
// kit's 5.7 MB fixture compile it.
export 'kit_files_web.dart' if (dart.library.io) 'kit_files_vm.dart';
