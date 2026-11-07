import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_identity.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_status.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Composes the game title, readiness, and single refresh action.
class TrainerGameHeader extends StatelessWidget {
  /// Accessible name and tooltip for the single refresh action.
  static const String _refreshLabel = 'Refresh values or rediscover RPCS3';

  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Refreshes field values or rediscovers RPCS3 when no process is selected.
  final VoidCallback onRefresh;

  /// Creates the compact trainer header from the current SDK snapshot.
  const TrainerGameHeader({
    required this.session,
    required this.onRefresh,
    super.key,
  });

  /// Displays identity, readiness, and a fixed-size icon-only refresh button.
  @override
  Widget build(BuildContext context) {
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
          Expanded(child: TrainerGameIdentity(session: session)),
          const SizedBox(width: LudavaSpacing.sm),
          TrainerGameStatus(session: session),
          const SizedBox(width: LudavaSpacing.sm),
          Semantics(
            button: true,
            label: _refreshLabel,
            child: IconButton(
              tooltip: _refreshLabel,
              onPressed: onRefresh,
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
