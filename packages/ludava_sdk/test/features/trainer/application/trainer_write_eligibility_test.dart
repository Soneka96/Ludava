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
    processIds: processIsDiscovered ? const [42] : const [],
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
      processId: detectionProcessId ?? 42,
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

/// Creates a valid field without attaching it to a profile.
GameField _standaloneField() => GameField(
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

void _expectInvalidTarget(String scenario, TrainerSessionState session) {
  expect(
    TrainerWriteEligibility.hasValidTarget(session, _field(session)),
    isFalse,
    reason: scenario,
  );
}

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
      'Method TrainerWriteEligibility.hasValidTarget() rejects unapproved profile reads',
      () => _expectInvalidTarget(
        'profile read approval is missing',
        _session(profileReadStatus: VerificationStatus.none),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects unapproved profile writes',
      () => _expectInvalidTarget(
        'profile write approval is missing',
        _session(profileWriteStatus: VerificationStatus.none),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects unapproved field reads',
      () => _expectInvalidTarget(
        'field read approval is missing',
        _session(fieldReadStatus: VerificationStatus.none),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects unapproved field writes',
      () => _expectInvalidTarget(
        'field write approval is missing',
        _session(fieldWriteStatus: VerificationStatus.none),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects a missing minimum bound',
      () => _expectInvalidTarget(
        'minimum value bound is missing',
        _session(omitMinimum: true),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects a missing maximum bound',
      () => _expectInvalidTarget(
        'maximum value bound is missing',
        _session(omitMaximum: true),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects a missing selected process',
      () => _expectInvalidTarget(
        'selected process is missing while discovery and detection remain valid',
        _session(selected: false),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects a process absent from discovery',
      () => _expectInvalidTarget(
        'selected process is absent from discovered process ids',
        _session(processIsDiscovered: false),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects missing process metadata',
      () => _expectInvalidTarget(
        'selected process metadata is missing',
        _session(includeMetadata: false),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects detection for another process',
      () => _expectInvalidTarget(
        'detection process id differs from the selected process',
        _session(detectionProcessId: 43),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects a missing memory base',
      () => _expectInvalidTarget(
        'session memory base is missing',
        _session(hasMemoryBase: false),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects unconfirmed identity confidence',
      () => _expectInvalidTarget(
        'identity confidence is only manually selected',
        _session(confidence: GameIdentityConfidence.manuallySelected),
      ),
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects a valid field when there is no active profile',
      () {
        final session = TrainerSessionState();

        expect(
          TrainerWriteEligibility.hasValidTarget(session, _standaloneField()),
          isFalse,
          reason: 'session has no active profile for the standalone field',
        );
      },
    );

    test(
      'Method TrainerWriteEligibility.hasValidTarget() rejects a field owned by another profile',
      () {
        final session = _session();
        final foreignField = _field(_session());

        expect(
          TrainerWriteEligibility.hasValidTarget(session, foreignField),
          isFalse,
          reason: 'field belongs to a different profile instance',
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
        final missingReadSession = _session(includeRead: false);
        final missingReadField = _field(missingReadSession);
        expect(
          TrainerWriteEligibility.isWriteEligible(
            missingReadSession,
            missingReadField,
          ),
          isFalse,
          reason: 'current read is missing for an otherwise valid target',
        );
        final failedReadSession = _session(
          readStatus: GameReadStatus.readFailed,
        );
        final failedReadField = _field(failedReadSession);
        expect(
          TrainerWriteEligibility.isWriteEligible(
            failedReadSession,
            failedReadField,
          ),
          isFalse,
          reason: 'current read failed for an otherwise valid target',
        );
      },
    );

    test(
      'Method TrainerWriteEligibility.isWriteEligible() denies an approved field when the profile is not approved',
      () {
        final session = _session(profileWriteStatus: VerificationStatus.none);
        final field = _field(session);

        expect(field.canWrite, isTrue);
        expect(session.profile!.canWrite, isFalse);
        expect(
          TrainerWriteEligibility.isWriteEligible(session, field),
          isFalse,
        );
      },
    );
  });
}
