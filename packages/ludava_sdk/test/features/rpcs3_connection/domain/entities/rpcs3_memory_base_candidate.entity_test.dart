import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:test/test.dart';

void main() {
  group('Class Rpcs3MemoryBaseCandidate construction', () {
    test('Class Rpcs3MemoryBaseCandidate stores its base and log path', () {
      const candidate = Rpcs3MemoryBaseCandidate(
        memoryBase: 0x300000000,
        logPath: r'C:\RPCS3\log\RPCS3.log',
      );

      expect(candidate.memoryBase, 0x300000000);
      expect(candidate.logPath, r'C:\RPCS3\log\RPCS3.log');
    });
  });
}
