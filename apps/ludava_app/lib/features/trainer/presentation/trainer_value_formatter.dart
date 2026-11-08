/// Formats integer values for trainer labels without floating-point conversion.
abstract final class TrainerValueFormatter {
  /// Groups [value] in threes, or returns `Unavailable` for a missing value.
  static String format(int? value) {
    if (value == null) return 'Unavailable';
    final digits = value.toString();
    final negative = digits.startsWith('-');
    final firstDigit = negative ? 1 : 0;
    final formatted = StringBuffer();
    if (negative) formatted.write('-');
    for (var index = firstDigit; index < digits.length; index++) {
      if (index > firstDigit && (digits.length - index) % 3 == 0) {
        formatted.write(',');
      }
      formatted.write(digits[index]);
    }
    return formatted.toString();
  }
}
