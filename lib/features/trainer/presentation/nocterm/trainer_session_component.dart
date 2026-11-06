import 'dart:async';

import 'package:ludava/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava/features/trainer/application/trainer_session_controller.dart';
import 'package:ludava/features/trainer/application/trainer_session_state.entity.dart';
import 'package:ludava/features/trainer/presentation/nocterm/layout_constants.dart';
import 'package:ludava/features/trainer/presentation/nocterm/trainer_menu_component.dart';
import 'package:ludava/features/trainer/presentation/nocterm/trainer_value_editor_component.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:nocterm/nocterm.dart';

/// Connects the trainer screens to a reusable [TrainerSessionController].
class TrainerSessionComponent extends StatefulComponent {
  /// Coordinates process, identity, read, and write operations.
  final TrainerSessionController sessionController;

  /// Requests safe application shutdown and terminal restoration.
  final void Function() onQuit;

  /// Creates the terminal application for [sessionController].
  const TrainerSessionComponent({
    required this.sessionController,
    required this.onQuit,
    super.key,
  });

  @override
  State<TrainerSessionComponent> createState() => _TrainerSessionState();
}

class _TrainerSessionState extends State<TrainerSessionComponent> {
  late TrainerSessionState _session;
  StreamSubscription<TrainerSessionState>? _stateSubscription;
  GameField? _editingField;
  int _selectedFieldIndex = 0;
  int _selectedProcessIndex = 0;

  @override
  void initState() {
    final controller = component.sessionController;
    if (controller.state.processIds.isEmpty &&
        controller.state.selectedProcessId == null) {
      controller.connect();
    }
    _session = controller.state;
    _stateSubscription = controller.stateChanges.listen(_handleStateChanged);
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (_session.selectedProcessId == null && _session.processIds.length > 1) {
      return _buildProcessPicker();
    }
    final field = _editingField;
    if (field != null) return _buildEditor(field);
    return _buildMenu();
  }

  /// Renders available RPCS3 processes before one is selected.
  Component _buildProcessPicker() => LayoutBuilder(
    builder: (context, constraints) {
      final processIds = _session.processIds;
      final requiredHeight =
          NoctermLayoutConstants.fixedMenuRows + processIds.length;
      if (constraints.maxWidth < NoctermLayoutConstants.minimumMenuWidth ||
          constraints.maxHeight < requiredHeight) {
        return const Center(
          child: Text(
            'Terminal too small. Enlarge the window to use Ludava.',
            style: TextStyle(color: Colors.yellow),
          ),
        );
      }
      return Focusable(
        focused: true,
        onKeyEvent: _handleProcessPickerKey,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LUDAVA',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              const Text('Select an RPCS3 process'),
              const SizedBox(height: 1),
              ...processIds.indexed.map(
                (entry) => Text(
                  '${entry.$1 == _selectedProcessIndex ? '❯' : ' '} '
                  '${entry.$1 + 1}. PID ${entry.$2}',
                  style: TextStyle(
                    color:
                        entry.$1 == _selectedProcessIndex ? Colors.green : null,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              const Text('↑↓ Navigate   1–9 Select   Enter Select'),
              const Text('R Refresh     G Re-detect  Q Quit'),
            ],
          ),
        ),
      );
    },
  );

  /// Renders session feedback and the field menu.
  Component _buildMenu() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_statusMessage case final message?)
        Text(
          message,
          style: TextStyle(
            color:
                _session.lastWriteResult?.succeeded == true
                    ? Colors.green
                    : Colors.yellow,
          ),
        ),
      Expanded(
        child: TrainerMenuComponent(
          session: _session,
          initialSelection: _selectedFieldIndex,
          onSelectionChanged: (selection) => _selectedFieldIndex = selection,
          onOpenField: _openField,
          onRefresh: _refresh,
          onRedetect: _redetect,
          onQuit: component.onQuit,
        ),
      ),
    ],
  );

  /// Opens the editor with the latest verified value for [field].
  Component _buildEditor(GameField field) {
    final readResult = _session.readResults[field.id];
    return TrainerValueEditorComponent(
      field: field,
      currentValue: readResult?.succeeded == true ? readResult?.value : null,
      onApply:
          (value) => component.sessionController.writeField(field.id, value),
      onApplied: _returnToMenu,
      onCancel: _returnToMenu,
    );
  }

  /// Returns the session warning or successful write status, if any.
  String? get _statusMessage {
    final write = _session.lastWriteResult;
    final fieldId = write?.fieldId;
    final readBackValue = write?.readBackValue;
    if (write != null &&
        write.succeeded &&
        fieldId != null &&
        readBackValue != null) {
      final fieldName = _session.profile?.findField(fieldId)?.name;
      return '✓ ${fieldName ?? fieldId} updated to '
          '${_formatValue(readBackValue)}';
    }
    final error = _session.errorMessage;
    if (error != null) return '⚠ $error';
    if (_session.selectedProcessId == null && _session.processIds.isEmpty) {
      return 'RPCS3 was not found. Start RPCS3 and press R to refresh.';
    }
    return switch (_session.detection?.status) {
      GameDetectionStatus.rpcs3NotRunning =>
        'RPCS3 was not found. Start RPCS3 and press R to refresh.',
      GameDetectionStatus.noActiveGame =>
        'Start a supported Collection game, then press R to refresh.',
      GameDetectionStatus.unsupportedGame => 'This game is not supported.',
      GameDetectionStatus.ambiguous =>
        'Could not verify the active game. Press G to re-detect.',
      GameDetectionStatus.failed =>
        _session.detection?.evidenceDescription ?? 'Game detection failed.',
      _ => null,
    };
  }

  /// Handles input owned by the process picker.
  bool _handleProcessPickerKey(KeyboardEvent event) {
    final processIds = _session.processIds;
    if (event.logicalKey == LogicalKey.arrowUp) {
      _setProcessSelection(_selectedProcessIndex - 1);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowDown) {
      _setProcessSelection(_selectedProcessIndex + 1);
      return true;
    }
    final digit = _digitFor(event.logicalKey);
    if (digit != null && digit <= processIds.length) {
      _selectProcess(processIds[digit - 1]);
      return true;
    }
    if (event.logicalKey == LogicalKey.enter && processIds.isNotEmpty) {
      _selectProcess(processIds[_selectedProcessIndex]);
      return true;
    }
    if (_matchesLetter(event, 'r', LogicalKey.keyR) ||
        _matchesLetter(event, 'g', LogicalKey.keyG)) {
      _refresh();
      return true;
    }
    if (_matchesLetter(event, 'q', LogicalKey.keyQ)) {
      component.onQuit();
      return true;
    }
    return false;
  }

  /// Keeps the selected process row within the current result list.
  void _setProcessSelection(int index) {
    final processIds = _session.processIds;
    if (processIds.isEmpty) return;
    final selection = index.clamp(0, processIds.length - 1);
    if (selection == _selectedProcessIndex) return;
    setState(() => _selectedProcessIndex = selection);
  }

  /// Requests application selection of [processId].
  void _selectProcess(int processId) {
    component.sessionController.selectProcess(processId);
  }

  /// Opens [field] for editing without copying its verified value.
  void _openField(GameField field) {
    setState(() => _editingField = field);
  }

  /// Reconnects or refreshes the selected process through the controller.
  void _refresh() {
    final controller = component.sessionController;
    if (_session.selectedProcessId == null) {
      controller.connect();
    } else {
      controller.refresh();
    }
  }

  /// Rechecks the selected process identity and memory base.
  void _redetect() {
    final controller = component.sessionController;
    if (_session.selectedProcessId == null) {
      controller.connect();
    } else {
      controller.redetect();
    }
  }

  /// Replaces the rendered snapshot and drops UI state tied to an old session.
  void _handleStateChanged(TrainerSessionState session) {
    if (!_sameSession(_session, session)) {
      _editingField = null;
      _selectedFieldIndex = 0;
    }
    _selectedProcessIndex =
        session.processIds.isEmpty
            ? 0
            : _selectedProcessIndex.clamp(0, session.processIds.length - 1);
    setState(() => _session = session);
  }

  /// Reports whether two snapshots refer to the same process and game target.
  bool _sameSession(TrainerSessionState first, TrainerSessionState second) =>
      first.selectedProcessId == second.selectedProcessId &&
      first.processMetadata?.startedAtUtc ==
          second.processMetadata?.startedAtUtc &&
      first.detection?.status == second.detection?.status &&
      first.detection?.confidence == second.detection?.confidence &&
      first.profile?.id == second.profile?.id &&
      first.detection?.executableHash == second.detection?.executableHash &&
      first.memoryBase == second.memoryBase;

  /// Returns to the field menu using the controller's newest snapshot.
  void _returnToMenu() {
    setState(() {
      _editingField = null;
      _session = component.sessionController.state;
    });
  }

  /// Formats a verified value with thousands separators for status text.
  String _formatValue(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );

  /// Maps a menu digit key to its one-based field or process index.
  int? _digitFor(LogicalKey key) => switch (key) {
    LogicalKey.digit1 => 1,
    LogicalKey.digit2 => 2,
    LogicalKey.digit3 => 3,
    LogicalKey.digit4 => 4,
    LogicalKey.digit5 => 5,
    LogicalKey.digit6 => 6,
    LogicalKey.digit7 => 7,
    LogicalKey.digit8 => 8,
    LogicalKey.digit9 => 9,
    _ => null,
  };

  /// Recognizes a letter shortcut from its key or typed character.
  bool _matchesLetter(KeyboardEvent event, String letter, LogicalKey key) =>
      event.logicalKey == key || event.character?.toLowerCase() == letter;
}
