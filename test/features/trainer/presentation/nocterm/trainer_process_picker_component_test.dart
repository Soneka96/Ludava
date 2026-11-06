import 'package:ludava/features/trainer/presentation/nocterm/trainer_process_picker_component.dart';
import 'package:nocterm/nocterm.dart'
    show BuildContext, Component, Size, State, StatefulComponent;
import 'package:nocterm/nocterm_test.dart'
    show LogicalKey, containsText, testNocterm;
import 'package:test/test.dart';

void main() {
  group('Class TrainerProcessPickerComponent selection behavior', () {
    test(
      'Class TrainerProcessPickerComponent renders available process identifiers',
      () async {
        await testNocterm('available processes', (tester) async {
          await tester.pumpComponent(_picker([41, 42]));

          expect(tester.terminalState, containsText('Select an RPCS3 process'));
          expect(tester.terminalState, containsText('PID 41'));
          expect(tester.terminalState, containsText('PID 42'));
        });
      },
    );

    test(
      'Class TrainerProcessPickerComponent selects the highlighted process with Enter',
      () async {
        await testNocterm('arrow and Enter selection', (tester) async {
          int? selectedProcess;
          await tester.pumpComponent(
            _picker([41, 42], onSelectProcess: (id) => selectedProcess = id),
          );

          await tester.sendArrowDown();
          await tester.sendEnter();

          expect(selectedProcess, 42);
        });
      },
    );

    test(
      'Class TrainerProcessPickerComponent selects a process directly by number',
      () async {
        await testNocterm('direct process shortcut', (tester) async {
          int? selectedProcess;
          await tester.pumpComponent(
            _picker([41, 42], onSelectProcess: (id) => selectedProcess = id),
          );

          await tester.sendKey(LogicalKey.digit2);

          expect(selectedProcess, 42);
        });
      },
    );

    test(
      'Class TrainerProcessPickerComponent resets selection to the first process when the selected process exits',
      () async {
        await testNocterm('process list shrinks', (tester) async {
          int? selectedProcess;
          await tester.pumpComponent(
            _ProcessPickerHost(onSelectProcess: (id) => selectedProcess = id),
          );
          await tester.sendArrowDown();
          await tester.sendArrowDown();
          tester.findState<_ProcessPickerHostState>().updateProcessIds([
            41,
            42,
          ]);
          await tester.pump();
          await tester.sendEnter();

          expect(selectedProcess, 41);
        });
      },
    );

    test(
      'Class TrainerProcessPickerComponent resets selection when the selected process disappears from same-length results',
      () async {
        await testNocterm('selected process exits from same-length list', (
          tester,
        ) async {
          int? selectedProcess;
          await tester.pumpComponent(
            _ProcessPickerHost(onSelectProcess: (id) => selectedProcess = id),
          );
          await tester.sendArrowDown();
          expect(tester.terminalState, containsText('❯ 2. PID 42'));

          tester.findState<_ProcessPickerHostState>().updateProcessIds([
            41,
            43,
            44,
          ]);
          await tester.pump();

          expect(tester.terminalState, containsText('❯ 1. PID 41'));
          await tester.sendEnter();
          expect(selectedProcess, 41);
        });
      },
    );

    test(
      'Class TrainerProcessPickerComponent keeps the selected process highlighted when results reorder',
      () async {
        await testNocterm('process list reorders', (tester) async {
          int? selectedProcess;
          await tester.pumpComponent(
            _ProcessPickerHost(onSelectProcess: (id) => selectedProcess = id),
          );
          await tester.sendArrowDown();
          expect(tester.terminalState, containsText('❯ 2. PID 42'));

          tester.findState<_ProcessPickerHostState>().updateProcessIds([
            42,
            41,
            43,
          ]);
          await tester.pump();

          expect(tester.terminalState, containsText('❯ 1. PID 42'));
          await tester.sendEnter();
          expect(selectedProcess, 42);
        });
      },
    );

    test(
      'Class TrainerProcessPickerComponent ignores an out-of-range number',
      () async {
        await testNocterm('out-of-range process shortcut', (tester) async {
          final selections = <int>[];
          await tester.pumpComponent(
            _picker([41, 42], onSelectProcess: selections.add),
          );

          await tester.sendKey(LogicalKey.digit3);

          expect(selections, isEmpty);
          expect(tester.terminalState, containsText('Select an RPCS3 process'));
        });
      },
    );

    test(
      'Class TrainerProcessPickerComponent routes refresh and quit actions',
      () async {
        await testNocterm('process picker actions', (tester) async {
          var refreshCount = 0;
          var redetectCount = 0;
          var quitCount = 0;
          await tester.pumpComponent(
            _picker(
              [41],
              onRefresh: () => refreshCount++,
              onRedetect: () => redetectCount++,
              onQuit: () => quitCount++,
            ),
          );

          await tester.sendKey(LogicalKey.keyR);
          await tester.sendKey(LogicalKey.keyG);
          await tester.sendKey(LogicalKey.keyQ);

          expect(refreshCount, 1);
          expect(redetectCount, 1);
          expect(quitCount, 1);
        });
      },
    );

    test(
      'Class TrainerProcessPickerComponent handles a terminal that is too small',
      () async {
        await testNocterm('small process picker', (tester) async {
          await tester.pumpComponent(_picker([41, 42]));

          expect(tester.terminalState, containsText('Terminal too small'));
        }, size: const Size(30, 5));
      },
    );
  });
}

TrainerProcessPickerComponent _picker(
  List<int> processIds, {
  void Function(int processId)? onSelectProcess,
  void Function()? onRefresh,
  void Function()? onRedetect,
  void Function()? onQuit,
}) => TrainerProcessPickerComponent(
  processIds: processIds,
  onSelectProcess: onSelectProcess ?? (_) {},
  onRefresh: onRefresh ?? () {},
  onRedetect: onRedetect ?? () {},
  onQuit: onQuit ?? () {},
);

class _ProcessPickerHost extends StatefulComponent {
  final void Function(int processId) onSelectProcess;

  const _ProcessPickerHost({required this.onSelectProcess});

  @override
  State<_ProcessPickerHost> createState() => _ProcessPickerHostState();
}

class _ProcessPickerHostState extends State<_ProcessPickerHost> {
  List<int> _processIds = [41, 42, 43];

  /// Replaces the process results while preserving the picker state.
  void updateProcessIds(List<int> processIds) {
    setState(() => _processIds = processIds);
  }

  @override
  Component build(BuildContext context) =>
      _picker(_processIds, onSelectProcess: component.onSelectProcess);
}
