// What the sprite and canvas tests read of coqui/ref/sprites/engine/ and coqui/ref/ctx/: on the vm the files
// themselves, in a browser the fixtures made from them (tool/make_sprite_fixtures.dart). The same path names a file
// on both, as the path under coqui/ref/, e.g. `sprites/engine/mkCoqui.bin`.
export 'ref_files_web.dart' if (dart.library.io) 'ref_files_vm.dart';
