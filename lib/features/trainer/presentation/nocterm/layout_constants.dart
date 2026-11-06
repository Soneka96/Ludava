/// Layout limits and dimensions used by the Nocterm trainer screens.
abstract final class NoctermLayoutConstants {
  /// Narrowest terminal width that can show the trainer menu clearly.
  static const int minimumMenuWidth = 48;

  /// Fixed menu rows for its header, title, separators, and keyboard hints.
  static const int fixedMenuRows = 11;

  /// Fixed editor rows for its title, current value, input, and key hints.
  static const int fixedEditorRows = 11;

  /// Width of the horizontal separators in terminal cells.
  static const int separatorWidth = 40;
}
