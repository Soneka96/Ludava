import 'dart:typed_data';

enum MemoryReadStatus {
  complete,
  nativeFailure,
  partial,
  invalidAddress,
  invalidRequest,
  invalidByteCount,
}

class MemoryReadResult {
  const MemoryReadResult({
    required this.status,
    required this.bytes,
    required this.bytesRead,
    required this.requestedBytes,
    this.errorCode,
  });

  final MemoryReadStatus status;
  final Uint8List bytes;
  final int bytesRead;
  final int requestedBytes;
  final int? errorCode;

  bool get isComplete => status == MemoryReadStatus.complete;
}

abstract interface class MemoryReader {
  MemoryReadResult read(int address, int byteCount);
}
