// The scenes' sheets as text: on the vm the files themselves (docs/proyecto/pixel/<id>-sheet.json), in a browser the
// fixtures made from them (tool/make_sheet_fixture.dart).
export 'sheet_text_web.dart' if (dart.library.io) 'sheet_text_vm.dart';
