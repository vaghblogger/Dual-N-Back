import 'package:flutter/material.dart';

/// Breakpoints and helpers for adaptive layout across small phones, large phones, and tablets.
/// Uses [MediaQuery.sizeOf] only; no separate framework.
class ResponsiveLayout {
  ResponsiveLayout._();

  /// Width below which we treat as small phone (compact padding).
  static const double smallPhone = 360;

  /// Width at or above which we treat as tablet (expanded padding, optional max content width).
  static const double tablet = 600;

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
}
