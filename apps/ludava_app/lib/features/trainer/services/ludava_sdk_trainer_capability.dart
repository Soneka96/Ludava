import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Adapts one owned [LudavaSdk] to the Flutter trainer capability.
class LudavaSdkTrainerCapability implements TrainerSdkCapability {
  /// Wraps the SDK runtime owned by this capability.
  LudavaSdkTrainerCapability(this._sdk);

  final LudavaSdk _sdk;

  /// Returns the current SDK trainer snapshot.
  @override
  TrainerSessionState get state => _sdk.session.state;

  /// Forwards trainer session observations from the SDK.
  @override
  Stream<TrainerSessionState> get stateChanges => _sdk.session.stateChanges;

  /// Starts SDK process discovery.
  @override
  void connect() => _sdk.session.connect();

  /// Refreshes the SDK's selected process session.
  @override
  void refresh() => _sdk.session.refresh();

  /// Selects [processId] through the SDK trainer session.
  @override
  bool selectProcess(int processId) => _sdk.session.selectProcess(processId);

  /// Delegates [fieldId] and [value] to the SDK's guarded write.
  @override
  GameWriteResult writeField(String fieldId, int value) =>
      _sdk.session.writeField(fieldId, value);

  /// Disposes the complete SDK runtime.
  @override
  Future<void> dispose() => _sdk.dispose();
}
