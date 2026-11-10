import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

/// Presentation state and process-selection callback for the session body.
class LudavaSessionBodyViewModel extends Equatable {
  /// Whether the selected SDK session can show its trainer fields.
  final bool isReady;

  /// Process IDs available for explicit selection.
  final List<int> processIds;

  /// Currently selected RPCS3 process ID.
  final int? selectedProcessId;

  /// Current detection outcome used by connection guidance.
  final GameDetectionResult? detection;

  /// Whether the current session has a usable guest memory base.
  final bool hasMemoryBase;

  /// Current session error shown by the trainer body.
  final String? errorMessage;

  /// Selects an RPCS3 process through trainer middleware.
  final ValueChanged<int> onSelectProcess;

  /// Creates selected session presentation data and its callback.
  const LudavaSessionBodyViewModel({
    required this.isReady,
    required this.processIds,
    required this.selectedProcessId,
    required this.detection,
    required this.hasMemoryBase,
    required this.errorMessage,
    required this.onSelectProcess,
  });

  /// Creates presentation state and process dispatch from [store].
  factory LudavaSessionBodyViewModel.fromStore(Store<AppState> store) =>
      LudavaSessionBodyViewModel(
        isReady: TrainerSelectors.isReady(store.state),
        processIds: TrainerSelectors.processIds(store.state),
        selectedProcessId: TrainerSelectors.selectedProcessId(store.state),
        detection: TrainerSelectors.detection(store.state),
        hasMemoryBase: TrainerSelectors.hasMemoryBase(store.state),
        errorMessage: TrainerSelectors.errorMessage(store.state),
        onSelectProcess: (processId) =>
            store.dispatch(SelectRpcs3ProcessAction(processId)),
      );

  @override
  List<Object?> get props => [
    isReady,
    processIds,
    selectedProcessId,
    detection == null
        ? null
        : (
            detection!.status,
            detection!.gameTitle,
            detection!.evidenceDescription,
          ),
    hasMemoryBase,
    errorMessage,
  ];
}
