import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/app/presentation/screens/ludava_session_body.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_shutdown_overlay.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_title_bar.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header_connector.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:window_manager/window_manager.dart';

/// Composes the title bar, game header, and active connection or trainer body.
class LudavaShell extends StatelessWidget {
  /// Minimizes the native window.
  final VoidCallback onMinimize;

  /// Toggles the native window between maximized and restored states.
  final VoidCallback onToggleMaximize;

  /// Current maximized state reported by the native window manager.
  final ValueListenable<bool> isMaximized;

  /// Closes the native window.
  final VoidCallback onClose;

  /// Explains a rejected native close while keeping the app noninteractive.
  final String? closeFailure;

  /// Whether resource cleanup is still underway.
  final bool isClosing;

  /// Creates the app shell with native window actions supplied by its owner.
  const LudavaShell({
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.isMaximized,
    required this.onClose,
    this.isClosing = false,
    this.closeFailure,
    super.key,
  });

  /// Renders the integrated window chrome and compact utility content.
  @override
  Widget build(BuildContext context) {
    final isBlocked = isClosing || closeFailure != null;
    return DragToResizeArea(
      resizeEdgeSize: LudavaDimensions.windowResizeHandleSize,
      child: Scaffold(
        body: Stack(
          children: [
            ExcludeSemantics(
              excluding: isBlocked,
              child: ExcludeFocus(
                excluding: isBlocked,
                child: AbsorbPointer(
                  absorbing: isBlocked,
                  child: Column(
                    children: [
                      LudavaWindowTitleBar(
                        isMaximized: isMaximized,
                        onMinimize: onMinimize,
                        onToggleMaximize: onToggleMaximize,
                        onClose: onClose,
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: LudavaDimensions.maximumContentWidth,
                            ),
                            child: SizedBox.expand(
                              child: Column(
                                children: [
                                  const TrainerGameHeaderConnector(),
                                  Expanded(
                                    child: SafeArea(
                                      child: const LudavaSessionBody(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isBlocked)
              Positioned.fill(
                child: LudavaShutdownOverlay(
                  isClosing: isClosing,
                  closeFailure: closeFailure,
                  onRetryClose: onClose,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
