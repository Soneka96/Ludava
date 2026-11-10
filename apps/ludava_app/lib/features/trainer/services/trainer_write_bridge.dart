import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Performs the approved synchronous SDK write callback for Flutter editors.
class TrainerWriteBridge {
  /// Uses the same SDK capability and terminal gate as trainer middleware.
  TrainerWriteBridge(this._capability, this._operationGate);

  final TrainerSdkCapability _capability;
  final SdkOperationGate _operationGate;

  /// Returns the SDK result for [fieldId] and [value], or the closed-gate sentinel.
  GameWriteResult writeField(String fieldId, int value) {
    if (!_operationGate.isOpen) {
      return GameWriteResult(
        status: GameWriteStatus.none,
        fieldId: fieldId,
        requestedValue: value,
      );
    }
    return _capability.writeField(fieldId, value);
  }
}
