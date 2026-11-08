import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/game_profile_catalog.dart';
import 'package:ludava_sdk/features/game_memory/domain/utils/address_resolver.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

/// Returns the executable identity used to distinguish registered builds.
String _profileIdentity(GameProfile profile) =>
    '${profile.buildId.trim().toLowerCase()}\u0000'
    '${profile.executable.trim().toLowerCase()}\u0000'
    '${profile.executableHash?.trim().toLowerCase() ?? ''}';

void main() {
  group('Method find() behaves correctly', () {
    test('Method find() returns each registered profile by its id', () {
      for (final profile in GameProfileCatalog.profiles) {
        expect(GameProfileCatalog.find(profile.id), same(profile));
      }
    });

    test('Method find() returns null when profile id is not registered', () {
      expect(GameProfileCatalog.find('unregistered-synthetic-profile'), isNull);
    });
  });

  group('Property profiles behaves correctly', () {
    test('Property profiles exposes distinguishable valid identities', () {
      final profiles = GameProfileCatalog.profiles;
      final profileIds = <String>{};
      final identities = <String>{};

      expect(profiles, isNotEmpty);
      for (final profile in profiles) {
        expect(profile.id.trim(), isNotEmpty);
        expect(profile.gameName.trim(), isNotEmpty, reason: profile.id);
        expect(profile.buildId.trim(), isNotEmpty, reason: profile.id);
        expect(profile.executable.trim(), isNotEmpty, reason: profile.id);
        expect(
          profile.executableHash == null ||
              profile.executableHash!.trim().isNotEmpty,
          isTrue,
          reason: profile.id,
        );
        expect(profileIds.add(profile.id), isTrue, reason: profile.id);
        expect(
          identities.add(_profileIdentity(profile)),
          isTrue,
          reason: 'Duplicate executable identity for ${profile.id}',
        );
        expect(GameProfileCatalog.find(profile.id), same(profile));
      }
    });

    test('Property profiles contains structurally valid fields', () {
      for (final profile in GameProfileCatalog.profiles) {
        for (final entry in profile.fields.entries) {
          final field = entry.value;
          final byteLength = field.valueType.byteLength;

          expect(entry.key.trim(), isNotEmpty, reason: profile.id);
          expect(entry.key, field.id, reason: profile.id);
          expect(
            field.name.trim(),
            isNotEmpty,
            reason: '${profile.id}.${field.id}',
          );
          expect(byteLength, isNotNull, reason: '${profile.id}.${field.id}');
          expect(field.byteOrder, isNot(ByteOrder.none), reason: profile.id);
          expect(
            () => AddressResolver.resolve(
              memoryBase: 0,
              guestOffset: field.guestOffset,
              byteLength: byteLength!,
            ),
            returnsNormally,
            reason: '${profile.id}.${field.id} has an invalid memory mapping',
          );

          final maximumValue = switch (field.valueType) {
            MemoryValueType.none => null,
            MemoryValueType.unsigned32 => GameMemoryConstants.maxUnsigned32,
          };
          expect(
            field.minimumValue == null ||
                (field.minimumValue! >= 0 &&
                    maximumValue != null &&
                    field.minimumValue! <= maximumValue),
            isTrue,
            reason: '${profile.id}.${field.id} has an invalid minimum',
          );
          expect(
            field.maximumValue == null ||
                (field.maximumValue! >= 0 &&
                    maximumValue != null &&
                    field.maximumValue! <= maximumValue),
            isTrue,
            reason: '${profile.id}.${field.id} has an invalid maximum',
          );
          expect(
            field.minimumValue == null ||
                field.maximumValue == null ||
                field.minimumValue! <= field.maximumValue!,
            isTrue,
            reason: '${profile.id}.${field.id} has an inverted range',
          );
          if (field.canWrite) {
            expect(profile.canWrite, isTrue, reason: profile.id);
            expect(field.minimumValue, isNotNull, reason: profile.id);
            expect(field.maximumValue, isNotNull, reason: profile.id);
          }
        }
      }
    });
  });
}
