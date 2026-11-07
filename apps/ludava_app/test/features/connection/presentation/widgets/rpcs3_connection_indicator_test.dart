import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_indicator.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class Rpcs3ConnectionIndicator session behavior', () {
    testWidgets('Class Rpcs3ConnectionIndicator reports an absent process', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(TrainerSessionState()));

      expect(find.text('RPCS3'), findsOneWidget);
      expect(find.byTooltip('RPCS3 not detected'), findsOneWidget);
      expect(
        _dotColor(tester),
        LudavaTheme.graphiteAndTeal.extension<LudavaThemeTokens>()!.textMuted,
      );
    });

    testWidgets(
      'Class Rpcs3ConnectionIndicator distinguishes detected processes awaiting selection',
      (tester) async {
        const message = 'RPCS3 detected · select one of 2 processes';
        await tester.pumpWidget(
          _wrap(TrainerSessionState(processIds: const [42, 43])),
        );

        expect(find.text('RPCS3'), findsOneWidget);
        expect(find.byTooltip(message), findsOneWidget);
        expect(
          _dotColor(tester),
          LudavaTheme.graphiteAndTeal.extension<LudavaThemeTokens>()!.warning,
        );
        final semantics = tester.ensureSemantics();
        expect(find.bySemanticsLabel(RegExp('RPCS3 detected')), findsWidgets);
        semantics.dispose();
      },
    );

    testWidgets(
      'Class Rpcs3ConnectionIndicator reports connected only for a discovered selected process',
      (tester) async {
        const message = 'RPCS3 connected · process 42';
        final session = TrainerSessionState(
          processIds: const [42],
          selectedProcessId: 42,
          detection: GameDetectionResult(
            status: GameDetectionStatus.noActiveGame,
            processId: 42,
            confidence: GameIdentityConfidence.none,
            evidenceDescription: 'RPCS3 is running without an active game.',
          ),
        );
        await tester.pumpWidget(_wrap(session));

        expect(find.text('RPCS3'), findsOneWidget);
        expect(find.byTooltip(message), findsOneWidget);
        expect(find.text('No active game'), findsNothing);
        expect(
          _dotColor(tester),
          LudavaTheme.graphiteAndTeal.extension<LudavaThemeTokens>()!.success,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class Rpcs3ConnectionIndicator does not connect a stale selected process',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            TrainerSessionState(processIds: const [42], selectedProcessId: 99),
          ),
        );

        expect(
          find.byTooltip('RPCS3 detected · awaiting process selection'),
          findsOneWidget,
        );
        expect(
          _dotColor(tester),
          LudavaTheme.graphiteAndTeal.extension<LudavaThemeTokens>()!.warning,
        );
      },
    );
  });
}

/// Builds the indicator under the shipped semantic theme.
Widget _wrap(TrainerSessionState session) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: Rpcs3ConnectionIndicator(session: session)),
);

/// Reads the color of the small process-status dot.
Color _dotColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.circle_rounded)).color!;
