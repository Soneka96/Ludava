import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Property byteLength behaves correctly', () {
    test('Property byteLength returns null when type is none', () {
      expect(MemoryValueType.none.byteLength, isNull);
    });

    test('Property byteLength returns four when type is unsigned32', () {
      expect(MemoryValueType.unsigned32.byteLength, 4);
    });
  });
}
