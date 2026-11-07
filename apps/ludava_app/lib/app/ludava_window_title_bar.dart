import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/layout_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:window_manager/window_manager.dart';

/// Renders the integrated Ludava title bar and accessible window controls.
class LudavaWindowTitleBar extends StatelessWidget {
  /// Minimizes the application window.
  final VoidCallback onMinimize;

  /// Maximizes or restores the application window.
  final VoidCallback onToggleMaximize;

  /// Closes the application window.
  final VoidCallback onClose;

  /// Creates the title bar with the native window actions supplied by its owner.
  const LudavaWindowTitleBar({
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
    final maximizeButton = SizedBox(
      width: AppLayoutConstants.windowControlWidth,
      height: AppLayoutConstants.titleBarHeight,
      child: IconButton(
        tooltip: 'Maximize or restore window',
        onPressed: onToggleMaximize,
        icon: const Icon(Icons.crop_square_rounded),
      ),
    );
    return DecoratedBox(
      key: const ValueKey('ludava-titlebar-surface'),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
      ),
      child: SizedBox(
        height: AppLayoutConstants.titleBarHeight,
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppLayoutConstants.titleBarInset,
                  ),
                  child: Row(
                    children: [
                      DecoratedBox(
                        key: const ValueKey('ludava-titlebar-mark'),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(
                            AppLayoutConstants.smallCornerRadius,
                          ),
                        ),
                        child: const SizedBox(width: 3, height: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ludava',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildControl(
              tooltip: 'Minimize window',
              icon: Icons.remove_rounded,
              onPressed: onMinimize,
            ),
            maximizeButton,
            _buildControl(
              tooltip: 'Close window',
              icon: Icons.close_rounded,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a caption button with the theme's shared hit target and style.
  Widget _buildControl({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) => SizedBox(
    width: AppLayoutConstants.windowControlWidth,
    height: AppLayoutConstants.titleBarHeight,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: AppLayoutConstants.windowIconSize),
    ),
  );
}
