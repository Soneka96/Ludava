import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Coordinates Flutter trainer interaction with one owned SDK runtime.
class TrainerController implements Listenable {
  /// Creates an SDK-backed trainer controller and starts RPCS3 discovery.
  TrainerController({LudavaSdk? sdk}) : _sdk = sdk ?? LudavaSdk.create() {
    _session = _sdk.session.state;
    _stateSubscription = _sdk.session.stateChanges.listen(_handleStateChanged);
    _sdk.session.connect();
  }

  final LudavaSdk _sdk;
  final ValueNotifier<int> _changeVersion = ValueNotifier(0);
  late TrainerSessionState _session;
  String? _editingFieldId;
  StreamSubscription<TrainerSessionState>? _stateSubscription;
  Future<void>? _disposeFuture;
  bool _disposed = false;

  /// Latest immutable session snapshot published by the SDK.
  TrainerSessionState get session => _session;

  /// ID of the field being edited, or `null` when no field is active.
  String? get editingFieldId => _editingFieldId;

  /// Registers [listener] for session and editing-state changes.
  @override
  void addListener(VoidCallback listener) =>
      _changeVersion.addListener(listener);

  /// Removes a previously registered [listener].
  @override
  void removeListener(VoidCallback listener) =>
      _changeVersion.removeListener(listener);

  /// Refreshes a selected session or rediscovers when no process is selected.
  void refresh() {
    _ensureActive();
    if (_session.selectedProcessId == null) {
      _sdk.session.connect();
    } else {
      _sdk.session.refresh();
    }
  }

  /// Selects an RPCS3 process through the SDK trainer session.
  bool selectProcess(int processId) {
    _ensureActive();
    return _sdk.session.selectProcess(processId);
  }

  /// Opens the editor for [field] only when the SDK marks its target eligible.
  bool editField(GameField field) {
    _ensureActive();
    if (!TrainerWriteEligibility.isWriteEligible(_session, field)) return false;
    if (_editingFieldId == field.id) return true;
    _editingFieldId = field.id;
    _notifyListeners();
    return true;
  }

  /// Delegates [value] to the SDK's guarded write for [fieldId].
  GameWriteResult writeField(String fieldId, int value) {
    _ensureActive();
    final result = _sdk.session.writeField(fieldId, value);
    if (result.succeeded && _editingFieldId == fieldId) {
      _editingFieldId = null;
      _notifyListeners();
    }
    return result;
  }

  /// Clears the active field selection without changing SDK session state.
  void cancelEditing() {
    _ensureActive();
    if (_editingFieldId == null) return;
    _editingFieldId = null;
    _notifyListeners();
  }

  /// Cancels state observation and awaits disposal of the owned SDK runtime.
  Future<void> dispose() {
    final existingDisposal = _disposeFuture;
    if (existingDisposal != null) return existingDisposal;
    _disposed = true;
    final subscription = _stateSubscription;
    _stateSubscription = null;
    final cancellation = subscription?.cancel();
    final sdkDisposal = _sdk.dispose();
    return _disposeFuture = _finishDisposal(cancellation, sdkDisposal);
  }

  /// Waits for owned resources before releasing controller listeners.
  Future<void> _finishDisposal(
    Future<void>? cancellation,
    Future<void> sdkDisposal,
  ) async {
    try {
      await Future.wait<void>([?cancellation, sdkDisposal]);
    } finally {
      _changeVersion.dispose();
    }
  }

  /// Reconciles an SDK snapshot with the active field's write target.
  void _handleStateChanged(TrainerSessionState state) {
    if (_disposed) return;
    final editingFieldId = _editingFieldId;
    if (editingFieldId != null) {
      final field = state.profile?.findField(editingFieldId);
      final readResult = state.readResults[editingFieldId];
      if (!_sameSession(_session, state) ||
          field == null ||
          !TrainerWriteEligibility.hasValidTarget(state, field) ||
          (readResult != null &&
              !readResult.succeeded &&
              state.lastWriteResult?.fieldId != editingFieldId)) {
        _editingFieldId = null;
      }
    }
    _session = state;
    _notifyListeners();
  }

  /// Signals that the current session or editing field has changed.
  void _notifyListeners() => _changeVersion.value++;

  /// Reports whether [first] and [second] describe the same write target.
  bool _sameSession(TrainerSessionState first, TrainerSessionState second) =>
      first.selectedProcessId == second.selectedProcessId &&
      first.processMetadata?.startedAtUtc ==
          second.processMetadata?.startedAtUtc &&
      first.detection?.status == second.detection?.status &&
      first.detection?.confidence == second.detection?.confidence &&
      first.profile?.id == second.profile?.id &&
      first.detection?.executableHash == second.detection?.executableHash &&
      first.memoryBase == second.memoryBase;

  /// Rejects operations after terminal disposal has begun.
  void _ensureActive() {
    if (_disposed) {
      throw StateError('This Flutter trainer controller has been disposed.');
    }
  }
}
