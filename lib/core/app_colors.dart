import 'package:flutter/material.dart';

/// Central dark palette, mapped from the Figma "Music app" design variables
/// as resolved on the actual screens (primary accent = violet #8B5CF6).
class AppColors {
  AppColors._();

  // --- Backgrounds -------------------------------------------------------
  /// App background — near-black with a faint cool tint (overlay rgba(9,9,11)).
  static const Color background = Color(0xFF09090B);

  /// Slightly raised surfaces (mini player base rgba(23,23,32)).
  static const Color surface = Color(0xFF17171F);

  /// Cards / list rows (≈ white 5-6% over the background, solid approx).
  static const Color card = Color(0xFF17171E);

  /// A lighter raised surface for pills / chips.
  static const Color elevated = Color(0xFF212129);

  // --- Accents -----------------------------------------------------------
  /// Primary brand accent — violet (background/Main, Buttons/Main).
  static const Color accent = Color(0xFF8B5CF6);

  /// Magenta used for the ambient background glow (rgba(206,51,185)).
  static const Color glowMagenta = Color(0xFFCE33B9);

  /// Cyan used faintly in the top-left ambient glow (rgba(53,192,238)).
  static const Color glowCyan = Color(0xFF35C0EE);

  /// Lime — kept for the small notification-badge ring (rgba(239,255,120)).
  static const Color lime = Color(0xFFEFFF78);

  /// Error + the "like" accent.
  static const Color error = Color(0xFFC70036);
  static const Color like = Color(0xFFF43F6E);

  // --- Text --------------------------------------------------------------
  /// Typography/W to W, Haeding.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// A soft white-grey for secondary labels.
  static const Color textSecondary = Color(0xFFB3B3B3);

  /// Typography/paragraph — muted grey for subtitles.
  static const Color textMuted = Color(0xFF7D7D7D);

  /// Strok/Gray — thumbnail / divider hairlines.
  static const Color strokeGray = Color(0xFFB3B3B3);

  /// Hairline dividers (≈ white 10%).
  static const Color divider = Color(0xFF26262D);
}
