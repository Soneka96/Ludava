import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Shows game detection and memory-base readiness without RPCS3 process state.
class TrainerGameStatus extends StatelessWidget {
  /// Fill opacity keeps the badge visible without dominating the header.
  static const double _fillOpacity = 0.12;

  /// Outline opacity separates the badge from its surrounding surface.
  static const double _outlineOpacity = 0.35;

  /// Whether RPCS3 has a selected process.
  final bool hasSelectedProcess;

  /// Whether any RPCS3 processes were discovered.
  final bool hasProcesses;

  /// Current game detection status.
  final GameDetectionStatus? detectionStatus;

  /// Whether the session has a usable guest memory base.
  final bool hasMemoryBase;

  /// Whether the SDK reported a session error.
  final bool hasError;

  /// Creates a badge from selected SDK readiness values.
  const TrainerGameStatus({
    required this.hasSelectedProcess,
    required this.hasProcesses,
    required this.detectionStatus,
    required this.hasMemoryBase,
    required this.hasError,
    super.key,
  });

  /// Renders a concise status label using semantic theme roles.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final color = _statusColor(theme, tokens);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color.withValues(alpha: _fillOpacity),
        shape: StadiumBorder(
          side: BorderSide(color: color.withValues(alpha: _outlineOpacity)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LudavaSpacing.sm,
          vertical: LudavaSpacing.xs,
        ),
        child: Text(
          _statusLabel,
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }

  /// Returns the current game readiness label.
  String get _statusLabel {
    if (hasError) return 'Attention';
    if (!hasSelectedProcess) {
      return hasProcesses ? 'Choose process' : 'Not detected';
    }
    return switch (detectionStatus) {
      GameDetectionStatus.supportedGame =>
        hasMemoryBase ? 'Ready' : 'Base unavailable',
      GameDetectionStatus.noActiveGame => 'No game',
      GameDetectionStatus.unsupportedGame => 'Unsupported',
      GameDetectionStatus.ambiguous => 'Unverified',
      GameDetectionStatus.failed => 'Detection failed',
      GameDetectionStatus.rpcs3NotRunning => 'Not detected',
      GameDetectionStatus.none || null => 'Not detected',
    };
  }

  /// Selects the semantic color for the SDK detection outcome.
  Color _statusColor(ThemeData theme, LudavaThemeTokens tokens) {
    if (hasError || detectionStatus == GameDetectionStatus.failed) {
      return theme.colorScheme.error;
    }
    return switch (detectionStatus) {
      GameDetectionStatus.supportedGame when hasMemoryBase => tokens.success,
      GameDetectionStatus.ambiguous ||
      GameDetectionStatus.unsupportedGame => tokens.warning,
      _ => tokens.textMuted,
    };
  }
}
