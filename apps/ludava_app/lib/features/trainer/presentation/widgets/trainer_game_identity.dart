import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Displays the active game title and useful build or process context.
class TrainerGameIdentity extends StatelessWidget {
  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Creates the game identity and process context presentation.
  const TrainerGameIdentity({required this.session, super.key});

  /// Wraps long names and context so they remain discoverable.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_gameTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: LudavaSpacing.xs),
        Text(
          _contextDescription,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
        ),
      ],
    );
  }

  /// Returns the active profile title or a useful connection prompt.
  String get _gameTitle {
    final profile = session.profile;
    if (profile != null) return profile.gameName;
    final detectedTitle = session.detection?.gameTitle;
    if (detectedTitle != null && detectedTitle.isNotEmpty) return detectedTitle;
    if (session.selectedProcessId != null) return 'No active game';
    if (session.processIds.length > 1) return 'Select an RPCS3 process';
    return 'Connect to RPCS3';
  }

  /// Describes the matched build and selected process or discovery state.
  String get _contextDescription {
    final processId = session.selectedProcessId;
    final buildId = session.profile?.buildId;
    if (processId != null) {
      final process = 'RPCS3 process · PID $processId';
      return buildId == null ? process : '$buildId · $process';
    }
    final count = session.processIds.length;
    if (count == 0) return 'Start RPCS3 to detect a game';
    return '$count RPCS3 processes found';
  }
}
