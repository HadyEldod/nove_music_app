/// Spacing, radius, stroke and type-scale tokens, mapped 1:1 from the Figma
/// design variables. The base unit is 3px.
library;

/// Gap / spacing scale (Figma: Gap).
class Gap {
  Gap._();
  static const double s = 3;
  static const double m = 6;
  static const double l = 9;
  static const double x1 = 12;
  static const double xl = 15;
  static const double xxl = 18;
  static const double xxxl = 21;
  static const double xxxxl = 27;
}

/// Corner-radius scale (Figma: Corner radius).
class Radii {
  Radii._();
  static const double s = 6;
  static const double m = 9;
  static const double l = 12;
  static const double xl = 15;
  static const double xxl = 18;
  static const double xxxl = 21;
  static const double xxxxl = 24;
}

/// Stroke / border widths (Figma: Stroke).
class Strokes {
  Strokes._();
  static const double s = 0.9;
  static const double l = 1.2;
  static const double m = 1.6;
  static const double xl = 2.1;
  static const double xxl = 2.7;
  static const double xxxl = 3.0;
  static const double xxxxl = 3.3;
}

/// Font-size scale (Figma: Text).
class TextSizes {
  TextSizes._();
  static const double x = 9;
  static const double caption = 12;
  static const double input = 15;
  static const double label = 18;
  static const double button = 21;
  static const double xl = 24;
  static const double heading = 27;
}
