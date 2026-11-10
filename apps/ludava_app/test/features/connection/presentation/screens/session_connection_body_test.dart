import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_guidance.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_process_picker.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

GameProfile _profile() => GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'SYNTHETIC',
  executable: 'SYNTHETIC.self',
  executableHash: 'PPU-synthetic-hash',
  readStatus: VerificationStatus.experimental,
);

Widget _connectionBody({
  required TrainerSessionState session,
  ValueChanged<int> onSelectProcess = _ignoreProcess,
}) => SessionConnectionBody(
  processIds: session.processIds,
  selectedProcessId: session.selectedProcessId,
  detection: session.detection,
  hasMemoryBase: session.memoryBase != null,
  errorMessage: session.errorMessage,
  onSelectProcess: onSelectProcess,
);

void _ignoreProcess(int processId) {}

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

TrainerSessionState _session(
  GameDetectionStatus status, {
  String? gameTitle,
  String? evidence,
  bool withProfile = false,
  int? memoryBase,
}) {
  final profile = withProfile ? _profile() : null;
  return TrainerSessionState(
    processIds: const [42],
    selectedProcessId: 42,
    detection: GameDetectionResult(
      status: status,
      processId: 42,
      gameTitle: gameTitle,
      profile: profile,
      confidence: status == GameDetectionStatus.supportedGame
          ? GameIdentityConfidence.confirmed
          : GameIdentityConfidence.none,
      evidenceDescription: evidence ?? 'Test evidence.',
    ),
    memoryBase: memoryBase,
  );
}

void main() {
  group('Class SessionConnectionBody session guidance behavior', () {
    testWidgets('Class SessionConnectionBody guides the missing RPCS3 state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: TrainerSessionState(),
            onSelectProcess: (_) {},
          ),
        ),
      );

      expect(
        find.text('RPCS3 was not found. Start RPCS3, then select Refresh.'),
        findsOneWidget,
      );
    });

    testWidgets('Class SessionConnectionBody explains active-game outcomes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: _session(GameDetectionStatus.noActiveGame),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text(
          'No active game was detected. Start a supported game in RPCS3.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: _session(
              GameDetectionStatus.unsupportedGame,
              gameTitle: 'Unknown Game',
            ),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text('Unknown Game is not supported by Ludava.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: _session(GameDetectionStatus.unsupportedGame),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text('This game is not supported by Ludava.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: _session(
              GameDetectionStatus.ambiguous,
              evidence: 'The current executable evidence conflicts.',
            ),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text('The current executable evidence conflicts.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: _session(
              GameDetectionStatus.failed,
              evidence: 'The current RPCS3 log could not be read.',
            ),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text('The current RPCS3 log could not be read.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: _session(GameDetectionStatus.ambiguous, evidence: '  \t '),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text(
          'The active game could not be verified. Select Refresh to try again.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: _session(GameDetectionStatus.failed, evidence: ''),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text('Game detection failed. Select Refresh to try again.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: _session(
              GameDetectionStatus.failed,
              evidence: 'The current RPCS3 log could not be read.',
            ),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text('The current RPCS3 log could not be read.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Class SessionConnectionBody presents SDK errors and base limits',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _connectionBody(
              session: TrainerSessionState(
                errorMessage: 'Process metadata failed.',
                detection: _session(GameDetectionStatus.noActiveGame).detection,
              ),
              onSelectProcess: (_) {},
            ),
          ),
        );
        expect(find.text('Process metadata failed.'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            _connectionBody(
              session: _session(
                GameDetectionStatus.supportedGame,
                withProfile: true,
              ),
              onSelectProcess: (_) {},
            ),
          ),
        );
        expect(
          find.text(
            'The game was detected, but its session memory base is unavailable.',
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(
          _wrap(
            _connectionBody(
              session: _session(
                GameDetectionStatus.supportedGame,
                withProfile: true,
                memoryBase: 0x1000,
              ),
              onSelectProcess: (_) {},
            ),
          ),
        );
        expect(find.text('The game session is ready.'), findsOneWidget);
      },
    );

    testWidgets('Class SessionConnectionBody explains unselected SDK states', (
      tester,
    ) async {
      final notRunning = TrainerSessionState(
        detection: GameDetectionResult(
          status: GameDetectionStatus.rpcs3NotRunning,
          confidence: GameIdentityConfidence.none,
          evidenceDescription: 'No process was found.',
        ),
      );
      await tester.pumpWidget(
        _wrap(_connectionBody(session: notRunning, onSelectProcess: (_) {})),
      );
      expect(
        find.text('RPCS3 was not found. Start RPCS3, then select Refresh.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: TrainerSessionState(selectedProcessId: 42),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text('Connect to RPCS3 to detect the active game.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: TrainerSessionState(
              selectedProcessId: 42,
              detection: GameDetectionResult(
                status: GameDetectionStatus.none,
                confidence: GameIdentityConfidence.none,
                evidenceDescription: 'No detection is available.',
              ),
            ),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(
        find.text('Connect to RPCS3 to detect the active game.'),
        findsOneWidget,
      );
    });

    testWidgets('Class SessionConnectionBody renders the process picker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: TrainerSessionState(processIds: const [10, 20]),
            onSelectProcess: (_) {},
          ),
        ),
      );

      expect(find.byType(Rpcs3ProcessPicker), findsOneWidget);
      expect(find.byType(Rpcs3ConnectionGuidance), findsNothing);

      await tester.pumpWidget(
        _wrap(
          _connectionBody(
            session: TrainerSessionState(
              processIds: const [10, 20],
              selectedProcessId: 10,
              detection: GameDetectionResult(
                status: GameDetectionStatus.noActiveGame,
                processId: 10,
                confidence: GameIdentityConfidence.none,
                evidenceDescription: 'RPCS3 has no active game.',
              ),
            ),
            onSelectProcess: (_) {},
          ),
        ),
      );
      expect(find.byType(Rpcs3ProcessPicker), findsNothing);
      expect(find.byType(Rpcs3ConnectionGuidance), findsOneWidget);
    });

    testWidgets(
      'Class SessionConnectionBody selects guidance error state from SDK failures',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _connectionBody(
              session: _session(GameDetectionStatus.noActiveGame),
              onSelectProcess: (_) {},
            ),
          ),
        );
        expect(
          tester
              .widget<Rpcs3ConnectionGuidance>(
                find.byType(Rpcs3ConnectionGuidance),
              )
              .isError,
          isFalse,
        );

        await tester.pumpWidget(
          _wrap(
            _connectionBody(
              session: _session(GameDetectionStatus.failed),
              onSelectProcess: (_) {},
            ),
          ),
        );
        expect(
          tester
              .widget<Rpcs3ConnectionGuidance>(
                find.byType(Rpcs3ConnectionGuidance),
              )
              .isError,
          isTrue,
        );

        await tester.pumpWidget(
          _wrap(
            _connectionBody(
              session: TrainerSessionState(
                errorMessage: 'Process metadata failed.',
              ),
              onSelectProcess: (_) {},
            ),
          ),
        );
        expect(
          tester
              .widget<Rpcs3ConnectionGuidance>(
                find.byType(Rpcs3ConnectionGuidance),
              )
              .isError,
          isTrue,
        );
      },
    );
  });
}
