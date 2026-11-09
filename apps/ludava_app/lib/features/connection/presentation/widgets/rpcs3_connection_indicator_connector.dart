import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ludava_app/features/connection/presentation/state/rpcs3_connection_indicator_view_model.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_indicator.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/state/app_state.dart';

/// Connects the current trainer session to the title-bar connection indicator.
class Rpcs3ConnectionIndicatorConnector extends StatelessWidget {
  /// Creates the connected RPCS3 indicator.
  const Rpcs3ConnectionIndicatorConnector({super.key});

  /// Rebuilds only when the SDK session snapshot changes.
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, Rpcs3ConnectionIndicatorViewModel>(
        distinct: true,
        converter: (store) =>
            sl<Rpcs3ConnectionIndicatorViewModel>(param1: store),
        builder: (context, viewModel) =>
            Rpcs3ConnectionIndicator(session: viewModel.session),
      );
}
