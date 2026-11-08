import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_process_choice.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

void main() {
  group('Class Rpcs3ProcessChoice selection behavior', () {
    testWidgets(
      'Class Rpcs3ProcessChoice preserves process identity and selection callback',
      (tester) async {
        const processId = 246;
        int? selectedProcessId;
        await tester.pumpWidget(
          _wrap(
            Rpcs3ProcessChoice(
              processId: processId,
              onSelectProcess: (id) => selectedProcessId = id,
            ),
          ),
        );

        expect(find.text('RPCS3 process'), findsOneWidget);
        expect(find.text('Process ID 246'), findsOneWidget);
        expect(find.byKey(const ValueKey(processId)), findsOneWidget);
        expect(find.byType(Divider), findsNothing);
        await tester.tap(find.text('Process ID 246'));

        expect(selectedProcessId, processId);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class Rpcs3ProcessChoice renders an optional semantic divider',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const Rpcs3ProcessChoice(
              processId: 246,
              onSelectProcess: _noOp,
              showDividerBefore: true,
            ),
          ),
        );

        final divider = tester.widget<Divider>(find.byType(Divider));
        expect(
          divider.color,
          LudavaTheme.graphiteAndTeal
              .extension<LudavaThemeTokens>()!
              .borderSubtle,
        );
        expect(divider.height, ConnectionDimensions.processSeparatorExtent);
        expect(
          tester.getSize(find.byType(Divider)).height,
          ConnectionDimensions.processSeparatorExtent,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class Rpcs3ProcessChoice keeps its selection row touch friendly and keyboard accessible',
      (tester) async {
        int? selectedProcessId;
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _wrap(
            Rpcs3ProcessChoice(
              processId: 246,
              onSelectProcess: (id) => selectedProcessId = id,
            ),
          ),
        );

        expect(
          tester.getSize(find.byType(ListTile)).height,
          greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
        );
        expect(find.bySemanticsLabel(RegExp('Process ID 246')), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);

        expect(selectedProcessId, 246);
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

void _noOp(int processId) {}
