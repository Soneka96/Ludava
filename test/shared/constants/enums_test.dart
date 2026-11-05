import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Enum unset sentinels', () {
    test('all public enums start with none', () {
      expect(VerificationStatus.values.first, VerificationStatus.none);
      expect(MemoryValueType.values.first, MemoryValueType.none);
      expect(ByteOrder.values.first, ByteOrder.none);
      expect(MemoryReadStatus.values.first, MemoryReadStatus.none);
      expect(GameMemoryAction.values.first, GameMemoryAction.none);
      expect(MemoryWriteStatus.values.first, MemoryWriteStatus.none);
      expect(GameReadStatus.values.first, GameReadStatus.none);
      expect(GameWriteStatus.values.first, GameWriteStatus.none);
    });
  });

  group('Enum VerificationStatus evidence labels', () {
    test('VerificationStatus includes distinct research-confirmed evidence',
        () {
      expect(
        VerificationStatus.values,
        contains(VerificationStatus.researchConfirmed),
      );
      expect(
        VerificationStatus.researchConfirmed,
        isNot(VerificationStatus.verified),
      );
    });
  });

  group('Property byteLength behaves correctly', () {
    test('Property byteLength returns null when type is none', () {
      expect(MemoryValueType.none.byteLength, isNull);
    });

    test('Property byteLength returns four when type is unsigned32', () {
      expect(MemoryValueType.unsigned32.byteLength, 4);
    });
  });
}
