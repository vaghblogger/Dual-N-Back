import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nback_pro/src/core/constants/app_strings.dart';
import 'package:nback_pro/src/core/theme/app_theme.dart';
import 'package:nback_pro/src/presentation/screens/onboarding/login_screen.dart';
import '../../test_helpers.dart';

void main() {
  testWidgets('LoginScreen renders app name and sign-in options', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(),
        child: MaterialApp(
          theme: AppTheme.getTheme(0),
          home: const LoginScreen(),
        ),
      ),
    );
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.signInWithGoogle), findsOneWidget);
    expect(find.text(AppStrings.continueAsGuest), findsOneWidget);
  });
}
