import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_control_button.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_indicator_connector.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:window_manager/window_manager.dart';

/// Renders the integrated Ludava title bar and accessible window controls.
class LudavaWindowTitleBar extends StatelessWidget {
  /// Keeps the small brand mark's radius local to this title bar.
  static const double _controlHoverRadius = 4;

  /// Current native maximize state.
  final ValueListenable<bool> isMaximized;

  /// Minimizes the application window.
  final VoidCallback onMinimize;

  /// Maximizes or restores the application window.
  final VoidCallback onToggleMaximize;

  /// Closes the application window.
  final VoidCallback onClose;

  /// Creates the title bar with native window actions supplied by its owner.
  const LudavaWindowTitleBar({
    required this.isMaximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
    super.key,
  });

  /// Builds the drag region, wordmark, and standard caption controls.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    return DecoratedBox(
      key: const ValueKey('ludava-titlebar-surface'),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
      ),
      child: SizedBox(
        height: LudavaDimensions.titleBarHeight,
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: LudavaSpacing.xl),
                  child: Row(
                    children: [
                      DecoratedBox(
                        key: const ValueKey('ludava-titlebar-mark'),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(
                            _controlHoverRadius,
                          ),
                        ),
                        child: const SizedBox(width: 3, height: 16),
                      ),
                      const SizedBox(width: LudavaSpacing.sm),
                      Text(
                        'Ludava',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      const Rpcs3ConnectionIndicatorConnector(),
                      const SizedBox(width: LudavaSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
            LudavaWindowControlButton(
              tooltip: 'Minimize window',
              icon: Icons.remove_rounded,
              onPressed: onMinimize,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isMaximized,
              builder: (context, maximized, child) => LudavaWindowControlButton(
                tooltip: maximized ? 'Restore window' : 'Maximize window',
                icon: maximized
                    ? Icons.filter_none_rounded
                    : Icons.crop_square_rounded,
                onPressed: onToggleMaximize,
              ),
            ),
            LudavaWindowControlButton(
              tooltip: 'Close window',
              icon: Icons.close_rounded,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
