import 'package:ludava_sdk/ludava_sdk.dart';

/// SDK capabilities consumed by the Flutter trainer controller.
abstract interface class TrainerSdkCapability {
  /// Latest immutable session snapshot published by the SDK.
  TrainerSessionState get state;

  /// Emits the current session snapshot and subsequent SDK updates.
  Stream<TrainerSessionState> get stateChanges;

  /// Starts process discovery.
  void connect();

  /// Refreshes the selected process session.
  void refresh();

  /// Selects an RPCS3 process by [processId].
  bool selectProcess(int processId);

  /// Performs the SDK-authorized write for [fieldId].
  GameWriteResult writeField(String fieldId, int value);

  /// Disposes the SDK runtime and its owned capabilities.
  Future<void> dispose();
}
