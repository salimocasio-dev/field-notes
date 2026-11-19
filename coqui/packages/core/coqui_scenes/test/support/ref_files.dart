// The reference files under coqui/ref/: on the vm the files themselves; in a browser there are none (null), and a test
// falls back on its fixture.
export 'ref_files_web.dart' if (dart.library.io) 'ref_files_vm.dart';
