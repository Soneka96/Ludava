import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_request.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class DiagnosticGameMemoryRequest construction', () {
    test(
      'Class DiagnosticGameMemoryRequest defaults to unconfirmed and unverified',
      () {
        const request = DiagnosticGameMemoryRequest(
          gameId: 'rc2-collection',
          fieldId: 'bolts',
          processId: 42,
          memoryBase: 0x300000000,
          action: GameMemoryAction.read,
        );

        expect(request.value, isNull);
        expect(request.confirmed, isFalse);
        expect(request.requireCurrentIdentity, isFalse);
      },
    );

    test(
      'Class DiagnosticGameMemoryRequest initializes a confirmed write request',
      () {
        const request = DiagnosticGameMemoryRequest(
          gameId: 'rc2-collection',
          fieldId: 'bolts',
          processId: 42,
          memoryBase: 0x300000000,
          action: GameMemoryAction.write,
          value: 120,
          confirmed: true,
          requireCurrentIdentity: true,
        );

        expect(request.gameId, 'rc2-collection');
        expect(request.fieldId, 'bolts');
        expect(request.processId, 42);
        expect(request.memoryBase, 0x300000000);
        expect(request.action, GameMemoryAction.write);
        expect(request.value, 120);
        expect(request.confirmed, isTrue);
        expect(request.requireCurrentIdentity, isTrue);
      },
    );
  });
}
