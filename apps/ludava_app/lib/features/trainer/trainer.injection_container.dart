import 'package:get_it/get_it.dart';
import 'package:ludava_app/features/trainer/services/ludava_sdk_trainer_capability.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Registers the trainer capability and its shared terminal operation gate.
void initTrainerDependencies({TrainerSdkCapability? capability}) {
  GetIt.instance.registerSingleton<TrainerSdkCapability>(
    capability ?? LudavaSdkTrainerCapability(LudavaSdk.create()),
  );
  final operationGate = SdkOperationGate();
  GetIt.instance.registerSingleton<SdkOperationGate>(operationGate);
  GetIt.instance.registerSingleton<TrainerWriteBridge>(
    TrainerWriteBridge(GetIt.instance<TrainerSdkCapability>(), operationGate),
  );
}
