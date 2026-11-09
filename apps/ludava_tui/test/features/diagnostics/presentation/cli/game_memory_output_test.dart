import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/diagnostics/presentation/cli/game_memory_output.dart';
import 'package:test/test.dart';

final _profile = GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'TEST00001',
  executable: 'SYNTHETIC.self',
  readStatus: VerificationStatus.experimental,
  writeStatus: VerificationStatus.researchConfirmed,
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.experimental,
      writeStatus: VerificationStatus.researchConfirmed,
      minimumValue: 0,
      maximumValue: 0xffffffff,
    ),
  },
);

void main() {
  group('Method readResult() behaves correctly', () {
    test(
      'Method readResult() displays the selected field and decoded value',
      () {
        final output = GameMemoryOutput.readResult(
          _profile,
          const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 0,
          ),
        );

        expect(output, contains('synthetic-profile'));
        expect(output, contains('Profile status: experimental'));
        expect(output, contains('profile selection is manual or unverified'));
        expect(output, contains('Status: read complete'));
        expect(output, contains('Field: credits'));
        expect(output, contains('Value: 0'));
      },
    );

    test('Method readResult() displays a failed read and native error', () {
      final output = GameMemoryOutput.readResult(
        _profile,
        const GameReadResult(
          status: GameReadStatus.readFailed,
          fieldId: 'credits',
          errorCode: 299,
        ),
      );

      expect(output, contains('Status: native memory read failed'));
      expect(output, contains('Windows error: 299'));
      expect(output, isNot(contains('Value:')));
    });

    test('Method readResult() labels a success without a value invalid', () {
      final output = GameMemoryOutput.readResult(
        _profile,
        const GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
        ),
      );

      expect(output, contains('Status: invalid read result'));
      expect(output, isNot(contains('Value:')));
    });

    test('Method readResult() labels the remaining read outcomes', () {
      final expectedStatuses = {
        GameReadStatus.none: 'Status: no read attempted',
        GameReadStatus.unsupportedProfile:
            'Status: profile is not approved for reading',
        GameReadStatus.unsupportedField:
            'Status: field is not approved for reading',
        GameReadStatus.invalidReadResult: 'Status: invalid memory read result',
      };

      for (final entry in expectedStatuses.entries) {
        final output = GameMemoryOutput.readResult(
          _profile,
          GameReadResult(status: entry.key, fieldId: 'credits'),
        );

        expect(output, contains(entry.value));
      }
    });

    test('Method readResult() displays mapping and partial-read failures', () {
      final invalidMapping = GameMemoryOutput.readResult(
        _profile,
        const GameReadResult(
          status: GameReadStatus.invalidMapping,
          fieldId: 'credits',
        ),
      );
      final incompleteRead = GameMemoryOutput.readResult(
        _profile,
        const GameReadResult(
          status: GameReadStatus.incompleteRead,
          fieldId: 'credits',
        ),
      );

      expect(invalidMapping, contains('Status: invalid memory mapping'));
      expect(incompleteRead, contains('Status: incomplete memory read'));
      expect(invalidMapping, isNot(contains('Value:')));
      expect(incompleteRead, isNot(contains('Value:')));
    });
  });

  group('Method writeResult() behaves correctly', () {
    test('Method writeResult() displays matching read-back evidence', () {
      final output = GameMemoryOutput.writeResult(
        _profile,
        const GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
          requestedValue: 42,
          readBackValue: 42,
        ),
      );

      expect(output, contains('Profile status: researchConfirmed'));
      expect(output, contains('profile selection is manual or unverified'));
      expect(output, contains('Status: write and read-back complete'));
      expect(output, contains('Requested value: 42'));
      expect(output, contains('Read-back value: 42'));
    });

    test('Method writeResult() reports confirmed runtime identity', () {
      final output = GameMemoryOutput.writeResult(
        _profile,
        const GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
          requestedValue: 42,
          readBackValue: 42,
        ),
        identityConfirmed: true,
      );

      expect(output, contains('current RPCS3 PPU hash matches this profile'));
      expect(output, isNot(contains('manual or unverified')));
    });

    test('Method writeResult() explains rejected and failed writes', () {
      final confirmationRequired = GameMemoryOutput.writeResult(
        _profile,
        const GameWriteResult(
          status: GameWriteStatus.confirmationRequired,
          fieldId: 'credits',
          requestedValue: 42,
        ),
      );
      final invalidValue = GameMemoryOutput.writeResult(
        _profile,
        const GameWriteResult(
          status: GameWriteStatus.invalidValue,
          fieldId: 'credits',
          requestedValue: 0x100000000,
        ),
      );
      final readBackFailed = GameMemoryOutput.writeResult(
        _profile,
        const GameWriteResult(
          status: GameWriteStatus.readBackFailed,
          fieldId: 'credits',
          requestedValue: 42,
          errorCode: 299,
        ),
      );
      final preliminaryReadFailed = GameMemoryOutput.writeResult(
        _profile,
        const GameWriteResult(
          status: GameWriteStatus.preliminaryReadFailed,
          fieldId: 'credits',
          requestedValue: 42,
          errorCode: 299,
        ),
      );

      expect(
        confirmationRequired,
        contains('Status: explicit write confirmation is required'),
      );
      expect(
        invalidValue,
        contains('Status: value is outside the field range'),
      );
      expect(readBackFailed, contains('Status: write read-back failed'));
      expect(readBackFailed, contains('Windows error: 299'));
      expect(
        preliminaryReadFailed,
        contains('Status: preliminary memory read failed'),
      );
      expect(preliminaryReadFailed, contains('Windows error: 299'));
    });

    test('Method writeResult() labels the remaining write outcomes', () {
      final expectedStatuses = {
        GameWriteStatus.none: 'Status: no write attempted',
        GameWriteStatus.unsupportedProfile:
            'Status: profile is not approved for writing',
        GameWriteStatus.unsupportedField:
            'Status: field is not approved for writing',
        GameWriteStatus.invalidMapping: 'Status: invalid memory mapping',
        GameWriteStatus.writeFailed: 'Status: native memory write failed',
        GameWriteStatus.incompleteWrite: 'Status: incomplete memory write',
        GameWriteStatus.readBackMismatch:
            'Status: read-back did not match the requested value',
        GameWriteStatus.invalidWriteResult:
            'Status: invalid memory write result',
      };

      for (final entry in expectedStatuses.entries) {
        final output = GameMemoryOutput.writeResult(
          _profile,
          GameWriteResult(status: entry.key, fieldId: 'credits'),
        );

        expect(output, contains(entry.value));
      }
    });
  });
}
