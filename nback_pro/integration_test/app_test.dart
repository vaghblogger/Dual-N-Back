import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nback_pro/src/core/constants/app_strings.dart';
import 'package:nback_pro/src/data/models/user_settings.dart';
import 'package:nback_pro/src/data/repositories/stats_repository.dart';
import 'package:nback_pro/src/logic/providers/auth_provider.dart';
import 'package:nback_pro/src/logic/providers/game_provider.dart';
import 'package:nback_pro/src/logic/providers/settings_provider.dart';
import 'package:nback_pro/src/logic/providers/stats_provider.dart';
import 'package:nback_pro/src/logic/providers/subscription_provider.dart';
import 'package:nback_pro/src/app.dart';

import '../test/test_helpers.dart';

/// Smoke integration test: app starts and login screen is visible.
/// Run with: flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts and login screen is visible', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initHiveForTest();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository('guest')),
          statsRepositoryProvider.overrideWithValue(StatsRepository('guest')),
          settingsProvider.overrideWith(() => FakeSettingsNotifier(UserSettings())),
          isPremiumProvider.overrideWithValue(true),
        ],
        child: const NBackApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.signInWithGoogle), findsOneWidget);
    expect(find.text(AppStrings.continueAsGuest), findsOneWidget);
  });
}
