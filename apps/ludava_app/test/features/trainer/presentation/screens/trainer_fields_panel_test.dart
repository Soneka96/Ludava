import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerFieldsPanel vertical field behavior', () {
    testWidgets('Class TrainerFieldsPanel renders profile fields vertically', (
      tester,
    ) async {
      _setMinimumView(tester);

      await tester.pumpWidget(
        _wrap(_session(value: 0, includeSecondField: true)),
      );

      final bolts = find.byKey(const ValueKey('trainer-field-row-bolts'));
      final scrap = find.byKey(const ValueKey('trainer-field-row-scrap'));
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Bolts'), findsOneWidget);
      expect(find.text('Scrap'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(
        tester.getTopLeft(scrap).dy,
        greaterThan(tester.getTopLeft(bolts).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldsPanel scrolls a dynamic field list', (
      tester,
    ) async {
      _setMinimumView(tester);

      await tester.pumpWidget(_wrap(_session(includeManyFields: true)));
      final lastField = find.text('Part 11');

      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(lastField, findsOneWidget);
      await tester.ensureVisible(lastField);
      await tester.pumpAndSettle();
      expect(tester.getRect(lastField).bottom, lessThanOrEqualTo(340));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldsPanel keeps the maximum unsigned value readable at minimum size',
      (tester) async {
        _setMinimumView(tester);
        await tester.pumpWidget(_wrap(_session(value: 4294967295)));

        final value = find.text('4,294,967,295');
        expect(value, findsOneWidget);
        expect(tester.getRect(value).left, greaterThanOrEqualTo(0));
        expect(tester.getRect(value).right, lessThanOrEqualTo(480));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class TrainerFieldsPanel routes Edit to the selected field', (
      tester,
    ) async {
      _setMinimumView(tester);
      String? editedFieldId;

      await tester.pumpWidget(
        _wrap(
          _session(value: 17, includeSecondField: true),
          onEditField: (field) => editedFieldId = field.id,
        ),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Edit').first);

      expect(editedFieldId, 'bolts');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldsPanel applies an explicit editor request', (
      tester,
    ) async {
      _setMinimumView(tester);
      var writeCalls = 0;
      int? requestedValue;

      await tester.pumpWidget(
        _wrap(
          _session(value: 17),
          editingFieldId: 'bolts',
          onApplyField: (fieldId, value) {
            writeCalls++;
            requestedValue = value;
            return _success(fieldId, value);
          },
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('inline-editor-input-bolts')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('inline-editor-input-bolts')),
        '42',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();
      expect(writeCalls, 0);

      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pump();

      expect(writeCalls, 1);
      expect(requestedValue, 42);
      expect(find.text('Applied and verified: 42'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldsPanel cancels editing without writing', (
      tester,
    ) async {
      _setMinimumView(tester);
      var writeCalls = 0;
      var cancelCalls = 0;

      await tester.pumpWidget(
        _wrap(
          _session(value: 17),
          editingFieldId: 'bolts',
          onApplyField: (fieldId, value) {
            writeCalls++;
            return _success(fieldId, value);
          },
          onCancelEditing: () => cancelCalls++,
        ),
      );
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();

      expect(cancelCalls, 1);
      expect(writeCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldsPanel hides editing when permission is lost',
      (tester) async {
        _setMinimumView(tester);
        await tester.pumpWidget(
          _wrap(_session(value: 17), editingFieldId: 'bolts'),
        );
        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsOneWidget,
        );

        await tester.pumpWidget(
          _wrap(
            _session(value: 17, fieldWriteStatus: VerificationStatus.none),
            editingFieldId: 'bolts',
          ),
        );

        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
        expect(find.text('Read-only'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel keeps a failed read distinct from zero',
      (tester) async {
        _setMinimumView(tester);
        await tester.pumpWidget(
          _wrap(
            _session(
              readResult: const GameReadResult(
                status: GameReadStatus.readFailed,
                fieldId: 'bolts',
              ),
            ),
          ),
        );

        expect(find.text('Read failed'), findsOneWidget);
        expect(find.text('0'), findsNothing);
        expect(find.text('Writable'), findsNothing);
        expect(find.widgetWithText(TextButton, 'Edit'), findsNothing);

        await tester.pumpWidget(_wrap(_session(includeRead: false)));
        expect(find.text('Unavailable'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Edit'), findsNothing);

        await tester.pumpWidget(
          _wrap(
            _session(
              fieldReadStatus: VerificationStatus.none,
              readResult: const GameReadResult(
                status: GameReadStatus.none,
                fieldId: 'bolts',
              ),
            ),
          ),
        );
        expect(find.text('Unavailable'), findsOneWidget);
        expect(find.text('0'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class TrainerFieldsPanel keeps denied fields read-only', (
      tester,
    ) async {
      _setMinimumView(tester);
      final deniedStates = [
        _session(profileWriteStatus: VerificationStatus.none),
        _session(fieldWriteStatus: VerificationStatus.none),
        _session(confidence: GameIdentityConfidence.manuallySelected),
        _session(hasProcess: false),
        _session(hasMemoryBase: false),
        _session(omitMinimum: true),
        _session(omitMaximum: true),
      ];

      for (final state in deniedStates) {
        await tester.pumpWidget(_wrap(state));
        expect(find.text('Read-only'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Edit'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldsPanel shows empty and missing profiles', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_session(emptyProfile: true)));
      expect(
        find.text('No trainer fields are available for this profile.'),
        findsOneWidget,
      );

      await tester.pumpWidget(_wrap(TrainerSessionState()));
      expect(find.text('Bolts'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

void _setMinimumView(WidgetTester tester) {
  tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(
  TrainerSessionState session, {
  String? editingFieldId,
  ValueChanged<GameField>? onEditField,
  GameWriteResult Function(String fieldId, int value)? onApplyField,
  VoidCallback? onCancelEditing,
}) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(
    body: TrainerFieldsPanel(
      session: session,
      editingFieldId: editingFieldId,
      onEditField: onEditField ?? (_) {},
      onApplyField:
          onApplyField ??
          ((fieldId, value) => GameWriteResult(
            status: GameWriteStatus.none,
            fieldId: fieldId,
            requestedValue: value,
          )),
      onCancelEditing: onCancelEditing ?? () {},
    ),
  ),
);

TrainerSessionState _session({
  int? value = 17,
  GameReadResult? readResult,
  VerificationStatus profileReadStatus = VerificationStatus.verified,
  VerificationStatus profileWriteStatus = VerificationStatus.verified,
  VerificationStatus fieldReadStatus = VerificationStatus.verified,
  VerificationStatus fieldWriteStatus = VerificationStatus.verified,
  GameIdentityConfidence confidence = GameIdentityConfidence.confirmed,
  bool hasProcess = true,
  bool hasMemoryBase = true,
  bool omitMinimum = false,
  bool omitMaximum = false,
  bool includeSecondField = false,
  bool includeManyFields = false,
  bool includeRead = true,
  bool emptyProfile = false,
}) {
  final fields = <String, GameField>{};
  final reads = <String, GameReadResult>{};
  if (!emptyProfile) {
    fields['bolts'] = GameField(
      id: 'bolts',
      name: 'Bolts',
      guestOffset: 0,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: fieldReadStatus,
      writeStatus: fieldWriteStatus,
      minimumValue: omitMinimum ? null : 0,
      maximumValue: omitMaximum ? null : 4294967295,
    );
    if (includeRead) {
      reads['bolts'] =
          readResult ??
          GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'bolts',
            value: value,
          );
    }
  }
  if (includeSecondField) {
    fields['scrap'] = _field(id: 'scrap', name: 'Scrap', offset: 4, max: 100);
    reads['scrap'] = const GameReadResult(
      status: GameReadStatus.success,
      fieldId: 'scrap',
      value: 7,
    );
  }
  if (includeManyFields) {
    for (var index = 0; index < 12; index++) {
      final id = 'part-$index';
      fields[id] = _field(id: id, name: 'Part $index', offset: 8 + index * 4);
      reads[id] = GameReadResult(
        status: GameReadStatus.success,
        fieldId: id,
        value: index,
      );
    }
  }

  final profile = GameProfile(
    id: 'test-game',
    gameName: 'Test game',
    buildId: 'TEST',
    executable: 'test.self',
    readStatus: profileReadStatus,
    writeStatus: profileWriteStatus,
    fields: fields,
  );
  return TrainerSessionState(
    processIds: hasProcess ? const [123] : const [],
    selectedProcessId: hasProcess ? 123 : null,
    processMetadata: Rpcs3ProcessMetadata(
      executablePath: r'C:\RPCS3\rpcs3.exe',
      startedAtUtc: DateTime.utc(2026),
    ),
    detection: GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: hasProcess ? 123 : null,
      profile: profile,
      confidence: confidence,
      evidenceDescription: 'Test identity evidence.',
    ),
    memoryBase: hasMemoryBase ? 0x1000 : null,
    readResults: reads,
  );
}

GameField _field({
  required String id,
  required String name,
  required int offset,
  int max = 100,
}) => GameField(
  id: id,
  name: name,
  guestOffset: offset,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  readStatus: VerificationStatus.verified,
  writeStatus: VerificationStatus.verified,
  minimumValue: 0,
  maximumValue: max,
);

GameWriteResult _success(String fieldId, int value) => GameWriteResult(
  status: GameWriteStatus.success,
  fieldId: fieldId,
  requestedValue: value,
  readBackValue: value,
);
