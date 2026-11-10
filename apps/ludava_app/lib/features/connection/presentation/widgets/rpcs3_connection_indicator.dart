import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ludava_app/features/connection/presentation/state/rpcs3_connection_indicator_view_model.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/state/app_state.dart';

/// Displays basic RPCS3 process availability separately from game readiness.
class Rpcs3ConnectionIndicator extends StatelessWidget {
  /// Small diameter keeps the connection mark secondary to its label.
  static const double _dotSize = 8;

  /// Creates the connected title-bar connection indicator.
  const Rpcs3ConnectionIndicator({super.key});

  /// Renders connection text and its semantic status color.
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, Rpcs3ConnectionIndicatorViewModel>(
        distinct: true,
        converter: (store) =>
            sl<Rpcs3ConnectionIndicatorViewModel>(param1: store),
        builder: (context, viewModel) {
          final theme = Theme.of(context);
          final tokens = theme.extension<LudavaThemeTokens>()!;
          final message = _tooltipMessage(viewModel);
          final color = _statusColor(tokens, viewModel);

          return Tooltip(
            message: message,
            child: Semantics(
              label: message,
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle_rounded, size: _dotSize, color: color),
                  const SizedBox(width: LudavaSpacing.sm),
                  Text(
                    'RPCS3',
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          );
        },
      );

  /// Reports whether the selected process remains in the discovery result.
  bool _hasSelectedProcess(Rpcs3ConnectionIndicatorViewModel viewModel) =>
      viewModel.selectedProcessId != null &&
      viewModel.processIds.contains(viewModel.selectedProcessId);

  /// Describes absence, pending selection, or the selected process accurately.
  String _tooltipMessage(Rpcs3ConnectionIndicatorViewModel viewModel) {
    if (viewModel.processIds.isEmpty) return 'RPCS3 not detected';
    if (_hasSelectedProcess(viewModel)) {
      return 'RPCS3 connected · process ${viewModel.selectedProcessId}';
    }
    return viewModel.processIds.length == 1
        ? 'RPCS3 detected · awaiting process selection'
        : 'RPCS3 detected · select one of ${viewModel.processIds.length} processes';
  }

  /// Maps discovery state to its semantic status color.
  Color _statusColor(
    LudavaThemeTokens tokens,
    Rpcs3ConnectionIndicatorViewModel viewModel,
  ) {
    if (_hasSelectedProcess(viewModel)) return tokens.success;
    if (viewModel.processIds.isNotEmpty) return tokens.warning;
    return tokens.textMuted;
  }
}
