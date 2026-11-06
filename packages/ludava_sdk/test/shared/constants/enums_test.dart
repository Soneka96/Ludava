import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Enum unset sentinels', () {
    test('all public enums start with none', () {
      expect(VerificationStatus.values.first, VerificationStatus.none);
      expect(MemoryValueType.values.first, MemoryValueType.none);
      expect(ByteOrder.values.first, ByteOrder.none);
      expect(MemoryReadStatus.values.first, MemoryReadStatus.none);
      expect(GameMemoryAction.values.first, GameMemoryAction.none);
      expect(
        DiagnosticGameMemoryStatus.values.first,
        DiagnosticGameMemoryStatus.none,
      );
      expect(MemoryWriteStatus.values.first, MemoryWriteStatus.none);
      expect(GameReadStatus.values.first, GameReadStatus.none);
      expect(GameWriteStatus.values.first, GameWriteStatus.none);
      expect(GameDetectionStatus.values.first, GameDetectionStatus.none);
      expect(GameIdentityConfidence.values.first, GameIdentityConfidence.none);
    });
  });

  group('Enum VerificationStatus evidence labels', () {
    test(
      'VerificationStatus includes distinct research-confirmed evidence',
      () {
        expect(
          VerificationStatus.values,
          contains(VerificationStatus.researchConfirmed),
        );
        expect(
          VerificationStatus.researchConfirmed,
          isNot(VerificationStatus.verified),
        );
      },
    );
  });

  group('Enum GameWriteStatus enabled outcomes', () {
    test('GameWriteStatus distinguishes incomplete and verified writes', () {
      expect(GameWriteStatus.values, contains(GameWriteStatus.incompleteWrite));
      expect(
        GameWriteStatus.values,
        contains(GameWriteStatus.preliminaryReadFailed),
      );
      expect(
        GameWriteStatus.values,
        contains(GameWriteStatus.readBackMismatch),
      );
      expect(GameWriteStatus.values, contains(GameWriteStatus.success));
      expect(GameWriteStatus.values, isNot(contains('unverifiedBuild')));
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
