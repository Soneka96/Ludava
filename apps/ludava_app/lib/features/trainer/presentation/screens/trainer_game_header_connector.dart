import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_game_header_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/shared/state/app_state.dart';

/// Connects the current SDK identity and refresh action to the game header.
class TrainerGameHeaderConnector extends StatelessWidget {
  /// Creates the connected game header.
  const TrainerGameHeaderConnector({super.key});

  /// Rebuilds the existing header only when its presentation state changes.
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, TrainerGameHeaderViewModel>(
        distinct: true,
        converter: (store) => sl<TrainerGameHeaderViewModel>(param1: store),
        builder: (context, viewModel) => TrainerGameHeader(
          session: TrainerSelectors.session(viewModel.state),
          onRefresh: viewModel.onRefresh,
        ),
      );
}
