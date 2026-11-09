import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_process_choice.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_process_picker.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

void main() {
  group('Class Rpcs3ProcessPicker composition behavior', () {
    testWidgets(
      'Class Rpcs3ProcessPicker keeps its heading and composes named process choices',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            Rpcs3ProcessPicker(
              processIds: const [120, 240],
              onSelectProcess: (_) {},
            ),
          ),
        );

        expect(find.text('Available RPCS3 processes'), findsOneWidget);
        expect(
          find.text('Select the process running your game.'),
          findsOneWidget,
        );
        expect(find.byType(Rpcs3ProcessChoice), findsNWidgets(2));
      },
    );

    testWidgets(
      'Class Rpcs3ProcessPicker scrolls and selects a process at minimum size',
      (tester) async {
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        int? selectedProcessId;

        await tester.pumpWidget(
          _wrap(
            Rpcs3ProcessPicker(
              processIds: List.generate(12, (index) => 120 + index),
              onSelectProcess: (processId) => selectedProcessId = processId,
            ),
          ),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pumpAndSettle();

        expect(find.text('Process ID 131'), findsOneWidget);
        await tester.tap(find.text('Process ID 131'));
        expect(selectedProcessId, 131);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class Rpcs3ProcessPicker keeps the process list within its readable width',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _wrap(
            Rpcs3ProcessPicker(
              processIds: const [120, 240],
              onSelectProcess: (_) {},
            ),
          ),
        );

        expect(
          tester.getSize(find.byType(ListView)).width,
          ConnectionDimensions.contentMaxWidth,
        );
      },
    );
  });
}
