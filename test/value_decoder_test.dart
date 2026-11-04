import 'dart:typed_data';

import 'package:ludava/src/value_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('decodeUint32', () {
    test('decodes big-endian unsigned values', () {
      expect(
        decodeUint32(
          Uint8List.fromList([0x00, 0x01, 0x23, 0x45]),
          endian: Endian.big,
        ),
        0x00012345,
      );
    });

    test('preserves a legitimate zero value', () {
      expect(decodeUint32(Uint8List(4), endian: Endian.big), 0);
    });

    test('preserves the full unsigned 32-bit range', () {
      expect(
        decodeUint32(
          Uint8List.fromList([0xff, 0xff, 0xff, 0xff]),
          endian: Endian.big,
        ),
        0xffffffff,
      );
    });

    test('uses the explicitly requested byte order', () {
      expect(
        decodeUint32(
          Uint8List.fromList([0x00, 0x01, 0x23, 0x45]),
          endian: Endian.little,
        ),
        0x45230100,
      );
    });

    test('rejects buffers shorter or longer than four bytes', () {
      expect(
        () => decodeUint32(Uint8List(3), endian: Endian.big),
        throwsArgumentError,
      );
      expect(
        () => decodeUint32(Uint8List(5), endian: Endian.big),
        throwsArgumentError,
      );
    });
  });
}
