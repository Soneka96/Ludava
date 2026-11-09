import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void _setMinimumView(WidgetTester tester) {
  _setViewSize(tester, LudavaDimensions.minimumWindowSize);
}

/// Sets a logical-size test surface at device scale one.
void _setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
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
  VerificationStatus fieldWriteStatus = VerificationStatus.verified,
  bool includeSecondField = false,
  bool includeManyFields = false,
  bool emptyProfile = false,
  GameWriteResult? lastWriteResult,
}) {
  final fields = <String, GameField>{};
  final reads = <String, GameReadResult>{};
  if (!emptyProfile) {
    fields['credits'] = GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.verified,
      writeStatus: fieldWriteStatus,
      minimumValue: 0,
      maximumValue: 4294967295,
    );
    reads['credits'] = GameReadResult(
      status: GameReadStatus.success,
      fieldId: 'credits',
      value: value,
    );
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
    readStatus: VerificationStatus.verified,
    writeStatus: VerificationStatus.verified,
    fields: fields,
  );
  return TrainerSessionState(
    processIds: const [123],
    selectedProcessId: 123,
    processMetadata: Rpcs3ProcessMetadata(
      executablePath: r'C:\RPCS3\rpcs3.exe',
      startedAtUtc: DateTime.utc(2026),
    ),
    detection: GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: 123,
      profile: profile,
      confidence: GameIdentityConfidence.confirmed,
      evidenceDescription: 'Test identity evidence.',
    ),
    memoryBase: 0x1000,
    readResults: reads,
    lastWriteResult: lastWriteResult,
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

void main() {
  group('Class TrainerFieldsPanel vertical field behavior', () {
    testWidgets('Class TrainerFieldsPanel renders profile fields vertically', (
      tester,
    ) async {
      _setMinimumView(tester);

      await tester.pumpWidget(
        _wrap(_session(value: 0, includeSecondField: true)),
      );

      final credits = find.byKey(const ValueKey('trainer-field-row-credits'));
      final scrap = find.byKey(const ValueKey('trainer-field-row-scrap'));
      expect(find.byType(ListView), findsOneWidget);
      expect(credits, findsOneWidget);
      expect(scrap, findsOneWidget);
      expect(
        tester.getTopLeft(scrap).dy,
        greaterThan(tester.getTopLeft(credits).dy),
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
      'Class TrainerFieldsPanel preserves row geometry in normal edit and error states',
      (tester) async {
        for (final size in const [Size(520, 360), Size(480, 340)]) {
          _setViewSize(tester, size);
          await tester.pumpWidget(
            _wrap(_session(value: 17, includeSecondField: true)),
          );
          final creditsRow = find.byKey(
            const ValueKey('trainer-field-row-credits'),
          );
          final scrapRow = find.byKey(
            const ValueKey('trainer-field-row-scrap'),
          );
          final normalCreditsRect = tester.getRect(creditsRow);
          final normalScrapRect = tester.getRect(scrapRow);
          expect(
            normalCreditsRect.height,
            LudavaDimensions.minimumInteractiveTarget,
          );

          await tester.pumpWidget(
            _wrap(
              _session(value: 17, includeSecondField: true),
              editingFieldId: 'credits',
            ),
          );
          expect(tester.getRect(creditsRow), normalCreditsRect);
          expect(tester.getRect(scrapRow), normalScrapRect);

          const failedWrite = GameWriteResult(
            status: GameWriteStatus.writeFailed,
            fieldId: 'credits',
            requestedValue: 42,
          );
          await tester.pumpWidget(
            _wrap(
              _session(
                value: 17,
                includeSecondField: true,
                lastWriteResult: failedWrite,
              ),
              editingFieldId: 'credits',
            ),
          );
          expect(find.byTooltip('The write failed.'), findsOneWidget);
          expect(tester.getRect(creditsRow), normalCreditsRect);
          expect(tester.getRect(scrapRow), normalScrapRect);

          await tester.pumpWidget(
            _wrap(_session(value: 18, includeSecondField: true)),
          );
          expect(
            find.byKey(const ValueKey('inline-editor-input-credits')),
            findsNothing,
          );
          expect(tester.getRect(creditsRow), normalCreditsRect);
          expect(tester.getRect(scrapRow), normalScrapRect);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('Class TrainerFieldsPanel forwards field editing callbacks', (
      tester,
    ) async {
      _setMinimumView(tester);
      GameField? editedField;
      String? appliedFieldId;
      int? appliedValue;
      var cancelCalls = 0;

      await tester.pumpWidget(
        _wrap(
          _session(value: 17, includeSecondField: true),
          onEditField: (field) => editedField = field,
        ),
      );

      await tester.tap(find.byTooltip('Edit Credits'));
      expect(editedField?.id, 'credits');

      await tester.pumpWidget(
        _wrap(
          _session(value: 17, includeSecondField: true),
          editingFieldId: 'scrap',
          onApplyField: (fieldId, value) {
            appliedFieldId = fieldId;
            appliedValue = value;
            return GameWriteResult(
              status: GameWriteStatus.success,
              fieldId: fieldId,
              requestedValue: value,
              readBackValue: value,
            );
          },
          onCancelEditing: () => cancelCalls++,
        ),
      );
      final editor = tester.widget<InlineValueEditor>(
        find.byType(InlineValueEditor),
      );
      expect(editor.onApply(42).status, GameWriteStatus.success);
      editor.onCancel();

      expect(appliedFieldId, 'scrap');
      expect(appliedValue, 42);
      expect(cancelCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldsPanel reflects approved and denied edit eligibility',
      (tester) async {
        _setMinimumView(tester);
        await tester.pumpWidget(_wrap(_session(value: 17)));
        expect(find.byTooltip('Edit Credits'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(_session(value: 17), editingFieldId: 'credits'),
        );
        expect(
          find.byKey(const ValueKey('inline-editor-input-credits')),
          findsOneWidget,
        );

        await tester.pumpWidget(
          _wrap(
            _session(value: 17, fieldWriteStatus: VerificationStatus.none),
            editingFieldId: 'credits',
          ),
        );

        expect(
          find.byKey(const ValueKey('inline-editor-input-credits')),
          findsNothing,
        );
        expect(find.byTooltip('Edit Credits'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class TrainerFieldsPanel shows empty and missing profiles', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_session(emptyProfile: true)));
      expect(
        find.text('No trainer fields are available for this profile.'),
        findsOneWidget,
      );

      await tester.pumpWidget(_wrap(TrainerSessionState()));
      expect(find.text('Credits'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
