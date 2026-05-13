import 'package:circleplus/core/utils/date_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pulseDateKey formats local date as yyyyMMdd', () {
    expect(pulseDateKey(DateTime(2026, 5, 3)), '20260503');
  });
}
