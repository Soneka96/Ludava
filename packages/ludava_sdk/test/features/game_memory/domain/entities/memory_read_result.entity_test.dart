import 'package:ludava_sdk/features/game_memory/domain/entities/memory_read_result.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class MemoryReadResult construction', () {
    test('Class MemoryReadResult takes an immutable byte snapshot', () {
      final bytes = [1, 2, 3, 4];
      final result = MemoryReadResult(
        status: MemoryReadStatus.complete,
        bytes: bytes,
        bytesRead: 4,
        requestedBytes: 4,
      );
      bytes[0] = 99;

      expect(result.bytes, [1, 2, 3, 4]);
      expect(() => result.bytes[0] = 0, throwsUnsupportedError);
    });
  });

  group('Property isComplete behaves correctly', () {
    test('Property isComplete returns true for an exact complete read', () {
      final result = MemoryReadResult(
        status: MemoryReadStatus.complete,
        bytes: [1, 2, 3, 4],
        bytesRead: 4,
        requestedBytes: 4,
      );

      expect(result.isComplete, isTrue);
    });

    test(
      'Property isComplete returns false for partial or inconsistent results',
      () {
        final results = [
          MemoryReadResult(
            status: MemoryReadStatus.partial,
            bytes: [1, 2],
            bytesRead: 2,
            requestedBytes: 4,
          ),
          MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: [1, 2],
            bytesRead: 2,
            requestedBytes: 4,
          ),
          MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: [1, 2, 3, 4],
            bytesRead: 3,
            requestedBytes: 4,
          ),
          MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: const [],
            bytesRead: 0,
            requestedBytes: 0,
          ),
        ];

        for (final result in results) {
          expect(result.isComplete, isFalse);
        }
      },
    );
  });
}
