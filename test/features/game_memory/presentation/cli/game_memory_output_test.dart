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
  });

  group('Method writeResult() behaves correctly', () {
    test(
        'Method writeResult() explains why active-build verification is required',
        () {
      final output = GameMemoryOutput.writeResult(
        Rc2CollectionProfile.profile,
        const GameWriteResult(
          status: GameWriteStatus.unverifiedBuild,
          fieldId: 'bolts',
          requestedValue: 99,
        ),
      );

      expect(output, contains('Status: active game build is not verified'));
      expect(output, contains('Requested value: 99'));
    });

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

      expect(output, contains('Status: write and read-back complete'));
      expect(output, contains('Read-back value: 42'));
    });
  });
}
