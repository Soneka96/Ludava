import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:redux/redux.dart';

/// Presentation state and process-selection callback for the session body.
class LudavaSessionBodyViewModel extends Equatable {
  /// Current Redux state used to choose connection or trainer content.
  final AppState state;

  /// Selects an RPCS3 process through trainer middleware.
  final ValueChanged<int> onSelectProcess;

  /// Creates a session-body view model from [state] and its callback.
  const LudavaSessionBodyViewModel({
    required this.state,
    required this.onSelectProcess,
  });

  /// Creates presentation state and process dispatch from [store].
  factory LudavaSessionBodyViewModel.fromStore(Store<AppState> store) =>
      LudavaSessionBodyViewModel(
        state: store.state,
        onSelectProcess: (processId) =>
            store.dispatch(SelectRpcs3ProcessAction(processId)),
      );

  @override
  List<Object?> get props => [state];
}
