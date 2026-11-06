import 'package:ludava/features/rpcs3_connection/data/models/windows_process_discovery_call_result.model.dart';
import 'package:test/test.dart';

void main() {
  group('Class WindowsProcessDiscoveryCallResult construction', () {
    test(
      'Class WindowsProcessDiscoveryCallResult preserves value and error code',
      () {
        const result = WindowsProcessDiscoveryCallResult<bool>(
          value: false,
          errorCode: 18,
        );

        expect(result.value, isFalse);
        expect(result.errorCode, 18);
      },
    );
  });
}
