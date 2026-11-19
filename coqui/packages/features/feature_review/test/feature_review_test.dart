import 'package:feature_review/feature_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the module is review', () {
    expect(const ReviewModule().id, 'review');
  });
}
