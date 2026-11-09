import 'package:equatable/equatable.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

/// Presentation data for the title-bar process connection indicator.
class Rpcs3ConnectionIndicatorViewModel extends Equatable {
  /// Current immutable SDK session snapshot.
  final TrainerSessionState session;

  /// Creates an indicator view model from [session].
  const Rpcs3ConnectionIndicatorViewModel({required this.session});

  /// Selects the latest session from [store].
  factory Rpcs3ConnectionIndicatorViewModel.fromStore(Store<AppState> store) =>
      Rpcs3ConnectionIndicatorViewModel(session: store.state.trainer.session);

  @override
  List<Object?> get props => [session];
}
