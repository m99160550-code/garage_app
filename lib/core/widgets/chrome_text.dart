import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Text painted with the chrome gradient (`chrome.text`, spec 1.2).
///
/// Used for the "Garage" title, health score digits and the dashboard brand
/// name. Set [decorative] to hide it from screen readers when the meaning is
/// announced elsewhere.
///
/// How it's drawn: an invisible copy of the text sets the layout size and
/// carries the semantics. The visible copy is masked with the gradient over
/// a box that also covers the space below the line, so letters that reach
/// below it (the "g" in "Garage", Arabic descenders) are chrome too instead
/// of plain white.
class ChromeText extends StatelessWidget {
  const ChromeText(this.text, {super.key, required this.style, this.textAlign, this.decorative = false, this.maxLines});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final bool decorative;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final descenderRoom = fontSize * 0.35;

    Text copy() => Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );

    final layoutCopy = Opacity(opacity: 0, child: copy());
    final painted = Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ExcludeSemantics(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: context.colors.chromeText.createShader,
          child: Padding(
            padding: EdgeInsets.only(bottom: descenderRoom),
            child: copy(),
          ),
        ),
      ),
    );

    final result = Stack(clipBehavior: Clip.none, children: [layoutCopy, painted]);
    return decorative ? ExcludeSemantics(child: result) : result;
  }
}
