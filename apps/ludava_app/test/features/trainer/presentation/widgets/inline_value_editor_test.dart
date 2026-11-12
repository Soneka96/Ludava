import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_style_preset.dart';
import 'package:ludava_app/shared/theme/ludava_style_presets.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_factory.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

InlineValueEditor _editor({
  GameField? field,
  int? currentValue = 17,
  GameWriteResult? writeResult,
  required GameWriteResult Function(int value) onApply,
  VoidCallback? onCancel,
  VoidCallback? onApplied,
  Key? key,
}) => InlineValueEditor(
  key: key,
  field: field ?? _field(maximumValue: 0xffffffff),
  currentValue: currentValue,
  writeResult: writeResult,
  onApply: onApply,
  onCancel: onCancel ?? () {},
  onApplied: onApplied ?? () {},
);

/// Wraps the editor in the shipped theme and a full-width test surface.
Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? LudavaTheme.graphiteAndTeal,
  home: Scaffold(
    body: Center(child: SizedBox(width: 480, child: child)),
  ),
);

/// Builds a test theme whose style preset supplies the requested focus width.
ThemeData _themeWithFocusedBorderWidth(double width) {
  final comfortable = LudavaStylePresets.comfortable;
  final style = LudavaStylePreset(
    fontFamily: comfortable.fontFamily,
    textTheme: comfortable.textTheme,
    controlRadius: comfortable.controlRadius,
    surfaceRadius: comfortable.surfaceRadius,
    buttonPadding: comfortable.buttonPadding,
    buttonMinimumSize: comfortable.buttonMinimumSize,
    inputPadding: comfortable.inputPadding,
    inputFocusedBorderWidth: width,
  );
  return LudavaThemeFactory.build(
    colors: GraphiteTealTheme.colors,
    style: style,
    brightness: GraphiteTealTheme.brightness,
  );
}

/// Creates a numeric trainer field with the requested inclusive range.
GameField _field({
  String id = 'credits',
  required int? maximumValue,
  int? minimumValue = 0,
  int guestOffset = 0,
}) => GameField(
  id: id,
  name: 'Credits',
  guestOffset: guestOffset,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  minimumValue: minimumValue,
  maximumValue: maximumValue,
);

/// Returns a successful fake write with a matching read-back value.
GameWriteResult _success(int value) => GameWriteResult(
  status: GameWriteStatus.success,
  fieldId: 'credits',
  requestedValue: value,
  readBackValue: value,
);

/// Finds the field input owned by the inline editor.
Finder get _inputFinder =>
    find.byKey(const ValueKey('inline-editor-input-credits'));

/// Reads the unsigned draft text without grouping separators.
String _editorText(WidgetTester tester, {String fieldId = 'credits'}) => tester
    .widget<TextField>(find.byKey(ValueKey('inline-editor-input-$fieldId')))
    .controller!
    .text;

void main() {
  group('Class InlineValueEditor draft and apply behavior', () {
    testWidgets(
      'Class InlineValueEditor uses supplied focused borders in normal and error states',
      (tester) async {
        const alternateWidth = 2.75;
        final alternateTheme = _themeWithFocusedBorderWidth(alternateWidth);
        await tester.pumpWidget(
          _wrap(
            _editor(
              field: _field(maximumValue: 50),
              currentValue: 10,
              onApply: (_) => const GameWriteResult(
                status: GameWriteStatus.invalidValue,
                fieldId: 'credits',
                requestedValue: 51,
              ),
            ),
            theme: alternateTheme,
          ),
        );

        await tester.tap(_inputFinder);
        await tester.pump();
        var decorator = tester.widget<InputDecorator>(
          find.descendant(
            of: _inputFinder,
            matching: find.byType(InputDecorator),
          ),
        );
        expect(decorator.isFocused, isTrue);
        var focusedBorder =
            decorator.decoration.focusedBorder! as OutlineInputBorder;
        expect(focusedBorder.borderSide.width, alternateWidth);
        expect(
          focusedBorder.borderSide.color,
          alternateTheme.extension<LudavaThemeTokens>()!.focus,
        );
        expect(tester.getSize(find.byType(InlineValueEditor)).height, 48);

        await tester.enterText(_inputFinder, '51');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();
        await tester.tap(_inputFinder);
        await tester.pump();
        decorator = tester.widget<InputDecorator>(
          find.descendant(
            of: _inputFinder,
            matching: find.byType(InputDecorator),
          ),
        );
        expect(decorator.isFocused, isTrue);
        final focusedErrorBorder =
            decorator.decoration.focusedErrorBorder! as OutlineInputBorder;
        expect(focusedErrorBorder.borderSide.width, alternateWidth);
        expect(
          focusedErrorBorder.borderSide.color,
          alternateTheme.colorScheme.error,
        );
        expect(tester.getSize(find.byType(InlineValueEditor)).height, 48);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor uses body typography from an alternate supplied theme',
      (tester) async {
        final alternateTheme = LudavaTheme.graphiteAndTeal.copyWith(
          textTheme: LudavaTheme.graphiteAndTeal.textTheme.copyWith(
            bodyMedium: LudavaTheme.graphiteAndTeal.textTheme.bodyMedium
                ?.copyWith(fontSize: 19),
          ),
        );
        await tester.pumpWidget(
          _wrap(_editor(onApply: _success), theme: alternateTheme),
        );

        expect(tester.widget<TextField>(_inputFinder).style?.fontSize, 19);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor renders fixed inline actions and draft',
      (tester) async {
        await tester.pumpWidget(_wrap(_editor(onApply: _success)));

        expect(_editorText(tester), '17');
        expect(find.byTooltip('Apply Credits'), findsOneWidget);
        expect(find.byTooltip('Cancel editing Credits'), findsOneWidget);
        expect(find.text('Current value: 17'), findsNothing);
        expect(find.text('Allowed:'), findsNothing);
        expect(find.text('Enter Apply'), findsNothing);
        expect(
          tester.getSize(find.byType(InlineValueEditor)).height,
          LudavaDimensions.minimumInteractiveTarget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor positions the initial caret after the value',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_editor(currentValue: 123, onApply: _success)),
        );
        final input = tester.widget<TextField>(_inputFinder);
        expect(_editorText(tester), '123');
        expect(
          input.controller!.selection,
          const TextSelection.collapsed(offset: 3),
        );
        await tester.tap(_inputFinder);
        await tester.pump();
        final focusedInput = tester.widget<TextField>(_inputFinder);
        expect(focusedInput.controller!.selection.extentOffset, 3);
        expect(focusedInput.controller!.selection.isCollapsed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor keeps maximum unsigned draft ungrouped',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_editor(currentValue: 4294967295, onApply: _success)),
        );

        expect(_editorText(tester), '4294967295');
        expect(find.text('4,294,967,295'), findsNothing);
      },
    );

    testWidgets(
      'Class InlineValueEditor preserves draft and cursor across same-session refresh',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        await tester.pumpWidget(
          _wrap(_editor(key: editorKey, currentValue: 123, onApply: _success)),
        );
        await tester.enterText(_inputFinder, '1234');
        await tester.pump();
        final controller = tester.widget<TextField>(_inputFinder).controller!;
        controller.selection = const TextSelection.collapsed(offset: 2);

        await tester.pumpWidget(
          _wrap(_editor(key: editorKey, currentValue: 456, onApply: _success)),
        );

        expect(_editorText(tester), '1234');
        expect(controller.selection, const TextSelection.collapsed(offset: 2));

        controller.selection = const TextSelection(
          baseOffset: 1,
          extentOffset: 3,
        );
        await tester.pumpWidget(
          _wrap(_editor(key: editorKey, currentValue: 789, onApply: _success)),
        );
        expect(
          controller.selection,
          const TextSelection(baseOffset: 1, extentOffset: 3),
        );
      },
    );

    testWidgets(
      'Class InlineValueEditor treats unchanged values as a neutral no-op',
      (tester) async {
        var writeCalls = 0;
        var appliedCalls = 0;
        var editing = true;
        await tester.pumpWidget(
          MaterialApp(
            theme: LudavaTheme.graphiteAndTeal,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => editing
                    ? Center(
                        child: SizedBox(
                          width: 480,
                          child: _editor(
                            currentValue: 123,
                            onApply: (value) {
                              writeCalls++;
                              return _success(value);
                            },
                            onApplied: () {
                              appliedCalls++;
                              setState(() => editing = false);
                            },
                          ),
                        ),
                      )
                    : const Text('Read-only value: 123'),
              ),
            ),
          ),
        );

        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(writeCalls, 0);
        expect(appliedCalls, 1);
        expect(find.text('Read-only value: 123'), findsOneWidget);
        expect(find.byType(InlineValueEditor), findsNothing);
        expect(find.byTooltip('No value was written.'), findsNothing);
        expect(find.byTooltip('Applied and verified: 123'), findsNothing);
      },
    );

    testWidgets(
      'Class InlineValueEditor completes unchanged draft after a failed refresh without writing',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        var writeCalls = 0;
        var appliedCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: 17,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        final initialSize = tester.getSize(find.byType(InlineValueEditor));

        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: null,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        expect(_editorText(tester), '17');
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(writeCalls, 0);
        expect(appliedCalls, 1);
        expect(find.byType(InlineValueEditor), findsOneWidget);
        expect(tester.getSize(find.byType(InlineValueEditor)), initialSize);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor completes untouched draft after a changed read without writing',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        var writeCalls = 0;
        var appliedCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: 17,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        final initialSize = tester.getSize(find.byType(InlineValueEditor));

        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: 25,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        expect(_editorText(tester), '17');
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(writeCalls, 0);
        expect(appliedCalls, 1);
        expect(find.byType(InlineValueEditor), findsOneWidget);
        expect(tester.getSize(find.byType(InlineValueEditor)), initialSize);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor does not write a draft restored to its starting value',
      (tester) async {
        var writeCalls = 0;
        var appliedCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
              currentValue: 17,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );

        await tester.enterText(_inputFinder, '25');
        await tester.pump();
        await tester.enterText(_inputFinder, '17');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(writeCalls, 0);
        expect(appliedCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor sends a changed draft after a failed refresh to the SDK callback',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        final requestedValues = <int>[];
        var appliedCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: 17,
              onApply: (value) {
                requestedValues.add(value);
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );

        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: null,
              onApply: (value) {
                requestedValues.add(value);
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        await tester.enterText(_inputFinder, '25');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(requestedValues, [25]);
        expect(appliedCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor writes a changed draft when a later read matches it',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        final requestedValues = <int>[];
        var appliedCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: 17,
              onApply: (value) {
                requestedValues.add(value);
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        await tester.enterText(_inputFinder, '25');
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: 25,
              onApply: (value) {
                requestedValues.add(value);
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(requestedValues, [25]);
        expect(appliedCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor applies once through the explicit check action',
      (tester) async {
        var writeCalls = 0;
        var appliedCalls = 0;
        int? requestedValue;
        await tester.pumpWidget(
          _wrap(
            _editor(
              onApply: (value) {
                writeCalls++;
                requestedValue = value;
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        await tester.enterText(_inputFinder, '42');
        await tester.pump();
        expect(writeCalls, 0);

        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(writeCalls, 1);
        expect(requestedValue, 42);
        expect(appliedCalls, 1);
        expect(find.text('Applied and verified: 42'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class InlineValueEditor applies once on Enter', (
      tester,
    ) async {
      var writeCalls = 0;
      var appliedCalls = 0;
      await tester.pumpWidget(
        _wrap(
          _editor(
            onApply: (value) {
              writeCalls++;
              return _success(value);
            },
            onApplied: () => appliedCalls++,
          ),
        ),
      );
      await tester.enterText(_inputFinder, '24');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(writeCalls, 1);
      expect(appliedCalls, 1);
      expect(find.text('Applied and verified: 24'), findsNothing);
    });

    testWidgets(
      'Class InlineValueEditor cancels with its close action or Escape',
      (tester) async {
        var writeCalls = 0;
        var cancelCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
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
        await tester.tap(find.byTooltip('Cancel editing Credits'));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(cancelCalls, 2);
        expect(writeCalls, 0);
      },
    );

    testWidgets(
      'Class InlineValueEditor coalesces Enter and check-button submissions',
      (tester) async {
        var writeCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
              onApply: (value) {
                writeCalls++;
                return GameWriteResult(
                  status: GameWriteStatus.writeFailed,
                  fieldId: 'credits',
                  requestedValue: value,
                );
              },
            ),
          ),
        );
        await tester.enterText(_inputFinder, '24');
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.check_rounded),
            )
            .onPressed!();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(writeCalls, 1);
        expect(_editorText(tester), '24');
        expect(find.byTooltip('The write failed.'), findsOneWidget);
      },
    );

    testWidgets(
      'Class InlineValueEditor validates numeric text without checking field bounds',
      (tester) async {
        final writeValues = <int>[];
        await tester.pumpWidget(
          _wrap(
            _editor(
              field: _field(maximumValue: 50),
              currentValue: 10,
              onApply: (value) {
                writeValues.add(value);
                return const GameWriteResult(
                  status: GameWriteStatus.invalidValue,
                  fieldId: 'credits',
                  requestedValue: 51,
                );
              },
            ),
          ),
        );
        await tester.enterText(_inputFinder, '51');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(writeValues, [51]);
        expect(_editorText(tester), '51');
        expect(
          find.byTooltip('The value is outside the allowed range.'),
          findsOneWidget,
        );
        expect(
          find.text('The value is outside the allowed range.'),
          findsNothing,
        );
        final input = tester.widget<TextField>(_inputFinder);
        final tokens = LudavaTheme.graphiteAndTeal
            .extension<LudavaThemeTokens>()!;
        final border = input.decoration!.enabledBorder! as OutlineInputBorder;
        expect(
          border.borderSide.color,
          LudavaTheme.graphiteAndTeal.colorScheme.error,
        );
        expect(tokens.error, LudavaTheme.graphiteAndTeal.colorScheme.error);
        await tester.enterText(_inputFinder, '');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();
        expect(writeValues, [51]);
        expect(find.byTooltip('Enter a whole number.'), findsOneWidget);
        expect(tester.getSize(find.byType(InlineValueEditor)).height, 48);
      },
    );

    testWidgets(
      'Class InlineValueEditor retains attempted text after SDK failure',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _editor(
              onApply: (value) => GameWriteResult(
                status: GameWriteStatus.writeFailed,
                fieldId: 'credits',
                requestedValue: value,
                errorCode: 5,
              ),
            ),
          ),
        );
        await tester.enterText(_inputFinder, '42');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(_editorText(tester), '42');
        expect(
          find.byTooltip('The write failed with system error 5.'),
          findsOneWidget,
        );
        expect(
          find.text('The write failed with system error 5.'),
          findsNothing,
        );
        expect(find.text('Applied and verified: 42'), findsNothing);
        expect(tester.getSize(find.byType(InlineValueEditor)).height, 48);
      },
    );

    testWidgets(
      'Class InlineValueEditor retains the draft when an SDK call throws',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _editor(
              onApply: (_) => throw StateError('Memory write could not start.'),
            ),
          ),
        );
        await tester.enterText(_inputFinder, '42');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(_editorText(tester), '42');
        expect(
          find.byTooltip(
            'Write failed: Bad state: Memory write could not start.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Write failed: Bad state: Memory write could not start.'),
          findsNothing,
        );
        expect(tester.getSize(find.byType(InlineValueEditor)).height, 48);
      },
    );

    testWidgets(
      'Class InlineValueEditor explains typed SDK failure outcomes in its tooltip',
      (tester) async {
        final failureCases = <(GameWriteStatus, String, int?)>[
          (GameWriteStatus.none, 'No value was written.', null),
          (
            GameWriteStatus.unsupportedProfile,
            'The current game identity or session is unavailable.',
            null,
          ),
          (
            GameWriteStatus.confirmationRequired,
            'The write was not authorized.',
            null,
          ),
          (
            GameWriteStatus.unsupportedField,
            'The selected field is not registered in the current profile.',
            null,
          ),
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
            'The SDK returned an invalid result.',
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
          final expectedTooltip = failure.$2;
          final errorCode = failure.$3;
          await tester.pumpWidget(
            _wrap(
              _editor(
                key: ValueKey('failure-${status.name}'),
                onApply: (value) => GameWriteResult(
                  status: status,
                  fieldId: 'credits',
                  requestedValue: value,
                  readBackValue: status == GameWriteStatus.readBackMismatch
                      ? 41
                      : null,
                  errorCode: errorCode,
                ),
              ),
            ),
          );
          await tester.enterText(_inputFinder, '42');
          await tester.pump();
          await tester.tap(find.byTooltip('Apply Credits'));
          await tester.pump();

          expect(find.byTooltip(expectedTooltip), findsOneWidget);
          expect(find.text(expectedTooltip), findsNothing);
          expect(_editorText(tester), '42');
          expect(
            tester.getSize(find.byType(InlineValueEditor)).height,
            LudavaDimensions.minimumInteractiveTarget,
          );
        }
      },
    );

    testWidgets('Class InlineValueEditor accepts the inclusive field bounds', (
      tester,
    ) async {
      final appliedValues = <int>[];
      for (final value in const [10, 20]) {
        await tester.pumpWidget(
          _wrap(
            _editor(
              field: _field(minimumValue: 10, maximumValue: 20),
              currentValue: 15,
              onApply: (requested) {
                appliedValues.add(requested);
                return GameWriteResult(
                  status: GameWriteStatus.writeFailed,
                  fieldId: 'credits',
                  requestedValue: requested,
                );
              },
            ),
          ),
        );
        await tester.enterText(_inputFinder, '$value');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();
      }

      expect(appliedValues, [10, 20]);
    });

    testWidgets(
      'Class InlineValueEditor submits values when field bounds are absent',
      (tester) async {
        final appliedValues = <int>[];
        await tester.pumpWidget(
          _wrap(
            _editor(
              field: _field(minimumValue: null, maximumValue: null),
              currentValue: 17,
              onApply: (value) {
                appliedValues.add(value);
                return const GameWriteResult(
                  status: GameWriteStatus.invalidValue,
                  fieldId: 'credits',
                  requestedValue: 44,
                );
              },
            ),
          ),
        );
        await tester.enterText(_inputFinder, '44');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(appliedValues, [44]);
        expect(
          find.byTooltip('The value is outside the allowed range.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Class InlineValueEditor resets its local draft when the field changes',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              field: _field(id: 'credits', maximumValue: 20),
              currentValue: 17,
              onApply: _success,
            ),
          ),
        );
        await tester.enterText(_inputFinder, '42');
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              field: _field(id: 'scrap', maximumValue: 100),
              currentValue: 5,
              onApply: _success,
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('inline-editor-input-scrap')),
          findsOneWidget,
        );
        expect(_editorText(tester, fieldId: 'scrap'), '5');
      },
    );

    testWidgets(
      'Class InlineValueEditor resets its starting value when a same-ID mapping changes',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        var writeCalls = 0;
        var appliedCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              field: _field(maximumValue: 20, guestOffset: 0x1000),
              currentValue: 17,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        await tester.enterText(_inputFinder, '25');
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              field: _field(maximumValue: 20, guestOffset: 0x2000),
              currentValue: 5,
              onApply: (value) {
                writeCalls++;
                return _success(value);
              },
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        expect(_editorText(tester), '5');
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(writeCalls, 0);
        expect(appliedCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class InlineValueEditor ignores a write result for another field',
      (tester) async {
        const editorKey = ValueKey('inline-editor');
        var appliedCalls = 0;
        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: 17,
              onApply: _success,
              onApplied: () => appliedCalls++,
            ),
          ),
        );
        await tester.enterText(_inputFinder, '42');
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            _editor(
              key: editorKey,
              currentValue: 17,
              writeResult: const GameWriteResult(
                status: GameWriteStatus.readBackMismatch,
                fieldId: 'scrap',
                requestedValue: 42,
                readBackValue: 41,
              ),
              onApply: _success,
              onApplied: () => appliedCalls++,
            ),
          ),
        );

        expect(_editorText(tester), '42');
        expect(
          find.byTooltip('The written value did not match the verified value.'),
          findsNothing,
        );
        expect(appliedCalls, 0);
      },
    );
  });
}
