import 'package:flutter/material.dart';

/// Shared typography, shape, and control measurements for one visual style.
@immutable
class LudavaStylePreset {
  /// Creates one coordinated set of Material styling decisions.
  const LudavaStylePreset({
    required this.fontFamily,
    required this.textTheme,
    required this.controlRadius,
    required this.surfaceRadius,
    required this.buttonPadding,
    required this.buttonMinimumSize,
    required this.inputPadding,
    required this.inputFocusedBorderWidth,
  });

  /// Application typeface.
  final String fontFamily;

  /// Hierarchical text styles, including tabular numeric figures.
  final TextTheme textTheme;

  /// Radius shared by buttons and input fields.
  final double controlRadius;

  /// Radius used by card-like surfaces.
  final double surfaceRadius;

  /// Default button content padding.
  final EdgeInsetsGeometry buttonPadding;

  /// Minimum interactive button dimensions.
  final Size buttonMinimumSize;

  /// Default input content padding.
  final EdgeInsetsGeometry inputPadding;

  /// Thickness shared by focused input borders.
  final double inputFocusedBorderWidth;
}
