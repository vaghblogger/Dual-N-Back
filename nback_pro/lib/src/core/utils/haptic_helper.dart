import 'package:flutter/services.dart';

class HapticHelper {
  HapticHelper._();

  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
}
