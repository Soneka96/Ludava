import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/trainer/presentation/nocterm/trainer_field_row_component.dart';
import 'package:nocterm/nocterm_test.dart' show containsText, testNocterm;
import 'package:test/test.dart';

final _field = GameField(
  id: 'credits',
  name: 'Credits',
  guestOffset: 0x1000,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  readStatus: VerificationStatus.verified,
);

void main() {
  group('Class TrainerFieldRowComponent rendering behavior', () {
    test(
      'Class TrainerFieldRowComponent renders a grouped verified value and selection marker',
      () async {
        await testNocterm('selected field row', (tester) async {
          await tester.pumpComponent(
            TrainerFieldRowComponent(
              index: 0,
              field: _field,
              canEdit: true,
              readResult: GameReadResult(
                status: GameReadStatus.success,
                fieldId: 'credits',
                value: 1234567,
              ),
              selected: true,
            ),
          );

          expect(tester.terminalState, containsText('❯'));
          expect(tester.terminalState, containsText('1. Credits'));
          expect(tester.terminalState, containsText('1,234,567'));
        });
      },
    );

    test(
      'Class TrainerFieldRowComponent labels a non-writable field read-only',
      () async {
        await testNocterm('read-only field row', (tester) async {
          await tester.pumpComponent(
            TrainerFieldRowComponent(
              index: 0,
              field: _field,
              canEdit: false,
              readResult: const GameReadResult(
                status: GameReadStatus.success,
                fieldId: 'credits',
                value: 1234,
              ),
              selected: false,
            ),
          );

          expect(tester.terminalState, containsText('1. Credits (read-only)'));
          expect(tester.terminalState, containsText('1,234'));
        });
      },
    );

    test(
      'Class TrainerFieldRowComponent shows unavailable when a read did not succeed',
      () async {
        await testNocterm('unavailable field row', (tester) async {
          await tester.pumpComponent(
            TrainerFieldRowComponent(
              index: 0,
              field: _field,
              canEdit: false,
              readResult: const GameReadResult(
                status: GameReadStatus.readFailed,
                fieldId: 'credits',
              ),
              selected: false,
            ),
          );

          expect(tester.terminalState, containsText('Unavailable'));
          expect(tester.terminalState, isNot(containsText('0')));
          expect(tester.terminalState, containsText('Credits'));
        });
      },
    );

    test(
      'Class TrainerFieldRowComponent shows unavailable without a read result',
      () async {
        await testNocterm('missing field read', (tester) async {
          await tester.pumpComponent(
            TrainerFieldRowComponent(
              index: 0,
              field: _field,
              canEdit: false,
              readResult: null,
              selected: false,
            ),
          );

          expect(tester.terminalState, containsText('Unavailable'));
          expect(tester.terminalState, isNot(containsText('0')));
        });
      },
    );
  });
}
