import 'dart:typed_data';

int decodeUint32(Uint8List bytes, {required Endian endian}) {
  if (bytes.length != 4) {
    throw ArgumentError.value(
      bytes.length,
      'bytes.length',
      'must be exactly 4',
    );
  }

  return ByteData.sublistView(bytes).getUint32(0, endian);
}
