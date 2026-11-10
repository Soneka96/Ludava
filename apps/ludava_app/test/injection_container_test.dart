import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/state/ludava_session_body_view_model.dart';
import 'package:ludava_app/features/connection/presentation/state/rpcs3_connection_indicator_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_game_header_view_model.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

class _RegistrationCapability implements TrainerSdkCapability {
  @override
  TrainerSessionState get state => TrainerSessionState();

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

void main() {
  setUp(() => sl.pushNewScope());
  tearDown(() async => sl.popScope());

  group('Method initDependencies() behaves correctly', () {
    test('Method initDependencies() registers required app dependencies', () {
      initDependencies(trainerSdkCapability: _RegistrationCapability());

      expect(sl.isRegistered<TrainerSdkCapability>(), isTrue);
      expect(sl.isRegistered<SdkOperationGate>(), isTrue);
      expect(sl.isRegistered<Store<AppState>>(), isTrue);
      expect(sl.isRegistered<TrainerWriteBridge>(), isTrue);
      expect(sl.isRegistered<TrainerFieldsViewModel>(), isTrue);
      expect(sl.isRegistered<TrainerGameHeaderViewModel>(), isTrue);
      expect(sl.isRegistered<LudavaSessionBodyViewModel>(), isTrue);
      expect(sl.isRegistered<Rpcs3ConnectionIndicatorViewModel>(), isTrue);
    });
  });
}
