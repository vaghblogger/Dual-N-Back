import 'package:flutter/material.dart';

/// Breakpoints and helpers for adaptive layout across small phones, large phones, and tablets.
/// Uses [MediaQuery.sizeOf] only; no separate framework.
/// All dimensions (padding, font, icon, spacing) scale with screen size.
class ResponsiveLayout {
  ResponsiveLayout._();

  /// Width below which we treat as small phone (compact padding).
  static const double smallPhone = 360;

  /// Width at or above which we treat as tablet (expanded padding, optional max content width).
  static const double tablet = 600;

  /// Reference shortest side for scale factor (e.g. ~400 for typical phone).
  static const double _refShort = 400;

  /// Text scale factor: 1.0 at reference size, scales up on larger screens (clamped).
  static double textScaleFactor(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    final scale = short / _refShort;
    return scale.clamp(0.85, 1.5);
  }

  /// Font size scaled by screen size. Use for any custom text that should adapt.
  static double scaledFontSize(BuildContext context, double baseFontSize) {
    return baseFontSize * textScaleFactor(context);
  }

  /// Spacing (height/width) scaled by screen size. Use for SizedBox(height: ...) etc.
  static double spacing(BuildContext context, double baseSpacing) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    final scale = (short / _refShort).clamp(0.9, 1.4);
    return (baseSpacing * scale).roundToDouble();
  }

  /// App bar and large list icon size (adaptive).
  static double iconSizeAppBar(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.09).clamp(28.0, 44.0);
  }

  /// Medium icon (list tiles, buttons).
  static double iconSizeMedium(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.065).clamp(22.0, 36.0);
  }

  /// Small icon (inline, badges).
  static double iconSizeSmall(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.045).clamp(16.0, 28.0);
  }

  /// Horizontal padding in logical pixels: 12 for small phone, 16 for phone, 24 for tablet.
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < smallPhone) return 12;
    if (w >= tablet) return 24;
    return 16;
  }

  /// General screen padding: same logic as [horizontalPadding] for all sides.
  static EdgeInsets contentPadding(BuildContext context) {
    final p = horizontalPadding(context);
    return EdgeInsets.all(p);
  }

  /// Padding for the game grid area: scales with shortest side (e.g. min(24, shortSide * 0.06)).
  static double gridPadding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final short = size.shortestSide;
    final scaled = short * 0.06;
    return scaled.clamp(12.0, 24.0);
  }

  /// Inner padding inside the game canvas so the canvas is visibly larger than the 3x3 grid.
  static double gameCanvasInnerPadding(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    final scaled = short * 0.08;
    return scaled.clamp(16.0, 36.0);
  }

  /// Size for the center "+" icon in the game grid: proportional to shortest side.
  static double gameGridCenterIconSize(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.12).clamp(32.0, 64.0);
  }

  /// Bottom button row: horizontal padding (same as [horizontalPadding]).
  static double buttonRowHorizontalPadding(BuildContext context) =>
      horizontalPadding(context);

  /// Bottom button row: bottom padding. Slightly larger on tablet.
  static double buttonRowBottomPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= tablet ? 32 : 28;
  }

  /// Game screen: circle button size (adaptive to avoid overflow on small screens).
  static double gameCircleButtonSize(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.22).clamp(64.0, 104.0);
  }

  /// Game screen: gap between canvas and button row (compact on small screens).
  static double gameCanvasToButtonGap(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.04).clamp(12.0, 24.0);
  }

  /// Button vertical padding: scale with shortest side (clamped).
  static double buttonVerticalPadding(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.045).clamp(14.0, 22.0);
  }

  /// Button horizontal padding: scale with shortest side (clamped).
  static double buttonHorizontalPadding(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.05).clamp(16.0, 24.0);
  }

  /// Button minimum height: scale with shortest side (clamped).
  static double buttonMinHeight(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.07).clamp(48.0, 64.0);
  }

  /// Button font size: scale with shortest side (clamped).
  static double buttonFontSize(BuildContext context) {
    final short = MediaQuery.sizeOf(context).shortestSide;
    return (short * 0.042).clamp(15.0, 19.0);
  }

  /// Max content width for tablet layout (e.g. center content on wide screens).
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < tablet) return double.infinity;
    return 600;
  }

  /// Returns a copy of [base] with all font sizes scaled by [scaleFactor].
  static TextTheme scaleTextTheme(TextTheme base, double scaleFactor) {
    double scale(double? size) => size == null ? 16 : (size * scaleFactor).roundToDouble();
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(fontSize: scale(base.displayLarge?.fontSize)),
      displayMedium: base.displayMedium?.copyWith(fontSize: scale(base.displayMedium?.fontSize)),
      displaySmall: base.displaySmall?.copyWith(fontSize: scale(base.displaySmall?.fontSize)),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: scale(base.headlineLarge?.fontSize)),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: scale(base.headlineMedium?.fontSize)),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: scale(base.headlineSmall?.fontSize)),
      titleLarge: base.titleLarge?.copyWith(fontSize: scale(base.titleLarge?.fontSize)),
      titleMedium: base.titleMedium?.copyWith(fontSize: scale(base.titleMedium?.fontSize)),
      titleSmall: base.titleSmall?.copyWith(fontSize: scale(base.titleSmall?.fontSize)),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: scale(base.bodyLarge?.fontSize)),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: scale(base.bodyMedium?.fontSize)),
      bodySmall: base.bodySmall?.copyWith(fontSize: scale(base.bodySmall?.fontSize)),
      labelLarge: base.labelLarge?.copyWith(fontSize: scale(base.labelLarge?.fontSize)),
      labelMedium: base.labelMedium?.copyWith(fontSize: scale(base.labelMedium?.fontSize)),
      labelSmall: base.labelSmall?.copyWith(fontSize: scale(base.labelSmall?.fontSize)),
    );
  }
}
