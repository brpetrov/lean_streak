import 'package:flutter/material.dart';

/// A tap target that also shows the pointer cursor in browsers, which a bare
/// GestureDetector doesn't.
class Clickable extends StatelessWidget {
  const Clickable({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
