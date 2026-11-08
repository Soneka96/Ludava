import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Renders and selects one RPCS3 process in the discovered-process list.
class Rpcs3ProcessChoice extends StatelessWidget {
  /// Process identifier returned by the SDK's discovery operation.
  final int processId;

  /// Selects this process through the SDK session capability.
  final ValueChanged<int> onSelectProcess;

  /// Whether a separator precedes this choice in the list.
  final bool showDividerBefore;

  /// Creates one process row with its original stable key identity.
  const Rpcs3ProcessChoice({
    required this.processId,
    required this.onSelectProcess,
    this.showDividerBefore = false,
    super.key,
  });

  /// Renders the process identity, divider, and touch-friendly selection row.
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (showDividerBefore)
        Divider(
          height: ConnectionDimensions.processSeparatorExtent,
          color: Theme.of(context).extension<LudavaThemeTokens>()!.borderSubtle,
        ),
      ListTile(
        key: ValueKey(processId),
        leading: const Icon(Icons.desktop_windows_outlined),
        title: const Text('RPCS3 process'),
        subtitle: Text('Process ID $processId'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => onSelectProcess(processId),
      ),
    ],
  );
}
