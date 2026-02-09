import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nback_pro/src/logic/providers/onboarding_provider.dart';

void main() {
  group('Onboarding providers', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('onboardingCompleteProvider default is false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final value = await container.read(onboardingCompleteProvider.future);
      expect(value, false);
    });

    test('setOnboardingComplete then onboardingCompleteProvider is true', () async {
      await setOnboardingComplete(true);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final value = await container.read(onboardingCompleteProvider.future);
      expect(value, true);
    });

    test('isGuestProvider default is false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final value = await container.read(isGuestProvider.future);
      expect(value, false);
    });

    test('setGuest then isGuestProvider is true', () async {
      await setGuest(true);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final value = await container.read(isGuestProvider.future);
      expect(value, true);
    });

    test('tutorialCompleteProvider default is false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final value = await container.read(tutorialCompleteProvider.future);
      expect(value, false);
    });

    test('setTutorialComplete then tutorialCompleteProvider is true', () async {
      await setTutorialComplete(true);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final value = await container.read(tutorialCompleteProvider.future);
      expect(value, true);
    });
  });
}
