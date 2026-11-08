import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';

/// Presents shutdown progress or a recoverable native close failure.
class LudavaShutdownOverlay extends StatelessWidget {
  /// Whether SDK cleanup is still in progress.
  final bool isClosing;

  /// Native close failure details, when a retry is available.
  final String? closeFailure;

  /// Retries the app-owned native close sequence.
  final VoidCallback onRetryClose;

  /// Creates the overlay from the shell's current shutdown state.
  const LudavaShutdownOverlay({
    required this.isClosing,
    required this.closeFailure,
    required this.onRetryClose,
    super.key,
  });

  /// Opacity shared by the closing and close-failure scrims.
  static const double _scrimOpacity = 0.72;

  /// Renders the active shutdown presentation using the supplied theme.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = closeFailure;
    if (isClosing) {
      return ColoredBox(
        color: theme.colorScheme.scrim.withValues(alpha: _scrimOpacity),
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Closing Ludava… Finishing cleanup',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: theme.colorScheme.secondary),
                const SizedBox(height: LudavaSpacing.md),
                Text('Closing Ludava…', style: theme.textTheme.titleSmall),
                const SizedBox(height: LudavaSpacing.xs),
                Text('Finishing cleanup', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    if (failure == null) return const SizedBox.shrink();

    return ColoredBox(
      color: theme.colorScheme.scrim.withValues(alpha: _scrimOpacity),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(LudavaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ludava could not close. App actions are disabled.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: LudavaSpacing.sm),
              Tooltip(
                message: failure,
                child: Text(
                  failure,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: LudavaSpacing.md),
              FilledButton(
                autofocus: true,
                onPressed: onRetryClose,
                child: const Text('Retry close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
