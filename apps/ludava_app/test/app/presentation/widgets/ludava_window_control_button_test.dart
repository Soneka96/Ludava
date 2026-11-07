import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_control_button.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';

void main() {
  group('Class LudavaWindowControlButton interaction behavior', () {
    testWidgets(
      'Class LudavaWindowControlButton exposes an accessible action',
      (tester) async {
        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LudavaWindowControlButton(
                tooltip: 'Minimize window',
                icon: Icons.remove_rounded,
                onPressed: () => calls++,
              ),
            ),
          ),
        );

        expect(find.byTooltip('Minimize window'), findsOneWidget);
        expect(
          tester.getSize(find.byTooltip('Minimize window')),
          const Size(
            LudavaDimensions.windowControlWidth,
            LudavaDimensions.titleBarHeight,
          ),
        );
        await tester.tap(find.byTooltip('Minimize window'));

        expect(calls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
