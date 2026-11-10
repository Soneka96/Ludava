import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_game_header_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_identity.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_status.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/state/app_state.dart';

/// Composes the game title, readiness, and single refresh action.
class TrainerGameHeader extends StatelessWidget {
  /// Accessible name and tooltip for the single refresh action.
  static const String _refreshLabel = 'Refresh values or rediscover RPCS3';

  /// Creates the connected compact trainer header.
  const TrainerGameHeader({super.key});

  /// Displays identity, readiness, and a fixed-size icon-only refresh button.
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, TrainerGameHeaderViewModel>(
        distinct: true,
        converter: (store) => sl<TrainerGameHeaderViewModel>(param1: store),
        builder: (context, viewModel) => _buildHeader(context, viewModel),
      );

  /// Renders the header from selected values in [viewModel].
  Widget _buildHeader(
    BuildContext context,
    TrainerGameHeaderViewModel viewModel,
  ) {
    final tokens = Theme.of(context).extension<LudavaThemeTokens>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LudavaSpacing.xl,
        vertical: LudavaSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TrainerGameIdentity(
              profile: viewModel.profile,
              detectedTitle: viewModel.detectedTitle,
              processIds: viewModel.processIds,
              selectedProcessId: viewModel.selectedProcessId,
            ),
          ),
          const SizedBox(width: LudavaSpacing.sm),
          TrainerGameStatus(
            hasSelectedProcess:
                viewModel.selectedProcessId != null &&
                viewModel.processIds.contains(viewModel.selectedProcessId),
            hasProcesses: viewModel.processIds.isNotEmpty,
            detectionStatus: viewModel.detectionStatus,
            hasMemoryBase: viewModel.hasMemoryBase,
            hasError: viewModel.errorMessage != null,
          ),
          const SizedBox(width: LudavaSpacing.sm),
          Semantics(
            button: true,
            label: _refreshLabel,
            child: IconButton(
              tooltip: _refreshLabel,
              onPressed: viewModel.onRefresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: LudavaDimensions.minimumInteractiveTarget,
                height: LudavaDimensions.minimumInteractiveTarget,
              ),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
