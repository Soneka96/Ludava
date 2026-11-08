import 'package:flutter/material.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Displays the game title and hides build or process details in a tooltip.
class TrainerGameIdentity extends StatelessWidget {
  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Creates the one-line game identity for the current SDK snapshot.
  const TrainerGameIdentity({required this.session, super.key});

  /// Truncates long titles while keeping their full details discoverable.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: _tooltipDetails,
      child: Text(
        _gameTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
    );
  }

  /// Returns the active profile title or a useful connection prompt.
  String get _gameTitle {
    final profile = session.profile;
    if (profile != null) return profile.gameName;
    final detectedTitle = session.detection?.gameTitle;
    if (detectedTitle != null && detectedTitle.isNotEmpty) return detectedTitle;
    if (_hasSelectedProcess) return 'No active game';
    if (session.processIds.length > 1) return 'Select an RPCS3 process';
    if (session.processIds.isNotEmpty) return 'RPCS3 detected';
    return 'Connect to RPCS3';
  }

  /// Reports whether the selected process is still in the discovery snapshot.
  bool get _hasSelectedProcess =>
      session.selectedProcessId != null &&
      session.processIds.contains(session.selectedProcessId);

  /// Combines hidden build and process details for the title tooltip.
  String get _tooltipDetails {
    final details = <String>[_gameTitle];
    final buildId = session.profile?.buildId;
    if (buildId != null) details.add('Build ID: $buildId');
    if (_hasSelectedProcess) {
      details.add('RPCS3 process ID: ${session.selectedProcessId}');
    } else if (session.processIds.isNotEmpty) {
      details.add('Available process IDs: ${session.processIds.join(', ')}');
    } else {
      details.add('RPCS3 not detected');
    }
    return details.join('\n');
  }
}
