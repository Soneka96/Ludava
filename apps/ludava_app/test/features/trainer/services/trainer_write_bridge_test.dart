import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/mock_trainer_sdk_capability.dart';
import '../../../support/trainer_state_fixture.dart';

void main() {
  late MockTrainerSdkCapability capability;
  late SdkOperationGate operationGate;
  late TrainerWriteBridge bridge;
  late TrainerSessionState origin;
  late GameField field;

  setUp(() {
    capability = MockTrainerSdkCapability();
    operationGate = SdkOperationGate();
    bridge = TrainerWriteBridge(capability, operationGate);
    origin = trainerStateFixtureSession();
    field = origin.profile!.findField('credits')!;
    when(() => capability.state).thenReturn(origin);
  });

  GameWriteResult write(int value) => bridge.writeField(
    'credits',
    value,
    expectedSession: origin,
    expectedField: field,
  );

  group('Method writeField() behaves correctly', () {
    test('Method writeField() returns the actual successful SDK result', () {
      final result = const GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: 'credits',
        requestedValue: 44,
        readBackValue: 44,
      );
      when(() => capability.writeField('credits', 44)).thenReturn(result);

      expect(write(44), same(result));
      verify(() => capability.writeField('credits', 44)).called(1);
      verify(() => capability.state).called(1);
      verifyNoMoreInteractions(capability);
    });

    test('Method writeField() returns the actual unsuccessful SDK result', () {
      final result = const GameWriteResult(
        status: GameWriteStatus.readBackMismatch,
        fieldId: 'credits',
        requestedValue: 44,
        readBackValue: 43,
      );
      when(() => capability.writeField('credits', 44)).thenReturn(result);

      expect(write(44), same(result));
      verify(() => capability.writeField('credits', 44)).called(1);
      verify(() => capability.state).called(1);
      verifyNoMoreInteractions(capability);
    });

    test('Method writeField() propagates SDK exceptions', () {
      when(() => capability.writeField('credits', 44))
          .thenThrow(StateError('write failed'));

      expect(() => write(44), throwsA(isA<StateError>()));
      verify(() => capability.writeField('credits', 44)).called(1);
      verify(() => capability.state).called(1);
      verifyNoMoreInteractions(capability);
    });

    test(
      'Method writeField() returns the sentinel without calling a closed SDK',
      () {
        operationGate.close();

        final result = write(44);

        expect(result.status, GameWriteStatus.none);
        expect(result.fieldId, 'credits');
        expect(result.requestedValue, 44);
        expect(result.readBackValue, isNull);
        verifyNever(() => capability.writeField(any(), any()));
      },
    );

    test(
      'Method writeField() rejects a session replacement before SDK write',
      () {
        when(() => capability.state)
            .thenReturn(trainerStateFixtureSession(profileId: 'other-profile'));

        final result = write(44);

        expect(result.status, GameWriteStatus.none);
        verifyNever(() => capability.writeField(any(), any()));
      },
    );

    test('Method writeField() rejects a changed mapping before SDK write', () {
      final changedFieldSession = trainerStateFixtureSession(
        guestOffset: 0x200,
      );
      when(() => capability.state).thenReturn(changedFieldSession);

      final result = write(44);

      expect(result.status, GameWriteStatus.none);
      verifyNever(() => capability.writeField(any(), any()));
    });
  });
}
