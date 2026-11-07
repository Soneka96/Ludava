import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/rpcs3_process_picker.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';

void main() {
  group('Class Rpcs3ProcessPicker selection behavior', () {
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
