import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/value_editor/presentation/nocterm/trainer_value_editor_component.dart';
import 'package:nocterm/nocterm.dart'
    show
        BuildContext,
        Component,
        Size,
        State,
        StatefulComponent,
        TextEditingController,
        TextField,
        TextSelection;
import 'package:nocterm/nocterm_test.dart'
    show
        KeyboardEvent,
        LogicalKey,
        ModifierKeys,
        NoctermTester,
        containsText,
        testNocterm;
import 'package:test/test.dart';

TrainerValueEditorComponent _editor({
  GameField? field,
  int? currentValue = 123,
  required GameWriteResult Function(int value) onApply,
  void Function()? onApplied,
  void Function()? onCancel,
}) => TrainerValueEditorComponent(
  field: field ?? _field(),
  currentValue: currentValue,
  onApply: onApply,
  onApplied: onApplied,
  onCancel: onCancel ?? () {},
);

TextEditingController _controller(NoctermTester tester) =>
    tester.findAllComponents<TextField>().single.controller!;

Future<void> _replaceAll(NoctermTester tester, String text) async {
  await tester.sendKeyEvent(
    const KeyboardEvent(
      logicalKey: LogicalKey.keyA,
      modifiers: ModifierKeys(ctrl: true),
    ),
  );
  if (text.isEmpty) {
    await tester.sendBackspace();
  } else {
    await tester.enterText(text);
  }
}

GameField _field({
  bool readEnabled = true,
  bool writeEnabled = true,
  int? minimumValue = 0,
  int? maximumValue = 4294967295,
}) => GameField(
  id: 'credits',
  name: 'Credits',
  guestOffset: 0x1000,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  readStatus:
      readEnabled ? VerificationStatus.verified : VerificationStatus.none,
  writeStatus:
      writeEnabled
          ? VerificationStatus.researchConfirmed
          : VerificationStatus.none,
  minimumValue: minimumValue,
  maximumValue: maximumValue,
);

class _EditorHost extends StatefulComponent {
  final GameField field;
  final int? currentValue;
  final GameWriteResult Function(int value) onApply;

  const _EditorHost({
    required this.field,
    required this.currentValue,
    required this.onApply,
  });

  @override
  State<_EditorHost> createState() => _EditorHostState();
}

class _EditorHostState extends State<_EditorHost> {
  late GameField _field = component.field;
  late int? _currentValue = component.currentValue;

  void updateCurrentValue(int? value) {
    setState(() => _currentValue = value);
  }

  void updateField(GameField field) {
    setState(() => _field = field);
  }

  @override
  Component build(BuildContext context) => TrainerValueEditorComponent(
    field: _field,
    currentValue: _currentValue,
    onApply: component.onApply,
    onCancel: () {},
  );
}

GameWriteResult _success(int value) => GameWriteResult(
  status: GameWriteStatus.success,
  fieldId: 'credits',
  requestedValue: value,
  readBackValue: value,
);

void main() {
  group('Class TrainerValueEditorComponent editing behavior', () {
    test(
      'Class TrainerValueEditorComponent calls onApplied after verified success',
      () async {
        await testNocterm('successful apply callback', (tester) async {
          var applied = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (value) => _success(value),
              onApplied: () => applied++,
            ),
          );
          await _replaceAll(tester, '124');
          await tester.sendEnter();

          expect(applied, 1);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent does not call onApplied after a failed write',
      () async {
        await testNocterm('failed apply callback', (tester) async {
          var applied = 0;
          await tester.pumpComponent(
            _editor(
              onApply:
                  (value) => GameWriteResult(
                    status: GameWriteStatus.readBackMismatch,
                    fieldId: 'credits',
                    requestedValue: value,
                    readBackValue: value + 1,
                  ),
              onApplied: () => applied++,
            ),
          );
          await _replaceAll(tester, '124');
          await tester.sendEnter();

          expect(applied, 0);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent prefills an unselected cursor at the end',
      () async {
        await testNocterm('initial editor cursor', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(1234)));
          final controller = _controller(tester);

          expect(controller.text, '123');
          expect(controller.selection.isCollapsed, isTrue);
          expect(controller.selection.extentOffset, 3);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent groups display values but not editor text',
      () async {
        await testNocterm('grouped current value', (tester) async {
          await tester.pumpComponent(
            _editor(currentValue: 244866, onApply: (_) => _success(244867)),
          );

          expect(_controller(tester).text, '244866');
          expect(tester.terminalState, containsText('Current value: 244,866'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent uses Nocterm insertion at the end',
      () async {
        await testNocterm('append a digit', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(1230)));

          await tester.enterText('0');

          expect(_controller(tester).text, '1230');
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent handles Home, Delete, and insertion',
      () async {
        await testNocterm('home delete insert', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(323)));

          await tester.sendKey(LogicalKey.home);
          await tester.sendDelete();
          await tester.enterText('3');

          expect(_controller(tester).text, '323');
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent handles Backspace and insertion',
      () async {
        await testNocterm('backspace and insert', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(120)));

          await tester.sendBackspace();
          await tester.enterText('0');

          expect(_controller(tester).text, '120');
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent replaces selected text with Ctrl+A',
      () async {
        await testNocterm('replace all text', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(999)));

          await tester.sendKeyEvent(
            const KeyboardEvent(
              logicalKey: LogicalKey.keyA,
              modifiers: ModifierKeys(ctrl: true),
            ),
          );
          expect(_controller(tester).selection.isCollapsed, isFalse);
          await tester.enterText('999');

          expect(_controller(tester).text, '999');
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent moves the cursor and inserts in the middle',
      () async {
        await testNocterm('middle insertion and navigation', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(1293)));

          await tester.sendArrowLeft();
          await tester.enterText('9');
          expect(_controller(tester).text, '1293');
          await tester.sendKey(LogicalKey.home);
          expect(_controller(tester).selection.extentOffset, 0);
          await tester.sendKey(LogicalKey.end);
          expect(_controller(tester).selection.extentOffset, 4);
          await tester.sendArrowLeft();
          await tester.sendArrowRight();
          expect(_controller(tester).selection.extentOffset, 4);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent leaves text unchanged when Delete is at the end',
      () async {
        await testNocterm('Delete at end', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(123)));

          await tester.sendDelete();

          expect(_controller(tester).text, '123');
          expect(_controller(tester).selection.extentOffset, 3);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent lets Nocterm delete selected text',
      () async {
        await testNocterm('Delete selection', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(23)));
          final controller = _controller(tester);
          controller.selection = const TextSelection(
            baseOffset: 0,
            extentOffset: 1,
          );

          await tester.sendDelete();

          expect(controller.text, '23');
          expect(controller.selection.extentOffset, 0);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent deletes a multi-code-unit character',
      () async {
        await testNocterm('Delete Unicode character', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(123)));
          final controller =
              _controller(tester)
                ..text = '1💰23'
                ..selection = const TextSelection.collapsed(offset: 1);

          await tester.sendDelete();

          expect(controller.text, '123');
          expect(controller.selection.extentOffset, 1);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent applies a changed value immediately',
      () async {
        await testNocterm('apply a changed value', (tester) async {
          final appliedValues = <int>[];
          await tester.pumpComponent(
            _editor(
              onApply: (value) {
                appliedValues.add(value);
                return _success(value);
              },
            ),
          );
          await tester.enterText('0');
          await tester.sendEnter();

          expect(appliedValues, [1230]);
          expect(tester.terminalState, containsText('Verified value: 1,230'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent reports a read-back mismatch as failure',
      () async {
        await testNocterm('failed read-back', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (value) {
                applyCount++;
                return GameWriteResult(
                  status: GameWriteStatus.readBackMismatch,
                  fieldId: 'credits',
                  requestedValue: value,
                  readBackValue: 99,
                );
              },
            ),
          );
          await tester.enterText('4');
          await tester.sendEnter();

          expect(applyCount, 1);
          expect(
            tester.terminalState,
            containsText('written value did not verify'),
          );
          expect(tester.terminalState, isNot(containsText('Verified value')));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent maps every write status to feedback',
      () async {
        await testNocterm('write status feedback', (tester) async {
          const feedbackByStatus = <GameWriteStatus, String>{
            GameWriteStatus.none: 'No value was applied.',
            GameWriteStatus.unsupportedProfile:
                'This field is not approved for writing.',
            GameWriteStatus.confirmationRequired:
                'The write was not authorized.',
            GameWriteStatus.unsupportedField:
                'This field is not approved for writing.',
            GameWriteStatus.invalidValue:
                'The value is outside the allowed range.',
            GameWriteStatus.invalidMapping: 'The field address is unavailable.',
            GameWriteStatus.preliminaryReadFailed:
                'The current value could not be checked. No write was made.',
            GameWriteStatus.writeFailed: 'The write failed.',
            GameWriteStatus.incompleteWrite: 'The write was incomplete.',
            GameWriteStatus.readBackFailed:
                'The written value could not be verified.',
            GameWriteStatus.readBackMismatch:
                'The written value did not verify.',
            GameWriteStatus.invalidWriteResult: 'The write result was invalid.',
            GameWriteStatus.success: 'The written value could not be verified.',
          };

          var currentValue = 100;
          for (final entry in feedbackByStatus.entries) {
            await tester.pumpComponent(
              _editor(
                currentValue: currentValue,
                onApply:
                    (value) => GameWriteResult(
                      status: entry.key,
                      fieldId: 'credits',
                      requestedValue: value,
                      readBackValue:
                          entry.key == GameWriteStatus.readBackMismatch
                              ? value - 1
                              : null,
                    ),
              ),
            );
            await tester.enterText('4');
            await tester.sendEnter();

            expect(tester.terminalState, containsText(entry.value));
            currentValue++;
          }
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent handles apply callback failures',
      () async {
        await testNocterm('writer exception', (tester) async {
          await tester.pumpComponent(
            _editor(onApply: (_) => throw StateError('writer unavailable')),
          );
          await tester.enterText('4');
          await tester.sendEnter();

          expect(tester.terminalState, containsText('writer unavailable'));
          expect(tester.terminalState, isNot(containsText('Verified value')));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent allows another apply after editing a failed value',
      () async {
        await testNocterm('retry after a failed write', (tester) async {
          final appliedValues = <int>[];
          await tester.pumpComponent(
            _editor(
              onApply: (value) {
                appliedValues.add(value);
                if (appliedValues.length == 1) {
                  return GameWriteResult(
                    status: GameWriteStatus.readBackMismatch,
                    fieldId: 'credits',
                    requestedValue: value,
                    readBackValue: value - 1,
                  );
                }
                return _success(value);
              },
            ),
          );
          await tester.enterText('4');
          await tester.sendEnter();
          expect(
            tester.terminalState,
            containsText('written value did not verify'),
          );

          await _replaceAll(tester, '1235');
          await tester.sendEnter();

          expect(appliedValues, [1234, 1235]);
          expect(tester.terminalState, containsText('Verified value: 1,235'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent does not apply an unchanged value',
      () async {
        await testNocterm('unchanged value', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (_) {
                applyCount++;
                return _success(123);
              },
            ),
          );

          await tester.sendEnter();

          expect(applyCount, 0);
          expect(tester.terminalState, containsText('The value is unchanged.'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent does not apply twice for rapid Enter',
      () async {
        await testNocterm('repeated Enter', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (value) {
                applyCount++;
                return _success(value);
              },
            ),
          );
          await tester.enterText('4');

          await tester.sendEnter();
          await tester.sendEnter();

          expect(applyCount, 1);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent clears validation feedback after editing',
      () async {
        await testNocterm('correct invalid input', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (value) {
                applyCount++;
                return _success(value);
              },
            ),
          );
          await tester.enterText('x');
          await tester.sendEnter();
          expect(tester.terminalState, containsText('Enter digits only.'));

          await _replaceAll(tester, '124');
          expect(
            tester.terminalState,
            isNot(containsText('Enter digits only.')),
          );
          await tester.sendEnter();

          expect(applyCount, 1);
          expect(tester.terminalState, containsText('Verified value: 124'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent cancels without applying edited text',
      () async {
        await testNocterm('cancel edit', (tester) async {
          var applyCount = 0;
          var cancelCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (_) {
                applyCount++;
                return _success(1234);
              },
              onCancel: () => cancelCount++,
            ),
          );
          await tester.enterText('4');
          await tester.sendEscape();

          expect(cancelCount, 1);
          expect(applyCount, 0);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent keeps menu shortcuts as editable text',
      () async {
        await testNocterm('editor key isolation', (tester) async {
          var cancelCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (_) => _success(123),
              onCancel: () => cancelCount++,
            ),
          );

          await tester.enterText('rgq');

          expect(_controller(tester).text, '123rgq');
          expect(cancelCount, 0);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent accepts leading zeroes as a number',
      () async {
        await testNocterm('leading zeroes', (tester) async {
          final appliedValues = <int>[];
          await tester.pumpComponent(
            _editor(
              onApply: (value) {
                appliedValues.add(value);
                return _success(value);
              },
            ),
          );
          await _replaceAll(tester, '000124');
          await tester.sendEnter();

          expect(appliedValues, [124]);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent rejects leading zeroes for an unchanged value',
      () async {
        await testNocterm('unchanged leading zeroes', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (_) {
                applyCount++;
                return _success(123);
              },
            ),
          );
          await _replaceAll(tester, '000123');
          await tester.sendEnter();

          expect(applyCount, 0);
        });
      },
    );

    test('Class TrainerValueEditorComponent rejects empty input', () async {
      await testNocterm('empty input', (tester) async {
        var applyCount = 0;
        await tester.pumpComponent(
          _editor(
            onApply: (_) {
              applyCount++;
              return _success(0);
            },
          ),
        );
        await _replaceAll(tester, '');
        await tester.sendEnter();

        expect(applyCount, 0);
        expect(tester.terminalState, containsText('Enter a value.'));
      });
    });

    test(
      'Class TrainerValueEditorComponent rejects invalid characters',
      () async {
        await testNocterm('invalid characters', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (_) {
                applyCount++;
                return _success(0);
              },
            ),
          );
          await tester.enterText('x');
          await tester.sendEnter();

          expect(applyCount, 0);
          expect(tester.terminalState, containsText('Enter digits only.'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent rejects values above the unsigned range',
      () async {
        await testNocterm('unsigned overflow', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (_) {
                applyCount++;
                return _success(0);
              },
            ),
          );
          await _replaceAll(tester, '4294967296');
          await tester.sendEnter();

          expect(applyCount, 0);
          expect(
            tester.terminalState,
            containsText('Enter a value from 0 to 4,294,967,295.'),
          );
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent rejects integers too large to parse',
      () async {
        await testNocterm('integer parse overflow', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              onApply: (_) {
                applyCount++;
                return _success(0);
              },
            ),
          );
          await _replaceAll(tester, '999999999999999999999999999999');
          await tester.sendEnter();

          expect(applyCount, 0);
          expect(tester.terminalState, containsText('value is too large'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent accepts the minimum and maximum values',
      () async {
        await testNocterm('inclusive boundaries', (tester) async {
          final appliedValues = <int>[];
          final field = _field(minimumValue: 10, maximumValue: 20);
          await tester.pumpComponent(
            _editor(
              field: field,
              currentValue: 15,
              onApply: (value) {
                appliedValues.add(value);
                return _success(value);
              },
            ),
          );
          await _replaceAll(tester, '10');
          await tester.sendEnter();
          expect(appliedValues, [10]);

          await tester.pumpComponent(
            _editor(
              field: field,
              currentValue: 15,
              onApply: (value) {
                appliedValues.add(value);
                return _success(value);
              },
            ),
          );
          await _replaceAll(tester, '20');
          await tester.sendEnter();

          expect(appliedValues, [10, 20]);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent rejects a value below the minimum',
      () async {
        await testNocterm('below minimum', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              field: _field(minimumValue: 10, maximumValue: 20),
              currentValue: 15,
              onApply: (_) {
                applyCount++;
                return _success(9);
              },
            ),
          );
          await _replaceAll(tester, '9');
          await tester.sendEnter();

          expect(applyCount, 0);
          expect(tester.terminalState, containsText('from 10 to 20'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent rejects a value above the maximum',
      () async {
        await testNocterm('above maximum', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              field: _field(minimumValue: 10, maximumValue: 20),
              currentValue: 15,
              onApply: (_) {
                applyCount++;
                return _success(21);
              },
            ),
          );
          await _replaceAll(tester, '21');
          await tester.sendEnter();

          expect(applyCount, 0);
          expect(tester.terminalState, containsText('from 10 to 20'));
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent edits the maximum unsigned value',
      () async {
        await testNocterm('large unsigned value', (tester) async {
          const value = 0xffffffff;
          await tester.pumpComponent(
            _editor(
              field: _field(maximumValue: value),
              currentValue: value,
              onApply: (_) => _success(value),
            ),
          );

          expect(_controller(tester).text, '4294967295');
          await tester.sendBackspace();
          await tester.enterText('4');

          expect(_controller(tester).text, '4294967294');
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent disables unavailable current values',
      () async {
        await testNocterm('unavailable current value', (tester) async {
          var applyCount = 0;
          var cancelCount = 0;
          await tester.pumpComponent(
            _editor(
              currentValue: null,
              onApply: (_) {
                applyCount++;
                return _success(1);
              },
              onCancel: () => cancelCount++,
            ),
          );
          final input = tester.findAllComponents<TextField>().single;

          await tester.enterText('9');
          await tester.sendEnter();
          await tester.sendEscape();

          expect(input.enabled, isFalse);
          expect(_controller(tester).text, isEmpty);
          expect(applyCount, 0);
          expect(cancelCount, 1);
          expect(
            tester.terminalState,
            containsText('Current value unavailable.'),
          );
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent disables read-only fields',
      () async {
        await testNocterm('read-only field', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              field: _field(writeEnabled: false),
              onApply: (_) {
                applyCount++;
                return _success(1);
              },
            ),
          );
          final input = tester.findAllComponents<TextField>().single;

          await tester.enterText('9');
          await tester.sendEnter();

          expect(input.enabled, isFalse);
          expect(_controller(tester).text, '123');
          expect(applyCount, 0);
          expect(
            tester.terminalState,
            containsText('This field is read-only.'),
          );
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent disables fields without read approval',
      () async {
        await testNocterm('field without read evidence', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              field: _field(readEnabled: false),
              onApply: (_) {
                applyCount++;
                return _success(1);
              },
            ),
          );
          final input = tester.findAllComponents<TextField>().single;

          expect(input.enabled, isFalse);
          expect(_controller(tester).text, isEmpty);
          expect(
            tester.terminalState,
            containsText('Current value unavailable.'),
          );
          await tester.sendEnter();
          expect(applyCount, 0);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent disables fields without approved bounds',
      () async {
        await testNocterm('field without bounds', (tester) async {
          var applyCount = 0;
          await tester.pumpComponent(
            _editor(
              field: _field(minimumValue: null, maximumValue: null),
              onApply: (_) {
                applyCount++;
                return _success(1);
              },
            ),
          );
          final input = tester.findAllComponents<TextField>().single;

          expect(input.enabled, isFalse);
          expect(_controller(tester).text, '123');
          expect(
            tester.terminalState,
            containsText('This field has no approved value range.'),
          );
          await tester.sendEnter();
          expect(applyCount, 0);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent disables editing when either bound is absent',
      () async {
        await testNocterm('one missing bound', (tester) async {
          for (final field in [
            _field(minimumValue: null),
            _field(maximumValue: null),
          ]) {
            var applyCount = 0;
            await tester.pumpComponent(
              _editor(
                field: field,
                onApply: (_) {
                  applyCount++;
                  return _success(124);
                },
              ),
            );
            final input = tester.findAllComponents<TextField>().single;

            expect(input.enabled, isFalse);
            expect(
              tester.terminalState,
              containsText('no approved value range'),
            );
            await tester.sendEnter();
            expect(applyCount, 0);
          }
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent renders an error for a small terminal',
      () async {
        await testNocterm('small editor terminal', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(1234)));

          expect(tester.terminalState, containsText('Terminal too small'));
        }, size: const Size(30, 5));
      },
    );

    test(
      'Class TrainerValueEditorComponent handles narrow terminals independently',
      () async {
        await testNocterm('narrow editor terminal', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(124)));

          expect(tester.terminalState, containsText('Terminal too small'));
        }, size: const Size(30, 24));
      },
    );

    test(
      'Class TrainerValueEditorComponent handles short terminals independently',
      () async {
        await testNocterm('short editor terminal', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(124)));

          expect(tester.terminalState, containsText('Terminal too small'));
        }, size: const Size(80, 5));
      },
    );

    test(
      'Class TrainerValueEditorComponent renders at exact minimum dimensions',
      () async {
        await testNocterm('minimum editor dimensions', (tester) async {
          await tester.pumpComponent(_editor(onApply: (_) => _success(124)));

          expect(tester.terminalState, containsText('EDIT CREDITS'));
          expect(
            tester.terminalState,
            isNot(containsText('Terminal too small')),
          );
        }, size: const Size(48, 11));
      },
    );

    test(
      'Class TrainerValueEditorComponent resets text and feedback when the value changes',
      () async {
        await testNocterm('current value update', (tester) async {
          final appliedValues = <int>[];
          await tester.pumpComponent(
            _EditorHost(
              field: _field(),
              currentValue: 123,
              onApply: (value) {
                appliedValues.add(value);
                return _success(value);
              },
            ),
          );
          await tester.enterText('4');
          await tester.sendEnter();
          expect(appliedValues, [1234]);
          expect(tester.terminalState, containsText('Verified value: 1,234'));

          tester.findState<_EditorHostState>().updateCurrentValue(456);
          await tester.pump();
          expect(_controller(tester).text, '456');
          expect(
            tester.terminalState,
            isNot(containsText('Verified value: 1,234')),
          );
          await tester.enterText('7');
          await tester.sendEnter();

          expect(appliedValues, [1234, 4567]);
        });
      },
    );

    test(
      'Class TrainerValueEditorComponent resets when the field metadata changes',
      () async {
        await testNocterm('field metadata update', (tester) async {
          await tester.pumpComponent(
            _EditorHost(
              field: _field(),
              currentValue: 123,
              onApply: (_) => _success(124),
            ),
          );
          await tester.enterText('x');
          await tester.sendEnter();
          expect(tester.terminalState, containsText('Enter digits only.'));

          tester.findState<_EditorHostState>().updateField(
            _field(maximumValue: 1000),
          );
          await tester.pump();

          expect(_controller(tester).text, '123');
          expect(
            tester.terminalState,
            isNot(containsText('Enter digits only.')),
          );
        });
      },
    );
  });
}
