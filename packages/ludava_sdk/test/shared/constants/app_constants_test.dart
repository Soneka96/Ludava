import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:test/test.dart';

void main() {
  group('Constant GameMemoryConstants.maxUnsigned32', () {
    test('represents the maximum unsigned 32-bit value', () {
      expect(GameMemoryConstants.maxUnsigned32, 0xffffffff);
    });
  });
}
