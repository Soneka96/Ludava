import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/trainer.injection_container.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  setUp(() async => sl.pushNewScope());
  tearDown(() async => sl.popScope());

  group('Method initTrainerDependencies() behaves correctly', () {
    test(
      'Method initTrainerDependencies() registers one capability and gate',
      () {
        final capability = _FakeTrainerSdkCapability(TrainerSessionState());

        initTrainerDependencies(capability: capability);

        expect(sl<TrainerSdkCapability>(), same(capability));
        final gate = sl<SdkOperationGate>();
        expect(sl<SdkOperationGate>(), same(gate));
        expect(gate.isOpen, isTrue);
        expect(sl.isRegistered<LudavaSdk>(), isFalse);
      },
    );
  });
}

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  _FakeTrainerSdkCapability(this.state);

  @override
  final TrainerSessionState state;

  @override
  Stream<TrainerSessionState> get stateChanges => const Stream.empty();

  @override
  void connect() {}

  @override
  void refresh() {}

  @override
  bool selectProcess(int processId) => false;

  @override
  GameWriteResult writeField(String fieldId, int value) =>
      GameWriteResult(status: GameWriteStatus.none, fieldId: fieldId);

  @override
  Future<void> dispose() async {}
}
