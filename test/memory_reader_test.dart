import 'dart:typed_data';

import 'package:ludava/src/memory_reader.dart';
import 'package:test/test.dart';

void main() {
  test('marks only complete results as complete', () {
    final result = MemoryReadResult(
      status: MemoryReadStatus.complete,
      bytes: Uint8List(4),
      bytesRead: 4,
      requestedBytes: 4,
    );
    final failed = MemoryReadResult(
      status: MemoryReadStatus.nativeFailure,
      bytes: Uint8List(0),
      bytesRead: 0,
      requestedBytes: 4,
      errorCode: 299,
    );

    expect(result.isComplete, isTrue);
    expect(failed.isComplete, isFalse);
    expect(failed.errorCode, 299);
  });
}
