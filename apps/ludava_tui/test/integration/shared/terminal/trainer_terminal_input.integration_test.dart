import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/value_editor/presentation/nocterm/trainer_value_editor_component.dart';
import 'package:ludava_tui/shared/terminal/trainer_terminal_backend.dart';
import 'package:nocterm/nocterm.dart'
    show
        BuildContext,
        Component,
        Element,
        Focusable,
        KeyboardEvent,
        LogicalKey,
        Size,
        State,
        StatefulComponent,
        Terminal,
        TerminalBackend,
        TerminalBinding,
        Text,
        TextField;
import 'package:test/test.dart';

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

  /// Opens the editor after the focused screen receives Enter.
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
  minimumValue: 0,
  maximumValue: 0xffffffff,
);

TextField? _editorTextField(TerminalBinding binding) {
  final root = binding.rootElement;
  if (root == null) return null;
  TextField? found;
  void visit(Element element) {
    if (element.component is TextField) found = element.component as TextField;
    element.visitChildren(visit);
  }

  root.visitChildren(visit);
  return found;
}

void main() {
  group('Integration Nocterm raw terminal input behaves correctly', () {
    test(
      'Integration Escape cancels without leaking text or writing',
      () async {
        final source = _RawInputBackend();
        final binding = TerminalBinding(
          Terminal(TrainerTerminalBackend(source)),
        );
        final cancelledDrafts = <String>[];
        final writtenValues = <int>[];
        binding.initialize();
        binding.attachRootComponent(
          _RawEditorHarness(
            field: _editableField(),
            onCancel: () {
              cancelledDrafts.add(
                _editorTextField(binding)?.controller?.text ?? '',
              );
            },
            onWrite: (value) {
              writtenValues.add(value);
              return GameWriteResult(
                status: GameWriteStatus.success,
                fieldId: 'credits',
                requestedValue: value,
                readBackValue: value,
              );
            },
          ),
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
          source.sendBytes([0x0d]);
          await pumpFrame();
          source.sendBytes([0x34]);
          source.sendBytes([0x32]);
          await pumpFrame();
          source.sendBytes([0x1b]);
          await pumpFrame();

          expect(cancelledDrafts, ['10042']);
          expect(writtenValues, isEmpty);

          source.sendBytes([0x0d]);
          await pumpFrame();
          source.sendBytes([0x32]);
          source.sendBytes([0x0d]);
          await pumpFrame();

          expect(writtenValues, [1002]);
        } finally {
          try {
            binding.shutdown();
          } finally {
            try {
              await app.timeout(const Duration(seconds: 4));
            } finally {
              source.dispose();
            }
          }
        }
      },
    );
  });
}
