import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nback_pro/src/logic/providers/auth_provider.dart';
import 'package:nback_pro/src/logic/providers/onboarding_provider.dart';
import 'package:nback_pro/src/data/models/user_settings.dart';
import 'package:nback_pro/src/data/repositories/stats_repository.dart';
import 'package:nback_pro/src/logic/providers/game_provider.dart';
import 'package:nback_pro/src/logic/providers/router_provider.dart';
import 'package:nback_pro/src/logic/providers/settings_provider.dart';
import '../../test_helpers.dart';

void main() {
  group('GoRouter redirect', () {
    setUpAll(() async {
      await initHiveForTest();
    });

    tearDown(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('signed-in user at / redirects to /home', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            MockAuthService(currentUser: MockUser(uid: 'test_uid')),
          ),
          onboardingCompleteProvider.overrideWith((ref) async => true),
          tutorialCompleteProvider.overrideWith((ref) async => true),
          settingsProvider.overrideWith(() => FakeSettingsNotifier(UserSettings())),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository('test_uid'),
          ),
          statsRepositoryProvider.overrideWithValue(
            StatsRepository('test_uid'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.fullPath, '/home');
    });

    testWidgets('signed-in user at /login redirects to /home', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            MockAuthService(currentUser: MockUser(uid: 'test_uid')),
          ),
          onboardingCompleteProvider.overrideWith((ref) async => true),
          tutorialCompleteProvider.overrideWith((ref) async => true),
          settingsProvider.overrideWith(() => FakeSettingsNotifier(UserSettings())),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository('test_uid'),
          ),
          statsRepositoryProvider.overrideWithValue(
            StatsRepository('test_uid'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(goRouterProvider);
      router.go('/login');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.fullPath, '/home');
    });

    testWidgets('not signed-in and onboarding not complete redirects non-entry to /', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          onboardingCompleteProvider.overrideWith((ref) async => false),
          tutorialCompleteProvider.overrideWith((ref) async => false),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(goRouterProvider);
      router.go('/home');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.fullPath, '/');
    });

    testWidgets('onboarding complete and tutorial not complete redirects /home to /tutorial/flow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          onboardingCompleteProvider.overrideWith((ref) async => true),
          tutorialCompleteProvider.overrideWith((ref) async => false),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(goRouterProvider);
      router.go('/home');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.fullPath,
        startsWith('/tutorial/flow'),
      );
    });

    testWidgets('/tutorial/n1 redirects to /tutorial/flow?start=1', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await setOnboardingComplete(true);
      await setTutorialComplete(true);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          onboardingCompleteProvider.overrideWith((ref) async => true),
          tutorialCompleteProvider.overrideWith((ref) async => true),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(goRouterProvider);
      router.go('/tutorial/n1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        contains('start=1'),
      );
    });

    testWidgets('/tutorial/n2 redirects to /tutorial/flow?start=5', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await setOnboardingComplete(true);
      await setTutorialComplete(true);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          onboardingCompleteProvider.overrideWith((ref) async => true),
          tutorialCompleteProvider.overrideWith((ref) async => true),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(goRouterProvider);
      router.go('/tutorial/n2');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        contains('start=5'),
      );
    });
  });
}
