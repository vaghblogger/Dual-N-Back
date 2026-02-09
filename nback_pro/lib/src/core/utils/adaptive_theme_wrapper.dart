import 'package:flutter/material.dart';

import 'responsive_layout.dart';

/// Wraps the app with a [Theme] that scales [TextTheme] by screen size so fonts
/// are adaptive on phones and tablets. Place via [MaterialApp.builder].
class AdaptiveThemeWrapper extends StatelessWidget {
  const AdaptiveThemeWrapper({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveLayout.textScaleFactor(context);
    final scaledTextTheme = ResponsiveLayout.scaleTextTheme(theme.textTheme, scale);
    return Theme(
      data: theme.copyWith(textTheme: scaledTextTheme),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
