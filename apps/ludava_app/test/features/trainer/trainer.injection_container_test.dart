import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_app/features/trainer/trainer.injection_container.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_sdk/ludava_sdk.dart';

import '../../support/mock_trainer_sdk_capability.dart';

void main() {
  setUp(() => sl.pushNewScope());
  tearDown(() async => sl.popScope());

  group('Method initTrainerDependencies() behaves correctly', () {
    test('Method initTrainerDependencies() registers trainer dependencies', () {
      initTrainerDependencies(capability: MockTrainerSdkCapability());

      expect(sl.isRegistered<TrainerSdkCapability>(), isTrue);
      expect(sl.isRegistered<SdkOperationGate>(), isTrue);
      expect(sl.isRegistered<TrainerWriteBridge>(), isTrue);
      expect(sl.isRegistered<LudavaSdk>(), isFalse);
    });
  });
}
