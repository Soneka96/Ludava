import 'package:flutter/material.dart';
import 'package:ludava_app/shared/layout/ludava_dimensions.dart';

/// Provides a consistently sized, accessible native-window caption action.
class LudavaWindowControlButton extends StatelessWidget {
  /// Tooltip and accessible label for the action.
  final String tooltip;

  /// Icon that identifies the action.
  final IconData icon;

  /// Invokes the native window action.
  final VoidCallback onPressed;

  /// Creates a native-window caption button.
  const LudavaWindowControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  /// Renders the action at the shared window-control hit-target dimensions.
  @override
  Widget build(BuildContext context) => SizedBox(
    width: LudavaDimensions.windowControlWidth,
    height: LudavaDimensions.titleBarHeight,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: LudavaDimensions.iconSmall),
    ),
  );
}
