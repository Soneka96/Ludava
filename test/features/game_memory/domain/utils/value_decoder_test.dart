import 'dart:typed_data';

import 'package:ludava/features/game_memory/domain/utils/value_decoder.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method decodeUnsigned32() behaves correctly', () {
    test('Method decodeUnsigned32() returns the big-endian unsigned value', () {
      expect(
        ValueDecoder.decodeUnsigned32(
          Uint8List.fromList([0x00, 0x01, 0x23, 0x45]),
          ByteOrder.big,
        ),
        0x00012345,
      );
    });

    test('Method decodeUnsigned32() returns the little-endian value', () {
      expect(
        ValueDecoder.decodeUnsigned32(
          Uint8List.fromList([0x00, 0x01, 0x23, 0x45]),
          ByteOrder.little,
        ),
        0x45230100,
      );
    });

    test('Method decodeUnsigned32() preserves zero and the maximum value', () {
      expect(
        ValueDecoder.decodeUnsigned32(Uint8List(4), ByteOrder.big),
        0,
      );
      expect(
        ValueDecoder.decodeUnsigned32(
          Uint8List.fromList([0xff, 0xff, 0xff, 0xff]),
          ByteOrder.big,
        ),
        GameMemoryConstants.maxUnsigned32,
      );
    });

    test(
        'Method decodeUnsigned32() throws ArgumentError for non-four-byte input',
        () {
      for (final length in [3, 5]) {
        expect(
          () => ValueDecoder.decodeUnsigned32(
            Uint8List(length),
            ByteOrder.big,
          ),
          throwsArgumentError,
        );
      }
    });

    test(
        'Method decodeUnsigned32() throws ArgumentError when byte order is none',
        () {
      expect(
        () => ValueDecoder.decodeUnsigned32(Uint8List(4), ByteOrder.none),
        throwsArgumentError,
      );
    });
  });
}
