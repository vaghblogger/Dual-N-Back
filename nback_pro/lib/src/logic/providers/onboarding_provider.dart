import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingComplete = 'onboarding_complete';
const String _keyIsGuest = 'is_guest';
const String _keyTutorialComplete = 'tutorial_complete';

final onboardingCompleteProvider =
    FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyOnboardingComplete) ?? false;
});

final isGuestProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyIsGuest) ?? false;
});

final tutorialCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyTutorialComplete) ?? false;
});

Future<void> setOnboardingComplete(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyOnboardingComplete, value);
}

Future<void> setGuest(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyIsGuest, value);
}

Future<void> setTutorialComplete(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyTutorialComplete, value);
}
