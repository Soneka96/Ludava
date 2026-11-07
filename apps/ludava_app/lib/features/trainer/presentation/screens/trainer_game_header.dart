import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_identity.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_status.dart';
import 'package:ludava_app/shared/layout/ludava_breakpoints.dart';
import 'package:ludava_app/shared/layout/ludava_spacing.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Composes game identity, readiness, and session actions for the trainer.
class TrainerGameHeader extends StatelessWidget {
  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Refreshes the selected session or retries process discovery.
  final VoidCallback onRefresh;

  /// Re-detects the selected game or retries process discovery.
  final VoidCallback onRedetect;

  /// Creates the responsive trainer header from the current SDK snapshot.
  const TrainerGameHeader({
    required this.session,
    required this.onRefresh,
    required this.onRedetect,
    super.key,
  });

  /// Rearranges identity, readiness, and actions at the shared width breakpoint.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < LudavaBreakpoints.trainerHeaderWide;
      final theme = Theme.of(context);
      final tokens = theme.extension<LudavaThemeTokens>()!;
      final actions = Wrap(
        spacing: LudavaSpacing.sm,
        runSpacing: LudavaSpacing.xs,
        children: [
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
          OutlinedButton.icon(
            onPressed: onRedetect,
            icon: const Icon(Icons.manage_search_rounded),
            label: const Text('Re-detect'),
          ),
        ],
      );

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LudavaSpacing.xl,
          vertical: LudavaSpacing.lg,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: TrainerGameIdentity(session: session)),
                      const SizedBox(width: LudavaSpacing.sm),
                      TrainerGameStatus(session: session),
                    ],
                  ),
                  const SizedBox(height: LudavaSpacing.sm),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: TrainerGameIdentity(session: session)),
                  const SizedBox(width: LudavaSpacing.md),
                  TrainerGameStatus(session: session),
                  const SizedBox(width: LudavaSpacing.md),
                  actions,
                ],
              ),
      );
    },
  );
}
