import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'chrome_text.dart';

/// The TDC-mena Garage app mark: a chrome "G" monogram in a circular tile,
/// using the same neutral tile style as brand monograms (spec 1.2).
///
/// Placeholder until the final brand asset is delivered; replace the
/// contents of this widget only, not its call sites.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surfaceRaised,
          border: Border.all(color: colors.borderStrong),
          boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 12))],
        ),
        child: ChromeText(
          'G',
          style: TextStyle(
            fontFamily: AppFonts.interDisplay,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.5,
            height: 1,
          ),
        ),
      ),
    );
  }
}
