import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:get_it/get_it.dart';
import 'package:redux/redux.dart';

/// Presentation state and callbacks for the connected trainer fields list.
class TrainerFieldsViewModel extends Equatable {
  /// Current Redux snapshot used to derive the field rows.
  final AppState state;

  /// Requests an edit for the field identified by its stable ID.
  final ValueChanged<String> onEditField;

  /// Performs the synchronous SDK write callback for a requested value.
  final GameWriteResult Function(String fieldId, int value) onApplyField;

  /// Cancels the active trainer edit.
  final VoidCallback onCancelEditing;

  /// Creates a fields view model from [state] and its presentation callbacks.
  const TrainerFieldsViewModel({
    required this.state,
    required this.onEditField,
    required this.onApplyField,
    required this.onCancelEditing,
  });

  /// Creates presentation state and dispatch callbacks from [store].
  factory TrainerFieldsViewModel.fromStore(Store<AppState> store) =>
      TrainerFieldsViewModel(
        state: store.state,
        onEditField: (fieldId) => store.dispatch(BeginEditingAction(fieldId)),
        onApplyField: (fieldId, value) =>
            GetIt.instance<TrainerWriteBridge>().writeField(fieldId, value),
        onCancelEditing: () => store.dispatch(const CancelEditingAction()),
      );

  @override
  List<Object?> get props => [state];
}
