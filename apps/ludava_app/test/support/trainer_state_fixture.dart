import 'package:ludava_sdk/ludava_sdk.dart';

/// Creates a synthetic field that is approved for reading and writing.
GameField trainerStateFixtureField({
  String id = 'credits',
  VerificationStatus readStatus = VerificationStatus.verified,
  VerificationStatus writeStatus = VerificationStatus.researchConfirmed,
}) => GameField(
  id: id,
  name: 'Credits',
  guestOffset: 0x100,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.little,
  readStatus: readStatus,
  writeStatus: writeStatus,
  minimumValue: 0,
  maximumValue: 100000,
);

/// Creates a synthetic SDK session suitable for trainer Redux tests.
TrainerSessionState trainerStateFixtureSession({
  String fieldId = 'credits',
  List<String> additionalFieldIds = const [],
  String gameName = 'Synthetic Game',
  VerificationStatus fieldWriteStatus = VerificationStatus.researchConfirmed,
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
}) {
  final fields = <String, GameField>{
    if (!emptyProfile)
      for (final id in [fieldId, ...additionalFieldIds])
        id: trainerStateFixtureField(id: id, writeStatus: fieldWriteStatus),
  };
  final profile = GameProfile(
    id: profileId,
    gameName: gameName,
    buildId: 'test-build',
    executable: 'synthetic.exe',
    executableHash: executableHash,
    readStatus: VerificationStatus.verified,
    writeStatus: VerificationStatus.researchConfirmed,
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
