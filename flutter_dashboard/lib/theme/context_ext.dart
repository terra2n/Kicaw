import 'package:flutter/material.dart';

extension ThemeColors on BuildContext {
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get background => Theme.of(this).scaffoldBackgroundColor;
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get textTertiary => Theme.of(this).colorScheme.outline;
  Color get border => Theme.of(this).dividerColor;
  Color get trackBg => Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get statusOccupied => Theme.of(this).colorScheme.primaryContainer;
  Color get statusEmpty => brightness == Brightness.dark
      ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
  Color get dotGreen => const Color(0xFF22C55E);
  Color get dotGray => brightness == Brightness.dark
      ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);
  Color get primaryLight => brightness == Brightness.dark
      ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);

  Brightness get brightness => Theme.of(this).brightness;
  bool get isDark => brightness == Brightness.dark;
}
