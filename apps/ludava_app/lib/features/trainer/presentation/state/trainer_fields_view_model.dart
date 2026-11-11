import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:get_it/get_it.dart';
import 'package:redux/redux.dart';

/// Presentation state and callbacks for the connected trainer fields list.
class TrainerFieldsViewModel extends Equatable {
  /// Selected SDK data and edit state used to render each field row.
  final List<
    ({
      GameField field,
      GameReadResult? readResult,
      GameWriteResult? writeResult,
      bool isEditing,
    })
  >
  fields;

  /// Whether the current SDK snapshot contains a selected profile.
  final bool hasProfile;

  /// Requests an edit for the field identified by its stable ID.
  final ValueChanged<String> onEditField;

  /// Performs the synchronous SDK write callback for a requested value.
  final GameWriteResult Function(String fieldId, int value) onApplyField;

  /// Cancels the active trainer edit.
  final VoidCallback onCancelEditing;

  /// Creates a fields view model from selected [fields] and callbacks.
  const TrainerFieldsViewModel({
    required this.fields,
    required this.hasProfile,
    required this.onEditField,
    required this.onApplyField,
    required this.onCancelEditing,
  });

  /// Creates presentation state and dispatch callbacks from [store].
  factory TrainerFieldsViewModel.fromStore(Store<AppState> store) {
    final state = store.state;
    return TrainerFieldsViewModel(
      hasProfile: TrainerSelectors.hasProfile(state),
      fields: TrainerSelectors.fieldRows(state),
      onEditField: (fieldId) => store.dispatch(BeginEditingAction(fieldId)),
      onApplyField: (fieldId, value) {
        final originSession = state.trainer.session;
        final originField = originSession.profile?.findField(fieldId);
        final currentState = store.state.trainer;
        if (originField == null ||
            currentState.editingFieldId != fieldId ||
            !TrainerFieldsViewModel._sameTarget(
              originSession,
              currentState.session,
            ) ||
            !TrainerFieldsViewModel._sameFieldMapping(
              originField,
              currentState.session.profile?.findField(fieldId),
            )) {
          return GameWriteResult(
            status: GameWriteStatus.none,
            fieldId: fieldId,
            requestedValue: value,
          );
        }
        return GetIt.instance<TrainerWriteBridge>().writeField(
          fieldId,
          value,
          expectedSession: originSession,
          expectedField: originField,
        );
      },
      onCancelEditing: () => store.dispatch(const CancelEditingAction()),
    );
  }

  @override
  List<Object?> get props => [
    fields.map(
      (row) => (
        field: (
          row.field.id,
          row.field.name,
          row.field.guestOffset,
          row.field.valueType,
          row.field.byteOrder,
          row.field.minimumValue,
          row.field.maximumValue,
        ),
        readResult: (
          row.readResult?.status,
          row.readResult?.fieldId,
          row.readResult?.value,
          row.readResult?.errorCode,
        ),
        writeResult: (
          row.writeResult?.status,
          row.writeResult?.fieldId,
          row.writeResult?.requestedValue,
          row.writeResult?.readBackValue,
          row.writeResult?.errorCode,
        ),
        isEditing: row.isEditing,
      ),
    ),
    hasProfile,
  ];

  /// Compares the target-defining parts of two field mappings.
  static bool _sameFieldMapping(GameField first, GameField? second) =>
      second != null &&
      first.id == second.id &&
      first.guestOffset == second.guestOffset &&
      first.valueType == second.valueType &&
      first.byteOrder == second.byteOrder;

  /// Compares session facts that bind an edit to its original target.
  static bool _sameTarget(
    TrainerSessionState first,
    TrainerSessionState second,
  ) =>
      first.selectedProcessId == second.selectedProcessId &&
      first.processMetadata?.startedAtUtc ==
          second.processMetadata?.startedAtUtc &&
      first.profile?.id == second.profile?.id &&
      first.profile?.buildId == second.profile?.buildId &&
      first.profile?.executable == second.profile?.executable &&
      first.profile?.executableHash == second.profile?.executableHash &&
      first.detection?.executableHash == second.detection?.executableHash &&
      first.memoryBase == second.memoryBase;
}
