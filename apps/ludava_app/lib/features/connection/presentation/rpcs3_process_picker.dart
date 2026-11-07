import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/layout_constants.dart';
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

  /// Renders one keyboard- and touch-friendly choice for each process ID.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppLayoutConstants.contentInset),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayoutConstants.connectionMessageMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available RPCS3 processes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppLayoutConstants.connectionPickerCopyGap),
            Text(
              'Select the process running your game.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppLayoutConstants.connectionPickerGap),
            Expanded(
              child: ListView.separated(
                itemCount: processIds.length,
                separatorBuilder: (context, index) => Divider(
                  height: AppLayoutConstants.connectionPickerDividerHeight,
                  color: Theme.of(context)
                      .extension<LudavaThemeTokens>()!
                      .borderSubtle,
                ),
                itemBuilder: (context, index) {
                  final processId = processIds[index];
                  return ListTile(
                    key: ValueKey(processId),
                    leading: const Icon(Icons.desktop_windows_outlined),
                    title: const Text('RPCS3 process'),
                    subtitle: Text('Process ID $processId'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => onSelectProcess(processId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
