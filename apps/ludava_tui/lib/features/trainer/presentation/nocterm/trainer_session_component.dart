import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/trainer/presentation/nocterm/trainer_menu_component.dart';
import 'package:ludava_tui/features/connection/presentation/nocterm/trainer_process_picker_component.dart';
import 'package:ludava_tui/features/value_editor/presentation/nocterm/trainer_value_editor_component.dart';
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
  TrainerSessionState? _editingOriginSession;
  int? _editingStartingValue;
  int? _editingInstanceId;
  int _nextEditingInstanceId = 0;
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
    final originSession = _editingOriginSession;
    final editInstanceId = _editingInstanceId;
    return TrainerValueEditorComponent(
      field: field,
      currentValue: _editingStartingValue,
      onApply:
          (value) => _applyEdit(editInstanceId, originSession, field, value),
      onApplied: () => _returnToMenu(editInstanceId),
      onCancel: () => _returnToMenu(editInstanceId),
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
        'Start a supported game in RPCS3, then press R to refresh.',
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

  /// Opens [field] when its exact registered field value was read.
  void _openField(GameField field) {
    final profile = _session.profile;
    if (profile == null) return;
    final editableField = profile.findField(field.id);
    final result = _session.readResults[field.id];
    if (editableField == null ||
        result?.fieldId != field.id ||
        result?.succeeded != true ||
        result?.value == null) {
      return;
    }
    final editInstanceId = ++_nextEditingInstanceId;
    setState(() {
      _editingField = editableField;
      _editingOriginSession = _session;
      _editingStartingValue = result!.value;
      _editingInstanceId = editInstanceId;
    });
  }

  /// Writes only while the callback still owns the active edit instance.
  GameWriteResult _applyEdit(
    int? editInstanceId,
    TrainerSessionState? originSession,
    GameField originField,
    int value,
  ) {
    final currentSession = component.sessionController.state;
    final editingField = _editingField;
    if (editInstanceId == null ||
        editInstanceId != _editingInstanceId ||
        originSession == null ||
        !identical(originSession, _editingOriginSession) ||
        editingField == null ||
        !_sameFieldMapping(originField, editingField) ||
        !_sameSession(originSession, currentSession) ||
        !_sameFieldMapping(
          originField,
          currentSession.profile?.findField(originField.id),
        )) {
      return GameWriteResult(
        status: GameWriteStatus.none,
        fieldId: originField.id,
        requestedValue: value,
      );
    }
    return component.sessionController.writeField(originField.id, value);
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
      _clearEditing();
      _selectedFieldIndex = 0;
    }
    final editingField = _editingField;
    final originSession = _editingOriginSession;
    final currentField =
        editingField == null
            ? null
            : session.profile?.findField(editingField.id);
    if (editingField != null &&
        (originSession == null ||
            !_sameSession(originSession, session) ||
            !_sameFieldMapping(editingField, currentField))) {
      _clearEditing();
    }
    setState(() => _session = session);
  }

  /// Reports whether two snapshots refer to the same process and game target.
  bool _sameSession(TrainerSessionState first, TrainerSessionState second) =>
      first.selectedProcessId == second.selectedProcessId &&
      first.processMetadata?.startedAtUtc ==
          second.processMetadata?.startedAtUtc &&
      first.profile?.id == second.profile?.id &&
      first.profile?.buildId == second.profile?.buildId &&
      first.profile?.executable == second.profile?.executable &&
      first.profile?.executableHash == second.profile?.executableHash &&
      first.detection?.executableHash == second.detection?.executableHash &&
      first.memoryBase == second.memoryBase;

  /// Reports whether [first] and [second] use the same field mapping.
  bool _sameFieldMapping(GameField first, GameField? second) =>
      second != null &&
      first.id == second.id &&
      first.guestOffset == second.guestOffset &&
      first.valueType == second.valueType &&
      first.byteOrder == second.byteOrder;

  /// Clears the editor origin after invalidation or intentional completion.
  void _clearEditing() {
    _editingField = null;
    _editingOriginSession = null;
    _editingStartingValue = null;
    _editingInstanceId = null;
  }

  /// Completes or cancels only the edit instance that owns the callback.
  void _returnToMenu(int? editInstanceId) {
    if (editInstanceId == null || editInstanceId != _editingInstanceId) return;
    setState(() {
      _clearEditing();
      _session = component.sessionController.state;
    });
  }

  /// Formats a verified value with thousands separators for status text.
  String _formatValue(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}
