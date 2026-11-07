import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_indicator.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class Rpcs3ConnectionIndicator session behavior', () {
    testWidgets('Class Rpcs3ConnectionIndicator shows a running process', (
      tester,
    ) async {
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
      expect(find.byTooltip('RPCS3 Connected'), findsOneWidget);
      expect(find.text('No active game'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class Rpcs3ConnectionIndicator reports a disconnected state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(TrainerSessionState()));

      expect(find.text('RPCS3'), findsOneWidget);
      expect(find.byTooltip('RPCS3 Disconnected'), findsOneWidget);
    });
  });
}

Widget _wrap(TrainerSessionState session) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: Rpcs3ConnectionIndicator(session: session)),
);
