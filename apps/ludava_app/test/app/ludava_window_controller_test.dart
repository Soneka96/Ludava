import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  group('Method LudavaWindowController.configure() behaves correctly', () {
    test(
      'Method LudavaWindowController.configure() skips non-Windows targets',
      () {
        var lookups = 0;
        final controller = LudavaWindowController(
          currentWindow: () {
            lookups++;
            return null;
          },
          isWindows: () => false,
        );

        controller.configure();

        expect(lookups, 0);
      },
    );

    test(
      'Method LudavaWindowController.configure() tolerates a missing window',
      () {
        var lookups = 0;
        final controller = LudavaWindowController(
          currentWindow: () {
            lookups++;
            return null;
          },
          isWindows: () => true,
        );

        controller.configure();

        expect(lookups, 1);
      },
    );

    test(
      'Method LudavaWindowController.configure() applies shared window sizes',
      () {
        final window = Window.borrowed(0);
        Size? minimumSize;
        Size? initialSize;
        final controller = LudavaWindowController(
          currentWindow: () => window,
          isWindows: () => true,
          onConfigureWindow: (configuredWindow, minimum, initial) {
            expect(configuredWindow, same(window));
            minimumSize = minimum;
            initialSize = initial;
          },
        );

        controller.configure();

        expect(minimumSize, const Size(720, 560));
        expect(initialSize, const Size(1180, 760));
      },
    );
  });

  group('Method LudavaWindowController.minimize() behaves correctly', () {
    test(
      'Method LudavaWindowController.minimize() tolerates a missing window',
      () {
        final controller = LudavaWindowController(currentWindow: () => null);

        expect(controller.minimize, returnsNormally);
      },
    );
  });

  group('Method LudavaWindowController.toggleMaximize() behaves correctly', () {
    test('Method LudavaWindowController.toggleMaximize() tolerates a missing window', () {
      final controller = LudavaWindowController(currentWindow: () => null);

      expect(controller.toggleMaximize, returnsNormally);
    });
  });

  group('Method LudavaWindowController.close() behaves correctly', () {
    test(
      'Method LudavaWindowController.close() tolerates a missing window',
      () {
        final controller = LudavaWindowController(currentWindow: () => null);

        expect(controller.close, returnsNormally);
      },
    );
  });
}
