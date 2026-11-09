import 'dart:ui' show Color;

/// The 12 paint colours for recolouring car illustrations (UI/UX spec 1.2).
/// Silver is the default when the user hasn't picked one.
enum PaintColor {
  obsidianBlack(Color(0xFF1C1D20)),
  polarWhite(Color(0xFFECEEF0)),
  silver(Color(0xFFAEB4BC)),
  gunmetalGrey(Color(0xFF5B616A)),
  desertSand(Color(0xFFC9B48A)),
  champagne(Color(0xFFD8C7A3)),
  midnightBlue(Color(0xFF1F3A68)),
  skyBlue(Color(0xFF6FA8DC)),
  racingRed(Color(0xFFB3261E)),
  sunsetOrange(Color(0xFFD9692B)),
  forestGreen(Color(0xFF2F5D46)),
  bronze(Color(0xFF8A6A4A));

  const PaintColor(this.color);

  final Color color;

  static const PaintColor fallback = PaintColor.silver;
}
