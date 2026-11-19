// What the tests read of coqui/ref/pp/: on the vm the files themselves, in a browser the fixture made from them
// (tool/make_fixtures.dart). The same path names a file on both.
export 'ref_data_web.dart' if (dart.library.io) 'ref_data_vm.dart';
