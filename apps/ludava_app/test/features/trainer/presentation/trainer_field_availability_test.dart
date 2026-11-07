import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_field_availability.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Method TrainerFieldAvailability.hasWriteTarget behaves correctly', () {
    test('Method TrainerFieldAvailability.hasWriteTarget accepts an approved current target', () {
      final session = _session();

      expect(
        TrainerFieldAvailability.hasWriteTarget(
          session,
          session.profile!.fields.values.first,
        ),
        isTrue,
      );
    });

    test('Method TrainerFieldAvailability.hasWriteTarget rejects a missing profile', () {
      final field = _session().profile!.fields.values.first;

      expect(
        TrainerFieldAvailability.hasWriteTarget(TrainerSessionState(), field),
        isFalse,
      );
    });

    test('Method TrainerFieldAvailability.hasWriteTarget rejects missing approval or target evidence', () {
      final deniedSessions = [
        _session(profileWriteStatus: VerificationStatus.none),
        _session(fieldWriteStatus: VerificationStatus.none),
        _session(fieldReadStatus: VerificationStatus.none),
        _session(profileReadStatus: VerificationStatus.none),
        _session(omitMinimum: true),
        _session(omitMaximum: true),
        _session(selected: false),
        _session(hasMemoryBase: false),
        _session(confidence: GameIdentityConfidence.manuallySelected),
      ];

      for (final session in deniedSessions) {
        expect(
          TrainerFieldAvailability.hasWriteTarget(
            session,
            session.profile!.fields.values.first,
          ),
          isFalse,
        );
      }
    });
  });

  group('Method TrainerFieldAvailability.canEdit behaves correctly', () {
    test(
      'Method TrainerFieldAvailability.canEdit requires a successful read',
      () {
        final field = _session().profile!.fields.values.first;

        expect(TrainerFieldAvailability.canEdit(_session(), field), isTrue);
        expect(
          TrainerFieldAvailability.canEdit(_session(includeRead: false), field),
          isFalse,
        );
        expect(
          TrainerFieldAvailability.canEdit(
            _session(readStatus: GameReadStatus.readFailed),
            field,
          ),
          isFalse,
        );
      },
    );
  });
}

TrainerSessionState _session({
  VerificationStatus profileReadStatus = VerificationStatus.verified,
  VerificationStatus profileWriteStatus = VerificationStatus.verified,
  VerificationStatus fieldReadStatus = VerificationStatus.verified,
  VerificationStatus fieldWriteStatus = VerificationStatus.verified,
  GameIdentityConfidence confidence = GameIdentityConfidence.confirmed,
  GameReadStatus readStatus = GameReadStatus.success,
  bool selected = true,
  bool hasMemoryBase = true,
  bool omitMinimum = false,
  bool omitMaximum = false,
  bool includeRead = true,
}) {
  final field = GameField(
    id: 'bolts',
    name: 'Bolts',
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
    fields: {'bolts': field},
  );
  return TrainerSessionState(
    processIds: selected ? const [42] : const [],
    selectedProcessId: selected ? 42 : null,
    detection: GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: selected ? 42 : null,
      profile: profile,
      confidence: confidence,
      evidenceDescription: 'Test identity evidence.',
    ),
    memoryBase: hasMemoryBase ? 0x1000 : null,
    readResults: includeRead
        ? {
            'bolts': GameReadResult(
              status: readStatus,
              fieldId: 'bolts',
              value: readStatus == GameReadStatus.success ? 1 : null,
            ),
          }
        : const {},
  );
}
