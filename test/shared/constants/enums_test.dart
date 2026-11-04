import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Enum unset sentinels', () {
    test('all public enums start with none', () {
      expect(VerificationStatus.values.first, VerificationStatus.none);
      expect(MemoryValueType.values.first, MemoryValueType.none);
      expect(ByteOrder.values.first, ByteOrder.none);
      expect(MemoryReadStatus.values.first, MemoryReadStatus.none);
      expect(GameReadStatus.values.first, GameReadStatus.none);
      expect(GameWriteStatus.values.first, GameWriteStatus.none);
    });
  });
}
