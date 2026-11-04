import 'address_resolver.dart';
import 'game_profile.dart';
import 'memory_reader.dart';
import 'value_decoder.dart';

enum BoltReadStatus {
  success,
  unsupportedProfile,
  invalidMapping,
  readFailed,
  incompleteRead,
  invalidReadResult,
}

class BoltReadResult {
  const BoltReadResult({
    required this.status,
    this.boltCount,
    this.errorCode,
  });

  final BoltReadStatus status;
  final int? boltCount;
  final int? errorCode;

  bool get succeeded => status == BoltReadStatus.success;
}

class BoltService {
  const BoltService(this._memoryReader);

  final MemoryReader _memoryReader;

  BoltReadResult readBolts({
    required GameProfile profile,
    required int memoryBase,
  }) {
    if (!profile.canReadExperimentally) {
      return const BoltReadResult(status: BoltReadStatus.unsupportedProfile);
    }

    final byteLength = profile.boltType.byteLength;
    late final int address;
    try {
      address = resolveGuestAddress(
        memoryBase: memoryBase,
        guestOffset: profile.boltGuestOffset,
        byteLength: byteLength,
      );
    } on ArgumentError {
      return const BoltReadResult(status: BoltReadStatus.invalidMapping);
    }

    final read = _memoryReader.read(address, byteLength);
    if (read.status == MemoryReadStatus.nativeFailure) {
      return BoltReadResult(
        status: BoltReadStatus.readFailed,
        errorCode: read.errorCode,
      );
    }
    if (read.status == MemoryReadStatus.partial) {
      return const BoltReadResult(status: BoltReadStatus.incompleteRead);
    }
    if (read.status != MemoryReadStatus.complete ||
        read.requestedBytes != byteLength ||
        read.bytesRead != byteLength ||
        read.bytes.length != byteLength) {
      return const BoltReadResult(status: BoltReadStatus.invalidReadResult);
    }

    return BoltReadResult(
      status: BoltReadStatus.success,
      boltCount: decodeUint32(read.bytes, endian: profile.boltEndian),
    );
  }
}
