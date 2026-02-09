import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/core/constants/settings_constants.dart';

void main() {
  test('speedOptions has length 7', () {
    expect(speedOptions.length, 7);
  });

  test('speedOptions contains expected values', () {
    expect(speedOptions, [0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0]);
  });

  test('speedOptions includes default 1.0', () {
    expect(speedOptions.contains(1.0), true);
  });
}
