import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/screens/ludava_session_body.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel_connector.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
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

  Store<AppState> store() => sl<Store<AppState>>();

  Widget wrap() => StoreProvider<AppState>(
    store: store(),
    child: MaterialApp(
      theme: LudavaTheme.graphiteAndTeal,
      home: const Scaffold(body: LudavaSessionBody()),
    ),
  );

  group('Class LudavaSessionBody session composition behavior', () {
    testWidgets(
      'Class LudavaSessionBody shows process choices from Redux state',
      (tester) async {
        store().dispatch(
          TrainerSessionChangedAction(
            TrainerSessionState(processIds: const [42, 43]),
          ),
        );

        await tester.pumpWidget(wrap());

        expect(find.byType(SessionConnectionBody), findsOneWidget);
        expect(find.byType(TrainerFieldsPanelConnector), findsNothing);
        expect(find.text('Available RPCS3 processes'), findsOneWidget);
        expect(find.text('Process ID 42'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaSessionBody requires supported detection and a base',
      (tester) async {
        store().dispatch(
          TrainerSessionChangedAction(_readySession(memoryBase: null)),
        );

        await tester.pumpWidget(wrap());
        expect(find.byType(SessionConnectionBody), findsOneWidget);
        expect(find.byType(TrainerFieldsPanelConnector), findsNothing);

        store().dispatch(
          TrainerSessionChangedAction(
            _readySession(status: GameDetectionStatus.unsupportedGame),
          ),
        );
        await tester.pump();

        expect(find.byType(SessionConnectionBody), findsOneWidget);
        expect(find.byType(TrainerFieldsPanelConnector), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class LudavaSessionBody shows SDK fields when ready', (
      tester,
    ) async {
      store().dispatch(TrainerSessionChangedAction(_readySession()));

      await tester.pumpWidget(wrap());

      expect(find.byType(SessionConnectionBody), findsNothing);
      expect(find.byType(TrainerFieldsPanelConnector), findsOneWidget);
      expect(find.text('Credits'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class LudavaSessionBody preserves feedback and row geometry', (
      tester,
    ) async {
      const errorMessage = 'A synthetic session refresh failed.';
      final profile = _testProfile();
      final field = profile.fields.values.single;

      for (final size in const [Size(520, 360), Size(480, 340)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        store().dispatch(TrainerSessionChangedAction(_readySession()));
        await tester.pumpWidget(wrap());

        final initialRow = tester.getRect(find.byKey(ValueKey(field.id)));
        expect(initialRow.height, LudavaDimensions.minimumInteractiveTarget);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('session-feedback-region')))
              .height,
          LudavaDimensions.sessionFeedbackHeight,
        );

        store().dispatch(
          TrainerSessionChangedAction(
            _readySession(errorMessage: errorMessage),
          ),
        );
        await tester.pump();

        expect(tester.getRect(find.byKey(ValueKey(field.id))), initialRow);
        expect(find.byTooltip(errorMessage), findsOneWidget);
        expect(tester.takeException(), isNull);

        store().dispatch(const BeginEditingAction('credits'));
        await tester.pump();
        await tester.pump();
        expect(store().state.trainer.editingFieldId, 'credits');
        final activeState = store().state;
        final activeField =
            activeState.trainer.session.profile!.fields['credits']!;
        expect(TrainerSelectors.canEdit(activeState, activeField), isTrue);
        expect(TrainerSelectors.isEditing(activeState, activeField), isTrue);
        expect(
          tester
              .widget<TrainerFieldRow>(find.byKey(ValueKey(field.id)))
              .isEditing,
          isTrue,
        );
        expect(find.byType(InlineValueEditor), findsOneWidget);
        expect(tester.getRect(find.byKey(ValueKey(field.id))), initialRow);

        store().dispatch(
          TrainerSessionChangedAction(
            _readySession(processId: 43, readValue: 18),
          ),
        );
        await tester.pump();
        expect(find.byType(InlineValueEditor), findsNothing);
        expect(find.text('18'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}

TrainerSessionState _readySession({
  int processId = 42,
  int readValue = 17,
  int? memoryBase = 0x100000,
  GameDetectionStatus status = GameDetectionStatus.supportedGame,
  String? errorMessage,
}) {
  final profile = _testProfile();
  return TrainerSessionState(
    processIds: [processId],
    selectedProcessId: processId,
    processMetadata: Rpcs3ProcessMetadata(
      executablePath: r'C:\RPCS3\rpcs3.exe',
      startedAtUtc: DateTime.utc(2026, 11, 6, 10),
    ),
    detection: GameDetectionResult(
      status: status,
      processId: processId,
      titleId: profile.buildId,
      gameTitle: profile.gameName,
      executable: profile.executable,
      executableHash: 'session-body-test-hash',
      confidence: GameIdentityConfidence.confirmed,
      profile: status == GameDetectionStatus.supportedGame ? profile : null,
      evidenceDescription: 'Synthetic session-body state.',
    ),
    memoryBase: memoryBase,
    readResults: {
      'credits': GameReadResult(
        status: GameReadStatus.success,
        fieldId: 'credits',
        value: readValue,
      ),
    },
    errorMessage: errorMessage,
  );
}

GameProfile _testProfile() => GameProfile(
  id: 'session-body-test',
  gameName: 'Test Trainer',
  buildId: 'TST00001',
  executable: 'test-trainer.self',
  executableHash: 'session-body-test-hash',
  readStatus: VerificationStatus.verified,
  writeStatus: VerificationStatus.verified,
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.verified,
      writeStatus: VerificationStatus.verified,
      minimumValue: 0,
      maximumValue: 0xffffffff,
    ),
  },
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
