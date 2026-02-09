import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nback_pro/src/core/constants/app_strings.dart';
import 'package:nback_pro/src/core/theme/app_theme.dart';
import 'package:nback_pro/src/data/models/user_settings.dart';
import 'package:nback_pro/src/logic/providers/game_provider.dart';
import 'package:nback_pro/src/logic/providers/stats_provider.dart';
import 'package:nback_pro/src/presentation/screens/home/home_screen.dart';
import '../../test_helpers.dart';

void main() {
  testWidgets('HomeScreen renders and shows Train button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(settings: UserSettings(), isPremium: true),
          highestNProvider.overrideWith((ref) async => 2),
          currentStreakProvider.overrideWith((ref) async => 0),
          isChallengeCompleteTodayProvider.overrideWith((ref) async => false),
          last7DaysCompletedProvider.overrideWith((ref) async => List.filled(7, false)),
        ],
        child: MaterialApp(
          theme: AppTheme.getTheme(0),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.trainYourBrain), findsOneWidget);
  });

  testWidgets('HomeScreen has settings and stats icons in app bar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(settings: UserSettings(), isPremium: true),
          highestNProvider.overrideWith((ref) async => 2),
          currentStreakProvider.overrideWith((ref) async => 0),
          isChallengeCompleteTodayProvider.overrideWith((ref) async => false),
          last7DaysCompletedProvider.overrideWith((ref) async => List.filled(7, false)),
        ],
        child: MaterialApp(
          theme: AppTheme.getTheme(0),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart), findsOneWidget);
  });
}
