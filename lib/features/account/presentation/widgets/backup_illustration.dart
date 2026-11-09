import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A phone, a dotted path and a cloud with a check, 88 pt (spec S-29 step 1).
/// Decorative: the title says the same thing. Not mirrored in Arabic: the
/// data still travels from the phone to the cloud.
class BackupIllustration extends StatelessWidget {
  const BackupIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget bubble(IconData icon, {Color? tint}) => Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceRaised,
        border: Border.all(color: colors.borderStrong),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Icon(icon, size: 30, color: tint ?? colors.textPrimary),
    );
    return ExcludeSemantics(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 88,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              bubble(Icons.smartphone),
              for (var i = 0; i < 4; i++)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.textTertiary),
                ),
              bubble(Icons.cloud_done_outlined, tint: colors.success),
            ],
          ),
        ),
      ),
    );
  }
}
