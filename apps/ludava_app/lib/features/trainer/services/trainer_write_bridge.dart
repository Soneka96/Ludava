import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Performs the approved synchronous SDK write callback for Flutter editors.
class TrainerWriteBridge {
  /// Uses the same SDK capability and terminal gate as trainer middleware.
  TrainerWriteBridge(this._capability, this._operationGate);

  final TrainerSdkCapability _capability;
  final SdkOperationGate _operationGate;

  /// Writes [value] only while the SDK still matches the editor's origin.
  GameWriteResult writeField(
    String fieldId,
    int value, {
    required TrainerSessionState expectedSession,
    required GameField expectedField,
  }) {
    if (!_operationGate.isOpen) {
      return _notAttempted(fieldId, value);
    }
    final currentSession = _capability.state;
    if (!_sameTarget(expectedSession, currentSession) ||
        !_sameFieldMapping(
          expectedField,
          currentSession.profile?.findField(fieldId),
        )) {
      return _notAttempted(fieldId, value);
    }
    return _capability.writeField(fieldId, value);
  }

  /// Creates the SDK's existing result for a write that was not attempted.
  GameWriteResult _notAttempted(String fieldId, int value) => GameWriteResult(
    status: GameWriteStatus.none,
    fieldId: fieldId,
    requestedValue: value,
  );

  /// Compares process, profile/build, executable, and memory-base identity.
  bool _sameTarget(TrainerSessionState first, TrainerSessionState second) =>
      first.selectedProcessId == second.selectedProcessId &&
      first.processMetadata?.startedAtUtc ==
          second.processMetadata?.startedAtUtc &&
      first.profile?.id == second.profile?.id &&
      first.profile?.buildId == second.profile?.buildId &&
      first.profile?.executable == second.profile?.executable &&
      first.profile?.executableHash == second.profile?.executableHash &&
      first.detection?.executableHash == second.detection?.executableHash &&
      first.memoryBase == second.memoryBase;

  /// Compares the field address and numeric representation.
  bool _sameFieldMapping(GameField first, GameField? second) =>
      second != null &&
      first.id == second.id &&
      first.guestOffset == second.guestOffset &&
      first.valueType == second.valueType &&
      first.byteOrder == second.byteOrder;
}
