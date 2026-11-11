import 'package:ludava_sdk/ludava_sdk.dart';

/// Creates a synthetic registered field with writable bounds.
GameField trainerStateFixtureField({String id = 'credits'}) => GameField(
  id: id,
  name: 'Credits',
  guestOffset: 0x100,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.little,
  minimumValue: 0,
  maximumValue: 100000,
);

/// Creates a synthetic SDK session suitable for trainer Redux tests.
TrainerSessionState trainerStateFixtureSession({
  String fieldId = 'credits',
  List<String> additionalFieldIds = const [],
  String gameName = 'Synthetic Game',
  String buildId = 'test-build',
  bool emptyProfile = false,
  int? memoryBase = 0x1000,
  int processId = 42,
  DateTime? startedAtUtc,
  GameReadResult? readResult,
  GameWriteResult? lastWriteResult,
  bool selectedProcessPresent = true,
  GameIdentityConfidence confidence = GameIdentityConfidence.confirmed,
  GameDetectionStatus detectionStatus = GameDetectionStatus.supportedGame,
  String profileId = 'synthetic-profile',
  String executableHash = 'synthetic-hash',
  int guestOffset = 0x100,
  MemoryValueType valueType = MemoryValueType.unsigned32,
  ByteOrder byteOrder = ByteOrder.little,
  int? minimumValue = 0,
  int? maximumValue = 100000,
}) {
  final fields = <String, GameField>{
    if (!emptyProfile)
      for (final id in [fieldId, ...additionalFieldIds])
        id: GameField(
          id: id,
          name: 'Credits',
          guestOffset: guestOffset,
          valueType: valueType,
          byteOrder: byteOrder,
          minimumValue: minimumValue,
          maximumValue: maximumValue,
        ),
  };
  final profile = GameProfile(
    id: profileId,
    gameName: gameName,
    buildId: buildId,
    executable: 'synthetic.exe',
    executableHash: executableHash,
    fields: fields,
  );
  return TrainerSessionState(
    processIds: selectedProcessPresent ? [processId] : const [],
    selectedProcessId: processId,
    processMetadata: Rpcs3ProcessMetadata(
      executablePath: r'C:\synthetic\rpcs3.exe',
      startedAtUtc: startedAtUtc ?? DateTime.utc(2026),
    ),
    detection: GameDetectionResult(
      status: detectionStatus,
      processId: processId,
      executable: 'synthetic.exe',
      executableHash: executableHash,
      confidence: confidence,
      profile: detectionStatus == GameDetectionStatus.supportedGame
          ? profile
          : null,
      evidenceDescription: 'Synthetic test evidence',
    ),
    memoryBase: memoryBase,
    readResults: readResult == null ? {} : {fieldId: readResult},
    lastWriteResult: lastWriteResult,
  );
}
