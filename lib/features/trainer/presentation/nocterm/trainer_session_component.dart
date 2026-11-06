import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava/features/trainer/presentation/nocterm/trainer_menu_component.dart';
import 'package:ludava/features/trainer/presentation/nocterm/trainer_process_picker_component.dart';
import 'package:ludava/features/trainer/presentation/nocterm/trainer_value_editor_component.dart';
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

  /// Creates state that observes the trainer session and owns screen navigation.
  @override
  State<TrainerSessionComponent> createState() => _TrainerSessionState();
}

class _TrainerSessionState extends State<TrainerSessionComponent> {
  late TrainerSessionState _session;
  StreamSubscription<TrainerSessionState>? _stateSubscription;
  GameField? _editingField;
  int _selectedFieldIndex = 0;

  /// Connects when needed and subscribes to the controller's latest snapshot.
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

  /// Cancels session observation before releasing the component state.
  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  /// Chooses the process picker, active editor, or trainer menu to display.
  @override
  Component build(BuildContext context) {
    if (_session.selectedProcessId == null && _session.processIds.length > 1) {
      return TrainerProcessPickerComponent(
        processIds: _session.processIds,
        onSelectProcess: _selectProcess,
        onRefresh: _refresh,
        onRedetect: _redetect,
        onQuit: component.onQuit,
      );
    }
    final field = _editingField;
    if (field != null) return _buildEditor(field);
    return _buildMenu();
  }

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
      GameDetectionStatus.failed => _detectionFailureMessage,
      _ => null,
    };
  }

  /// Returns useful failed-detection evidence or a safe generic message.
  String get _detectionFailureMessage {
    final evidence = _session.detection?.evidenceDescription;
    return evidence == null || evidence.isEmpty
        ? 'Game detection failed.'
        : evidence;
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
    final sessionChanged = !_sameSession(_session, session);
    if (sessionChanged) {
      _editingField = null;
      _selectedFieldIndex = 0;
    }
    final editingField = _editingField;
    final writeResult = session.lastWriteResult;
    if (editingField != null &&
        session.readResults[editingField.id]?.succeeded != true &&
        writeResult?.fieldId != editingField.id) {
      _editingField = null;
    }
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
}
