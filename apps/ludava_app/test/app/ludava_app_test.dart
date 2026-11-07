import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/ludava_app.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class LudavaApp lifecycle behavior', () {
    testWidgets('Class LudavaApp renders the missing RPCS3 state', (
      tester,
    ) async {
      var discoveryCalls = 0;
      final sdk = _createSdk(() {
        discoveryCalls++;
        return const [];
      });

      await tester.pumpWidget(LudavaApp(sdk: sdk));

      expect(find.text('LUDAVA'), findsOneWidget);
      expect(
        find.text('RPCS3 was not found. Start RPCS3 to connect.'),
        findsOneWidget,
      );
      expect(discoveryCalls, 1);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });

    testWidgets('Class LudavaApp renders the latest process snapshot', (
      tester,
    ) async {
      var processIds = <int>[];
      final sdk = _createSdk(() => processIds);

      await tester.pumpWidget(LudavaApp(sdk: sdk));
      expect(
        find.text('RPCS3 was not found. Start RPCS3 to connect.'),
        findsOneWidget,
      );

      processIds = [120, 240];
      sdk.session.connect();
      await tester.pump();

      expect(find.text('Select an RPCS3 process to continue.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await expectLater(sdk.session.stateChanges, emitsDone);
    });

    testWidgets('Class LudavaApp selects the single discovered process', (
      tester,
    ) async {
      final sdk = LudavaSdk.create(
        isWindows: false,
        discoverProcessIds: () => const [120],
        readProcessMetadata: (_) => Rpcs3ProcessMetadata(
          executablePath: r'C:\Games\rpcs3.exe',
          startedAtUtc: DateTime.utc(2026),
        ),
        resolveMemoryBaseCandidate: (_) => null,
        detectGame: (processId, _) => GameDetectionResult(
          status: GameDetectionStatus.noActiveGame,
          processId: processId,
          confidence: GameIdentityConfidence.none,
          evidenceDescription: 'No game is active.',
        ),
      );

      await tester.pumpWidget(LudavaApp(sdk: sdk));
      await tester.pump();

      expect(find.text('Connected to RPCS3 (PID 120).'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });

    testWidgets('Class LudavaApp displays SDK connection errors', (
      tester,
    ) async {
      final sdk = _createSdk(
        () => throw StateError('Process discovery failed.'),
      );

      await tester.pumpWidget(LudavaApp(sdk: sdk));
      await tester.pump();

      expect(
        sdk.session.state.errorMessage,
        'Bad state: Process discovery failed.',
      );
      expect(find.text('Bad state: Process discovery failed.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });
  });
}

LudavaSdk _createSdk(List<int> Function() discoverProcessIds) =>
    LudavaSdk.create(
      isWindows: false,
      discoverProcessIds: discoverProcessIds,
      readProcessMetadata: (_) => throw StateError('Not used by these tests.'),
      resolveMemoryBaseCandidate: (_) => null,
      detectGame: (_, _) => throw StateError('Not used by these tests.'),
    );
