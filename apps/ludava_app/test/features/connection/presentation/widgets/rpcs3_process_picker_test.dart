import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_process_picker.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

void main() {
  group('Class Rpcs3ProcessPicker selection behavior', () {
    testWidgets(
      'Class Rpcs3ProcessPicker scrolls process choices at minimum size',
      (tester) async {
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        int? selectedProcess;

        await tester.pumpWidget(
          MaterialApp(
            theme: LudavaTheme.graphiteAndTeal,
            home: Scaffold(
              body: Rpcs3ProcessPicker(
                processIds: List.generate(12, (index) => 120 + index),
                onSelectProcess: (processId) => selectedProcess = processId,
              ),
            ),
          ),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pumpAndSettle();

        expect(find.text('Process ID 131'), findsOneWidget);
        await tester.tap(find.text('Process ID 131'));
        expect(selectedProcess, 131);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class Rpcs3ProcessPicker selects the tapped process', (
      tester,
    ) async {
      int? selectedProcess;

      await tester.pumpWidget(
        MaterialApp(
          theme: LudavaTheme.graphiteAndTeal,
          home: Scaffold(
            body: Rpcs3ProcessPicker(
              processIds: const [120, 240],
              onSelectProcess: (processId) => selectedProcess = processId,
            ),
          ),
        ),
      );

      expect(find.text('Process ID 120'), findsOneWidget);
      expect(find.text('Process ID 240'), findsOneWidget);
      await tester.tap(find.text('Process ID 240'));

      expect(selectedProcess, 240);
    });

    testWidgets('Class Rpcs3ProcessPicker uses the semantic border role', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: LudavaTheme.graphiteAndTeal,
          home: Scaffold(
            body: Rpcs3ProcessPicker(
              processIds: const [120, 240],
              onSelectProcess: (_) {},
            ),
          ),
        ),
      );

      final divider = tester.widget<Divider>(find.byType(Divider).first);
      expect(
        divider.color,
        LudavaTheme.graphiteAndTeal
            .extension<LudavaThemeTokens>()!
            .borderSubtle,
      );
      expect(
        tester.getSize(find.byType(Divider).first).height,
        ConnectionDimensions.processSeparatorExtent,
      );
      expect(
        tester.getSize(find.byType(ListView)).width,
        ConnectionDimensions.contentMaxWidth,
      );
    });

    testWidgets(
      'Class Rpcs3ProcessPicker supports keyboard activation and semantics',
      (tester) async {
        int? selectedProcess;
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            theme: LudavaTheme.graphiteAndTeal,
            home: Scaffold(
              body: Rpcs3ProcessPicker(
                processIds: const [120, 240],
                onSelectProcess: (processId) => selectedProcess = processId,
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel(RegExp('Process ID 120')), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);

        expect(selectedProcess, 120);
        semantics.dispose();
      },
    );
  });
}
