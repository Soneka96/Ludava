import 'dart:async';

import 'package:ludava/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/trainer/application/trainer_session_controller.dart';
import 'package:ludava/features/trainer/presentation/nocterm/trainer_session_component.dart';
import 'package:ludava/features/trainer/presentation/nocterm/trainer_value_editor_component.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:nocterm/nocterm_test.dart'
    show KeyboardEvent, LogicalKey, containsText, testNocterm;
import 'package:nocterm/nocterm.dart'
    show
        BuildContext,
        Component,
        Focusable,
        Size,
        SizedBox,
        State,
        StatefulComponent,
        Terminal,
        TerminalBinding,
        TerminalBackend,
        TextEditingController,
        Text,
        TextField;
import 'package:test/test.dart';

void main() {
  group('Class TrainerSessionComponent session behavior', () {
    test(
      'Class TrainerSessionComponent connects one process and shows its field value',
      () async {
        await testNocterm('single RPCS3 process', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));

          expect(tester.terminalState, containsText('CONNECTED'));
          expect(tester.terminalState, containsText('Ratchet & Clank 2'));
          expect(tester.terminalState, containsText('100'));
          expect(fixture.controller.state.selectedProcessId, 42);
        });
      },
    );

    test(
      'Class TrainerSessionComponent asks which process to use when several exist',
      () async {
        await testNocterm('multiple RPCS3 processes', (tester) async {
          final fixture = _SessionFixture()..processIds = [42, 43];
          await tester.pumpComponent(_app(fixture));

          expect(tester.terminalState, containsText('Select an RPCS3 process'));
          expect(tester.terminalState, containsText('PID 42'));
          expect(tester.terminalState, containsText('PID 43'));
          await tester.sendArrowDown();
          await tester.sendEnter();

          expect(fixture.controller.state.selectedProcessId, 43);
          expect(tester.terminalState, containsText('CONNECTED'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent selects a process directly by number',
      () async {
        await testNocterm('direct process shortcut', (tester) async {
          final fixture = _SessionFixture()..processIds = [42, 43];
          await tester.pumpComponent(_app(fixture));

          await tester.sendKey(LogicalKey.digit3);
          expect(fixture.controller.state.selectedProcessId, isNull);
          expect(fixture.detectCalls, 0);
          expect(tester.terminalState, containsText('Select an RPCS3 process'));

          await tester.sendKey(LogicalKey.digit2);

          expect(fixture.controller.state.selectedProcessId, 43);
          expect(fixture.detectCalls, greaterThan(0));
          expect(tester.terminalState, containsText('CONNECTED'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent stops observing after disposal',
      () async {
        await testNocterm('session observer cleanup', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));

          await tester.pumpComponent(const SizedBox());
          fixture.detectionStatus = GameDetectionStatus.unsupportedGame;
          fixture.controller.refresh();

          expect(
            fixture.controller.state.detection?.status,
            GameDetectionStatus.unsupportedGame,
          );
          expect(
            tester.terminalState,
            isNot(containsText('This game is not supported')),
          );
        });
      },
    );

    test(
      'Class TrainerSessionComponent refreshes and re-detects from menu shortcuts',
      () async {
        await testNocterm('refresh and re-detect', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));
          final initialReads = fixture.readCalls;
          final initialDetections = fixture.detectCalls;

          await tester.sendKey(LogicalKey.keyR);
          expect(fixture.readCalls, greaterThan(initialReads));
          await tester.sendKey(LogicalKey.keyG);

          expect(fixture.detectCalls, greaterThan(initialDetections));
          expect(tester.terminalState, containsText('100'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent lets the user retry discovery when RPCS3 starts',
      () async {
        await testNocterm('RPCS3 starts later', (tester) async {
          final fixture = _SessionFixture()..processIds = [];
          await tester.pumpComponent(_app(fixture));
          expect(tester.terminalState, containsText('RPCS3 was not found'));
          fixture.processIds = [42];

          await tester.sendKey(LogicalKey.keyR);

          expect(fixture.controller.state.selectedProcessId, 42);
          expect(tester.terminalState, containsText('CONNECTED'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent explains inactive and unsupported games',
      () async {
        await testNocterm('game status feedback', (tester) async {
          final fixture =
              _SessionFixture()
                ..detectionStatus = GameDetectionStatus.noActiveGame;
          await tester.pumpComponent(_app(fixture));
          expect(
            tester.terminalState,
            containsText('Start a supported Collection game'),
          );

          fixture.detectionStatus = GameDetectionStatus.unsupportedGame;
          await tester.sendKey(LogicalKey.keyG);

          expect(
            tester.terminalState,
            containsText('This game is not supported'),
          );
        });
      },
    );

    test(
      'Class TrainerSessionComponent preserves selection when cancelling an editor',
      () async {
        await testNocterm('cancel and return to selected field', (
          tester,
        ) async {
          final fixture =
              _SessionFixture()..profile = _profile(twoFields: true);
          await tester.pumpComponent(_app(fixture));

          await tester.sendKey(LogicalKey.digit2);
          await tester.sendEnter();
          expect(tester.terminalState, containsText('EDIT WEAPONS'));
          await tester.sendEscape();
          expect(fixture.writeCalls, 0);

          await tester.sendEnter();

          expect(tester.terminalState, containsText('EDIT WEAPONS'));
          expect(fixture.writeCalls, 0);
        });
      },
    );

    test(
      'Class TrainerSessionComponent opens a field by number and keeps editor digits local',
      () async {
        await testNocterm('menu and editor digit ownership', (tester) async {
          final fixture =
              _SessionFixture()..profile = _profile(twoFields: true);
          await tester.pumpComponent(_app(fixture));

          await tester.sendKey(LogicalKey.digit1);
          expect(tester.terminalState, containsText('EDIT BOLTS'));
          await tester.enterText('2');
          expect(tester.terminalState, containsText('1002'));
          await tester.sendEscape();
          await tester.sendEnter();

          expect(tester.terminalState, containsText('EDIT BOLTS'));
          expect(tester.terminalState, containsText('Current value: 100'));
          expect(fixture.writeCalls, 0);
        });
      },
    );

    test(
      'Class TrainerSessionComponent closes after applying and shows read-back',
      () async {
        await testNocterm('apply from the editor', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));

          await tester.sendEnter();
          await tester.enterText('5');
          await tester.sendEnter();

          expect(fixture.writeCalls, 1);
          expect(fixture.lastConfirmed, isTrue);
          expect(tester.terminalState, containsText('Bolts updated to 1,005'));
          expect(tester.terminalState, isNot(containsText('EDIT BOLTS')));

          await tester.sendEnter();
          expect(tester.terminalState, containsText('Current value: 1,005'));
          expect(fixture.writeCalls, 1);
          await tester.sendEscape();

          expect(tester.terminalState, containsText('1,005'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent invalidates the editor when write validation detects a game change',
      () async {
        await testNocterm('game changes before apply', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));
          await tester.sendEnter();
          await tester.enterText('101');
          fixture.profile = _profile(id: 'rc3-collection');

          await tester.sendEnter();

          expect(fixture.writeCalls, 0);
          expect(fixture.controller.state.profile, isNull);
          expect(fixture.controller.state.readResults, isEmpty);
          expect(
            tester.terminalState,
            containsText('active game or memory base changed'),
          );
          expect(tester.terminalState, isNot(containsText('EDIT BOLTS')));
        });
      },
    );

    test(
      'Class TrainerSessionComponent invalidates the editor when the process session changes before apply',
      () async {
        await testNocterm('process session changes before apply', (
          tester,
        ) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));
          await tester.sendEnter();
          await tester.enterText('1');
          fixture.startedAtUtc = DateTime.utc(2026, 11, 6, 11);

          await tester.sendEnter();

          expect(fixture.writeCalls, 0);
          expect(fixture.controller.state.profile, isNull);
          expect(fixture.controller.state.readResults, isEmpty);
          expect(tester.terminalState, containsText('session changed'));
          expect(tester.terminalState, isNot(containsText('EDIT BOLTS')));
        });
      },
    );

    test(
      'Class TrainerSessionComponent invalidates the editor when the memory base changes before apply',
      () async {
        await testNocterm('memory base changes before apply', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));
          await tester.sendEnter();
          await tester.enterText('1');
          fixture.memoryBase = 0x400000000;

          await tester.sendEnter();

          expect(fixture.writeCalls, 0);
          expect(fixture.controller.state.profile, isNull);
          expect(fixture.controller.state.readResults, isEmpty);
          expect(
            tester.terminalState,
            containsText('active game or memory base changed'),
          );
          expect(tester.terminalState, isNot(containsText('EDIT BOLTS')));
        });
      },
    );

    test(
      'Class TrainerSessionComponent quits through the supplied shutdown action',
      () async {
        await testNocterm('quit action', (tester) async {
          final fixture = _SessionFixture();
          var quitCount = 0;
          await tester.pumpComponent(_app(fixture, onQuit: () => quitCount++));

          await tester.sendKey(LogicalKey.keyQ);

          expect(quitCount, 1);
        });
      },
    );
  });

  group('Class Nocterm raw keyboard input behavior', () {
    test(
      'Class Nocterm decodes raw Escape sequences and the trainer cancels without writing',
      () async {
        final backend = _RawInputBackend();
        final textController = TextEditingController();
        final events = <KeyboardEvent>[];
        final binding = TerminalBinding(Terminal(backend));
        binding.initialize();
        binding.attachRootComponent(
          _RawKeyboardProbe(controller: textController, events: events),
        );
        final app = binding.runEventLoop();

        try {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          backend.sendBytes([0x61]);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          backend.sendBytes([0x1b]);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          backend.sendBytes([0x1b, 0x5b]);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          backend.sendBytes([0x32, 0x37, 0x75]);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          backend.sendBytes([0x62, 0x1b, 0x5b, 0x32, 0x37, 0x75]);
          await Future<void>.delayed(const Duration(milliseconds: 40));

          expect(
            events.where((event) => event.logicalKey == LogicalKey.escape),
            hasLength(3),
          );
          expect(textController.text, 'ab');
          expect(textController.text, isNot(contains('[27u')));

          var cancelCount = 0;
          var writeCount = 0;
          binding.attachRootComponent(
            _RawEditorHarness(
              field: _profile().findField('bolts')!,
              onCancel: () => cancelCount++,
              onWrite: (value) {
                writeCount++;
                return GameWriteResult(
                  status: GameWriteStatus.success,
                  fieldId: 'bolts',
                  requestedValue: value,
                  readBackValue: value,
                );
              },
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 40));
          backend.sendBytes([0x0d]);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          backend.sendBytes([0x32]);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          backend.sendBytes([0x1b]);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          expect(cancelCount, 1);
          expect(writeCount, 0);
          backend.sendBytes([0x0d]);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          backend.sendBytes([0x33]);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          backend.sendBytes([0x1b, 0x5b]);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          backend.sendBytes([0x32, 0x37, 0x75]);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          expect(cancelCount, 2);
          expect(writeCount, 0);
          backend.sendBytes([0x0d]);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          backend.sendBytes([0x34, 0x1b, 0x5b, 0x32, 0x37, 0x75]);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          expect(cancelCount, 3);
          expect(writeCount, 0);
        } finally {
          binding.shutdown();
          await app.timeout(const Duration(seconds: 4));
          backend.dispose();
          textController.dispose();
        }
      },
    );
  });
}

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
  final StreamController<List<int>> _input = StreamController.broadcast();

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

TrainerSessionComponent _app(
  _SessionFixture fixture, {
  void Function()? onQuit,
}) => TrainerSessionComponent(
  sessionController: fixture.controller,
  onQuit: onQuit ?? () {},
);

class _SessionFixture {
  List<int> processIds = [42];
  GameProfile profile = _profile();
  DateTime startedAtUtc = DateTime.utc(2026, 11, 6, 10);
  int memoryBase = 0x300000000;
  int readCalls = 0;
  int detectCalls = 0;
  int writeCalls = 0;
  bool? lastConfirmed;
  GameDetectionStatus detectionStatus = GameDetectionStatus.supportedGame;

  late final TrainerSessionController controller = TrainerSessionController(
    discoverProcessIds: () => processIds,
    readProcessMetadata:
        (_) => Rpcs3ProcessMetadata(
          executablePath: r'C:\RPCS3\rpcs3.exe',
          startedAtUtc: startedAtUtc,
        ),
    resolveMemoryBaseCandidate:
        (_) => Rpcs3MemoryBaseCandidate(
          memoryBase: memoryBase,
          logPath: r'C:\RPCS3\log\RPCS3.log',
        ),
    detectGame: (processId, _) {
      detectCalls++;
      return GameDetectionResult(
        status: detectionStatus,
        processId: processId,
        titleId: profile.buildId,
        gameTitle: profile.gameName,
        executable: profile.executable,
        executableHash: profile.executableHash,
        confidence:
            detectionStatus == GameDetectionStatus.supportedGame
                ? GameIdentityConfidence.confirmed
                : GameIdentityConfidence.none,
        profile:
            detectionStatus == GameDetectionStatus.supportedGame
                ? profile
                : null,
        evidenceDescription: 'Synthetic session evidence.',
      );
    },
    readField: (processId, selectedProfile, memoryBase, fieldId) {
      readCalls++;
      return GameReadResult(
        status: GameReadStatus.success,
        fieldId: fieldId,
        value: fieldId == 'weapons' ? 7 : 100,
      );
    },
    writeField: (
      processId,
      selectedProfile,
      memoryBase,
      fieldId,
      value,
      confirmed,
    ) {
      writeCalls++;
      lastConfirmed = confirmed;
      return GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: fieldId,
        requestedValue: value,
        readBackValue: value,
      );
    },
  );
}

GameProfile _profile({String id = 'rc2-collection', bool twoFields = false}) =>
    GameProfile(
      id: id,
      gameName: 'Ratchet & Clank 2',
      buildId: 'BCUS98282',
      executable: 'RC2.ppu.self',
      executableHash: 'measured-hash',
      readStatus: VerificationStatus.verified,
      writeStatus: VerificationStatus.researchConfirmed,
      fields: {
        'bolts': GameField(
          id: 'bolts',
          name: 'Bolts',
          guestOffset: 0x1000,
          valueType: MemoryValueType.unsigned32,
          byteOrder: ByteOrder.big,
          readStatus: VerificationStatus.verified,
          writeStatus: VerificationStatus.researchConfirmed,
          minimumValue: 0,
          maximumValue: GameMemoryConstants.maxUnsigned32,
        ),
        if (twoFields)
          'weapons': GameField(
            id: 'weapons',
            name: 'Weapons',
            guestOffset: 0x2000,
            valueType: MemoryValueType.unsigned32,
            byteOrder: ByteOrder.big,
            readStatus: VerificationStatus.verified,
          ),
      },
    );
