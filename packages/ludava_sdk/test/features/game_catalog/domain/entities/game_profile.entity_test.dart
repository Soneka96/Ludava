import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

abstract final class _GameProfileTestData {
  static GameProfile build({
    VerificationStatus readStatus = VerificationStatus.experimental,
    VerificationStatus writeStatus = VerificationStatus.none,
    Map<String, GameField> fields = const {},
  }) => GameProfile(
    id: 'synthetic-profile',
    gameName: 'Synthetic game',
    buildId: 'TEST00001',
    executable: 'SYNTHETIC.self',
    readStatus: readStatus,
    writeStatus: writeStatus,
    fields: fields,
  );

  static GameField buildCreditField() => GameField(
    id: 'credits',
    name: 'Credits',
    guestOffset: 0x1234,
    valueType: MemoryValueType.unsigned32,
    byteOrder: ByteOrder.big,
    readStatus: VerificationStatus.experimental,
  );

  static GameField buildHealthField() => GameField(
    id: 'health',
    name: 'Health',
    guestOffset: 0x2000,
    valueType: MemoryValueType.unsigned32,
    byteOrder: ByteOrder.big,
    readStatus: VerificationStatus.experimental,
  );
}

void main() {
  group('Class GameProfile construction', () {
    test(
      'Class GameProfile initializes identity and an immutable field map',
      () {
        final fields = {'credits': _GameProfileTestData.buildCreditField()};
        final profile = _GameProfileTestData.build(fields: fields);
        fields['health'] = _GameProfileTestData.buildHealthField();

        expect(profile.fields.keys, ['credits']);
        expect(profile.fields.containsKey('health'), isFalse);
        expect(
          () =>
              profile.fields['health'] =
                  _GameProfileTestData.buildHealthField(),
          throwsUnsupportedError,
        );
      },
    );

    test(
      'Class GameProfile rejects a map key that differs from its field id',
      () {
        expect(
          () => _GameProfileTestData.build(
            fields: {'other': _GameProfileTestData.buildCreditField()},
          ),
          throwsArgumentError,
        );
      },
    );
  });

  group('Property canRead behaves correctly', () {
    test('Property canRead returns true when status is experimental', () {
      expect(
        _GameProfileTestData.build(
          readStatus: VerificationStatus.experimental,
        ).canRead,
        isTrue,
      );
    });

    test('Property canRead returns true when status is verified', () {
      expect(
        _GameProfileTestData.build(
          readStatus: VerificationStatus.verified,
        ).canRead,
        isTrue,
      );
    });

    test(
      'Property canRead returns false when status is none or unsupported',
      () {
        for (final status in [
          VerificationStatus.none,
          VerificationStatus.unsupported,
        ]) {
          expect(
            _GameProfileTestData.build(readStatus: status).canRead,
            isFalse,
          );
        }
      },
    );
  });

  group('Property canWrite behaves correctly', () {
    test('Property canWrite returns true when status is verified', () {
      expect(
        _GameProfileTestData.build(
          writeStatus: VerificationStatus.verified,
        ).canWrite,
        isTrue,
      );
    });

    test(
      'Property canWrite returns true when status is research-confirmed',
      () {
        expect(
          _GameProfileTestData.build(
            writeStatus: VerificationStatus.researchConfirmed,
          ).canWrite,
          isTrue,
        );
      },
    );

    test('Property canWrite returns false when status is not verified', () {
      for (final status in [
        VerificationStatus.none,
        VerificationStatus.experimental,
        VerificationStatus.unsupported,
      ]) {
        expect(
          _GameProfileTestData.build(writeStatus: status).canWrite,
          isFalse,
        );
      }
    });
  });

  group('Method findField() behaves correctly', () {
    test(
      'Method findField() returns the matching field when id is present',
      () {
        final profile = _GameProfileTestData.build(
          fields: {'credits': _GameProfileTestData.buildCreditField()},
        );

        expect(profile.findField('credits'), isA<GameField>());
        expect(profile.findField('credits')?.id, 'credits');
      },
    );

    test('Method findField() returns null when id is missing', () {
      expect(_GameProfileTestData.build().findField('health'), isNull);
    });
  });
}
