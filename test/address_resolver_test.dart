import 'package:ludava/src/address_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('resolveGuestAddress', () {
    test('resolves the research-backed guest offset against an explicit base',
        () {
      expect(
        resolveGuestAddress(
          memoryBase: 0x300000000,
          guestOffset: 0x01329e80,
          byteLength: 4,
        ),
        0x301329e80,
      );
    });

    test('preserves an address above 32 bits', () {
      expect(
        resolveGuestAddress(
          memoryBase: 0x100000000,
          guestOffset: 0x1234,
          byteLength: 4,
        ),
        0x100001234,
      );
    });

    test('accepts a zero base and zero offset when the range is valid', () {
      expect(
        resolveGuestAddress(memoryBase: 0, guestOffset: 0, byteLength: 1),
        0,
      );
    });

    test('accepts a field ending at the maximum native address', () {
      expect(
        resolveGuestAddress(
          memoryBase: 0x7fffffffffffffff,
          guestOffset: 0,
          byteLength: 1,
        ),
        0x7fffffffffffffff,
      );
    });

    test('rejects negative inputs and empty ranges', () {
      expect(
        () =>
            resolveGuestAddress(memoryBase: -1, guestOffset: 0, byteLength: 1),
        throwsArgumentError,
      );
      expect(
        () =>
            resolveGuestAddress(memoryBase: 0, guestOffset: -1, byteLength: 1),
        throwsArgumentError,
      );
      expect(
        () => resolveGuestAddress(memoryBase: 0, guestOffset: 0, byteLength: 0),
        throwsArgumentError,
      );
    });

    test('rejects addition and full field-range overflow', () {
      expect(
        () => resolveGuestAddress(
          memoryBase: 0x7fffffffffffffff,
          guestOffset: 1,
          byteLength: 1,
        ),
        throwsRangeError,
      );
      expect(
        () => resolveGuestAddress(
          memoryBase: 0x7ffffffffffffffe,
          guestOffset: 0,
          byteLength: 4,
        ),
        throwsRangeError,
      );
    });
  });
}
