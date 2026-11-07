import 'package:flutter/material.dart';
import 'package:ludava_app/shared/layout/ludava_spacing.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Shows game detection and memory-base readiness without RPCS3 process state.
class TrainerGameStatus extends StatelessWidget {
  /// Fill opacity keeps the badge visible without dominating the header.
  static const double _fillOpacity = 0.12;

  /// Outline opacity separates the badge from its surrounding surface.
  static const double _outlineOpacity = 0.35;

  /// Corner radius keeps the compact readiness badge pill-shaped.
  static const double _cornerRadius = 20;

  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Creates a badge from the current SDK readiness state.
  const TrainerGameStatus({required this.session, super.key});

  /// Renders a concise status label using semantic theme roles.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final color = _statusColor(theme, tokens);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LudavaSpacing.sm,
        vertical: LudavaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _fillOpacity),
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: color.withValues(alpha: _outlineOpacity)),
      ),
      child: Text(
        _statusLabel,
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  /// Returns the current game readiness label.
  String get _statusLabel {
    if (session.errorMessage != null) return 'Attention';
    if (session.selectedProcessId == null) {
      return session.processIds.isEmpty ? 'Not detected' : 'Choose process';
    }
    return switch (session.detection?.status) {
      GameDetectionStatus.supportedGame =>
        session.memoryBase == null ? 'Base unavailable' : 'Ready',
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
    if (session.errorMessage != null ||
        session.detection?.status == GameDetectionStatus.failed) {
      return theme.colorScheme.error;
    }
    return switch (session.detection?.status) {
      GameDetectionStatus.supportedGame when session.memoryBase != null =>
        tokens.success,
      GameDetectionStatus.ambiguous ||
      GameDetectionStatus.unsupportedGame => tokens.warning,
      _ => tokens.textMuted,
    };
  }
}
