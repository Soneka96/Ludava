import 'package:ludava_sdk/features/game_memory/domain/entities/memory_write_result.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Property isComplete behaves correctly', () {
    test('Property isComplete returns true for a complete non-empty write', () {
      const result = MemoryWriteResult(
        status: MemoryWriteStatus.complete,
        bytesWritten: 4,
        requestedBytes: 4,
      );

      expect(result.isComplete, isTrue);
    });

    test('Property isComplete returns false for failed partial or empty writes',
        () {
      const results = [
        MemoryWriteResult(
          status: MemoryWriteStatus.nativeFailure,
          bytesWritten: 0,
          requestedBytes: 4,
        ),
        MemoryWriteResult(
          status: MemoryWriteStatus.partial,
          bytesWritten: 2,
          requestedBytes: 4,
        ),
        MemoryWriteResult(
          status: MemoryWriteStatus.complete,
          bytesWritten: 4,
          requestedBytes: 0,
        ),
      ];

      for (final result in results) {
        expect(result.isComplete, isFalse);
      }
    });
  });
}
