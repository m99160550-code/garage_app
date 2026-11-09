import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../features/vehicles/domain/body_type.dart';

/// Generic side-view car illustration for each body type, recoloured to the
/// paint colour (FR-VEH-09, FR-REF-07). No brand-specific shapes.
///
/// INTERIM ARTWORK: stylised profiles drawn in code. The design team's
/// illustration set replaces [_BodyProfile.forType] without changing this
/// widget's API.
///
/// Car illustrations are never mirrored in Arabic (NFR-LOC-02).
class CarIllustration extends StatelessWidget {
  const CarIllustration({
    super.key,
    required this.bodyType,
    required this.paint,
    this.showReflection = true,
    this.semanticLabel,
  });

  final BodyType bodyType;
  final Color paint;

  /// Reflective floor under the car (dashboard and intro style).
  final bool showReflection;

  /// Describe the car for screen readers, or leave null when decorative.
  final String? semanticLabel;

  /// Width-to-height ratio of the painted car area.
  static const double aspectRatio = _CarPainter.canvasWidth / _CarPainter.canvasHeight;

  @override
  Widget build(BuildContext context) {
    final painter = _CarPainter(bodyColor: paint, profile: _BodyProfile.forType(bodyType));

    Widget result = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final carHeight = width / aspectRatio;
        final car = SizedBox(
          width: width,
          height: carHeight,
          child: CustomPaint(painter: painter),
        );
        if (!showReflection) return car;

        // Reflection: flipped copy at 28% opacity, fading out over 60% of
        // its height, with a slight blur (design spec S-09 region 3).
        final reflectionHeight = carHeight * 0.45;
        final reflection = SizedBox(
          width: width,
          height: reflectionHeight,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: carHeight,
              child: Opacity(
                opacity: 0.28,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0.05, 0.45],
                  ).createShader(bounds),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: Transform.flip(flipY: true, child: car),
                  ),
                ),
              ),
            ),
          ),
        );
        return Column(mainAxisSize: MainAxisSize.min, children: [car, reflection]);
      },
    );

    result = Directionality(textDirection: TextDirection.ltr, child: result);
    return semanticLabel == null
        ? ExcludeSemantics(child: result)
        : Semantics(
            image: true,
            label: semanticLabel,
            child: ExcludeSemantics(child: result),
          );
  }
}

/// The shape of one body type on the 400 × 130 canvas. The front faces the
/// start of the canvas (left), as in the reference dashboard.
class _BodyProfile {
  const _BodyProfile({
    required this.body,
    required this.glass,
    required this.wheelsX,
    required this.pillarsX,
    required this.shoulderY,
    required this.headlight,
    required this.taillight,
    this.wheelRadius = 23,
    this.extraLines = const [],
  });

  final Path Function() body;
  final Path Function() glass;
  final List<double> wheelsX;

  /// Pillars between windows (x, top y, bottom y).
  final List<(double, double, double)> pillarsX;
  final double shoulderY;
  final Rect headlight;
  final Rect taillight;
  final double wheelRadius;

  /// Extra panel lines, for example a pickup's bed rail.
  final List<(Offset, Offset)> extraLines;

  static _BodyProfile forType(BodyType type) => switch (type) {
    BodyType.sedan => _sedan,
    BodyType.hatchback => _hatchback,
    BodyType.suv => _suv,
    BodyType.coupe => _coupe,
    BodyType.wagon => _wagon,
    BodyType.pickup => _pickup,
    BodyType.van => _van,
  };

  static final _sedan = _BodyProfile(
    body: () => Path()
      ..moveTo(12, 100)
      ..lineTo(12, 84)
      ..quadraticBezierTo(14, 70, 58, 65)
      ..lineTo(132, 58)
      ..cubicTo(152, 50, 166, 34, 188, 29)
      ..lineTo(262, 27)
      ..cubicTo(288, 29, 306, 43, 322, 54)
      ..lineTo(370, 58)
      ..quadraticBezierTo(390, 60, 390, 76)
      ..lineTo(388, 100)
      ..close(),
    glass: () => Path()
      ..moveTo(148, 56)
      ..cubicTo(164, 44, 174, 36, 192, 33)
      ..lineTo(260, 31.5)
      ..cubicTo(280, 33, 296, 43, 308, 53)
      ..close(),
    wheelsX: const [92, 316],
    pillarsX: const [(226, 31, 56)],
    shoulderY: 66,
    headlight: const Rect.fromLTWH(15, 70, 22, 7),
    taillight: const Rect.fromLTWH(378, 64, 11, 9),
  );

  static final _hatchback = _BodyProfile(
    body: () => Path()
      ..moveTo(18, 100)
      ..lineTo(18, 84)
      ..quadraticBezierTo(20, 70, 62, 65)
      ..lineTo(134, 58)
      ..cubicTo(154, 50, 168, 34, 190, 29)
      ..lineTo(286, 28)
      ..cubicTo(312, 30, 330, 44, 344, 62)
      ..lineTo(352, 80)
      ..lineTo(350, 100)
      ..close(),
    glass: () => Path()
      ..moveTo(150, 56)
      ..cubicTo(166, 44, 176, 36, 194, 33)
      ..lineTo(284, 32)
      ..cubicTo(304, 34, 318, 44, 328, 56)
      ..close(),
    wheelsX: const [96, 296],
    pillarsX: const [(232, 32, 56)],
    shoulderY: 66,
    headlight: const Rect.fromLTWH(21, 70, 22, 7),
    taillight: const Rect.fromLTWH(340, 62, 10, 12),
  );

  static final _suv = _BodyProfile(
    body: () => Path()
      ..moveTo(12, 100)
      ..lineTo(12, 76)
      ..quadraticBezierTo(14, 58, 60, 54)
      ..lineTo(125, 50)
      ..cubicTo(145, 40, 160, 22, 185, 16)
      ..lineTo(330, 14)
      ..quadraticBezierTo(372, 16, 382, 40)
      ..lineTo(388, 58)
      ..lineTo(388, 100)
      ..close(),
    glass: () => Path()
      ..moveTo(142, 48)
      ..cubicTo(156, 36, 166, 25, 188, 21)
      ..lineTo(328, 19)
      ..quadraticBezierTo(360, 21, 370, 46)
      ..close(),
    wheelsX: const [92, 316],
    wheelRadius: 25,
    pillarsX: const [(232, 19, 48), (300, 19, 47)],
    shoulderY: 58,
    headlight: const Rect.fromLTWH(15, 62, 24, 8),
    taillight: const Rect.fromLTWH(380, 50, 9, 14),
  );

  static final _coupe = _BodyProfile(
    body: () => Path()
      ..moveTo(12, 100)
      ..lineTo(12, 86)
      ..quadraticBezierTo(14, 72, 58, 67)
      ..lineTo(140, 60)
      ..cubicTo(165, 49, 180, 37, 205, 34)
      ..lineTo(250, 33)
      ..cubicTo(290, 35, 330, 51, 360, 61)
      ..quadraticBezierTo(390, 63, 390, 78)
      ..lineTo(388, 100)
      ..close(),
    glass: () => Path()
      ..moveTo(158, 58)
      ..cubicTo(176, 46, 188, 39, 207, 38)
      ..lineTo(248, 37)
      ..cubicTo(276, 39, 300, 48, 318, 57)
      ..close(),
    wheelsX: const [92, 316],
    pillarsX: const [],
    shoulderY: 68,
    headlight: const Rect.fromLTWH(15, 72, 22, 6),
    taillight: const Rect.fromLTWH(378, 66, 11, 8),
  );

  static final _wagon = _BodyProfile(
    body: () => Path()
      ..moveTo(12, 100)
      ..lineTo(12, 84)
      ..quadraticBezierTo(14, 70, 58, 65)
      ..lineTo(132, 58)
      ..cubicTo(152, 50, 166, 34, 188, 29)
      ..lineTo(352, 28)
      ..quadraticBezierTo(376, 30, 384, 46)
      ..lineTo(390, 62)
      ..lineTo(388, 100)
      ..close(),
    glass: () => Path()
      ..moveTo(148, 56)
      ..cubicTo(164, 44, 174, 36, 192, 33)
      ..lineTo(350, 32)
      ..quadraticBezierTo(366, 34, 372, 54)
      ..close(),
    wheelsX: const [92, 316],
    pillarsX: const [(228, 32, 56), (300, 32, 55)],
    shoulderY: 66,
    headlight: const Rect.fromLTWH(15, 70, 22, 7),
    taillight: const Rect.fromLTWH(380, 60, 9, 12),
  );

  static final _pickup = _BodyProfile(
    body: () => Path()
      ..moveTo(12, 100)
      ..lineTo(12, 78)
      ..quadraticBezierTo(14, 62, 58, 58)
      ..lineTo(118, 54)
      ..cubicTo(134, 42, 146, 26, 168, 22)
      ..lineTo(222, 20)
      ..quadraticBezierTo(236, 20, 240, 38)
      ..lineTo(244, 56)
      ..lineTo(390, 56)
      ..lineTo(390, 100)
      ..close(),
    glass: () => Path()
      ..moveTo(132, 52)
      ..cubicTo(144, 40, 152, 30, 170, 27)
      ..lineTo(220, 25)
      ..quadraticBezierTo(230, 26, 233, 42)
      ..lineTo(234, 52)
      ..close(),
    wheelsX: const [88, 320],
    wheelRadius: 25,
    pillarsX: const [(184, 26, 52)],
    shoulderY: 62,
    headlight: const Rect.fromLTWH(15, 64, 24, 8),
    taillight: const Rect.fromLTWH(382, 60, 8, 14),
    extraLines: const [(Offset(250, 62), Offset(386, 62)), (Offset(248, 56), Offset(248, 98))],
  );

  static final _van = _BodyProfile(
    body: () => Path()
      ..moveTo(12, 100)
      ..lineTo(12, 70)
      ..quadraticBezierTo(14, 52, 40, 46)
      ..lineTo(78, 40)
      ..cubicTo(96, 22, 110, 12, 136, 10)
      ..lineTo(370, 10)
      ..quadraticBezierTo(388, 12, 390, 30)
      ..lineTo(390, 100)
      ..close(),
    glass: () => Path()
      ..moveTo(92, 40)
      ..cubicTo(104, 26, 114, 18, 136, 16)
      ..lineTo(176, 16)
      ..lineTo(176, 40)
      ..close()
      ..addRRect(RRect.fromLTRBR(186, 16, 270, 40, const Radius.circular(3)))
      ..addRRect(RRect.fromLTRBR(278, 16, 376, 40, const Radius.circular(3))),
    wheelsX: const [86, 322],
    wheelRadius: 24,
    pillarsX: const [],
    shoulderY: 52,
    headlight: const Rect.fromLTWH(15, 58, 20, 8),
    taillight: const Rect.fromLTWH(383, 40, 7, 20),
    extraLines: const [(Offset(180, 44), Offset(180, 98))],
  );
}

class _CarPainter extends CustomPainter {
  _CarPainter({required this.bodyColor, required this.profile});

  final Color bodyColor;
  final _BodyProfile profile;

  static const double canvasWidth = 400;
  static const double canvasHeight = 130;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / canvasWidth, size.height / canvasHeight);

    final hsl = HSLColor.fromColor(bodyColor);
    Color shade(double delta) => hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();

    // Contact shadow on the floor.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(200, 124), width: 360, height: 10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Body with top-light shading.
    final body = profile.body();
    final bounds = body.getBounds();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shade(0.22), bodyColor, shade(-0.28)],
          stops: const [0, 0.45, 1],
        ).createShader(bounds),
    );

    // Lower sill shadow.
    canvas.drawRect(
      Rect.fromLTRB(bounds.left + 18, 92, bounds.right - 14, 100),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    // Glass.
    final glass = profile.glass();
    canvas.drawPath(
      glass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A414B), Color(0xFF0E1013)],
        ).createShader(glass.getBounds()),
    );
    for (final (x, top, bottom) in profile.pillarsX) {
      canvas.drawRect(Rect.fromLTRB(x, top, x + 5, bottom), Paint()..color = shade(-0.12));
    }

    // Shoulder highlight.
    final shoulder = Path()
      ..moveTo(bounds.left + 28, profile.shoulderY + 3)
      ..quadraticBezierTo(200, profile.shoulderY - 6, bounds.right - 18, profile.shoulderY - 3);
    canvas.drawPath(
      shoulder,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Door seams and panel lines.
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black.withValues(alpha: 0.3);
    for (final (x, _, bottom) in profile.pillarsX.take(1)) {
      canvas.drawLine(Offset(x + 2, bottom + 1), Offset(x + 3, 97), seam);
    }
    for (final (from, to) in profile.extraLines) {
      canvas.drawLine(from, to, seam);
    }

    // Lights.
    canvas.drawRRect(
      RRect.fromRectAndRadius(profile.headlight, const Radius.circular(3)),
      Paint()..color = const Color(0xFFE8ECF0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(profile.taillight, const Radius.circular(2)),
      Paint()..color = const Color(0xFFB3261E),
    );

    // Wheels.
    final r = profile.wheelRadius;
    for (final x in profile.wheelsX) {
      final centre = Offset(x, 100);
      canvas.drawCircle(centre, r + 4, Paint()..color = const Color(0xFF08090B)); // arch
      canvas.drawCircle(centre, r, Paint()..color = const Color(0xFF15171A)); // tyre
      final rim = r * 0.65;
      canvas.drawCircle(
        centre,
        rim,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFE3E7EC), Color(0xFF8E959F), Color(0xFF4A5059)],
            stops: [0, 0.6, 1],
          ).createShader(Rect.fromCircle(center: centre, radius: rim)),
      );
      final spoke = Paint()
        ..color = const Color(0xFF3A404A)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 5; i++) {
        final angle = i * 2 * math.pi / 5;
        canvas.drawLine(
          centre.translate(4 * math.cos(angle), 4 * math.sin(angle)),
          centre.translate((rim - 2) * math.cos(angle), (rim - 2) * math.sin(angle)),
          spoke,
        );
      }
      canvas.drawCircle(centre, 3.5, Paint()..color = const Color(0xFF2A2F37));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CarPainter oldDelegate) => oldDelegate.bodyColor != bodyColor || oldDelegate.profile != profile;
}
