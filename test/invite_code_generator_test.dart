import 'dart:math';

import 'package:circleplus/core/utils/invite_code_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'generateInviteCode returns uppercase alphanumeric six character code',
    () {
      final code = generateInviteCode(random: Random(1));

      expect(code, hasLength(6));
      expect(isValidInviteCode(code), isTrue);
    },
  );

  test('isValidInviteCode rejects invalid code formats', () {
    expect(isValidInviteCode('ABC12'), isFalse);
    expect(isValidInviteCode('abc123'), isFalse);
    expect(isValidInviteCode('ABC-12'), isFalse);
  });
}
