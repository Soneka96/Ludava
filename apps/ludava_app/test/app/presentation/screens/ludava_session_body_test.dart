import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/screens/ludava_session_body.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_controller.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

LudavaSessionBody _body(
  TrainerSessionState session, {
  String? editingFieldId,
}) => LudavaSessionBody(
  session: session,
  editingFieldId: editingFieldId,
  onSelectProcess: (_) {},
  onEditField: (_) {},
  onApplyField: _failedWrite,
  onCancelEditing: () {},
);

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

List<Rect> _fieldRowRects(WidgetTester tester, GameProfile profile) => profile
    .fields
    .keys
    .map(
      (fieldId) =>
          tester.getRect(find.byKey(ValueKey('trainer-field-row-$fieldId'))),
    )
    .toList(growable: false);

Finder _feedbackRegion() =>
    find.byKey(const ValueKey('session-feedback-region'));

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

GameWriteResult _failedWrite(String fieldId, int value) => GameWriteResult(
  status: GameWriteStatus.writeFailed,
  fieldId: fieldId,
  requestedValue: value,
);

class _FakeTrainerSdk implements TrainerSdkCapability {
  /// Creates a controllable session source for widget and controller tests.
  _FakeTrainerSdk(this._state);

  final StreamController<TrainerSessionState> _states =
      StreamController<TrainerSessionState>.broadcast(sync: true);
  TrainerSessionState _state;

  @override
  TrainerSessionState get state => _state;

  @override
  Stream<TrainerSessionState> get stateChanges => _states.stream;

  @override
  void connect() {}

  @override
  void refresh() {}

  @override
  bool selectProcess(int processId) => _state.processIds.contains(processId);

  @override
  GameWriteResult writeField(String fieldId, int value) =>
      _failedWrite(fieldId, value);

  @override
  Future<void> dispose() => _states.close();

  /// Publishes [state] as a new SDK snapshot to the controller.
  void publish(TrainerSessionState state) {
    _state = state;
    _states.add(state);
  }
}

void main() {
  group('Class LudavaSessionBody session composition behavior', () {
    testWidgets(
      'Class LudavaSessionBody shows connection guidance until the session is ready',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            LudavaSessionBody(
              session: TrainerSessionState(processIds: const [42, 43]),
              editingFieldId: null,
              onSelectProcess: (_) {},
              onEditField: (_) {},
              onApplyField: _failedWrite,
              onCancelEditing: () {},
            ),
          ),
        );

        expect(find.byType(SessionConnectionBody), findsOneWidget);
        expect(find.byType(TrainerFieldsPanel), findsNothing);
        expect(find.text('Available RPCS3 processes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaSessionBody requires both supported detection and a memory base',
      (tester) async {
        final unresolvedStates = [
          _readySession(memoryBase: null),
          _readySession(status: GameDetectionStatus.unsupportedGame),
        ];

        for (final session in unresolvedStates) {
          await tester.pumpWidget(_wrap(_body(session)));

          expect(find.byType(SessionConnectionBody), findsOneWidget);
          expect(find.byType(TrainerFieldsPanel), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Class LudavaSessionBody shows profile fields and routes field actions when ready',
      (tester) async {
        final session = _readySession();
        final field = session.profile!.fields.values.single;
        GameField? editedField;
        String? appliedFieldId;
        int? appliedValue;
        var cancelCalls = 0;

        await tester.pumpWidget(
          _wrap(
            LudavaSessionBody(
              session: session,
              editingFieldId: null,
              onSelectProcess: (_) {},
              onEditField: (field) => editedField = field,
              onApplyField: (fieldId, value) {
                appliedFieldId = fieldId;
                appliedValue = value;
                return _failedWrite(fieldId, value);
              },
              onCancelEditing: () => cancelCalls++,
            ),
          ),
        );

        expect(find.byType(SessionConnectionBody), findsNothing);
        expect(find.byType(TrainerFieldsPanel), findsOneWidget);
        expect(find.text(field.name), findsOneWidget);
        expect(find.text('17'), findsOneWidget);

        final fieldsPanel = tester.widget<TrainerFieldsPanel>(
          find.byType(TrainerFieldsPanel),
        );
        fieldsPanel.onEditField(field);
        expect(
          fieldsPanel.onApplyField(field.id, 99).status,
          GameWriteStatus.writeFailed,
        );
        fieldsPanel.onCancelEditing();

        expect(editedField, same(field));
        expect(appliedFieldId, field.id);
        expect(appliedValue, 99);
        expect(cancelCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaSessionBody reserves error feedback space without moving inline rows',
      (tester) async {
        const errorMessage =
            'The SDK could not refresh the current game session and returned a long diagnostic message.';
        final profile = _testProfile();
        final field = profile.fields.values.single;

        for (final size in const [Size(520, 360), Size(480, 340)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;

          await tester.pumpWidget(_wrap(_body(_readySession())));
          final initialRows = _fieldRowRects(tester, profile);
          expect(
            initialRows.map((row) => row.height),
            everyElement(LudavaDimensions.minimumInteractiveTarget),
          );
          final initialFeedback = _feedbackRegion();
          expect(
            tester.getSize(initialFeedback).height,
            LudavaDimensions.sessionFeedbackHeight,
          );

          await tester.pumpWidget(
            _wrap(_body(_readySession(errorMessage: errorMessage))),
          );
          expect(_fieldRowRects(tester, profile), initialRows);
          expect(
            initialRows.map((row) => row.height),
            everyElement(LudavaDimensions.minimumInteractiveTarget),
          );
          expect(
            tester.getSize(_feedbackRegion()).height,
            LudavaDimensions.sessionFeedbackHeight,
          );
          expect(find.byTooltip(errorMessage), findsOneWidget);
          final message = tester.widget<Text>(find.text(errorMessage));
          expect(message.maxLines, 1);
          expect(message.overflow, TextOverflow.ellipsis);
          expect(
            message.style?.color,
            LudavaTheme.graphiteAndTeal.colorScheme.error,
          );
          expect(find.byType(InlineValueEditor), findsNothing);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            _wrap(
              _body(
                _readySession(errorMessage: errorMessage),
                editingFieldId: field.id,
              ),
            ),
          );
          expect(_fieldRowRects(tester, profile), initialRows);
          expect(find.byType(InlineValueEditor), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(_wrap(_body(_readySession())));
          expect(_fieldRowRects(tester, profile), initialRows);
          expect(find.byTooltip(errorMessage), findsNothing);
          expect(tester.takeException(), isNull);
        }

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );

    testWidgets(
      'Class LudavaSessionBody removes the open editor after controller invalidation',
      (tester) async {
        final capability = _FakeTrainerSdk(_readySession());
        final controller = TrainerController(capability: capability);
        addTearDown(() async => controller.dispose());
        final field = controller.session.profile!.fields.values.single;

        await tester.pumpWidget(
          _wrap(
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) => LudavaSessionBody(
                session: controller.session,
                editingFieldId: controller.editingFieldId,
                onSelectProcess: controller.selectProcess,
                onEditField: controller.editField,
                onApplyField: controller.writeField,
                onCancelEditing: controller.cancelEditing,
              ),
            ),
          ),
        );

        expect(controller.editField(field), isTrue);
        await tester.pump();
        final input = find.byKey(ValueKey('inline-editor-input-${field.id}'));
        expect(input, findsOneWidget);

        capability.publish(_readySession(processId: 43, readValue: 18));
        await tester.pump();
        expect(controller.editingFieldId, isNull);
        expect(
          find.byKey(ValueKey('inline-editor-input-${field.id}')),
          findsNothing,
        );
        expect(find.text('18'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
