import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

abstract final class _GameProfileTestData {
  static GameProfile build({Map<String, GameField> fields = const {}}) =>
      GameProfile(
        id: 'synthetic-profile',
        gameName: 'Synthetic game',
        buildId: 'TEST00001',
        executable: 'SYNTHETIC.self',
        fields: fields,
      );

  static GameField buildCreditField() => GameField(
    id: 'credits',
    name: 'Credits',
    guestOffset: 0x1234,
    valueType: MemoryValueType.unsigned32,
    byteOrder: ByteOrder.big,
  );

  static GameField buildHealthField() => GameField(
    id: 'health',
    name: 'Health',
    guestOffset: 0x2000,
    valueType: MemoryValueType.unsigned32,
    byteOrder: ByteOrder.big,
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
