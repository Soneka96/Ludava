import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_request.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class DiagnosticGameMemoryRequest construction', () {
    test(
      'Class DiagnosticGameMemoryRequest defaults to unconfirmed and unverified',
      () {
        const request = DiagnosticGameMemoryRequest(
          gameId: 'synthetic-profile',
          fieldId: 'credits',
          processId: 42,
          memoryBase: 0x300000000,
          action: GameMemoryAction.read,
        );

        expect(request.value, isNull);
        expect(request.confirmed, isFalse);
        expect(request.requireCurrentIdentity, isFalse);
      },
    );
  });
}
