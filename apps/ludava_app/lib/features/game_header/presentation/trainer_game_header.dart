import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/layout_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Shows current game identity, RPCS3 process, readiness, and session actions.
class TrainerGameHeader extends StatelessWidget {
  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Refreshes the selected session or retries process discovery.
  final VoidCallback onRefresh;

  /// Re-detects the selected game or retries process discovery.
  final VoidCallback onRedetect;

  /// Creates a compact header from the current SDK snapshot.
  const TrainerGameHeader({
    required this.session,
    required this.onRefresh,
    required this.onRedetect,
    super.key,
  });

  /// Renders the active identity and controls without owning session state.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final statusColor = _statusColor(theme, tokens);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayoutConstants.contentInset,
        vertical: AppLayoutConstants.headerVerticalInset,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.outlineSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _gameTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppLayoutConstants.headerTitleGap),
                Text(
                  _processDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppLayoutConstants.headerItemGap),
          _buildStatus(context, statusColor),
          const SizedBox(width: AppLayoutConstants.headerItemGap),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppLayoutConstants.headerActionHeight),
            ),
          ),
          const SizedBox(width: AppLayoutConstants.headerItemGap),
          OutlinedButton.icon(
            onPressed: onRedetect,
            icon: const Icon(Icons.manage_search_rounded),
            label: const Text('Re-detect'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppLayoutConstants.headerActionHeight),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the current game title or a useful connection prompt.
  String get _gameTitle {
    final profile = session.profile;
    if (profile != null) return profile.gameName;
    final detectedTitle = session.detection?.gameTitle;
    if (detectedTitle != null && detectedTitle.isNotEmpty) return detectedTitle;
    if (session.selectedProcessId != null) return 'No active game';
    if (session.processIds.length > 1) return 'Select an RPCS3 process';
    return 'Connect to RPCS3';
  }

  /// Describes the selected process or the discovery result.
  String get _processDescription {
    final processId = session.selectedProcessId;
    if (processId != null) return 'RPCS3 process · PID $processId';
    final count = session.processIds.length;
    if (count == 0) return 'RPCS3 is not running';
    return '$count RPCS3 processes found';
  }

  /// Creates the semantic status badge using theme-owned colors.
  Widget _buildStatus(BuildContext context, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayoutConstants.statusBadgeHorizontalInset,
        vertical: AppLayoutConstants.statusBadgeVerticalInset,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: LudavaTheme.statusBadgeFillOpacity),
        borderRadius: BorderRadius.circular(
          AppLayoutConstants.statusBadgeRadius,
        ),
        border: Border.all(
          color: color.withValues(alpha: LudavaTheme.statusBadgeOutlineOpacity),
        ),
      ),
      child: Text(
        _statusLabel,
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  /// Returns the concise readiness label for the current session.
  String get _statusLabel {
    if (session.errorMessage != null) return 'Attention';
    if (session.selectedProcessId == null) {
      return session.processIds.isEmpty ? 'Disconnected' : 'Choose process';
    }
    return switch (session.detection?.status) {
      GameDetectionStatus.supportedGame =>
        session.memoryBase == null ? 'Base unavailable' : 'Ready',
      GameDetectionStatus.noActiveGame => 'No game',
      GameDetectionStatus.unsupportedGame => 'Unsupported',
      GameDetectionStatus.ambiguous => 'Unverified',
      GameDetectionStatus.failed => 'Detection failed',
      GameDetectionStatus.rpcs3NotRunning => 'Disconnected',
      GameDetectionStatus.none || null => 'Not detected',
    };
  }

  /// Chooses a semantic color from the session result and theme tokens.
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
