import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerGameHeader session display behavior', () {
    testWidgets('Class TrainerGameHeader shows game readiness from the SDK', (
      tester,
    ) async {
      tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = GameProfileCatalog.profiles.first;
      final state = _state(
        status: GameDetectionStatus.supportedGame,
        processId: 321,
        profile: profile,
        memoryBase: 0x1000,
      );
      var refreshCount = 0;
      var redetectCount = 0;

      await tester.pumpWidget(
        _wrap(
          TrainerGameHeader(
            session: state,
            onRefresh: () => refreshCount++,
            onRedetect: () => redetectCount++,
          ),
        ),
      );

      expect(find.text(profile.gameName), findsOneWidget);
      expect(
        find.text('${profile.buildId} · RPCS3 process · PID 321'),
        findsOneWidget,
      );
      expect(find.text('Ready'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Ready')).style?.color,
        LudavaTheme.graphiteAndTeal.extension<LudavaThemeTokens>()!.success,
      );
      final header = tester.widget<Container>(find.byType(Container).first);
      expect(
        header.padding,
        const EdgeInsets.symmetric(
          horizontal: LudavaSpacing.xl,
          vertical: LudavaSpacing.lg,
        ),
      );
      expect(
        ((header.decoration! as BoxDecoration).border! as Border).bottom.color,
        LudavaTheme.graphiteAndTeal
            .extension<LudavaThemeTokens>()!
            .borderSubtle,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Re-detect'));

      expect(refreshCount, 1);
      expect(redetectCount, 1);
      expect(
        tester.getSize(find.widgetWithText(OutlinedButton, 'Refresh')).height,
        greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
      );
      expect(
        tester.getSize(find.widgetWithText(OutlinedButton, 'Re-detect')).height,
        greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Refresh'),
            )
            .style,
        isNull,
      );
    });

    testWidgets(
      'Class TrainerGameHeader reflects unsupported and ambiguous identity',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: _state(
                status: GameDetectionStatus.unsupportedGame,
                processId: 321,
                gameTitle: 'Unknown PS3 Game',
              ),
              onRefresh: () {},
              onRedetect: () {},
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
              onRedetect: () {},
            ),
          ),
        );

        expect(find.text('Unverified'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: _state(
                status: GameDetectionStatus.failed,
                processId: 321,
              ),
              onRefresh: () {},
              onRedetect: () {},
            ),
          ),
        );
        expect(find.text('Detection failed'), findsOneWidget);
      },
    );

    testWidgets('Class TrainerGameHeader reports discovery states', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TrainerGameHeader(
            session: TrainerSessionState(),
            onRefresh: () {},
            onRedetect: () {},
          ),
        ),
      );

      expect(find.text('Connect to RPCS3'), findsOneWidget);
      expect(find.text('Not detected'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          TrainerGameHeader(
            session: TrainerSessionState(processIds: const [12, 24]),
            onRefresh: () {},
            onRedetect: () {},
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
              onRedetect: () {},
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
              onRedetect: () {},
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
              onRedetect: () {},
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
              onRedetect: () {},
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
              onRedetect: () {},
            ),
          ),
        );
        expect(find.text('Attention'), findsOneWidget);
      },
    );

    testWidgets(
      'Class TrainerGameHeader keeps long game names discoverable at minimum width',
      (tester) async {
        const longTitle =
            'A Very Long Unsupported Game Title That Must Not Push Window Actions Off Screen';
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: _state(
                status: GameDetectionStatus.unsupportedGame,
                processId: 321,
                gameTitle: longTitle,
              ),
              onRefresh: () {},
              onRedetect: () {},
            ),
          ),
        );

        final title = tester.widget<Text>(find.text(longTitle));
        expect(title.maxLines, isNull);
        expect(title.overflow, isNull);
        expect(find.text('Refresh'), findsOneWidget);
        expect(find.text('Re-detect'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class TrainerGameHeader adapts across its width threshold', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final width in [
        LudavaBreakpoints.trainerHeaderWide - 1,
        LudavaBreakpoints.trainerHeaderWide,
        LudavaBreakpoints.trainerHeaderWide + 1,
      ]) {
        tester.view.physicalSize = Size(width, 420);
        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: _state(
                status: GameDetectionStatus.unsupportedGame,
                processId: 321,
                gameTitle: 'An Unsupported Game With a Very Long Name',
              ),
              onRefresh: () {},
              onRedetect: () {},
            ),
          ),
        );

        expect(find.text('Unsupported'), findsOneWidget);
        expect(find.text('Refresh'), findsOneWidget);
        expect(find.text('Re-detect'), findsOneWidget);
        final layout = tester.widget<Container>(
          find.descendant(
            of: find.byType(TrainerGameHeader),
            matching: find.byType(Container),
          ),
        );
        expect(
          layout.child,
          width < LudavaBreakpoints.trainerHeaderWide
              ? isA<Column>()
              : isA<Row>(),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

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
