import 'package:equatable/equatable.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:redux/redux.dart';

/// Presentation data for the title-bar process connection indicator.
class Rpcs3ConnectionIndicatorViewModel extends Equatable {
  /// Currently discovered RPCS3 process IDs.
  final List<int> processIds;

  /// Currently selected RPCS3 process ID.
  final int? selectedProcessId;

  /// Creates indicator presentation data from selected process values.
  const Rpcs3ConnectionIndicatorViewModel({
    required this.processIds,
    required this.selectedProcessId,
  });

  /// Selects the latest session from [store].
  factory Rpcs3ConnectionIndicatorViewModel.fromStore(Store<AppState> store) =>
      Rpcs3ConnectionIndicatorViewModel(
        processIds: TrainerSelectors.processIds(store.state),
        selectedProcessId: TrainerSelectors.selectedProcessId(store.state),
      );

  @override
  List<Object?> get props => [processIds, selectedProcessId];
}
