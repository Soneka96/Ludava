const _maxNativeAddress = 0x7fffffffffffffff;

int resolveGuestAddress({
  required int memoryBase,
  required int guestOffset,
  required int byteLength,
}) {
  if (memoryBase < 0) {
    throw ArgumentError.value(memoryBase, 'memoryBase', 'must not be negative');
  }
  if (guestOffset < 0) {
    throw ArgumentError.value(
        guestOffset, 'guestOffset', 'must not be negative');
  }
  if (byteLength <= 0) {
    throw ArgumentError.value(byteLength, 'byteLength', 'must be positive');
  }
  if (memoryBase > _maxNativeAddress ||
      guestOffset > _maxNativeAddress - memoryBase) {
    throw RangeError('Guest address resolution overflows a native address.');
  }

  final hostAddress = memoryBase + guestOffset;
  if (byteLength - 1 > _maxNativeAddress - hostAddress) {
    throw RangeError('Resolved memory range overflows a native address.');
  }
  return hostAddress;
}
