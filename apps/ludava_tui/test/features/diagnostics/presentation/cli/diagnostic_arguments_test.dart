import 'package:ludava_tui/features/diagnostics/presentation/cli/diagnostic_arguments.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Class DiagnosticArguments construction', () {
    test(
      'Class DiagnosticArguments stores the current-identity read guard',
      () {
        const arguments = DiagnosticArguments(
          action: GameMemoryAction.read,
          gameId: 'synthetic-profile',
          fieldId: 'credits',
          processId: 42,
          memoryBase: 0x300000000,
          confirmed: false,
          requireCurrentIdentity: true,
        );

        expect(arguments.requireCurrentIdentity, isTrue);
        expect(arguments.action, GameMemoryAction.read);
        expect(arguments.processId, 42);
      },
    );
  });
}
