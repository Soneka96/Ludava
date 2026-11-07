import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/inline_value_editor.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class InlineValueEditor draft and apply behavior', () {
    testWidgets('Class InlineValueEditor starts from the valid current value', (
      tester,
    ) async {
      var writeCalls = 0;

      await tester.pumpWidget(
        _wrap(
          InlineValueEditor(
            field: _field(maximumValue: 100),
            currentValue: 0,
            writeResult: null,
            onApply: (value) {
              writeCalls++;
              return _success(value);
            },
            onCancel: () {},
          ),
        ),
      );

      expect(_editorText(tester), '0');
      expect(find.text('Current value: 0'), findsOneWidget);
      expect(writeCalls, 0);
    });

    testWidgets('Class InlineValueEditor applies only after explicit Apply', (
      tester,
    ) async {
      var writeCalls = 0;
      int? requestedValue;

      await tester.pumpWidget(
        _wrap(
          InlineValueEditor(
            field: _field(maximumValue: 100),
            currentValue: 0,
            writeResult: null,
            onApply: (value) {
              writeCalls++;
              requestedValue = value;
              return _success(value);
            },
            onCancel: () {},
          ),
        ),
      );

      await tester.enterText(_inputFinder, '42');
      await tester.pump();
      expect(_editorText(tester), '42');
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply'))
            .onPressed,
        isNotNull,
      );
      expect(writeCalls, 0);
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pump();

      expect(writeCalls, 1);
      expect(requestedValue, 42);
      expect(find.text('Applied and verified: 42'), findsOneWidget);
      expect(_editorText(tester), '42');
    });

    testWidgets('Class InlineValueEditor cancels without invoking the writer', (
      tester,
    ) async {
      var writeCalls = 0;
      var cancelCalls = 0;

      await tester.pumpWidget(
        _wrap(
          InlineValueEditor(
            field: _field(maximumValue: 100),
            currentValue: 17,
            writeResult: null,
            onApply: (value) {
              writeCalls++;
              return _success(value);
            },
            onCancel: () => cancelCalls++,
          ),
        ),
      );

      await tester.enterText(_inputFinder, '33');
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();

      expect(cancelCalls, 1);
      expect(writeCalls, 0);
    });

    testWidgets(
      'Class InlineValueEditor rejects empty and out-of-range drafts',
      (tester) async {
        var writeCalls = 0;

        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              field: _field(maximumValue: 50),
              currentValue: 10,
              writeResult: null,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onCancel: () {},
            ),
          ),
        );

        await tester.enterText(_inputFinder, '51');
        await tester.pump();
        expect(_editorText(tester), '51');
        expect(find.text('Enter a value from 0 to 50.'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply'))
              .onPressed,
          isNull,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
        await tester.pump();
        expect(writeCalls, 0);

        await tester.enterText(_inputFinder, '');
        await tester.pump();
        expect(find.text('Enter a whole number.'), findsOneWidget);
        expect(writeCalls, 0);
      },
    );

    testWidgets('Class InlineValueEditor accepts the inclusive field bounds', (
      tester,
    ) async {
      final appliedValues = <int>[];

      for (final boundary in const [10, 20]) {
        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              field: _field(minimumValue: 10, maximumValue: 20),
              currentValue: 10,
              writeResult: null,
              onApply: (value) {
                appliedValues.add(value);
                return _success(value);
              },
              onCancel: () {},
            ),
          ),
        );

        await tester.enterText(_inputFinder, '$boundary');
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply'))
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
        await tester.pump();
        expect(find.text('Applied and verified: $boundary'), findsOneWidget);
      }

      expect(appliedValues, [10, 20]);
    });

    testWidgets(
      'Class InlineValueEditor blocks writes without a current value',
      (tester) async {
        var writeCalls = 0;

        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              field: _field(maximumValue: 50),
              currentValue: null,
              writeResult: null,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onCancel: () {},
            ),
          ),
        );

        expect(_editorText(tester), '');
        expect(
          find.text(
            'The current value is unavailable. Refresh before editing.',
          ),
          findsOneWidget,
        );
        await tester.enterText(_inputFinder, '22');
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
        await tester.pump();

        expect(writeCalls, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(writeCalls, 0);
      },
    );

    testWidgets(
      'Class InlineValueEditor applies on Enter and cancels on Escape',
      (tester) async {
        var writeCalls = 0;
        var cancelCalls = 0;

        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              field: _field(maximumValue: 100),
              currentValue: 4,
              writeResult: null,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onCancel: () => cancelCalls++,
            ),
          ),
        );

        await tester.enterText(_inputFinder, '24');
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(writeCalls, 1);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(cancelCalls, 1);
        expect(writeCalls, 1);
      },
    );

    testWidgets('Class InlineValueEditor keeps Tab navigation on its actions', (
      tester,
    ) async {
      var writeCalls = 0;
      var cancelCalls = 0;

      await tester.pumpWidget(
        _wrap(
          InlineValueEditor(
            field: _field(maximumValue: 100),
            currentValue: 4,
            writeResult: null,
            onApply: (value) {
              writeCalls++;
              return _success(value);
            },
            onCancel: () => cancelCalls++,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(cancelCalls, 1);
      expect(writeCalls, 0);
    });

    testWidgets(
      'Class InlineValueEditor explains SDK write failures without success',
      (tester) async {
        final failureCases = <(GameWriteStatus, String, int?)>[
          (GameWriteStatus.none, 'No value was written.', null),
          (
            GameWriteStatus.unsupportedProfile,
            'This profile is read-only.',
            null,
          ),
          (
            GameWriteStatus.confirmationRequired,
            'The write was not authorized.',
            null,
          ),
          (GameWriteStatus.unsupportedField, 'This field is read-only.', null),
          (
            GameWriteStatus.invalidValue,
            'The value is outside the allowed range.',
            null,
          ),
          (
            GameWriteStatus.invalidMapping,
            'The field mapping is unavailable.',
            null,
          ),
          (
            GameWriteStatus.preliminaryReadFailed,
            'The current value could not be checked. No write was made.',
            null,
          ),
          (
            GameWriteStatus.writeFailed,
            'The write failed with system error 5.',
            5,
          ),
          (GameWriteStatus.incompleteWrite, 'The write was incomplete.', null),
          (
            GameWriteStatus.readBackFailed,
            'The written value could not be verified.',
            null,
          ),
          (
            GameWriteStatus.readBackMismatch,
            'The written value did not match the verified value.',
            null,
          ),
          (
            GameWriteStatus.invalidWriteResult,
            'The SDK returned an invalid write result.',
            null,
          ),
          (
            GameWriteStatus.success,
            'The written value could not be verified.',
            null,
          ),
        ];

        for (final failure in failureCases) {
          final status = failure.$1;
          final expectedMessage = failure.$2;
          final errorCode = failure.$3;
          await tester.pumpWidget(
            _wrap(
              InlineValueEditor(
                key: ValueKey('failure-${status.name}'),
                field: _field(maximumValue: 100),
                currentValue: 17,
                writeResult: null,
                onApply: (value) => GameWriteResult(
                  status: status,
                  fieldId: 'bolts',
                  requestedValue: value,
                  readBackValue: status == GameWriteStatus.readBackMismatch
                      ? 41
                      : null,
                  errorCode: errorCode,
                ),
                onCancel: () {},
              ),
            ),
          );

          await tester.enterText(_inputFinder, '42');
          await tester.pump();
          await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
          await tester.pump();

          expect(find.text(expectedMessage), findsOneWidget);
          expect(find.text('Applied and verified: 42'), findsNothing);
          expect(_editorText(tester), '42');
        }
      },
    );

    testWidgets(
      'Class InlineValueEditor refreshes the draft from a new value',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              key: const ValueKey('inline-editor'),
              field: _field(maximumValue: 100),
              currentValue: 17,
              writeResult: null,
              onApply: _success,
              onCancel: () {},
            ),
          ),
        );
        expect(_editorText(tester), '17');

        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              key: const ValueKey('inline-editor'),
              field: _field(maximumValue: 100),
              currentValue: 29,
              writeResult: null,
              onApply: _success,
              onCancel: () {},
            ),
          ),
        );

        expect(_editorText(tester), '29');
      },
    );

    testWidgets(
      'Class InlineValueEditor reacts only to its own SDK write result',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              key: editorKey,
              field: _field(maximumValue: 100),
              currentValue: 17,
              writeResult: null,
              onApply: _success,
              onCancel: () {},
            ),
          ),
        );
        await tester.enterText(_inputFinder, '28');
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              key: editorKey,
              field: _field(maximumValue: 100),
              currentValue: 17,
              writeResult: const GameWriteResult(
                status: GameWriteStatus.success,
                fieldId: 'scrap',
                requestedValue: 28,
                readBackValue: 28,
              ),
              onApply: _success,
              onCancel: () {},
            ),
          ),
        );
        expect(find.text('Applied and verified: 28'), findsNothing);
        expect(_editorText(tester), '28');

        await tester.pumpWidget(
          _wrap(
            InlineValueEditor(
              key: editorKey,
              field: _field(maximumValue: 100),
              currentValue: 28,
              writeResult: const GameWriteResult(
                status: GameWriteStatus.success,
                fieldId: 'bolts',
                requestedValue: 28,
                readBackValue: 28,
              ),
              onApply: _success,
              onCancel: () {},
            ),
          ),
        );

        expect(find.text('Applied and verified: 28'), findsOneWidget);
        expect(_editorText(tester), '28');
      },
    );
  });
}

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

GameField _field({required int maximumValue, int minimumValue = 0}) =>
    GameField(
      id: 'bolts',
      name: 'Bolts',
      guestOffset: 0,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.verified,
      writeStatus: VerificationStatus.verified,
      minimumValue: minimumValue,
      maximumValue: maximumValue,
    );

GameWriteResult _success(int value) => GameWriteResult(
  status: GameWriteStatus.success,
  fieldId: 'bolts',
  requestedValue: value,
  readBackValue: value,
);

Finder get _inputFinder =>
    find.byKey(const ValueKey('inline-editor-input-bolts'));

String _editorText(WidgetTester tester) =>
    tester.widget<TextField>(_inputFinder).controller!.text;
