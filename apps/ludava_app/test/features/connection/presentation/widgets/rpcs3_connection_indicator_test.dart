import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_indicator.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
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

  group('Class Rpcs3ConnectionIndicator connected behavior', () {
    testWidgets('Class Rpcs3ConnectionIndicator updates from Redux state', (
      tester,
    ) async {
      final store = sl<Store<AppState>>();
      await tester.pumpWidget(_wrap(store));
      expect(
        tester.widgetList<Tooltip>(find.byType(Tooltip)).single.message,
        'RPCS3 not detected',
      );

      store.dispatch(
        TrainerSessionChangedAction(
          TrainerSessionState(processIds: const [42]),
        ),
      );
      await tester.pump();

      expect(
        tester.widgetList<Tooltip>(find.byType(Tooltip)).single.message,
        'RPCS3 detected · awaiting process selection',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class Rpcs3ConnectionIndicator shows status, tooltip, semantics, and theme color',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        final tokens = LudavaTheme.graphiteAndTeal
            .extension<LudavaThemeTokens>()!;
        final cases = <(TrainerSessionState, String, Color)>[
          (TrainerSessionState(), 'RPCS3 not detected', tokens.textMuted),
          (
            TrainerSessionState(processIds: const [42]),
            'RPCS3 detected · awaiting process selection',
            tokens.warning,
          ),
          (
            TrainerSessionState(processIds: const [42, 84]),
            'RPCS3 detected · select one of 2 processes',
            tokens.warning,
          ),
          (
            TrainerSessionState(processIds: const [42], selectedProcessId: 42),
            'RPCS3 connected · process 42',
            tokens.success,
          ),
          (
            TrainerSessionState(processIds: const [84], selectedProcessId: 42),
            'RPCS3 detected · awaiting process selection',
            tokens.warning,
          ),
        ];

        for (final (session, message, color) in cases) {
          final store = Store<AppState>(
            appReducer,
            initialState: AppState(trainer: TrainerState(session: session)),
          );
          await tester.pumpWidget(_wrap(store, key: ValueKey(message)));

          expect(
            tester.widgetList<Tooltip>(find.byType(Tooltip)).single.message,
            message,
          );
          final semanticsWidgets = tester
              .widgetList<Semantics>(find.byType(Semantics))
              .toList();
          final statusIndex = semanticsWidgets.indexWhere(
            (widget) => widget.properties.label == message,
          );
          expect(statusIndex, greaterThanOrEqualTo(0));
          expect(semanticsWidgets[statusIndex].properties.label, message);
          expect(find.bySemanticsLabel(message), findsOneWidget);
          expect(
            tester.widget<Icon>(find.byIcon(Icons.circle_rounded)).color,
            color,
          );
          expect(tester.widget<Text>(find.text('RPCS3')).style?.color, color);
          expect(tester.takeException(), isNull);
        }
        semanticsHandle.dispose();
      },
    );
  });
}

Widget _wrap(Store<AppState> store, {Key? key}) => StoreProvider<AppState>(
  key: key,
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: Rpcs3ConnectionIndicator()),
  ),
);

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  @override
  TrainerSessionState get state => TrainerSessionState();

  @override
  Stream<TrainerSessionState> get stateChanges => const Stream.empty();

  @override
  void connect() {}

  @override
  void refresh() {}

  @override
  bool selectProcess(int processId) => false;

  @override
  GameWriteResult writeField(String fieldId, int value) =>
      GameWriteResult(status: GameWriteStatus.none, fieldId: fieldId);

  @override
  Future<void> dispose() async {}
}
