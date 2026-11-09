import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/screens/ludava_shell.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_shutdown_overlay.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header_connector.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_process_choice.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

void main() {
  late _FakeTrainerSdkCapability capability;

  setUp(() {
    sl.pushNewScope();
    capability = _FakeTrainerSdkCapability();
    initDependencies(trainerSdkCapability: capability);
  });

  tearDown(() async {
    await sl.popScope();
    await capability.dispose();
  });

  Widget wrap(Widget child, {ThemeData? theme}) => StoreProvider<AppState>(
    store: sl<Store<AppState>>(),
    child: MaterialApp(
      theme: theme ?? LudavaTheme.graphiteAndTeal,
      home: child,
    ),
  );

  group('Class LudavaShell composition behavior', () {
    testWidgets('Class LudavaShell caps centered content on wide windows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final maximizeState = ValueNotifier(false);
      addTearDown(maximizeState.dispose);

      await tester.pumpWidget(
        wrap(
          LudavaShell(
            onMinimize: () {},
            onToggleMaximize: () {},
            isMaximized: maximizeState,
            onClose: () {},
          ),
        ),
      );

      final header = tester.getRect(find.byType(TrainerGameHeaderConnector));
      expect(header.width, LudavaDimensions.maximumContentWidth);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class LudavaShell wires connection selection and window actions',
      (tester) async {
        sl<Store<AppState>>().dispatch(
          TrainerSessionChangedAction(
            TrainerSessionState(processIds: [12, 15]),
          ),
        );
        var minimizeCalls = 0;
        var maximizeCalls = 0;
        var closeCalls = 0;
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);

        await tester.pumpWidget(
          wrap(
            LudavaShell(
              onMinimize: () => minimizeCalls++,
              onToggleMaximize: () => maximizeCalls++,
              isMaximized: maximizeState,
              onClose: () => closeCalls++,
            ),
          ),
        );

        expect(find.byType(Rpcs3ProcessChoice), findsNWidgets(2));
        await tester.tap(find.text('Process ID 12'));
        await tester.tap(find.byTooltip('Refresh values or rediscover RPCS3'));
        await tester.tap(find.byTooltip('Minimize window'));
        await tester.tap(find.byTooltip('Maximize window'));
        await tester.tap(find.byTooltip('Close window'));

        expect(capability.selectedProcessIds, [12]);
        expect(capability.connectCalls, 1);
        expect(minimizeCalls, 1);
        expect(maximizeCalls, 1);
        expect(closeCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaShell blocks trainer input behind shutdown overlay',
      (tester) async {
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);

        await tester.pumpWidget(
          wrap(
            LudavaShell(
              onMinimize: () {},
              onToggleMaximize: () {},
              isMaximized: maximizeState,
              onClose: () {},
              isClosing: true,
            ),
          ),
        );

        expect(find.byType(LudavaShutdownOverlay), findsOneWidget);
        expect(
          tester.getRect(find.byType(LudavaShutdownOverlay)),
          Offset.zero & LudavaDimensions.minimumWindowSize,
        );
        expect(find.byType(AbsorbPointer), findsWidgets);
        expect(find.byType(ExcludeFocus), findsWidgets);
        await tester.tap(
          find.byTooltip('Refresh values or rediscover RPCS3'),
          warnIfMissed: false,
        );
        expect(capability.connectCalls + capability.refreshCalls, 0);
        expect(find.text('Finishing cleanup'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  int connectCalls = 0;
  int refreshCalls = 0;
  final List<int> selectedProcessIds = [];

  @override
  TrainerSessionState get state => TrainerSessionState();

  @override
  Stream<TrainerSessionState> get stateChanges => const Stream.empty();

  @override
  void connect() => connectCalls++;

  @override
  void refresh() => refreshCalls++;

  @override
  bool selectProcess(int processId) {
    selectedProcessIds.add(processId);
    return true;
  }

  @override
  GameWriteResult writeField(String fieldId, int value) =>
      GameWriteResult(status: GameWriteStatus.none, fieldId: fieldId);

  @override
  Future<void> dispose() async {}
}
