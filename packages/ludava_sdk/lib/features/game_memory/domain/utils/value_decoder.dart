import 'dart:typed_data';

import 'package:ludava_sdk/shared/constants/enums.dart';

/// Decodes bytes according to a game's declared memory value type.
abstract final class ValueDecoder {
  /// Decodes an unsigned 32-bit integer in [byteOrder].
  static int decodeUnsigned32(Uint8List bytes, ByteOrder byteOrder) {
    if (bytes.length != 4) {
      throw ArgumentError.value(
        bytes.length,
        'bytes.length',
        'must be exactly 4',
      );
    }
    final endian = switch (byteOrder) {
      ByteOrder.big => Endian.big,
      ByteOrder.little => Endian.little,
      ByteOrder.none => throw ArgumentError.value(
          byteOrder,
          'byteOrder',
          'must be selected',
        ),
    };
    return ByteData.sublistView(bytes).getUint32(0, endian);
  }
}
