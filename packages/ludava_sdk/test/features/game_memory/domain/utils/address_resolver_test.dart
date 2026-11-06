import 'package:ludava_sdk/features/game_memory/domain/utils/address_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('Method resolve() behaves correctly', () {
    test('Method resolve() returns the RC2 host address when mapping is valid',
        () {
      expect(
        AddressResolver.resolve(
          memoryBase: 0x300000000,
          guestOffset: 0x01329e80,
          byteLength: 4,
        ),
        0x301329e80,
      );
    });

    test('Method resolve() preserves addresses above 32 bits when valid', () {
      expect(
        AddressResolver.resolve(
          memoryBase: 0x100000000,
          guestOffset: 0x1234,
          byteLength: 4,
        ),
        0x100001234,
      );
    });

    test('Method resolve() accepts the maximum native address for one byte',
        () {
      expect(
        AddressResolver.resolve(
          memoryBase: 0x7fffffffffffffff,
          guestOffset: 0,
          byteLength: 1,
        ),
        0x7fffffffffffffff,
      );
    });

    test(
        'Method resolve() throws ArgumentError for negative inputs or empty ranges',
        () {
      expect(
        () => AddressResolver.resolve(
          memoryBase: -1,
          guestOffset: 0,
          byteLength: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => AddressResolver.resolve(
          memoryBase: 0,
          guestOffset: -1,
          byteLength: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => AddressResolver.resolve(
          memoryBase: 0,
          guestOffset: 0,
          byteLength: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => AddressResolver.resolve(
          memoryBase: 0,
          guestOffset: 0,
          byteLength: -1,
        ),
        throwsArgumentError,
      );
    });

    test('Method resolve() throws RangeError when addition or range overflows',
        () {
      expect(
        () => AddressResolver.resolve(
          memoryBase: 0x7fffffffffffffff,
          guestOffset: 1,
          byteLength: 1,
        ),
        throwsRangeError,
      );
      expect(
        () => AddressResolver.resolve(
          memoryBase: 0x7ffffffffffffffe,
          guestOffset: 0,
          byteLength: 4,
        ),
        throwsRangeError,
      );
    });
  });
}
