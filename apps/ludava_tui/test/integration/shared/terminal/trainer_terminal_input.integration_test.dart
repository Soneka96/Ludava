import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/value_editor/presentation/nocterm/trainer_value_editor_component.dart';
import 'package:ludava_tui/shared/terminal/trainer_terminal_backend.dart';
import 'package:nocterm/nocterm.dart'
    show
        BuildContext,
        Component,
        Focusable,
        Size,
        State,
        StatefulComponent,
        Terminal,
        TerminalBackend,
        TerminalBinding,
        Text,
        TextEditingController,
        TextField;
import 'package:nocterm/nocterm_test.dart' show KeyboardEvent, LogicalKey;
import 'package:test/test.dart';

class _RawKeyboardProbe extends StatefulComponent {
  final TextEditingController controller;
  final List<KeyboardEvent> events;

  const _RawKeyboardProbe({required this.controller, required this.events});

  @override
  State<_RawKeyboardProbe> createState() => _RawKeyboardProbeState();
}

class _RawKeyboardProbeState extends State<_RawKeyboardProbe> {
  @override
  Component build(BuildContext context) => Focusable(
    focused: true,
    onKeyEvent: _recordEvent,
    child: TextField(
      controller: component.controller,
      focused: true,
      width: 24,
    ),
  );

  /// Captures delivered keys and keeps Escape out of the text field.
  bool _recordEvent(KeyboardEvent event) {
    component.events.add(event);
    return event.logicalKey == LogicalKey.escape;
  }
}

class _RawEditorHarness extends StatefulComponent {
  final GameField field;
  final void Function() onCancel;
  final GameWriteResult Function(int value) onWrite;

  const _RawEditorHarness({
    required this.field,
    required this.onCancel,
    required this.onWrite,
  });

  @override
  State<_RawEditorHarness> createState() => _RawEditorHarnessState();
}

class _RawEditorHarnessState extends State<_RawEditorHarness> {
  bool _editing = false;

  @override
  Component build(BuildContext context) =>
      _editing
          ? TrainerValueEditorComponent(
            field: component.field,
            currentValue: 100,
            onApply: component.onWrite,
            onCancel: () {
              component.onCancel();
              setState(() => _editing = false);
            },
          )
          : Focusable(
            focused: true,
            onKeyEvent: _openEditor,
            child: const Text('READY'),
          );

  /// Opens the editor after the menu receives Enter.
  bool _openEditor(KeyboardEvent event) {
    if (event.logicalKey != LogicalKey.enter) return false;
    setState(() => _editing = true);
    return true;
  }
}

class _RawInputBackend implements TerminalBackend {
  final StreamController<List<int>> _input =
      StreamController<List<int>>.broadcast(sync: true);

  void sendBytes(List<int> bytes) => _input.add(bytes);

  @override
  void dispose() {
    unawaited(_input.close());
  }

  @override
  void disableRawMode() {}

  @override
  void enableRawMode() {}

  @override
  Size getSize() => const Size(80, 24);

  @override
  bool get isAvailable => true;

  @override
  Stream<List<int>> get inputStream => _input.stream;

  @override
  void requestExit([int exitCode = 0]) {}

  @override
  void notifySizeChanged(Size newSize) {}

  @override
  Stream<Size>? get resizeStream => null;

  @override
  Stream<void>? get shutdownStream => null;

  @override
  bool get supportsSize => false;

  @override
  void writeRaw(String data) {}
}

GameField _editableField() => GameField(
  id: 'credits',
  name: 'Credits',
  guestOffset: 0x1000,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  readStatus: VerificationStatus.verified,
  writeStatus: VerificationStatus.researchConfirmed,
  minimumValue: 0,
  maximumValue: 0xffffffff,
);

void main() {
  group('Integration Nocterm raw terminal input behaves correctly', () {
    test(
      'Integration Nocterm decodes complete ANSI keys and cancels Escape without writing',
      () async {
        final source = _RawInputBackend();
        final backend = TrainerTerminalBackend(source);
        final textController = TextEditingController();
        final events = <KeyboardEvent>[];
        final parsedEvents = <KeyboardEvent>[];
        final binding = TerminalBinding(Terminal(backend));
        binding.initialize();
        final keyboardSubscription = binding.keyboardEvents.listen(
          parsedEvents.add,
        );
        binding.attachRootComponent(
          _RawKeyboardProbe(controller: textController, events: events),
        );
        final app = binding.runEventLoop();

        Future<void> pumpFrame() {
          final rendered = Completer<void>();
          binding.addPostFrameCallback((_) {
            if (!rendered.isCompleted) rendered.complete();
          });
          binding.scheduleFrame();
          return rendered.future.timeout(const Duration(seconds: 1));
        }

        try {
          await pumpFrame();
          source.sendBytes([0x61]);
          source.sendBytes([0x1b]);
          source.sendBytes([0x62]);
          source.sendBytes([0x1b]);
          await pumpFrame();

          source.sendBytes([0x1b, 0x5b, 0x41]);
          source.sendBytes([0x1b, 0x5b, 0x42]);
          source.sendBytes([0x1b, 0x5b, 0x43]);
          source.sendBytes([0x1b, 0x5b, 0x44]);
          await pumpFrame();

          expect(
            events.where((event) => event.logicalKey == LogicalKey.escape),
            hasLength(2),
          );
          expect(
            parsedEvents.where(
              (event) => event.logicalKey == LogicalKey.arrowUp,
            ),
            hasLength(1),
          );
          expect(
            parsedEvents.where(
              (event) => event.logicalKey == LogicalKey.arrowDown,
            ),
            hasLength(1),
          );
          expect(
            parsedEvents.where(
              (event) => event.logicalKey == LogicalKey.arrowRight,
            ),
            hasLength(1),
          );
          expect(
            parsedEvents.where(
              (event) => event.logicalKey == LogicalKey.arrowLeft,
            ),
            hasLength(1),
          );
          expect(textController.text, 'ab');
          expect(textController.text, isNot(contains('[27u')));

          var cancelCount = 0;
          var writeCount = 0;
          binding.attachRootComponent(
            _RawEditorHarness(
              field: _editableField(),
              onCancel: () => cancelCount++,
              onWrite: (value) {
                writeCount++;
                return GameWriteResult(
                  status: GameWriteStatus.success,
                  fieldId: 'credits',
                  requestedValue: value,
                  readBackValue: value,
                );
              },
            ),
          );
          await pumpFrame();
          source.sendBytes([0x0d]);
          await pumpFrame();
          source.sendBytes([0x32]);
          source.sendBytes([0x1b]);
          await pumpFrame();

          expect(cancelCount, 1);
          expect(writeCount, 0);
        } finally {
          try {
            await keyboardSubscription.cancel();
          } finally {
            try {
              binding.shutdown();
            } finally {
              try {
                await app.timeout(const Duration(seconds: 4));
              } finally {
                source.dispose();
                textController.dispose();
              }
            }
          }
        }
      },
    );
  });
}
