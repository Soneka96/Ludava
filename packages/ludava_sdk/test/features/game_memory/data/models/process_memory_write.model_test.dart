import 'package:ludava_sdk/features/game_memory/data/models/process_memory_write.model.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class ProcessMemoryWriteModel construction', () {
    test('Class ProcessMemoryWriteModel preserves native write details', () {
      const model = ProcessMemoryWriteModel(
        status: MemoryWriteStatus.nativeFailure,
        bytesWritten: 2,
        requestedBytes: 4,
        errorCode: 299,
      );

      expect(model.status, MemoryWriteStatus.nativeFailure);
      expect(model.bytesWritten, 2);
      expect(model.requestedBytes, 4);
      expect(model.errorCode, 299);
    });
  });
}
