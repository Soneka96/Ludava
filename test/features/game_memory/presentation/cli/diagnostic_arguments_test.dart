import 'package:ludava/features/game_memory/presentation/cli/diagnostic_arguments.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class DiagnosticArguments construction', () {
    test(
      'Class DiagnosticArguments stores the current-identity read guard',
      () {
        const arguments = DiagnosticArguments(
          action: GameMemoryAction.read,
          gameId: 'rc2-collection',
          fieldId: 'bolts',
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
