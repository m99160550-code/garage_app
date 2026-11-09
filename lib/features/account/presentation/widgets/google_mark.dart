import 'package:flutter/material.dart';

/// A plain "G" in Google's blue, standing in for the official mark until
/// the brand asset is added (Google's branding guidelines).
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w700, fontSize: 14, height: 1),
      ),
    ),
  );
}
