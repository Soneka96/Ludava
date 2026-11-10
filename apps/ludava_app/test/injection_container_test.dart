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
import 'package:mocktail/mocktail.dart';

import 'support/mock_trainer_sdk_capability.dart';
import 'package:redux/redux.dart';

void main() {
  setUp(() => sl.pushNewScope());
  tearDown(() async => sl.popScope());

  group('Method initDependencies() behaves correctly', () {
    test('Method initDependencies() registers required app dependencies', () {
      final capability = MockTrainerSdkCapability();
      when(() => capability.state).thenReturn(TrainerSessionState());
      initDependencies(trainerSdkCapability: capability);

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
