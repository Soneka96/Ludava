import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

/// Presentation state and refresh callback for the connected game header.
class TrainerGameHeaderViewModel extends Equatable {
  /// Active profile shown by the header.
  final GameProfile? profile;

  /// Detected game title shown before a profile is selected.
  final String? detectedTitle;

  /// Current discovered RPCS3 process IDs.
  final List<int> processIds;

  /// Currently selected RPCS3 process ID.
  final int? selectedProcessId;

  /// Current detection status shown in the readiness badge.
  final GameDetectionStatus? detectionStatus;

  /// Whether the detected session has a usable memory base.
  final bool hasMemoryBase;

  /// Current session error, when one is available.
  final String? errorMessage;

  /// Refreshes field values or rediscovers RPCS3 through middleware.
  final VoidCallback onRefresh;

  /// Creates header presentation values and its [onRefresh] callback.
  const TrainerGameHeaderViewModel({
    required this.profile,
    required this.detectedTitle,
    required this.processIds,
    required this.selectedProcessId,
    required this.detectionStatus,
    required this.hasMemoryBase,
    required this.errorMessage,
    required this.onRefresh,
  });

  /// Creates presentation state and refresh dispatch from [store].
  factory TrainerGameHeaderViewModel.fromStore(Store<AppState> store) {
    final state = store.state;
    final session = TrainerSelectors.session(state);
    return TrainerGameHeaderViewModel(
      profile: session.profile,
      detectedTitle: session.detection?.gameTitle,
      processIds: TrainerSelectors.processIds(state),
      selectedProcessId: TrainerSelectors.selectedProcessId(state),
      detectionStatus: session.detection?.status,
      hasMemoryBase: TrainerSelectors.hasMemoryBase(state),
      errorMessage: TrainerSelectors.errorMessage(state),
      onRefresh: () => store.dispatch(const RefreshTrainerAction()),
    );
  }

  @override
  List<Object?> get props => [
    profile,
    detectedTitle,
    processIds,
    selectedProcessId,
    detectionStatus,
    hasMemoryBase,
    errorMessage,
  ];
}
