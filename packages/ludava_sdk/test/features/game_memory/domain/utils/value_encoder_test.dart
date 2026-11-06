import 'dart:typed_data';

import 'package:ludava_sdk/features/game_memory/domain/utils/value_encoder.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method encodeUnsigned32() behaves correctly', () {
    test('Method encodeUnsigned32() returns big-endian bytes', () {
      expect(ValueEncoder.encodeUnsigned32(0x00012345, ByteOrder.big), [
        0x00,
        0x01,
        0x23,
        0x45,
      ]);
    });

    test('Method encodeUnsigned32() returns little-endian bytes', () {
      expect(ValueEncoder.encodeUnsigned32(0x00012345, ByteOrder.little), [
        0x45,
        0x23,
        0x01,
        0x00,
      ]);
    });

    test('Method encodeUnsigned32() preserves zero and the maximum value', () {
      expect(ValueEncoder.encodeUnsigned32(0, ByteOrder.big), Uint8List(4));
      expect(ValueEncoder.encodeUnsigned32(0xffffffff, ByteOrder.big), [
        0xff,
        0xff,
        0xff,
        0xff,
      ]);
    });

    test(
      'Method encodeUnsigned32() rejects values outside the unsigned range',
      () {
        expect(
          () => ValueEncoder.encodeUnsigned32(-1, ByteOrder.big),
          throwsArgumentError,
        );
        expect(
          () => ValueEncoder.encodeUnsigned32(0x100000000, ByteOrder.big),
          throwsArgumentError,
        );
      },
    );

    test('Method encodeUnsigned32() rejects an unspecified byte order', () {
      expect(
        () => ValueEncoder.encodeUnsigned32(1, ByteOrder.none),
        throwsArgumentError,
      );
    });
  });
}
