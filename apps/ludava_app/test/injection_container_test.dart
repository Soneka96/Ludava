import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

void main() {
  setUp(() async => sl.pushNewScope());
  tearDown(() async => sl.popScope());

  group('Method initDependencies() behaves correctly', () {
    test('Method initDependencies() reads one initial snapshot and eagerly registers one store', () {
      final capability = _CountingTrainerSdkCapability();

      initDependencies(trainerSdkCapability: capability);

      expect(capability.stateReads, 1);
      expect(sl.isRegistered<TrainerSdkCapability>(), isTrue);
      expect(sl.isRegistered<SdkOperationGate>(), isTrue);
      expect(sl.isRegistered<Store<AppState>>(), isTrue);
      expect(sl<Store<AppState>>(), same(sl<Store<AppState>>()));
      expect(
        sl<Store<AppState>>().state.trainer.session,
        same(capability.snapshot),
      );
      expect(capability.stateChangesReads, 0);
      expect(capability.commandCalls, 0);
    });
  });
}

class _CountingTrainerSdkCapability implements TrainerSdkCapability {
  final TrainerSessionState snapshot = TrainerSessionState();
  int stateReads = 0;
  int stateChangesReads = 0;
  int commandCalls = 0;

  @override
  TrainerSessionState get state {
    stateReads++;
    return snapshot;
  }

  @override
  Stream<TrainerSessionState> get stateChanges {
    stateChangesReads++;
    return const Stream.empty();
  }

  @override
  void connect() => commandCalls++;

  @override
  void refresh() => commandCalls++;

  @override
  bool selectProcess(int processId) {
    commandCalls++;
    return false;
  }

  @override
  GameWriteResult writeField(String fieldId, int value) {
    commandCalls++;
    return GameWriteResult(status: GameWriteStatus.none, fieldId: fieldId);
  }

  @override
  Future<void> dispose() async {}
}
