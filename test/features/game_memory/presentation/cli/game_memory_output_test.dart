import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/features/game_memory/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/features/game_memory/presentation/cli/game_memory_output.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method readResult() behaves correctly', () {
    test('Method readResult() displays the selected field and decoded value',
        () {
      final output = GameMemoryOutput.readResult(
        Rc2CollectionProfile.profile,
        const GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'bolts',
          value: 0,
        ),
      );

      expect(output, contains('rc2-collection'));
      expect(output, contains('Profile status: experimental'));
      expect(output, contains('process and profile are manually selected'));
      expect(output, contains('Ludava does not verify the active game'));
      expect(output, contains('Status: read complete'));
      expect(output, contains('Field: bolts'));
      expect(output, contains('Value: 0'));
    });

    test('Method readResult() displays a failed read and native error', () {
      final output = GameMemoryOutput.readResult(
        Rc2CollectionProfile.profile,
        const GameReadResult(
          status: GameReadStatus.readFailed,
          fieldId: 'bolts',
          errorCode: 299,
        ),
      );

      expect(output, contains('Status: native memory read failed'));
      expect(output, contains('Windows error: 299'));
      expect(output, isNot(contains('Value:')));
    });

    test('Method readResult() labels a success without a value invalid', () {
      final output = GameMemoryOutput.readResult(
        Rc2CollectionProfile.profile,
        const GameReadResult(status: GameReadStatus.success, fieldId: 'bolts'),
      );

      expect(output, contains('Status: invalid read result'));
      expect(output, isNot(contains('Value:')));
    });

    test('Method readResult() displays mapping and partial-read failures', () {
      final invalidMapping = GameMemoryOutput.readResult(
        Rc2CollectionProfile.profile,
        const GameReadResult(
          status: GameReadStatus.invalidMapping,
          fieldId: 'bolts',
        ),
      );
      final incompleteRead = GameMemoryOutput.readResult(
        Rc2CollectionProfile.profile,
        const GameReadResult(
          status: GameReadStatus.incompleteRead,
          fieldId: 'bolts',
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
        Rc2CollectionProfile.profile,
        const GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'bolts',
          requestedValue: 42,
          readBackValue: 42,
        ),
      );

      expect(output, contains('Profile status: researchConfirmed'));
      expect(output, contains('process and profile are manually selected'));
      expect(output, contains('Status: write and read-back complete'));
      expect(output, contains('Requested value: 42'));
      expect(output, contains('Read-back value: 42'));
    });

    test('Method writeResult() explains rejected and failed writes', () {
      final confirmationRequired = GameMemoryOutput.writeResult(
        Rc2CollectionProfile.profile,
        const GameWriteResult(
          status: GameWriteStatus.confirmationRequired,
          fieldId: 'bolts',
          requestedValue: 42,
        ),
      );
      final invalidValue = GameMemoryOutput.writeResult(
        Rc2CollectionProfile.profile,
        const GameWriteResult(
          status: GameWriteStatus.invalidValue,
          fieldId: 'bolts',
          requestedValue: 0x100000000,
        ),
      );
      final readBackFailed = GameMemoryOutput.writeResult(
        Rc2CollectionProfile.profile,
        const GameWriteResult(
          status: GameWriteStatus.readBackFailed,
          fieldId: 'bolts',
          requestedValue: 42,
          errorCode: 299,
        ),
      );

      expect(confirmationRequired,
          contains('Status: explicit write confirmation is required'));
      expect(
          invalidValue, contains('Status: value is outside the field range'));
      expect(readBackFailed, contains('Status: write read-back failed'));
      expect(readBackFailed, contains('Windows error: 299'));
    });
  });
}
