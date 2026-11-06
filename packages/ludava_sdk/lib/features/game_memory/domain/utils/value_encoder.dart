import 'dart:typed_data';

import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Encodes typed values according to a game's memory representation.
abstract final class ValueEncoder {
  /// Encodes [value] as an unsigned 32-bit integer in [byteOrder].
  static Uint8List encodeUnsigned32(int value, ByteOrder byteOrder) {
    if (value < 0 || value > GameMemoryConstants.maxUnsigned32) {
      throw ArgumentError.value(
        value,
        'value',
        'must fit an unsigned 32-bit value',
      );
    }
    final endian = switch (byteOrder) {
      ByteOrder.big => Endian.big,
      ByteOrder.little => Endian.little,
      ByteOrder.none =>
        throw ArgumentError.value(byteOrder, 'byteOrder', 'must be selected'),
    };
    final data = ByteData(4)..setUint32(0, value, endian);
    return data.buffer.asUint8List();
  }
}
