import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

void main() {
  test('parses', () {
    final sheet = Sheet.parse(lagoSheetText());
    expect(sheet.scene, 'lago');
  });
}
