import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Presents multiple RPCS3 processes for explicit selection.
class Rpcs3ProcessPicker extends StatelessWidget {
  /// Process identifiers returned by the SDK's latest discovery operation.
  final List<int> processIds;

  /// Selects a process through the SDK session capability.
  final ValueChanged<int> onSelectProcess;

  /// Creates a scrollable list of currently discovered processes.
  const Rpcs3ProcessPicker({
    required this.processIds,
    required this.onSelectProcess,
    super.key,
  });

  /// Renders a scrollable heading and touch-friendly process choices.
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ConnectionDimensions.contentMaxWidth,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: LudavaSpacing.lg,
          vertical: LudavaSpacing.md,
        ),
        itemCount: processIds.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: LudavaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Available RPCS3 processes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: LudavaSpacing.xs),
                  Text(
                    'Select the process running your game.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final processId = processIds[index - 1];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 1)
                Divider(
                  height: ConnectionDimensions.processSeparatorExtent,
                  color: Theme.of(context)
                      .extension<LudavaThemeTokens>()!
                      .borderSubtle,
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
        },
      ),
    ),
  );
}
