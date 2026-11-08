import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_identity.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerGameHeader session display behavior', () {
    testWidgets(
      'Class TrainerGameHeader renders one accessible refresh control with readiness',
      (tester) async {
        _setMinimumWindowSize(tester);
        final profile = GameProfileCatalog.profiles.first;
        final state = _state(
          status: GameDetectionStatus.supportedGame,
          processId: 321,
          profile: profile,
          memoryBase: 0x1000,
        );
        var refreshCount = 0;

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(session: state, onRefresh: () => refreshCount++),
          ),
        );

        expect(find.text(profile.gameName), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);
        expect(find.text(profile.buildId), findsNothing);
        expect(find.text('RPCS3 process · PID 321'), findsNothing);
        expect(find.text('Refresh'), findsNothing);
        expect(find.text('Re-detect'), findsNothing);
        final refresh = find.byTooltip('Refresh values or rediscover RPCS3');
        expect(refresh, findsOneWidget);
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
        expect(
          tester.getSize(refresh).height,
          greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
        );
        final semantics = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel('Refresh values or rediscover RPCS3'),
          findsWidgets,
        );
        semantics.dispose();

        await tester.tap(refresh);
        expect(refreshCount, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class TrainerGameHeader reflects identity readiness states', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TrainerGameHeader(
            session: _state(
              status: GameDetectionStatus.unsupportedGame,
              processId: 321,
              gameTitle: 'Unknown PS3 Game',
            ),
            onRefresh: () {},
          ),
        ),
      );
      expect(find.text('Unknown PS3 Game'), findsOneWidget);
      expect(find.text('Unsupported'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          TrainerGameHeader(
            session: _state(
              status: GameDetectionStatus.ambiguous,
              processId: 321,
              gameTitle: 'Possible Game',
            ),
            onRefresh: () {},
          ),
        ),
      );
      expect(find.text('Unverified'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          TrainerGameHeader(
            session: _state(status: GameDetectionStatus.failed, processId: 321),
            onRefresh: () {},
          ),
        ),
      );
      expect(find.text('Detection failed'), findsOneWidget);
    });

    testWidgets('Class TrainerGameHeader reports discovery states', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TrainerGameHeader(session: TrainerSessionState(), onRefresh: () {}),
        ),
      );
      expect(find.text('Connect to RPCS3'), findsOneWidget);
      expect(find.text('Not detected'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          TrainerGameHeader(
            session: TrainerSessionState(processIds: const [12, 24]),
            onRefresh: () {},
          ),
        ),
      );
      expect(find.text('Select an RPCS3 process'), findsOneWidget);
      expect(find.text('Choose process'), findsOneWidget);
    });

    testWidgets(
      'Class TrainerGameHeader distinguishes missing session details',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: _state(
                status: GameDetectionStatus.noActiveGame,
                processId: 321,
              ),
              onRefresh: () {},
            ),
          ),
        );
        expect(find.text('No game'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: TrainerSessionState(
                processIds: const [321],
                selectedProcessId: 321,
                detection: GameDetectionResult(
                  status: GameDetectionStatus.rpcs3NotRunning,
                  processId: 321,
                  confidence: GameIdentityConfidence.none,
                  evidenceDescription: 'The process ended.',
                ),
              ),
              onRefresh: () {},
            ),
          ),
        );
        expect(find.text('Not detected'), findsOneWidget);

        final profile = GameProfileCatalog.profiles.first;
        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: _state(
                status: GameDetectionStatus.supportedGame,
                processId: 321,
                profile: profile,
              ),
              onRefresh: () {},
            ),
          ),
        );
        expect(find.text('Base unavailable'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: TrainerSessionState(
                processIds: const [321],
                selectedProcessId: 321,
              ),
              onRefresh: () {},
            ),
          ),
        );
        expect(find.text('Not detected'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: TrainerSessionState(
                processIds: const [321],
                selectedProcessId: 321,
                errorMessage: 'The RPCS3 session changed.',
              ),
              onRefresh: () {},
            ),
          ),
        );
        expect(find.text('Attention'), findsOneWidget);
      },
    );

    testWidgets(
      'Class TrainerGameHeader keeps a long title discoverable in one compact row',
      (tester) async {
        const longTitle =
            'A Very Long Unsupported Game Title That Must Not Push Window Actions Off Screen';
        _setMinimumWindowSize(tester);

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: _state(
                status: GameDetectionStatus.unsupportedGame,
                processId: 321,
                gameTitle: longTitle,
              ),
              onRefresh: () {},
            ),
          ),
        );

        final title = tester.widget<Text>(
          find.descendant(
            of: find.byType(TrainerGameIdentity),
            matching: find.byType(Text),
          ),
        );
        expect(title.maxLines, 1);
        expect(title.overflow, TextOverflow.ellipsis);
        expect(
          find.byTooltip('$longTitle\nRPCS3 process ID: 321'),
          findsOneWidget,
        );
        final refresh = tester.getRect(
          find.byTooltip('Refresh values or rediscover RPCS3'),
        );
        expect(refresh.right, lessThanOrEqualTo(480));
        expect(tester.takeException(), isNull);
      },
    );
  });
}

/// Builds the header under the shipped semantic theme.
Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

/// Configures a widget test at the approved minimum desktop dimensions.
void _setMinimumWindowSize(WidgetTester tester) {
  tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Builds a session snapshot with the requested detection outcome.
TrainerSessionState _state({
  required GameDetectionStatus status,
  required int processId,
  GameProfile? profile,
  String? gameTitle,
  int? memoryBase,
}) => TrainerSessionState(
  processIds: [processId],
  selectedProcessId: processId,
  detection: GameDetectionResult(
    status: status,
    processId: processId,
    gameTitle: gameTitle,
    profile: profile,
    confidence: status == GameDetectionStatus.supportedGame
        ? GameIdentityConfidence.confirmed
        : GameIdentityConfidence.none,
    evidenceDescription: 'Test detection evidence.',
  ),
  memoryBase: memoryBase,
);
