import 'package:flutter/animation.dart';

/// Spacing on a 4 pt grid (UI/UX spec 1.4).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Start and end margin on phones.
  static const double screenMargin = 20;

  /// Minimum touch target (NFR-ACC).
  static const double minTouchTarget = 44;
}

/// Corner radii (UI/UX spec 1.4).
abstract final class AppRadii {
  static const double sheet = 32;
  static const double card = 24;
  static const double statCard = 22;
  static const double row = 18;
  static const double button = 16;
  static const double input = 14;
  static const double pill = 999;
}

/// Motion tokens (UI/UX spec 1.6).
abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration emphasis = Duration(milliseconds: 400);

  static const Curve quickCurve = Curves.easeOut;
  static const Curve standardCurve = Cubic(0.2, 0, 0, 1);
  static const Curve emphasisCurve = Cubic(0.05, 0.7, 0.1, 1);
}
