import 'package:ludava/shared/platform/windows_memory_exception.dart';
import 'package:test/test.dart';

void main() {
  group('Method toString() behaves correctly', () {
    test('Method toString() includes the operation and error code', () {
      const exception = WindowsMemoryException(
        operation: 'CloseHandle',
        errorCode: 6,
      );

      expect(exception.toString(), 'CloseHandle failed (Windows error 6).');
    });

    test('Method toString() includes the process id when opening fails', () {
      const exception = WindowsMemoryException(
        operation: 'OpenProcess',
        processId: 42,
        errorCode: 5,
      );

      expect(
        exception.toString(),
        'OpenProcess for process 42 failed (Windows error 5).',
      );
    });
  });
}
