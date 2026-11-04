import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class GameField construction', () {
    test('Class GameField initializes field metadata and read-only default',
        () {
      final field = GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x1329e80,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: VerificationStatus.experimental,
      );

      expect(field.id, 'bolts');
      expect(field.name, 'Bolts');
      expect(field.guestOffset, 0x1329e80);
      expect(field.valueType, MemoryValueType.unsigned32);
      expect(field.byteOrder, ByteOrder.big);
      expect(field.readStatus, VerificationStatus.experimental);
      expect(field.writeStatus, VerificationStatus.none);
      expect(field.minimumValue, isNull);
      expect(field.maximumValue, isNull);
    });

    test('Class GameField accepts valid inclusive unsigned bounds', () {
      final field = _GameFieldTestData.build(
        minimumValue: GameMemoryConstants.maxUnsigned32,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      );

      expect(field.minimumValue, GameMemoryConstants.maxUnsigned32);
      expect(field.maximumValue, GameMemoryConstants.maxUnsigned32);
    });

    test('Class GameField accepts zero and a non-degenerate unsigned range',
        () {
      final field =
          _GameFieldTestData.build(minimumValue: 0, maximumValue: 123);

      expect(field.minimumValue, 0);
      expect(field.maximumValue, 123);
    });

    test('Class GameField rejects bounds outside the unsigned 32-bit range',
        () {
      expect(
        () => _GameFieldTestData.build(minimumValue: -1),
        throwsArgumentError,
      );
      expect(
        () => _GameFieldTestData.build(
          minimumValue: GameMemoryConstants.maxUnsigned32 + 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => _GameFieldTestData.build(maximumValue: -1),
        throwsArgumentError,
      );
      expect(
        () => _GameFieldTestData.build(
          maximumValue: GameMemoryConstants.maxUnsigned32 + 1,
        ),
        throwsArgumentError,
      );
    });

    test('Class GameField rejects an inverted value range', () {
      expect(
        () => _GameFieldTestData.build(minimumValue: 2, maximumValue: 1),
        throwsArgumentError,
      );
    });
  });

  group('Property canRead behaves correctly', () {
    test('Property canRead returns true when status is experimental', () {
      final field = _GameFieldTestData.build(
        readStatus: VerificationStatus.experimental,
      );

      expect(field.canRead, isTrue);
    });

    test('Property canRead returns true when status is verified', () {
      final field = _GameFieldTestData.build(
        readStatus: VerificationStatus.verified,
      );

      expect(field.canRead, isTrue);
    });

    test('Property canRead returns false when status is none or unsupported',
        () {
      for (final status in [
        VerificationStatus.none,
        VerificationStatus.unsupported,
      ]) {
        expect(_GameFieldTestData.build(readStatus: status).canRead, isFalse);
      }
    });
  });

  group('Property canWrite behaves correctly', () {
    test('Property canWrite returns true when status is verified', () {
      final field = _GameFieldTestData.build(
        writeStatus: VerificationStatus.verified,
      );

      expect(field.canWrite, isTrue);
    });

    test('Property canWrite returns false when status is not verified', () {
      for (final status in [
        VerificationStatus.none,
        VerificationStatus.experimental,
        VerificationStatus.unsupported,
      ]) {
        expect(_GameFieldTestData.build(writeStatus: status).canWrite, isFalse);
      }
    });
  });
}

abstract final class _GameFieldTestData {
  static GameField build({
    VerificationStatus readStatus = VerificationStatus.none,
    VerificationStatus writeStatus = VerificationStatus.none,
    int? minimumValue,
    int? maximumValue,
  }) =>
      GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x1329e80,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: readStatus,
        writeStatus: writeStatus,
        minimumValue: minimumValue,
        maximumValue: maximumValue,
      );
}
