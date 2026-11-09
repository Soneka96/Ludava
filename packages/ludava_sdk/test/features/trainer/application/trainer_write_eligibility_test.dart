import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava_sdk/features/trainer/application/trainer_session_state.entity.dart';
import 'package:ludava_sdk/features/trainer/application/trainer_write_eligibility.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

TrainerSessionState _session({
  VerificationStatus profileReadStatus = VerificationStatus.verified,
  VerificationStatus profileWriteStatus = VerificationStatus.verified,
  VerificationStatus fieldReadStatus = VerificationStatus.verified,
  VerificationStatus fieldWriteStatus = VerificationStatus.verified,
  GameIdentityConfidence confidence = GameIdentityConfidence.confirmed,
  GameReadStatus readStatus = GameReadStatus.success,
  bool selected = true,
  bool processIsDiscovered = true,
  bool includeMetadata = true,
  int? detectionProcessId,
  bool hasMemoryBase = true,
  bool omitMinimum = false,
  bool omitMaximum = false,
  bool includeRead = true,
}) {
  final field = GameField(
    id: 'credits',
    name: 'Credits',
    guestOffset: 0,
    valueType: MemoryValueType.unsigned32,
    byteOrder: ByteOrder.big,
    readStatus: fieldReadStatus,
    writeStatus: fieldWriteStatus,
    minimumValue: omitMinimum ? null : 0,
    maximumValue: omitMaximum ? null : 4294967295,
  );
  final profile = GameProfile(
    id: 'test-game',
    gameName: 'Test game',
    buildId: 'TEST',
    executable: 'test.self',
    readStatus: profileReadStatus,
    writeStatus: profileWriteStatus,
    fields: {'credits': field},
  );
  return TrainerSessionState(
    processIds: selected && processIsDiscovered ? const [42] : const [],
    selectedProcessId: selected ? 42 : null,
    processMetadata:
        includeMetadata
            ? Rpcs3ProcessMetadata(
              executablePath: r'C:\RPCS3\rpcs3.exe',
              startedAtUtc: DateTime.utc(2026),
            )
            : null,
    detection: GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: detectionProcessId ?? (selected ? 42 : null),
      profile: profile,
      confidence: confidence,
      evidenceDescription: 'Synthetic test identity evidence.',
    ),
    memoryBase: hasMemoryBase ? 0x1000 : null,
    readResults:
        includeRead
            ? {
              'credits': GameReadResult(
                status: readStatus,
                fieldId: 'credits',
                value: readStatus == GameReadStatus.success ? 1 : null,
              ),
            }
            : const {},
  );
}

/// Returns the profile field from [session] for eligibility assertions.
GameField _field(TrainerSessionState session) =>
    session.profile!.fields.values.first;

/// Creates a separately allocated field to model a stale or foreign target.
GameField _orphanField() => GameField(
  id: 'credits',
  name: 'Credits',
  guestOffset: 0,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  readStatus: VerificationStatus.verified,
  writeStatus: VerificationStatus.verified,
  minimumValue: 0,
  maximumValue: 4294967295,
);

void main() {
  group('Method TrainerWriteEligibility.hasValidTarget() behaves correctly', () {
    test(
      'Method TrainerWriteEligibility.hasValidTarget() accepts approved target evidence',
      () {
        final session = _session();

        expect(
          TrainerWriteEligibility.hasValidTarget(session, _field(session)),
          isTrue,
        );
      },
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects missing approval or target evidence',
      () {
        final deniedSessions = [
          TrainerSessionState(),
          _session(profileReadStatus: VerificationStatus.none),
          _session(profileWriteStatus: VerificationStatus.none),
          _session(fieldReadStatus: VerificationStatus.none),
          _session(fieldWriteStatus: VerificationStatus.none),
          _session(omitMinimum: true),
          _session(omitMaximum: true),
          _session(selected: false),
          _session(processIsDiscovered: false),
          _session(includeMetadata: false),
          _session(detectionProcessId: 43),
          _session(hasMemoryBase: false),
          _session(confidence: GameIdentityConfidence.manuallySelected),
        ];
        final field = _field(_session());

        for (final session in deniedSessions) {
          expect(
            TrainerWriteEligibility.hasValidTarget(session, field),
            isFalse,
          );
        }
        expect(
          TrainerWriteEligibility.hasValidTarget(_session(), _orphanField()),
          isFalse,
        );
      },
    );
  });

  group('Method TrainerWriteEligibility.isWriteEligible() behaves correctly', () {
    test(
      'Method TrainerWriteEligibility.isWriteEligible() requires a successful current read',
      () {
        final session = _session();
        final field = _field(session);

        expect(TrainerWriteEligibility.isWriteEligible(session, field), isTrue);
        expect(
          TrainerWriteEligibility.isWriteEligible(
            _session(includeRead: false),
            _field(_session(includeRead: false)),
          ),
          isFalse,
        );
        expect(
          TrainerWriteEligibility.isWriteEligible(
            _session(readStatus: GameReadStatus.readFailed),
            _field(_session(readStatus: GameReadStatus.readFailed)),
          ),
          isFalse,
        );
      },
    );
  });
}

/// Builds a synthetic confirmed session with configurable eligibility evidence.
