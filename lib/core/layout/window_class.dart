import 'package:flutter/widgets.dart';

/// Responsive size classes (UI/UX spec 2.4).
enum WindowClass {
  /// Under 600 pt: phones.
  compact,

  /// 600–839 pt: iPad portrait, iPad mini, Split View.
  medium,

  /// 840 pt and wider: iPad landscape.
  expanded;

  static WindowClass fromWidth(double width) {
    if (width >= 840) return WindowClass.expanded;
    if (width >= 600) return WindowClass.medium;
    return WindowClass.compact;
  }

  static WindowClass of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == WindowClass.compact;
}
