import 'package:ludava_sdk/features/game_memory/data/models/process_memory_read.model.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class ProcessMemoryReadModel construction', () {
    test('Class ProcessMemoryReadModel snapshots native bytes immutably', () {
      final bytes = [1, 2, 3, 4];
      final model = ProcessMemoryReadModel(
        status: MemoryReadStatus.complete,
        bytes: bytes,
        bytesRead: 4,
        requestedBytes: 4,
      );
      bytes[0] = 99;

      expect(model.bytes, [1, 2, 3, 4]);
      expect(() => model.bytes[0] = 0, throwsUnsupportedError);
    });
  });
}
