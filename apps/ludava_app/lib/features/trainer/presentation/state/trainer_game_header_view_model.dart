import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:redux/redux.dart';

/// Presentation state and refresh callback for the connected game header.
class TrainerGameHeaderViewModel extends Equatable {
  /// Current Redux snapshot used to render game identity and readiness.
  final AppState state;

  /// Refreshes field values or rediscovers RPCS3 through middleware.
  final VoidCallback onRefresh;

  /// Creates a header view model from [state] and its [onRefresh] callback.
  const TrainerGameHeaderViewModel({
    required this.state,
    required this.onRefresh,
  });

  /// Creates presentation state and refresh dispatch from [store].
  factory TrainerGameHeaderViewModel.fromStore(Store<AppState> store) =>
      TrainerGameHeaderViewModel(
        state: store.state,
        onRefresh: () => store.dispatch(const RefreshTrainerAction()),
      );

  @override
  List<Object?> get props => [state];
}
