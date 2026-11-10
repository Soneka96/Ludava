import 'package:flutter/material.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Displays the game title and hides build or process details in a tooltip.
class TrainerGameIdentity extends StatelessWidget {
  /// Active profile title, when a supported game is selected.
  final GameProfile? profile;

  /// Detected title shown before profile selection.
  final String? detectedTitle;

  /// Available RPCS3 process IDs.
  final List<int> processIds;

  /// Currently selected RPCS3 process ID.
  final int? selectedProcessId;

  /// Creates a one-line game identity from selected presentation values.
  const TrainerGameIdentity({
    required this.profile,
    required this.detectedTitle,
    required this.processIds,
    required this.selectedProcessId,
    super.key,
  });

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
    final profile = this.profile;
    if (profile != null) return profile.gameName;
    final detectedTitle = this.detectedTitle;
    if (detectedTitle != null && detectedTitle.isNotEmpty) return detectedTitle;
    if (_hasSelectedProcess) return 'No active game';
    if (processIds.length > 1) return 'Select an RPCS3 process';
    if (processIds.isNotEmpty) return 'RPCS3 detected';
    return 'Connect to RPCS3';
  }

  /// Reports whether the selected process is still in the discovery snapshot.
  bool get _hasSelectedProcess =>
      selectedProcessId != null && processIds.contains(selectedProcessId);

  /// Combines hidden build and process details for the title tooltip.
  String get _tooltipDetails {
    final details = <String>[_gameTitle];
    final buildId = profile?.buildId;
    if (buildId != null) details.add('Build ID: $buildId');
    if (_hasSelectedProcess) {
      details.add('RPCS3 process ID: $selectedProcessId');
    } else if (processIds.isNotEmpty) {
      details.add('Available process IDs: ${processIds.join(', ')}');
    } else {
      details.add('RPCS3 not detected');
    }
    return details.join('\n');
  }
}
